// The source seam. Everything outside server/source/ sees the read model only through ReadModelSource;
// nothing outside it reads the filesystem or runs gh.
import type { Andon, Decision, Direction, IntakeEntry, Item, ParseFailure, ProjectConfig, ProjectSummary, TrackerConfig } from '../../shared/types'

export interface ReadModelSource {
  project(p: ProjectConfig): Promise<ProjectSummary>
  items(p: ProjectConfig): Promise<Item[]>
  decisions(p: ProjectConfig): Promise<Decision[]>
  directions(p: ProjectConfig): Promise<Direction[]>
  andon(p: ProjectConfig): Promise<Andon[]>
  intake(p: ProjectConfig): Promise<IntakeEntry[]>
  parseFailures(p: ProjectConfig): Promise<ParseFailure[]>
}

/** A card on the tracker's board, in the tracker's own terms. */
export interface TrackerCard {
  number: number | null
  title: string
  url: string | null
  factoryStatus: string | null
  kind: string | null
  role: string | null
  effort: { number: number; title: string | null } | null
  raw: string
}

/** The tracker behind an adapter. v1 is gh; a token-based client or another tracker implements the same interface. Read-only. */
export interface TrackerAdapter {
  cards(tracker: TrackerConfig): Promise<TrackerCard[]>
}

/** The source could not answer. `status` is the HTTP status the API gives it. */
export class SourceError extends Error {
  constructor(message: string, readonly status: number = 409) {
    super(message)
  }
}
