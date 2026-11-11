// The direction document (docs/direction.md): front matter `goal` and `current`, then a `## History` list.
// Same rule as the ADRs: a worktree copy that equals the main one is not repeated; a changed or new one is in flight.
import { readFile } from 'node:fs/promises'
import { join } from 'node:path'
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
  const field = (name: string) => fm[1].match(new RegExp(`^${name}:\\s*(\\S.*?)\\s*$`, 'm'))?.[1]
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
  if (mainText !== null) found.push(parse(mainText, main.provenance))
  for (const t of others) {
    const text = await read(t)
    if (text !== null && text !== mainText) found.push(parse(text, t.provenance))
  }
  return found
}
