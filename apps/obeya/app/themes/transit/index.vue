<script setup lang="ts">
// Transit: the project as a metro map with a departures board. Presents the `view` prop and nothing else.
import type { PageView, ProjectView } from '../../../shared/view'
import { buildMap, provenanceText, statusKey, STEP, X0, ROUTE_Y, FEEDER_Y } from './layout'
import Station from './Station.vue'

const props = defineProps<{ view: PageView }>()

// The selection is shared by the map and the boards, and survives a theme switch because it lives in app state, not in this theme.
const selected = useState<string | null>('obeya-selection', () => null)
const peeked = ref<string | null>(null)
const pick = (id: string) => (selected.value = selected.value === id ? null : id)

const maps = computed(() => new Map(props.view.projects.map((p) => [p.id, buildMap(p)])))
const active = (p: ProjectView) => {
  const m = maps.value.get(p.id)!
  const id = peeked.value ?? selected.value
  if (!id) return null
  return [...m.decisions, ...m.pending, ...m.ideas, ...m.lines.flatMap((l) => l.stations)].find((s) => s.id === id) ?? null
}
const items = (p: ProjectView) => p.board.flatMap((c) => c.items)
const waited = (s: number | null) => {
  if (s === null) return 'wait unknown'
  if (s < 3600) return `${Math.floor(s / 60)} min`
  if (s < 86400) return `${Math.floor(s / 3600)} h`
  return `${Math.floor(s / 86400)} d`
}
const goal = (p: ProjectView) => p.directions[0]
</script>

