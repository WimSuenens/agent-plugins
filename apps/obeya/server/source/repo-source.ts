// The v1 source: the main checkout, each live worktree (from git's worktree list) and the tracker.
import { execFile } from 'node:child_process'
import { readdir, readFile } from 'node:fs/promises'
import { basename, join } from 'node:path'
import { promisify } from 'node:util'
import type { Decision, Item, ParseFailure, Provenance, ProjectConfig, ProjectSummary } from '../../shared/types'
import { ideaEntries, inboxEntries } from './intake'
import { readWorkArtifacts } from './work-artifacts'
import { readDirections } from './direction'
import { pickInFlight } from './in-flight'
import { SourceError, type ReadModelSource, type TrackerAdapter } from './types'

const run = promisify(execFile)

interface Tree {
  path: string
  provenance: Provenance
}

export async function trees(p: ProjectConfig): Promise<Tree[]> {
  let out: string
  try {
    out = (await run('git', ['-C', p.path, 'worktree', 'list', '--porcelain'])).stdout
  } catch (e: any) {
    if (e?.code === 'ENOENT') throw new SourceError('git is not installed')
    throw new SourceError(`project path ${p.path} does not exist or is not a git repository`)
  }
  const list: Tree[] = []
  for (const block of out.split('\n\n')) {
    const lines = block.split('\n')
    const path = lines.find((l) => l.startsWith('worktree '))?.slice('worktree '.length)
    if (!path || lines.includes('bare')) continue
    if (list.length === 0) {
      list.push({ path, provenance: { kind: 'merged' } })
      continue
    }
    const branch = lines.find((l) => l.startsWith('branch '))?.slice('branch refs/heads/'.length)
    list.push({ path, provenance: { kind: 'in-flight', item: branch || basename(path) } })
  }
  return list
}

interface Found {
  decision?: Decision
  failure?: ParseFailure
}

/** The web address of a tree's origin remote (GitHub only), or null. */
async function webBase(treePath: string): Promise<string | null> {
  try {
    const url = (await run('git', ['-C', treePath, 'remote', 'get-url', 'origin'])).stdout.trim()
    const m = url.match(/github\.com[:/]([^/\s]+\/[^/\s]+?)(?:\.git)?\/?$/)
    return m ? `https://github.com/${m[1]}` : null
  } catch {
    return null
  }
}

function parseAdr(rel: string, text: string, provenance: Provenance, web: string | null): Found {
  const fail = (reason: string): Found => ({ failure: { path: rel, reason, provenance } })
  const num = basename(rel).match(/^(\d{4})-.+\.md$/)
  if (!num) return fail('file name does not start with a four digit number and a dash')
  const fm = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/)
  if (!fm) return fail('missing front matter block with a status line')
  const status = fm[1].match(/^status:[ \t]*(\S.*?)[ \t]*$/m)?.[1]
  if (!status) return fail('front matter has no status')
  const title = text.slice(fm[0].length).match(/^#\s+(\S.*?)\s*$/m)?.[1]
  if (!title) return fail('missing a "# title" heading')
  const order = Number(num[1])
  return { decision: { id: `adr-${num[1]}`, kind: 'adr', title, status, order, date: null, ref: rel, url: web && `${web}/blob/${provenance.kind === 'in-flight' ? provenance.item : 'HEAD'}/${rel}`, provenance } }
}

/** ADR artifacts of every tree. A worktree's copy is in flight only when its branch changed it since its merge-base with main. */
async function adrs([main, ...others]: Tree[]): Promise<Found[]> {
  const web = await webBase(main.path)
  const read = async (tree: Tree) => {
    const dir = join(tree.path, 'docs', 'adr')
    let names: string[] = []
    try {
      names = (await readdir(dir)).filter((n) => n.endsWith('.md')).sort()
    } catch {}
    return Promise.all(names.map(async (n) => ({ rel: `docs/adr/${n}`, text: await readFile(join(dir, n), 'utf8'), tree })))
  }
  const base = await read(main)
  const found: Found[] = []
  const ids = new Set<string>()
  for (const f of await pickInFlight(main.path, base, (await Promise.all(others.map(read))).flat())) {
    const r = parseAdr(f.rel, f.text, f.tree.provenance, web)
    if (r.decision) {
      if (ids.has(r.decision.id) && f.tree.provenance.kind === 'in-flight') r.decision.id += `@${f.tree.provenance.item}`
      ids.add(r.decision.id)
    }
    found.push(r)
  }
  return found
}

