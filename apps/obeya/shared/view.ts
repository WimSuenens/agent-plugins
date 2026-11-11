import type { Decision, Direction, Item, ParseFailure, ProjectSummary } from './types'

/** One project as a theme sees it: the summary plus the read-model objects the base views need. */
export type ProjectView = ProjectSummary & { parseFailures: ParseFailure[]; board: BoardColumn[]; decisions: Decision[]; directions: Direction[] }

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
  needsYou: Item[]
  /** The read-only lens badge: the address the server is bound to. */
  bindAddress: string
}
