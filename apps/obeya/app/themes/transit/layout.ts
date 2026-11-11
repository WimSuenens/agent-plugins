// Transit layout: turns a ProjectView into positions for the metro map. Presentation only; it never reads anything but its argument.
// The rule holds for any size: stations sit on a fixed grid (STEP apart, wider than any label), and a row that would exceed its cap
// folds its oldest stations into one aggregate station. The map therefore never overlaps labels, and rows stay a bounded width.
import type { Item, Provenance } from '../../../shared/types'
import type { ProjectView } from '../../../shared/view'

export const X0 = 190
export const STEP = 52
export const ROUTE_Y = 70
export const FEEDER_Y = 140
export const LINES_Y = 220
export const LINE_GAP = 70
export const CAPS = { decisions: 20, line: 16, ideas: 10, pending: 8 }

export type StatusKey = 'done' | 'running' | 'ready' | 'waiting' | 'blocked' | 'backlog' | 'other'
export type StationKind = 'item' | 'decision' | 'pending' | 'idea' | 'aggregate'

export interface Station {
  id: string
  kind: StationKind
  status: StatusKey
  x: number
  y: number
  label: string
  title: string
  detail: string
  provenance: string
  /** Aggregate stations only: how many stations are folded in. */
  count?: number
}

export interface MapLine {
  key: string
  name: string
  title: string
  y: number
  colour: string
  stations: Station[]
  summary: string
  endX: number
}

export interface Closure { stationId: string | null; x: number; y: number; reason: string }

export interface TransitMap {
  width: number
  height: number
  decisions: Station[]
  pending: Station[]
  ideas: Station[]
  lines: MapLine[]
  youX: number
  interchangeX: number
  routeEndX: number
  closures: Closure[]
}

// Colours chosen to read on a white map; every line is also named in text, so colour is never the only cue.
export const LINE_COLOURS = ['#0a62c9', '#0a7a41', '#a8266b', '#8a5a00', '#5a3fc0', '#b4141a', '#00798c']

export const statusKey = (s: string): StatusKey =>
  (({ done: 'done', running: 'running', ready: 'ready', 'waiting on you': 'waiting', blocked: 'blocked', backlog: 'backlog' }) as Record<string, StatusKey>)[s.trim().toLowerCase()] ?? 'other'

export const provenanceText = (p: Provenance) => (p.kind === 'in-flight' ? `in flight: ${p.item}` : p.kind)

/** Keeps the newest `max` entries; the rest fold into one aggregate described by `summarise`. */
function fold<T>(list: T[], max: number): { folded: T[]; kept: T[] } {
  if (list.length <= max) return { folded: [], kept: list }
  const cut = list.length - (max - 1)
  return { folded: list.slice(0, cut), kept: list.slice(cut) }
}

function tally(statuses: string[]): string {
  const n = new Map<string, number>()
  for (const s of statuses) n.set(s, (n.get(s) ?? 0) + 1)
  return [...n].map(([s, c]) => `${c} ${s}`).join(', ')
}

function aggregate(id: string, x: number, y: number, noun: string, statuses: string[]): Station {
  return {
    id, kind: 'aggregate', status: 'other', x, y, label: `+${statuses.length}`, title: `${statuses.length} earlier ${noun} folded together`,
    detail: `${tally(statuses)}. The full list is below.`, provenance: 'several', count: statuses.length,
  }
}

const itemStation = (i: Item, x: number, y: number): Station => ({
  id: i.id, kind: 'item', status: statusKey(i.factoryStatus), x, y, label: String(i.number), title: `#${i.number} ${i.title}`,
  detail: `${i.factoryStatus}${i.role ? `, ${i.role}` : ''}${i.blockedBy?.length ? `, blocked by ${i.blockedBy.map((n) => '#' + n).join(', ')}` : ''}`,
  provenance: provenanceText(i.provenance),
})

export function effortKey(i: Item): string { return i.effort ? String(i.effort.number) : 'none' }

