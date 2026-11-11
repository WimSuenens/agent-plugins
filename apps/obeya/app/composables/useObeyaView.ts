import type { Andon, Item, ParseFailure, PendingDecision, ProjectSummary } from '../../shared/types'
import type { PageView } from '../../shared/view'

interface Loaded {
  view: PageView
  /** ISO time of the last read that fully succeeded, or null if none has. */
  refreshedAt: string | null
  error: string | null
}

/** Reads the read model through the API and keeps it fresh. Themes never call this; they get the view. */
export async function useObeyaView() {
  const cfg = useRuntimeConfig().public
  const state = useState<Loaded>('obeya-loaded', () => ({
    view: { projects: [], needsYou: [], bindAddress: String(cfg.bindAddress) },
    refreshedAt: null,
    error: null,
  }))

  async function load() {
    try {
      const summaries = await $fetch<ProjectSummary[]>('/api/projects')
      const ok = (s: ProjectSummary) => s.state === 'ok'
      const projects = await Promise.all(
        summaries.map(async (s) => ({
          ...s,
          parseFailures: ok(s) ? await $fetch<ParseFailure[]>(`/api/projects/${s.id}/parse-failures`) : [],
          andon: ok(s) ? await $fetch<Andon[]>(`/api/projects/${s.id}/andon`) : [],
          pendingDecisions: ok(s) ? await $fetch<PendingDecision[]>(`/api/projects/${s.id}/pending-decisions`) : [],
        })),
      )
      const items = (
        await Promise.all(summaries.filter(ok).map((s) => $fetch<Item[]>(`/api/projects/${s.id}/items`)))
      ).flat()
      const now = new Date()
      const needsYou = buildNeedsYou(projects.flatMap((p) => p.pendingDecisions), items, now)
      state.value = { view: { ...state.value.view, projects, needsYou }, refreshedAt: now.toISOString(), error: null }
    } catch (e) {
      const err = e as { statusMessage?: string; message?: string }
      state.value = { ...state.value, error: err.statusMessage || err.message || 'unknown error' }
    }
  }

  await callOnce('obeya-initial-load', load)
  onMounted(() => {
    const timer = setInterval(load, Number(cfg.refreshSeconds) * 1000)
    onBeforeUnmount(() => clearInterval(timer))
  })
  return { state, refreshSeconds: Number(cfg.refreshSeconds) }
}
