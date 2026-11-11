import type { Item, PendingDecision } from '../types'
import type { IdeaNeed, NeedsYouEntry } from '../view'

/**
 * The "needs you" slot: pending decisions, board items and ideas waiting on the person, together.
 * Oldest wait first, newest last. A wait with no known start (a board item, an idea) sorts before dated ones.
 */
export function buildNeedsYou(pending: PendingDecision[], items: Item[], now: Date, ideas: IdeaNeed[] = []): NeedsYouEntry[] {
  const seconds = (since: string) => Math.max(0, Math.floor((now.getTime() - Date.parse(since)) / 1000))
  const entries: NeedsYouEntry[] = [
    ...items
      .filter((i) => i.factoryStatus === 'Waiting on you')
      .map((i): NeedsYouEntry => ({ kind: 'waiting', id: i.id, title: i.title, since: null, waitingSeconds: null, ref: i.url ?? `#${i.number}`, decision: null })),
    ...ideas.map((n): NeedsYouEntry => ({ kind: 'idea', id: `${n.projectId}:${n.entry.id}`, title: n.entry.title, since: null, waitingSeconds: null, ref: n.entry.id, decision: null })),
    ...pending.map((d): NeedsYouEntry => ({ kind: 'decision', id: d.id, title: d.title, since: d.since, waitingSeconds: seconds(d.since), ref: d.ref, decision: d })),
  ]
  const key = (e: NeedsYouEntry) => (e.since === null ? -Infinity : Date.parse(e.since))
  return entries.sort((a, b) => key(a) - key(b))
}
