import { execFile } from 'node:child_process'
import { promisify } from 'node:util'
import type { TrackerConfig } from '../../shared/types'
import { SourceError, type TrackerAdapter, type TrackerCard } from './types'

const run = promisify(execFile)

/** The only gh commands the app may run. All read. */
const READ_ONLY = ['project item-list', 'issue list', 'issue view', 'pr list', 'pr view']

async function gh(args: string[]): Promise<string> {
  if (!READ_ONLY.includes(args.slice(0, 2).join(' '))) throw new Error(`gh ${args.slice(0, 2).join(' ')} is not a read command`)
  try {
    return (await run('gh', args, { maxBuffer: 32 * 1024 * 1024 })).stdout
  } catch (e: any) {
    if (e?.code === 'ENOENT') throw new SourceError('gh is not installed', 502)
    throw new SourceError(`gh ${args.slice(0, 2).join(' ')} failed: ${String(e?.stderr || e?.message).trim().split('\n')[0]}`, 502)
  }
}

const norm = (s: string) => s.toLowerCase().replace(/[^a-z0-9]/g, '')
const text = (v: unknown) => (typeof v === 'string' && v.trim() ? v.trim() : null)

function effortOf(v: unknown): TrackerCard['effort'] {
  if (typeof v === 'string') {
    const m = v.match(/(\d+)\s*$/)
    return m ? { number: Number(m[1]), title: null } : null
  }
  if (v && typeof v === 'object' && Number.isInteger((v as any).number)) return { number: (v as any).number, title: text((v as any).title) }
  return null
}

export class GhTracker implements TrackerAdapter {
  async cards(t: TrackerConfig): Promise<TrackerCard[]> {
    const out = await gh(['project', 'item-list', String(t.projectNumber), '--owner', t.owner, '--format', 'json', '--limit', '1000'])
    let items: any[]
    try {
      items = JSON.parse(out).items
      if (!Array.isArray(items)) throw new Error('no items array')
    } catch {
      throw new SourceError('gh project item-list did not return JSON with an items list', 502)
    }
    return items.map((it): TrackerCard => {
      const field = (name: string) => {
        const key = Object.keys(it).find((k) => norm(k) === norm(name))
        return key ? it[key] : undefined
      }
      const n = it?.content?.number
      return {
        number: Number.isInteger(n) ? n : null,
        title: text(it?.title) ?? text(it?.content?.title) ?? '',
        url: text(it?.content?.url),
        factoryStatus: text(field('Factory status')),
        kind: text(field('Kind')),
        role: text(field('Role')),
        effort: effortOf(field('Parent issue')),
        raw: String(it?.id ?? ''),
      }
    })
  }
}
