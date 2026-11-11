// The v1 source: the main checkout, each live worktree (from git's worktree list) and the tracker.
import { execFile } from 'node:child_process'
import { readdir, readFile } from 'node:fs/promises'
import { basename, join } from 'node:path'
import { promisify } from 'node:util'
import type { Decision, Item, ParseFailure, Provenance, ProjectConfig, ProjectSummary } from '../../shared/types'
import { ideaEntries, inboxEntries } from './intake'
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

function parseAdr(rel: string, text: string, provenance: Provenance): Found {
  const fail = (reason: string): Found => ({ failure: { path: rel, reason, provenance } })
  const num = basename(rel).match(/^(\d{4})-.+\.md$/)
  if (!num) return fail('file name does not start with a four digit number and a dash')
  const fm = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/)
  if (!fm) return fail('missing front matter block with a status line')
  const status = fm[1].match(/^status:\s*(\S.*?)\s*$/m)?.[1]
  if (!status) return fail('front matter has no status')
  const title = text.slice(fm[0].length).match(/^#\s+(\S.*?)\s*$/m)?.[1]
  if (!title) return fail('missing a "# title" heading')
  const order = Number(num[1])
  return { decision: { id: `adr-${num[1]}`, kind: 'adr', title, status, order, date: null, ref: rel, provenance } }
}

/** ADR artifacts of every tree. A worktree's copy that equals the main one is not repeated; a changed one replaces it. */
async function adrs(p: ProjectConfig): Promise<Found[]> {
  const [main, ...others] = await trees(p)
  const read = async (tree: Tree) => {
    const dir = join(tree.path, 'docs', 'adr')
    let names: string[] = []
    try {
      names = (await readdir(dir)).filter((n) => n.endsWith('.md')).sort()
    } catch {}
    return Promise.all(names.map(async (n) => ({ rel: `docs/adr/${n}`, text: await readFile(join(dir, n), 'utf8'), tree })))
  }
  const base = await read(main)
  const mainText = new Map(base.map((f) => [f.rel, f.text]))
  const changed = (await Promise.all(others.map(read))).flat().filter((f) => mainText.get(f.rel) !== f.text)
  const replaced = new Set(changed.map((f) => f.rel))
  const found: Found[] = []
  const ids = new Set<string>()
  for (const f of [...base.filter((b) => !replaced.has(b.rel)), ...changed]) {
    const r = parseAdr(f.rel, f.text, f.tree.provenance)
    if (r.decision) {
      if (ids.has(r.decision.id) && f.tree.provenance.kind === 'in-flight') r.decision.id += `@${f.tree.provenance.item}`
      ids.add(r.decision.id)
    }
    found.push(r)
  }
  return found
}

export function createRepoSource(tracker: TrackerAdapter): ReadModelSource {
  const ideas = async (p: ProjectConfig) => {
    if (!p.tracker) return { entries: [], failures: [] }
    const { login, issues } = await tracker.ideas(p.path)
    return ideaEntries(login, issues)
  }
  const cards = async (p: ProjectConfig) => (p.tracker ? tracker.cards(p.tracker) : [])
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
      return (await adrs(p))
        .flatMap((f) => (f.decision ? [f.decision] : []))
        .sort((a, b) => (a.order ?? 0) - (b.order ?? 0) || a.id.localeCompare(b.id))
    },
    async parseFailures(p) {
      const artifact = (await adrs(p)).flatMap((f) => (f.failure ? [f.failure] : []))
      const board = (await cards(p))
        .filter((c) => c.number === null)
        .map((c): ParseFailure => ({ path: `tracker:${c.raw}`, reason: 'board card is not linked to an issue', provenance: { kind: 'event' } }))
      return [...artifact, ...board, ...(await ideas(p)).failures]
    },
    async items(p) {
      return (await cards(p)).flatMap((c): Item[] =>
        c.number === null
          ? []
          : [{ id: `item-${c.number}`, number: c.number, title: c.title, url: c.url, factoryStatus: c.factoryStatus ?? 'No status', kind: c.kind, role: c.role, effort: c.effort, provenance: { kind: 'event' } }],
      )
    },
    async directions() {
      return []
    },
    async andon() {
      return []
    },
    async intake(p) {
      return [...(await ideas(p)).entries, ...(await inboxEntries(await trees(p)))]
    },
  }
}
