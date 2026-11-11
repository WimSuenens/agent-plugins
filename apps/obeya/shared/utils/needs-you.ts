import type { Item, PendingDecision } from '../types'
import type { NeedsYouEntry } from '../view'

/**
 * The "needs you" slot: pending decisions and board items waiting on the person, together.
 * Oldest wait first, newest last. A wait with no known start (a board item) sorts before dated ones.
 */
export function buildNeedsYou(pending: PendingDecision[], items: Item[], now: Date): NeedsYouEntry[] {
  const seconds = (since: string) => Math.max(0, Math.floor((now.getTime() - Date.parse(since)) / 1000))
  const entries: NeedsYouEntry[] = [
    ...items
      .filter((i) => i.factoryStatus === 'Waiting on you')
      .map((i): NeedsYouEntry => ({ kind: 'waiting', id: i.id, title: i.title, since: null, waitingSeconds: null, ref: i.url ?? `#${i.number}`, decision: null })),
    ...pending.map((d): NeedsYouEntry => ({ kind: 'decision', id: d.id, title: d.title, since: d.since, waitingSeconds: seconds(d.since), ref: d.ref, decision: d })),
  ]
  const key = (e: NeedsYouEntry) => (e.since === null ? -Infinity : Date.parse(e.since))
  return entries.sort((a, b) => key(a) - key(b))
}
