import type { Direction, ParseFailure, ProjectSummary } from '../../shared/types'
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
      const projects = await Promise.all(
        summaries.map(async (s) => ({
          ...s,
          parseFailures: s.state === 'ok' ? await $fetch<ParseFailure[]>(`/api/projects/${s.id}/parse-failures`) : [],
          directions: s.state === 'ok' ? await $fetch<Direction[]>(`/api/projects/${s.id}/directions`) : [],
        })),
      )
      state.value = { view: { ...state.value.view, projects }, refreshedAt: new Date().toISOString(), error: null }
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