const ttlMs = () => Math.max(0, Number(process.env.OBEYA_CACHE_SECONDS ?? 5)) * 1000
const memo = new Map<string, { at: number; value: Promise<unknown> }>()

/** Tracker reads (gh calls) are shared by the endpoints of one refresh: a short TTL cache; a failed read is never kept. */
function cached<T>(key: string, read: () => Promise<T>): Promise<T> {
  const ttl = ttlMs()
  const hit = memo.get(key)
  if (ttl > 0 && hit && Date.now() - hit.at < ttl) return hit.value as Promise<T>
  const value = read()
  if (ttl > 0) {
    memo.set(key, { at: Date.now(), value })
    value.catch(() => {
      if (memo.get(key)?.value === value) memo.delete(key)
    })
  }
  return value
}

export function createRepoSource(tracker: TrackerAdapter): ReadModelSource {
  const ideas = async (p: ProjectConfig) => {
    if (!p.tracker) return { entries: [], failures: [] }
    const { login, issues } = await cached(`ideas:${p.path}`, () => tracker.ideas(p.path))
    return ideaEntries(login, issues)
  }
  const cards = async (p: ProjectConfig) => {
    const t = p.tracker
    return t ? cached(`cards:${t.owner}/${t.projectNumber}`, () => tracker.cards(t)) : []
  }
  return {
    async project(p): Promise<ProjectSummary> {
      try {
        const [main] = await trees(p)
        return { id: p.id, state: 'ok', name: basename(main.path) }
      } catch (e: any) {
        return { id: p.id, state: 'error', name: null, error: e.message }
      }
    },
    async decisions(p) {
      return (await adrs(await trees(p)))
        .flatMap((f) => (f.decision ? [f.decision] : []))
        .sort((a, b) => (a.order ?? 0) - (b.order ?? 0) || a.id.localeCompare(b.id))
    },
    async parseFailures(p) {
      const ts = await trees(p)
      const [adr, dirs, work, cardList, idea] = await Promise.all([adrs(ts), readDirections(ts), readWorkArtifacts(ts), cards(p), ideas(p)])
      const artifact = [...adr, ...dirs].flatMap((f) => (f.failure ? [f.failure] : [])).concat(work.failures)
      const board = cardList
        .filter((c) => c.number === null)
        .map((c): ParseFailure => ({ path: `tracker:${c.raw}`, reason: 'board card is not linked to an issue', provenance: { kind: 'event' } }))
      return [...artifact, ...board, ...idea.failures]
    },
    async items(p) {
      return (await cards(p)).flatMap((c): Item[] =>
        c.number === null
          ? []
          : [{ id: `item-${c.number}`, number: c.number, title: c.title, url: c.url, factoryStatus: c.factoryStatus ?? 'No status', kind: c.kind, role: c.role, effort: c.effort, ...(c.blockedBy ? { blockedBy: c.blockedBy } : {}), provenance: { kind: 'event' } }],
      )
    },
    async directions(p) {
      return (await readDirections(await trees(p))).flatMap((f) => (f.direction ? [f.direction] : []))
    },
    async andon(p) {
      return (await readWorkArtifacts(await trees(p))).andon
    },
    async pendingDecisions(p) {
      return (await readWorkArtifacts(await trees(p))).pending
    },
    async intake(p) {
      return [...(await ideas(p)).entries, ...(await inboxEntries(await trees(p)))]
    },
  }
}
