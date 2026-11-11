import type { Decision, IntakeEntry, Item, ParseFailure, ProjectSummary } from '../../shared/types'
import type { BoardColumn, IdeaNeed, PageView } from '../../shared/view'

/** The factory statuses, in board order. A status the tracker has that is not here follows them, never dropped. */
const FACTORY_STATUSES = ['Backlog', 'Ready', 'Running', 'Waiting on you', 'Blocked', 'Done']

/** Groups items by factory status: the six known statuses first (even when empty), then any other status the tracker has. */
function boardOf(items: Item[]): BoardColumn[] {
  const known = FACTORY_STATUSES
  const extra = [...new Set(items.map((i) => i.factoryStatus))].filter((s) => !known.includes(s))
  return [...known, ...extra].map((status) => ({
    status,
    items: items.filter((i) => i.factoryStatus === status).sort((a, b) => a.number - b.number),
  }))
}

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
        summaries.map(async (s) => {
          const get = <T,>(kind: string): Promise<T[]> => (s.state === 'ok' ? $fetch<T[]>(`/api/projects/${s.id}/${kind}`) : Promise.resolve([]))
          const [parseFailures, items, decisions, intake] = await Promise.all([get<ParseFailure>('parse-failures'), get<Item>('items'), get<Decision>('decisions'), get<IntakeEntry>('intake')])
          return { ...s, parseFailures, board: boardOf(items), decisions: [...decisions].sort((a, b) => (a.order ?? 0) - (b.order ?? 0)), intake }
        }),
      )
      // Needs-you slot: items waiting on you, then ideas waiting on a human.
      const waiting: Array<Item | IdeaNeed> = projects.flatMap((p) => p.board.find((c) => c.status === 'Waiting on you')?.items ?? [])
      const ideas: IdeaNeed[] = projects.flatMap((p) => p.intake.filter((e) => e.waitingOnHuman).map((entry) => ({ kind: 'idea' as const, projectId: p.id, entry })))
      const needsYou = [...waiting, ...ideas]
      state.value = { view: { ...state.value.view, projects, needsYou }, refreshedAt: new Date().toISOString(), error: null }
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