<template>
  <div class="transit">
    <header class="hd">
      <div class="roundel" aria-hidden="true"><span class="rd" /><span class="rd-name">OBEYA</span></div>
      <h1 class="sr-only">Obeya, route map</h1>
      <p class="lens" data-test="lens-badge">read-only lens &middot; bound to {{ view.bindAddress }}</p>
    </header>

    <section class="board needs-you" data-test="departures" aria-labelledby="dep-h">
      <h2 id="dep-h">Departures <small>what needs you first</small></h2>
      <div data-test="needs-you">
        <p v-if="!view.needsYou.length" class="none">No departures. Nothing needs you right now.</p>
        <ol v-else class="rows">
          <li
            v-for="e in view.needsYou"
            :key="e.id"
            :class="{ hl: selected === e.id }"
            :data-test="{ decision: 'pending-decision', idea: 'needs-you-idea', waiting: 'waiting-item' }[e.kind]"
          >
            <button type="button" :aria-pressed="selected === e.id ? 'true' : 'false'" @click="pick(e.id)">
              <span class="flag">{{ e.kind === 'idea' ? 'IDEA' : e.kind === 'decision' ? e.decision?.door + ' DOOR' : 'WAITING' }}</span>
              <span class="what">{{ e.title }}</span>
              <span class="when" data-test="waited">{{ e.kind === 'idea' ? 'idea waiting for you' : 'waiting ' + waited(e.waitingSeconds) }}</span>
              <span class="prov" data-test="provenance">{{ e.decision ? provenanceText(e.decision.provenance) : 'merged' }}</span>
            </button>
            <p v-if="e.decision" class="sub">Asked of {{ e.decision.askedOf }}. Options: {{ e.decision.options.join(' / ') }}. <code>{{ e.ref }}</code></p>
            <p v-else-if="e.kind !== 'idea'" class="sub"><a v-if="e.ref.startsWith('http')" :href="e.ref">{{ e.ref }}</a><code v-else>{{ e.ref }}</code></p>
          </li>
        </ol>
      </div>
    </section>

    <p v-if="!view.projects.length" data-test="empty">No project is configured.</p>

    <section v-for="p in view.projects" :key="p.id" class="project" :data-project="p.id">
      <template v-if="p.state === 'ok'">
        <h2 class="proj" data-test="project-name">{{ p.name }}</h2>
        <template v-if="goal(p)">
          <p class="goal">{{ goal(p)!.goal }}</p>
          <p class="heading"><b>Heading</b> {{ goal(p)!.current }}</p>
        </template>
      </template>
      <p v-else role="alert" class="proj-error" data-test="project-error">{{ p.id }}: {{ p.error }}</p>

      <!-- Line status strip -->
      <ul class="strip" aria-label="Line status">
        <li v-for="l in maps.get(p.id)!.lines" :key="l.key" :style="{ borderTopColor: l.colour }">
          <b>{{ l.title }}</b><span>{{ l.summary }}</span>
        </li>
        <li :class="{ bad: p.andon.some((a) => !a.resolved) }">
          <b>Service</b><span>{{ p.andon.some((a) => !a.resolved) ? 'Disruption: ' + p.andon.filter((a) => !a.resolved).length + ' track closure(s)' : 'Good service' }}</span>
        </li>
      </ul>

      <div class="mapbox" tabindex="0" role="region" aria-label="Route map, scrolls sideways" data-test="map">
        <svg :viewBox="`0 0 ${maps.get(p.id)!.width} ${maps.get(p.id)!.height}`" :width="maps.get(p.id)!.width" :height="maps.get(p.id)!.height" role="group" aria-label="Metro map of the project">
          <defs>
            <pattern id="hazard" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <rect width="4" height="8" fill="#ffcf00" /><rect x="4" width="4" height="8" fill="#1c1c1c" />
            </pattern>
          </defs>
          <template v-for="m in [maps.get(p.id)!]" :key="p.id">
            <!-- The route: solid behind, dashed ahead -->
            <text class="rowname" x="16" :y="ROUTE_Y + 4">THE ROUTE</text>
            <path :d="`M${X0 - 30} ${ROUTE_Y} H${m.youX}`" stroke="#1c1c1c" stroke-width="10" stroke-linecap="round" fill="none" />
            <path :d="`M${m.youX} ${ROUTE_Y} H${m.routeEndX}`" stroke="#1c1c1c" stroke-width="10" stroke-dasharray="16 10" fill="none" />
            <path :d="`M${m.routeEndX - 4} ${ROUTE_Y - 12} L${m.routeEndX + 20} ${ROUTE_Y} L${m.routeEndX - 4} ${ROUTE_Y + 12}Z`" fill="#1c1c1c" />
            <Station v-for="s in m.decisions" :key="s.id" :station="s" colour="#1c1c1c" :selected="selected === s.id" @pick="pick" @peek="(id) => (peeked = id)" />

            <g data-test="you-are-here">
              <circle :cx="m.youX" :cy="ROUTE_Y" r="12" fill="#c4161c" stroke="#fff" stroke-width="3" />
              <rect :x="m.youX - 50" :y="14" width="100" height="26" rx="4" fill="#c4161c" />
              <path :d="`M${m.youX - 6} 40 L${m.youX} 50 L${m.youX + 6} 40Z`" fill="#c4161c" />
              <text class="yah" :x="m.youX" y="31">YOU ARE HERE</text>
            </g>
            <Station v-for="s in m.pending" :key="s.id" :station="s" colour="#1c1c1c" :selected="selected === s.id" @pick="pick" @peek="(id) => (peeked = id)" />

            <!-- Feeder line: ideas merge into the route at the interchange -->
            <g data-test="feeder">
              <text class="rowname" x="16" :y="FEEDER_Y + 4">IDEAS FEEDER</text>
              <path v-if="m.ideas.length" :d="`M${m.ideas[0].x - 20} ${FEEDER_Y} H${m.interchangeX - 30} Q${m.interchangeX} ${FEEDER_Y} ${m.interchangeX} ${ROUTE_Y + 10}`" stroke="#0a7a41" stroke-width="7" fill="none" stroke-linecap="round" />
              <Station v-for="s in m.ideas" :key="s.id" :station="s" colour="#0a7a41" :selected="selected === s.id" @pick="pick" @peek="(id) => (peeked = id)" />
            </g>
            <g data-test="interchange">
              <circle :cx="m.interchangeX" :cy="ROUTE_Y" r="13" fill="#fff" stroke="#1c1c1c" stroke-width="5" />
              <circle :cx="m.interchangeX" :cy="ROUTE_Y" r="5" fill="#0a7a41" />
              <title>Interchange: triaged ideas change the direction</title>
            </g>

            <!-- Effort lines -->
            <g v-for="l in m.lines" :key="l.key" :data-line="l.key">
              <text class="rowname" x="16" :y="l.y - 2"><title>{{ l.title }}</title>{{ l.name }}</text>
              <rect x="16" :y="l.y + 6" width="130" height="5" :fill="l.colour" />
              <path :d="`M${X0 - 30} ${l.y} H${l.endX + STEP / 2}`" :stroke="l.colour" stroke-width="8" stroke-linecap="round" fill="none" />
              <Station v-for="s in l.stations" :key="s.id" :station="s" :colour="l.colour" :selected="selected === s.id" @pick="pick" @peek="(id) => (peeked = id)" />
            </g>

            <!-- Track closures -->
            <g v-for="(c, i) in m.closures" :key="i" data-test="closure" :data-closure-for="c.stationId ?? 'route'">
              <rect :x="c.x - STEP / 2 + 4" :y="c.y - 5" :width="STEP - 8" height="10" fill="url(#hazard)" stroke="#1c1c1c" stroke-width="1.5" />
              <text class="closed" :x="c.x" :y="c.y - 34">CLOSED</text>
              <title>Track closed: {{ c.reason }}</title>
            </g>
          </template>
        </svg>
      </div>
      <div class="detail" aria-live="polite" data-test="station-detail">
        <template v-if="active(p)">
          <b>{{ active(p)!.title }}</b> {{ active(p)!.detail }}
          <span class="chip">{{ active(p)!.provenance }}</span>
        </template>
        <template v-else>Hover, focus or press a station for its details. Dashed track and hollow stations are decisions still ahead.</template>
      </div>
      <p class="legend">Station shapes: check = done, pulsing ring = running, hollow = ready, "!" = waiting on you, cross = blocked, small grey = backlog, dashed ring = in flight, hazard bar = track closed.</p>

      <div class="two">
        <section class="board" data-test="item-board" aria-labelledby="ib-h">
          <h2 id="ib-h">Items <small>{{ items(p).length }}</small></h2>
          <p v-if="!items(p).length" class="none">No items on the board.</p>
          <ol class="rows scroll" tabindex="0" aria-label="Items, scrolls">
            <li v-for="i in items(p)" :key="i.id" :class="['s-' + statusKey(i.factoryStatus), { hl: selected === i.id }]" data-test="departure-item" :data-test-board-item="i.id">
              <button type="button" :aria-pressed="selected === i.id ? 'true' : 'false'" @click="pick(i.id)">
                <span class="flag">#{{ i.number }}</span>
                <span class="what">{{ i.title }}</span>
                <span class="when" data-test="item-status">{{ i.factoryStatus }}</span>
                <span class="prov" data-test="provenance">{{ provenanceText(i.provenance) }}</span>
              </button>
              <p class="sub">
                <span v-if="i.effort" data-test="item-effort">effort #{{ i.effort.number }}{{ i.effort.title ? ' ' + i.effort.title : '' }}</span>
                <span v-if="i.role">{{ i.role }}</span>
                <span v-if="i.blockedBy?.length" data-test="blocked-by">blocked by {{ i.blockedBy.map((n) => '#' + n).join(', ') }}</span>
                <a v-if="i.url" :href="i.url" data-test="item-link">open</a>
              </p>
            </li>
          </ol>
        </section>

        <aside class="notices" aria-label="Service notices">
          <h2>Service notices</h2>
          <AndonList :andon="p.andon" />
          <ParseFailureCard v-for="f in p.parseFailures" :key="f.path" :failure="f" />
          <IntakeQueue v-if="p.state === 'ok'" :entries="p.intake" />
          <DirectionPanel :directions="p.directions" :parse-failures="p.parseFailures" />
          <div class="scroll tall"><DecisionList :decisions="p.decisions" /></div>
        </aside>
      </div>
    </section>
  </div>
