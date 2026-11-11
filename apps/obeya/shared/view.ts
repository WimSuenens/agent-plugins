import type { Direction, ParseFailure, ProjectSummary } from './types'

/** One project as a theme sees it: the summary plus the read-model objects the base views need. */
export type ProjectView = ProjectSummary & { parseFailures: ParseFailure[]; directions: Direction[] }

/**
 * Everything a theme gets. Themes receive this and nothing else: they may not fetch, compute or reshape data.
 * `needsYou` is the "needs you" slot, filled by later views; it is always shown first.
 */
export interface PageView {
  projects: ProjectView[]
  needsYou: unknown[]
  /** The read-only lens badge: the address the server is bound to. */
  bindAddress: string
}
