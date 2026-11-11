// The direction document (docs/direction.md): front matter `goal` and `current`, then a `## History` list.
// Same rule as the ADRs: a worktree copy is in flight only when its branch changed it since its merge-base with main (or main lacks it).
import { readFile } from 'node:fs/promises'
import { join } from 'node:path'
import { pickInFlight } from './in-flight'
import type { Direction, ParseFailure, Provenance } from '../../shared/types'

export const DIRECTION_PATH = 'docs/direction.md'

export interface DirectionTree {
  path: string
  provenance: Provenance
}

export interface FoundDirection {
  direction?: Direction
  failure?: ParseFailure
}

function parse(text: string, provenance: Provenance): FoundDirection {
  const fail = (reason: string): FoundDirection => ({ failure: { path: DIRECTION_PATH, reason, provenance } })
  const fm = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/)
  if (!fm) return fail('missing front matter block with goal and current')
  const field = (name: string) => fm[1].match(new RegExp(`^${name}:[ \\t]*(\\S.*?)[ \\t]*$`, 'm'))?.[1]
  const goal = field('goal')
  if (!goal) return fail('front matter has no goal')
  const current = field('current')
  if (!current) return fail('front matter has no current')
  const body = text.slice(fm[0].length)
  const sec = body.match(/^##\s+History\s*$([\s\S]*?)(?=^##\s|(?![\s\S]))/m)
  if (!sec) return fail('missing a "## History" section')
  const history: Direction['history'] = []
  for (const line of sec[1].split('\n').map((l) => l.trim()).filter(Boolean)) {
    const m = line.match(/^[-*]\s+(\d{4}-\d{2}-\d{2}):\s+(\S.*)$/)
    if (!m) return fail(`history line is not "- YYYY-MM-DD: what changed": ${line}`)
    history.push({ date: m[1], change: m[2] })
  }
  const id = provenance.kind === 'in-flight' ? `direction@${provenance.item}` : 'direction'
  return { direction: { id, goal, current, history, ref: DIRECTION_PATH, provenance } }
}

export async function readDirections([main, ...others]: DirectionTree[]): Promise<FoundDirection[]> {
  const read = async (t: DirectionTree) => {
    try {
      return await readFile(join(t.path, DIRECTION_PATH), 'utf8')
    } catch {
      return null
    }
  }
  const mainText = await read(main)
  const found: FoundDirection[] = []
  const base = mainText === null ? [] : [{ rel: DIRECTION_PATH, text: mainText, tree: main }]
  if (mainText !== null) found.push(parse(mainText, main.provenance))
  const copies = []
  for (const t of others) {
    const text = await read(t)
    if (text !== null) copies.push({ rel: DIRECTION_PATH, text, tree: t })
  }
  for (const f of await pickInFlight(main.path, base, copies)) if (f.tree !== main) found.push(parse(f.text, f.tree.provenance))
  return found
}