</template>

<style scoped>
.transit { --paper: #f4efe3; --ink: #1c1c1c; --mute: #5a5547; --amber: #ffb400; background: var(--paper); color: var(--ink); font-family: system-ui, 'Helvetica Neue', Helvetica, Arial, sans-serif; max-width: 92rem; margin: 0 auto; padding: 0 1rem 4rem; line-height: 1.45; }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
.hd { display: flex; align-items: center; gap: 1.5rem; flex-wrap: wrap; padding: 1rem 0; border-bottom: 6px solid var(--ink); }
.roundel { position: relative; display: flex; align-items: center; }
.rd { width: 3.4rem; height: 3.4rem; border-radius: 50%; border: 0.55rem solid #c4161c; }
.rd-name { position: absolute; left: -0.9rem; right: -0.9rem; text-align: center; background: #0a4fa8; color: #fff; font: 800 0.7rem/1 Arial, sans-serif; letter-spacing: 0.14em; padding: 0.3rem 0; }
.lens { margin: 0; border: 2px solid var(--ink); background: #fff; border-radius: 999px; padding: 0 0.9rem; font-size: 0.9rem; }
.board { background: #111; color: #fff; border: 6px solid #2c2c2c; border-radius: 8px; padding: 0.8rem 1rem; margin: 1rem 0; min-width: 0; }
.board h2 { margin: 0 0 0.5rem; font-size: 1.1rem; letter-spacing: 0.14em; text-transform: uppercase; }
.board h2 small { color: var(--amber); font: 600 0.85rem ui-monospace, Menlo, monospace; letter-spacing: 0.05em; margin-left: 0.5rem; }
.none { color: #d6d6d6; margin: 0; }
.rows { list-style: none; margin: 0; padding: 0; }
.rows li { border-top: 1px solid #3a3a3a; padding: 0.3rem 0; }
.rows li.hl { background: #2a2410; outline: 1px solid var(--amber); }
.rows button { all: unset; box-sizing: border-box; display: grid; grid-template-columns: 7rem 1fr 11rem 9rem; gap: 0.8rem; width: 100%; cursor: pointer; font: 600 0.9rem ui-monospace, Menlo, monospace; color: var(--amber); }
.rows button:focus-visible { outline: 3px solid #fff; outline-offset: 2px; }
.rows .what { color: #fff; overflow-wrap: anywhere; }
.rows .when { color: #8dffb0; }
.rows .prov { color: #d6d6d6; }
.s-blocked .when { color: #ffb0b0; }
.rows .sub { margin: 0.1rem 0 0.2rem; font-size: 0.8rem; color: #d6d6d6; display: flex; gap: 0.8rem; flex-wrap: wrap; overflow-wrap: anywhere; }
.rows a { color: #9fd0ff; }
.rows code { color: #d6d6d6; }
.scroll { max-height: 26rem; overflow-y: auto; }
.tall { max-height: 20rem; }
.project { margin-top: 1.5rem; }
.proj { margin: 0; font-size: 1.8rem; letter-spacing: -0.01em; }
.goal { font-size: clamp(1.2rem, 2.4vw, 2rem); font-weight: 800; line-height: 1.1; margin: 0.3rem 0; max-width: 60rem; }
.heading { margin: 0.2rem 0 0.8rem; color: var(--mute); }
.heading b { background: var(--ink); color: #fff; padding: 0 0.4rem; margin-right: 0.4rem; font-size: 0.75rem; letter-spacing: 0.12em; text-transform: uppercase; }
.proj-error { border: 3px solid #b4141a; padding: 0.5rem; font-weight: bold; }
.strip { list-style: none; display: grid; grid-template-columns: repeat(auto-fit, minmax(11rem, 1fr)); margin: 0.8rem 0; padding: 0; border: 2px solid var(--ink); background: #fff; }
.strip li { padding: 0.4rem 0.8rem; border-left: 1px solid var(--ink); border-top: 6px solid var(--ink); display: flex; flex-direction: column; overflow-wrap: anywhere; }
.strip li.bad { background: #ffe3e3; }
.strip span { font-size: 0.85rem; color: var(--mute); }
.strip li.bad span { color: #8a0f14; font-weight: bold; }
.mapbox { background: #fff; border: 2px solid var(--ink); overflow-x: auto; padding: 0.3rem; }
.mapbox:focus-visible { outline: 3px solid #0a3d99; outline-offset: 2px; }
.mapbox svg { display: block; max-width: none; font-family: inherit; }
.rowname { font-size: 11px; font-weight: 800; letter-spacing: 0.08em; fill: var(--ink); }
.yah { fill: #fff; font-size: 11px; font-weight: 800; letter-spacing: 0.1em; text-anchor: middle; }
.closed { font-size: 10px; font-weight: 800; letter-spacing: 0.12em; fill: #1c1c1c; text-anchor: middle; }
.detail { background: var(--ink); color: #fff; padding: 0.5rem 0.8rem; font-size: 0.9rem; min-height: 2.6rem; }
.detail b { color: var(--amber); }
.chip { border: 1px solid #fff; padding: 0 0.5rem; margin-left: 0.4rem; font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.05em; }
.legend { font-size: 0.85rem; color: var(--mute); margin: 0.4rem 0; }
.two { display: grid; grid-template-columns: minmax(0, 1fr) 24rem; gap: 1.5rem; align-items: start; }
.notices h2 { margin: 1rem 0 0.4rem; font-size: 0.9rem; letter-spacing: 0.16em; text-transform: uppercase; border-bottom: 4px solid var(--ink); padding-bottom: 0.3rem; }
.notices :deep(section), .notices :deep(article) { background: #fff; border: 2px solid var(--ink); border-left-width: 12px; padding: 0.4rem 0.8rem; margin: 0.6rem 0; overflow-wrap: anywhere; }
.notices :deep(section article) { border: 1px solid var(--ink); border-left-width: 4px; }
.notices :deep(h3) { margin: 0.2rem 0; font-size: 0.95rem; }
.notices :deep(li) { margin: 0.3rem 0; }
@media (max-width: 64rem) { .two { grid-template-columns: 1fr; } }
@media (max-width: 40rem) {
  .rows button { grid-template-columns: 1fr; gap: 0.1rem; }
  .goal { font-size: 1.2rem; }
}
@media (prefers-reduced-motion: no-preference) {
  .rows li.hl { transition: background 0.2s; }
}
</style>
