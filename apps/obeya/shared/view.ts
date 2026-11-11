import type { Andon, ParseFailure, PendingDecision, ProjectSummary } from './types'

/** One project as a theme sees it: the summary plus the read-model objects the base views need. */
export type ProjectView = ProjectSummary & { parseFailures: ParseFailure[]; andon: Andon[]; pendingDecisions: PendingDecision[] }

/** One line of the "needs you" slot: a pending decision or a board item waiting on the person. */
export interface NeedsYouEntry {
  kind: 'decision' | 'waiting'
  id: string
  title: string
  /** When the wait began; null when the source does not know (board items). */
  since: string | null
  /** Whole seconds waited at the last refresh; null when `since` is unknown. */
  waitingSeconds: number | null
  ref: string
  /** Decisions only. */
  decision: PendingDecision | null
}

/**
 * Everything a theme gets. Themes receive this and nothing else: they may not fetch, compute or reshape data.
 * `needsYou` is the "needs you" slot, filled by later views; it is always shown first.
 */
export interface PageView {
  projects: ProjectView[]
  needsYou: NeedsYouEntry[]
  /** The read-only lens badge: the address the server is bound to. */
  bindAddress: string
}