export function buildMap(p: ProjectView): TransitMap {
  // Route: decisions made (behind), you are here, decisions pending (ahead).
  const decs = [...p.decisions].sort((a, b) => (a.order ?? 1e9) - (b.order ?? 1e9))
  const dFold = fold(decs, CAPS.decisions)
  const iFold = fold(p.intake, CAPS.ideas)
  const dCount = dFold.kept.length + (dFold.folded.length ? 1 : 0)
  const iCount = iFold.kept.length + (iFold.folded.length ? 1 : 0)
  const youX = X0 + Math.max(dCount, iCount + 1) * STEP
  const interchangeX = youX - STEP

  const decisions: Station[] = []
  let k = 0
  if (dFold.folded.length) decisions.push(aggregate('decisions-folded', X0 + k++ * STEP, ROUTE_Y, 'decisions', dFold.folded.map((d) => d.status)))
  for (const d of dFold.kept) {
    decisions.push({
      id: d.id, kind: 'decision', status: 'done', x: X0 + k++ * STEP, y: ROUTE_Y, label: String(d.order ?? ''), title: d.title,
      detail: `${d.kind === 'adr' ? 'ADR' : 'Decision card'}, ${d.status}. ${d.ref}`, provenance: provenanceText(d.provenance),
    })
  }

  const pFold = fold(p.pendingDecisions, CAPS.pending)
  const pending: Station[] = []
  k = 1
  if (pFold.folded.length) pending.push(aggregate('pending-folded', youX + k++ * STEP, ROUTE_Y, 'pending decisions', pFold.folded.map((d) => `${d.door}-door`)))
  for (const d of pFold.kept) {
    pending.push({
      id: d.id, kind: 'pending', status: 'waiting', x: youX + k++ * STEP, y: ROUTE_Y, label: d.item === null ? '?' : String(d.item), title: d.title,
      detail: `Waiting on ${d.askedOf}, ${d.door} door. Options: ${d.options.join(' / ')}`, provenance: provenanceText(d.provenance),
    })
  }
  const routeEndX = youX + (pending.length + 1) * STEP + 30

  // Feeder: ideas arrive from the left and merge into the route at the interchange.
  const ideas: Station[] = []
  const first = interchangeX - iCount * STEP
  k = 0
  if (iFold.folded.length) ideas.push(aggregate('ideas-folded', first + k++ * STEP, FEEDER_Y, 'ideas', iFold.folded.map((e) => e.outcome)))
  for (const e of iFold.kept) {
    ideas.push({
      id: e.id, kind: 'idea', status: e.waitingOnHuman ? 'waiting' : 'other', x: first + k++ * STEP, y: FEEDER_Y, label: '', title: e.title,
      detail: `${e.waitingOnHuman ? 'Needs you' : e.outcome} via ${e.channel}${e.reason ? `. ${e.reason}` : ''}`, provenance: provenanceText(e.provenance),
    })
  }

  // Lines: one per effort, in order of first appearance; items with no effort ride the "no effort" line.
  const groups = new Map<string, Item[]>()
  for (const col of p.board) for (const i of col.items) {
    const key = effortKey(i)
    groups.set(key, [...(groups.get(key) ?? []), i])
  }
  const lines: MapLine[] = []
  let y = LINES_Y
  let n = 0
  for (const [key, items] of groups) {
    items.sort((a, b) => a.number - b.number)
    const f = fold(items, CAPS.line)
    const stations: Station[] = []
    let j = 0
    if (f.folded.length) stations.push(aggregate(`line-${key}-folded`, X0 + j++ * STEP, y, 'items', f.folded.map((i) => i.factoryStatus)))
    for (const i of f.kept) stations.push(itemStation(i, X0 + j++ * STEP, y))
    const eff = items[0].effort
    const name = key === 'none' ? 'No effort' : `#${key}${eff?.title ? ' ' + eff.title : ''}`
    lines.push({
      key, name: name.length > 20 ? name.slice(0, 19) + '…' : name, title: name, y, colour: LINE_COLOURS[n++ % LINE_COLOURS.length],
      stations, summary: tally(items.map((i) => i.factoryStatus)), endX: X0 + (stations.length - 1) * STEP,
    })
    y += LINE_GAP
  }

  // Closures: an open andon blocks the track at its item's station, or at "you are here" when no item is named.
  const all = lines.flatMap((l) => l.stations)
  const closures: Closure[] = p.andon.filter((a) => !a.resolved).map((a) => {
    const s = a.item === null ? undefined : all.find((st) => st.kind === 'item' && st.label === String(a.item))
    return s ? { stationId: s.id, x: s.x, y: s.y, reason: a.reason } : { stationId: null, x: youX, y: ROUTE_Y, reason: a.reason }
  })

  const width = Math.max(720, routeEndX, ...lines.map((l) => l.endX + 60))
  return { width, height: lines.length ? y - LINE_GAP + 50 : 180, decisions, pending, ideas, lines, youX, interchangeX, routeEndX, closures }
}
