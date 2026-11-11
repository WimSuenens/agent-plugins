/** One configured project. All state is keyed by `id`; there is no process-wide "the repo". */
export interface ProjectConfig {
  id: string
  path: string
}

/** What the page and `GET /api/projects` return per project. `state: 'error'` is a visible state, never a crash. */
export type ProjectSummary =
  | { id: string; state: 'ok'; name: string }
  | { id: string; state: 'error'; name: null; error: string }
