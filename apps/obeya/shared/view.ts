import type { Andon, Decision, Direction, IntakeEntry, Item, ParseFailure, PendingDecision, ProjectSummary } from './types'

/** One project as a theme sees it: the summary plus the read-model objects the base views need. */
export type ProjectView = ProjectSummary & {
  parseFailures: ParseFailure[]
  board: BoardColumn[]
  decisions: Decision[]
  intake: IntakeEntry[]
  andon: Andon[]
  pendingDecisions: PendingDecision[]
  directions: Direction[]
}

/** An idea waiting on a human, input to the needs-you slot. */
export interface IdeaNeed {
  kind: 'idea'
  projectId: string
  entry: IntakeEntry
}

/** One board column: a factory status and its items, in issue order. */
export interface BoardColumn {
  status: string
  items: Item[]
}

/** One line of the "needs you" slot: a pending decision, a board item or an idea waiting on the person. */
export interface NeedsYouEntry {
  kind: 'decision' | 'waiting' | 'idea'
  /** Scoped by project: `<projectId>:<id>`, unique across projects. */
  id: string
  projectId: string
  title: string
  /** When the wait began; null when the source does not know (board items, ideas). */
  since: string | null
  /** Whole seconds waited at the last refresh; null when `since` is unknown. */
  waitingSeconds: number | null
  ref: string
  /** Decisions only. */
  decision: PendingDecision | null
}

/**
 * Everything a theme gets. Themes receive this and nothing else: they may not fetch, compute or reshape data.
 * `needsYou` is the "needs you" slot; it is always shown first.
 */
export interface PageView {
  projects: ProjectView[]
  needsYou: NeedsYouEntry[]
  /** The read-only lens badge: the address the server is bound to. */
  bindAddress: string
}
