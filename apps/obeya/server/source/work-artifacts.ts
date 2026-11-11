// Reads the front matter of decision cards and andon files under work/<id>/ in the main checkout and every worktree.
// Contract: contracts/130-obeya-pending-and-andon.md. A file that lacks or fails its front matter is a parse-failure, never dropped.
import { readdir, readFile } from 'node:fs/promises'
import { join } from 'node:path'
import type { Andon, ParseFailure, PendingDecision, Provenance } from '../../shared/types'

interface Tree {
  path: string
  provenance: Provenance
}

export interface WorkArtifacts {
  pending: PendingDecision[]
  andon: Andon[]
  failures: ParseFailure[]
}

type Front = Record<string, string | string[]>

/** The small YAML subset the contract allows: `key: value`, `key: [a, b]`, and `key:` followed by `  - item` lines. */
function frontMatter(text: string): Front | null {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/)
  if (!m) return null
  const out: Front = {}
  let list: string[] | null = null
  for (const line of m[1].split(/\r?\n/)) {
    const li = line.replace(/\s+#.*$/, '').match(/^\s+-\s+(.*?)\s*$/)
    if (li && list) {
      list.push(unquote(li[1]))
      continue
    }
    const kv = line.replace(/\s+#.*$/, '').match(/^([A-Za-z][\w-]*):\s*(.*?)\s*$/)
    if (!kv) continue
    list = null
    if (kv[2] === '') {
      list = []
      out[kv[1]] = list
    } else if (kv[2].startsWith('[') && kv[2].endsWith(']')) {
      out[kv[1]] = kv[2].slice(1, -1).split(',').map((s) => unquote(s.trim())).filter(Boolean)
    } else {
      out[kv[1]] = unquote(kv[2])
    }
  }
  return out
}

const unquote = (s: string) => s.replace(/^(["'])(.*)\1$/, '$2')
const str = (v: unknown) => (typeof v === 'string' && v.trim() ? v.trim() : null)
const isTime = (s: string) => !Number.isNaN(Date.parse(s))

interface Candidate {
  rel: string
  text: string
  tree: Tree
}

/** Files of the shape work/<id>/NN-<type>-<role>.md whose type is `kind`. A worktree copy equal to the main one is not repeated; a changed one replaces it. */
async function candidates(trees: Tree[], kind: string): Promise<Candidate[]> {
  const re = new RegExp(`^\\d+-${kind}(-.*)?\\.md$`)
  const read = async (tree: Tree): Promise<Candidate[]> => {
    const found: Candidate[] = []
    let ids: string[] = []
    try {
      ids = await readdir(join(tree.path, 'work'))
    } catch {}
    for (const id of ids) {
      let names: string[] = []
      try {
        names = (await readdir(join(tree.path, 'work', id))).filter((n) => re.test(n)).sort()
      } catch {}
      for (const n of names) found.push({ rel: `work/${id}/${n}`, text: await readFile(join(tree.path, 'work', id, n), 'utf8'), tree })
    }
    return found
  }
  const [main, ...others] = trees
  const base = await read(main)
  const mainText = new Map(base.map((f) => [f.rel, f.text]))
  const changed = (await Promise.all(others.map(read))).flat().filter((f) => mainText.get(f.rel) !== f.text)
  const replaced = new Set(changed.map((f) => f.rel))
  return [...base.filter((b) => !replaced.has(b.rel)), ...changed]
}

const itemOf = (rel: string) => {
  const id = rel.split('/')[1]
  return /^\d+$/.test(id) ? Number(id) : null
}
const suffix = (p: Provenance) => (p.kind === 'in-flight' ? `@${p.item}` : '')

export async function readWorkArtifacts(trees: Tree[]): Promise<WorkArtifacts> {
  const out: WorkArtifacts = { pending: [], andon: [], failures: [] }

  for (const f of await candidates(trees, 'decision-card')) {
    const fail = (reason: string) => out.failures.push({ path: f.rel, reason, provenance: f.tree.provenance })
    const fm = frontMatter(f.text)
    if (!fm) { fail('decision card has no front matter block'); continue }
    const door = fm.door
    if (door !== 'one-way' && door !== 'two-way') { fail('front matter door must be one-way or two-way'); continue }
    const asked = str(fm.asked)
    if (!asked) { fail('front matter has no asked (who is asked)'); continue }
    const since = str(fm.since)
    if (!since || !isTime(since)) { fail('front matter since must be a date and time'); continue }
    if (!Array.isArray(fm.options) || fm.options.length < 2) { fail('front matter options must list at least two options'); continue }
    const title = f.text.match(/^#{1,3}\s+Decision:\s*(\S.*?)\s*$/m)?.[1] ?? f.rel
    out.pending.push({ id: `card:${f.rel}${suffix(f.tree.provenance)}`, item: itemOf(f.rel), title, door, askedOf: asked, since, options: fm.options, ref: f.rel, provenance: f.tree.provenance })
  }

  for (const f of await candidates(trees, 'andon')) {
    const fail = (reason: string) => out.failures.push({ path: f.rel, reason, provenance: f.tree.provenance })
    const fm = frontMatter(f.text)
    if (!fm) { fail('andon has no front matter block'); continue }
    const andon = str(fm.andon)
    if (!andon) { fail('front matter has no andon id'); continue }
    const status = fm.status
    if (status !== 'open' && status !== 'resolved') { fail('front matter status must be open or resolved'); continue }
    const owner = str(fm.owner)
    if (!owner) { fail('front matter has no owner'); continue }
    const reason = str(fm.reason)
    if (!reason) { fail('front matter has no reason'); continue }
    const countermeasure = str(fm.countermeasure)
    if (status === 'resolved' && !countermeasure) { fail('a resolved andon needs a countermeasure'); continue }
    const since = str(fm.since)
    if (since && !isTime(since)) { fail('front matter since must be a date and time'); continue }
    const item = str(fm.item) && /^\d+$/.test(String(fm.item)) ? Number(fm.item) : itemOf(f.rel)
    out.andon.push({ id: `andon:${item ?? 'x'}:${andon}${suffix(f.tree.provenance)}`, item, owner, reason, resolved: status === 'resolved', countermeasure, since, ref: f.rel, provenance: f.tree.provenance })
  }
  return out
}
