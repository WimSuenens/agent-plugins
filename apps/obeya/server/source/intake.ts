// Intake queue: reads what the factory's intake (contract 110) records. Defines no intake behaviour and writes nothing.
import { readdir, lstat } from 'node:fs/promises'
import { join } from 'node:path'
import type { IntakeEntry, ParseFailure, Provenance } from '../../shared/types'
import type { TrackerIdea } from './types'

const OUTCOMES = ['direction', 'slice-candidate', 'research-ticket', 'parked', 'rejected']
const CHANNELS = ['slack', 'mail', 'teams', 'inbox', 'terminal']

type Channel = IntakeEntry['channel']

/** The channel is front matter in the idea body (`channel: slack`); without it, the inbox marker says inbox and the idea marker says terminal. */
function channelOf(body: string): Channel {
  const fm = body.replace(/^(\s*<!--[^>]*-->\s*)+/, '').match(/^---\r?\n([\s\S]*?)\r?\n---/)
  const declared = fm?.[1].match(/^channel:\s*(\S+)\s*$/im)?.[1].toLowerCase()
  if (declared) return (CHANNELS.includes(declared) ? declared : 'unknown') as Channel
  if (body.includes('<!-- factory:inbox ')) return 'inbox'
  if (body.includes('<!-- factory:idea -->')) return 'terminal'
  return 'unknown'
}

/** An open decision card from the lead that the person has not answered. */
const waiting = (mine: string[]) => mine.some((b) => b.startsWith('<!-- factory:needs-you v1 -->') && !b.includes('\nAnswered:'))

export function ideaEntries(login: string, ideas: TrackerIdea[]): { entries: IntakeEntry[]; failures: ParseFailure[] } {
  const entries: IntakeEntry[] = []
  const failures: ParseFailure[] = []
  const provenance: Provenance = { kind: 'event' }
  for (const i of ideas) {
    // Only the lead's own comments count; the last triage comment is the outcome.
    const mine = i.comments.filter((c) => c.author === login).map((c) => c.body)
    const triage = mine.filter((b) => b.startsWith('<!-- factory:triage ')).pop()
    const base = { id: `idea-${i.number}`, title: i.title, channel: channelOf(i.body), ref: i.url || `#${i.number}`, provenance }
    if (triage === undefined) {
      entries.push({ ...base, outcome: 'untriaged', reason: null, waitingOnHuman: waiting(mine) })
      continue
    }
    const outcome = triage.match(/^\*\*Outcome:\*\*[ \t]*(\S+)/m)?.[1]
    const reason = triage.match(/\*\*Reason:\*\*([\s\S]*)$/)?.[1].trim()
    const fail = (why: string) => failures.push({ path: base.ref, reason: `idea "${i.title}": ${why}`, provenance })
    if (!outcome || !OUTCOMES.includes(outcome)) fail('the triage comment has no recognised outcome')
    else if (!reason) fail('the triage comment has an empty reason field')
    else entries.push({ ...base, outcome: outcome as IntakeEntry['outcome'], reason, waitingOnHuman: false })
  }
  return { entries, failures }
}

/** Files waiting in an inbox folder are ideas that have not reached the tracker yet. */
export async function inboxEntries(trees: { path: string; provenance: Provenance }[]): Promise<IntakeEntry[]> {
  const out: IntakeEntry[] = []
  for (const t of trees) {
    const dir = join(t.path, '.claude', 'factory-inbox')
    let names: string[] = []
    try {
      names = (await readdir(dir)).filter((n) => !n.startsWith('.')).sort()
    } catch {}
    for (const n of names) {
      if (!(await lstat(join(dir, n))).isFile()) continue
      const where = t.provenance.kind === 'in-flight' ? `@${t.provenance.item}` : ''
      out.push({ id: `inbox:${n}${where}`, title: n, outcome: 'untriaged', channel: 'inbox', reason: null, waitingOnHuman: false, ref: `.claude/factory-inbox/${n}`, provenance: t.provenance })
    }
  }
  return out
}
