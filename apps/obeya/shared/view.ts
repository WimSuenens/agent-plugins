import type { Decision, IntakeEntry, Item, ParseFailure, ProjectSummary } from './types'

/** One project as a theme sees it: the summary plus the read-model objects the base views need. */
export type ProjectView = ProjectSummary & { parseFailures: ParseFailure[]; board: BoardColumn[]; decisions: Decision[]; intake: IntakeEntry[] }

/** An idea waiting on a human, shown in the needs-you slot. */
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

/**
 * Everything a theme gets. Themes receive this and nothing else: they may not fetch, compute or reshape data.
 * `needsYou` is the "needs you" slot, filled by later views; it is always shown first.
 */
export interface PageView {
  projects: ProjectView[]
  needsYou: Array<Item | IdeaNeed>
  /** The read-only lens badge: the address the server is bound to. */
  bindAddress: string
}
