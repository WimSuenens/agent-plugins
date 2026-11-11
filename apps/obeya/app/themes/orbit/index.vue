<script setup lang="ts">
// Orbit: a dark mission-control look. The direction is the core; every board item is a node on the ring of its
// factory status, nearest the core when it most needs the person. This file only presents the `view`.
import type { Item } from '../../../shared/types'
import type { PageView, ProjectView, NeedsYouEntry } from '../../../shared/view'

const props = defineProps<{ view: PageView }>()

/** Rings from the core outwards: the more it needs attention, the closer. A status not listed follows, outermost. */
const RING_ORDER = ['Waiting on you', 'Blocked', 'Running', 'Ready', 'Backlog', 'Done']
const CORE_R = 64
const GAP = 44
const NODE_R = 14

const select = useState<Record<string, string>>('obeya-orbit-selected', () => ({}))
const openRing = useState<Record<string, string>>('obeya-orbit-open', () => ({}))

// The sync ring counts down to the next refresh; the interval is declared by the page chrome.
const syncSeconds = ref(15)
const syncRun = ref(0)
const syncEl = ref<HTMLElement | null>(null)
onMounted(() => {
  const n = Number(syncEl.value?.closest('[data-refresh-seconds]')?.getAttribute('data-refresh-seconds'))
  if (n > 0) syncSeconds.value = n
})
watch(() => props.view, () => syncRun.value++)

const from = (p: { kind: string; item?: string }) => (p.kind === 'in-flight' ? `in flight: ${p.item}` : p.kind)
const waited = (s: number | null) => {
  if (s === null) return 'wait unknown'
  if (s < 3600) return `${Math.floor(s / 60)} min`
  if (s < 86400) return `${Math.floor(s / 3600)} h`
  return `${Math.floor(s / 86400)} d`
}
const doorOf = (e: NeedsYouEntry) => (e.decision ? `${e.decision.door} door` : null)

interface Slot { item: Item; x: number; y: number }
interface Ring { status: string; r: number; count: number; slots: Slot[]; more: { hidden: number; x: number; y: number } | null; items: Item[] }

const GLYPH: Record<string, string> = { 'Waiting on you': '!', Blocked: 'X', Running: '>', Ready: '+', Backlog: '-', Done: 'ok' }

function ringsOf(p: ProjectView): Ring[] {
  const order = [...RING_ORDER, ...p.board.map((c) => c.status).filter((s) => !RING_ORDER.includes(s))]
  return order.map((status, i) => {
    const items = p.board.find((c) => c.status === status)?.items ?? []
    const r = CORE_R + 40 + i * GAP
    const cap = Math.max(6, Math.floor((2 * Math.PI * r) / 38))
    const shown = items.length > cap ? items.slice(0, cap - 1) : items
    const hidden = items.length - shown.length
    const total = shown.length + (hidden ? 1 : 0)
    const at = (k: number) => {
      const a = (-90 + (360 * (k + 0.5)) / total) * (Math.PI / 180)
      return { x: Math.round(Math.cos(a) * r * 10) / 10, y: Math.round(Math.sin(a) * r * 10) / 10 }
    }
    return {
      status,
      r,
      count: items.length,
      items,
      slots: shown.map((item, k) => ({ item, ...at(k) })),
      more: hidden ? { hidden, ...at(shown.length) } : null,
    }
  })
}
const rings = computed(() => Object.fromEntries(props.view.projects.map((p) => [p.id, ringsOf(p)])))
const extent = (id: string) => (rings.value[id]?.at(-1)?.r ?? CORE_R) + 36

function selected(p: ProjectView): Item | null {
  const all = rings.value[p.id].flatMap((r) => r.items)
  return all.find((i) => i.id === select.value[p.id]) ?? all[0] ?? null
}
const pick = (p: ProjectView, i: Item) => (select.value = { ...select.value, [p.id]: i.id })
const toggleRing = (p: ProjectView, status: string) => {
  openRing.value = { ...openRing.value, [p.id]: openRing.value[p.id] === status ? '' : status }
}
const ringOpen = (p: ProjectView) => rings.value[p.id].find((r) => r.status === openRing.value[p.id]) ?? null
const slug = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, '-')
</script>

<template>
  <div class="orbit">
    <header class="top">
      <h1 class="brand">OBEYA <span>// orbit</span></h1>
      <p class="chip lens" data-test="lens-badge">read-only lens &middot; bound to {{ view.bindAddress }}</p>
      <div ref="syncEl" class="sync" data-test="sync-ring">
        <svg viewBox="0 0 24 24" width="28" height="28" aria-hidden="true" focusable="false">
          <circle cx="12" cy="12" r="10" class="sync-track" />
          <circle :key="syncRun" cx="12" cy="12" r="10" class="sync-arc" pathLength="100" :style="{ animationDuration: syncSeconds + 's' }" />
        </svg>
        <span>sync every {{ syncSeconds }}s</span>
      </div>
    </header>

    <section class="panel needs" data-test="needs-you" aria-labelledby="orbit-needs-h">
      <h2 id="orbit-needs-h">Needs you <em>{{ view.needsYou.length }}</em></h2>
      <p v-if="!view.needsYou.length" class="ok-line">Nothing needs you right now.</p>
      <ol v-else class="needs-list">
        <li v-for="e in view.needsYou" :key="e.id" :data-test="{ decision: 'pending-decision', idea: 'needs-you-idea', waiting: 'waiting-item' }[e.kind]">
          <strong>{{ e.title }}</strong>
          <span v-if="e.kind === 'idea'" class="tag">idea waiting for you</span>
          <span v-else class="tag" data-test="waited">waiting {{ waited(e.waitingSeconds) }}</span>
          <span v-if="doorOf(e)" class="tag" data-test="door">{{ doorOf(e) }}</span>
          <span v-if="e.decision" class="tag" data-test="provenance">{{ from(e.decision.provenance) }}</span>
          <span v-else-if="e.kind === 'waiting'" class="tag">waiting on you</span>
          <p v-if="e.decision" class="dim">Asked of {{ e.decision.askedOf }}. Options: {{ e.decision.options.join(' / ') }}.</p>
          <p v-if="e.kind !== 'idea'" class="dim"><a v-if="e.ref.startsWith('http')" :href="e.ref">{{ e.ref }}</a><code v-else>{{ e.ref }}</code></p>
        </li>
      </ol>
    </section>

    <p v-if="!view.projects.length" class="panel" data-test="empty">No project is configured.</p>

    <section v-for="p in view.projects" :key="p.id" class="project" :data-project="p.id">
      <p v-if="p.state !== 'ok'" role="alert" class="panel alert" data-test="project-error">{{ p.id }}: {{ p.error }}</p>
      <template v-else>
        <h2 class="project-name" data-test="project-name">{{ p.name }}</h2>
        <div class="grid">
          <div class="col">
            <section class="panel" data-test="direction" aria-label="Direction">
              <h3>Direction <em>docs/direction.md</em></h3>
              <p v-if="!p.directions.length && !p.parseFailures.some((f) => f.path === 'docs/direction.md')" data-test="direction-empty" class="dim">
                No direction yet. Create <code>docs/direction.md</code> with <code>goal</code> and <code>current</code> in its front matter and a
                <code>## History</code> list of <code>- YYYY-MM-DD: what changed</code> lines.
              </p>
              <article v-for="d in p.directions" :key="d.id">
                <p class="goal"><span class="lbl">Goal</span> <span data-test="direction-goal">{{ d.goal }}</span></p>
                <p class="head"><span class="lbl">Heading</span> <span data-test="direction-current">{{ d.current }}</span></p>
                <ol class="log" aria-label="History">
                  <li v-for="h in d.history" :key="h.date + h.change" data-test="direction-history-entry"><time :datetime="h.date">{{ h.date }}</time> {{ h.change }}</li>
                </ol>
                <p><code data-test="direction-source">{{ d.ref }}</code> <span class="tag" data-test="provenance">{{ from(d.provenance) }}</span></p>
              </article>
            </section>

            <section v-for="f in p.parseFailures" :key="f.path" class="panel glitch" data-test="parse-failure" role="group" :aria-label="`Corrupt signal: could not read ${f.path}`">
              <h3>Corrupt signal</h3>
              <p data-test="pf-path"><code>{{ f.path }}</code></p>
              <p data-test="pf-reason">{{ f.reason }}</p>
              <span class="tag" data-test="provenance">{{ from(f.provenance) }}</span>
            </section>
          </div>

          <div class="col centre">
            <section class="panel" data-test="board" aria-label="Factory board">
              <h3>Board <em>nearer the core needs you more</em></h3>
              <svg class="map" :viewBox="`${-extent(p.id)} ${-extent(p.id)} ${extent(p.id) * 2} ${extent(p.id) * 2}`" role="group" aria-label="Work items orbiting the project direction">
                <g class="sweep" aria-hidden="true"><path :d="`M0 0 L${extent(p.id)} 0 A${extent(p.id)} ${extent(p.id)} 0 0 0 ${extent(p.id) * 0.77} ${-extent(p.id) * 0.64} Z`" /></g>
                <g v-for="r in rings[p.id]" :key="r.status" class="ring" :data-ring="r.status" :data-count="r.count" :class="'s-' + slug(r.status)">
                  <circle :r="r.r" class="orb" />
                  <text :x="8" :y="-r.r + 11" class="ringlbl">{{ r.status.toUpperCase() }} &middot; {{ r.count }}</text>
                  <g
                    v-for="s in r.slots"
                    :key="s.item.id"
                    class="node"
                    :class="{ sel: selected(p)?.id === s.item.id, wait: r.status === 'Waiting on you', foreign: s.item.provenance.kind !== 'merged' }"
                    data-test="orbit-node"
                    :data-item="s.item.number"
                    :transform="`translate(${s.x} ${s.y})`"
                    role="button"
                    tabindex="0"
                    :aria-pressed="selected(p)?.id === s.item.id"
                    :aria-label="`#${s.item.number} ${s.item.title}, ${r.status}, ${from(s.item.provenance)}`"
                    @click="pick(p, s.item)"
                    @keydown.enter.prevent="pick(p, s.item)"
                    @keydown.space.prevent="pick(p, s.item)"
                  >
                    <circle v-if="r.status === 'Waiting on you'" class="pulse" :r="NODE_R" />
                    <circle class="body" :r="NODE_R" />
                    <text y="3.5">{{ s.item.number }}</text>
                    <text y="-17" class="glyph">{{ GLYPH[r.status] ?? '?' }}</text>
                  </g>
                  <g
                    v-if="r.more"
                    class="node more"
                    data-test="orbit-more"
                    :data-hidden="r.more.hidden"
                    :transform="`translate(${r.more.x} ${r.more.y})`"
                    role="button"
                    tabindex="0"
                    :aria-expanded="openRing[p.id] === r.status"
                    :aria-label="`${r.more.hidden} more in ${r.status}, show list`"
                    @click="toggleRing(p, r.status)"
                    @keydown.enter.prevent="toggleRing(p, r.status)"
                    @keydown.space.prevent="toggleRing(p, r.status)"
                  >
                    <circle class="body" :r="NODE_R + 2" />
                    <text y="3.5">+{{ r.more.hidden }}</text>
                  </g>
                </g>
                <g class="core" aria-hidden="true">
                  <circle :r="CORE_R - 18" class="core-body" />
                  <text y="-3" class="core-t">DIRECTION</text>
                  <text y="10" class="core-s">{{ p.directions[0]?.ref ?? 'none yet' }}</text>
                </g>
              </svg>
              <ul class="legend" aria-label="Rings">
                <li v-for="r in rings[p.id]" :key="r.status" :class="'s-' + slug(r.status)"><b aria-hidden="true">{{ GLYPH[r.status] ?? '?' }}</b> {{ r.status }} {{ r.count }}</li>
              </ul>
              <div v-if="ringOpen(p)" class="overflow" data-test="orbit-overflow" role="region" :aria-label="`All ${ringOpen(p)!.status} items`">
                <h4>{{ ringOpen(p)!.status }} &middot; {{ ringOpen(p)!.count }}</h4>
                <ul>
                  <li v-for="i in ringOpen(p)!.items" :key="i.id">
                    <button type="button" @click="pick(p, i)">#{{ i.number }} {{ i.title }}</button>
                    <span class="tag">{{ from(i.provenance) }}</span>
                  </li>
                </ul>
              </div>
            </section>

            <section v-if="p.andon.length" class="panel andon" data-test="andon" aria-label="Andon">
              <h3>Andon</h3>
              <article v-for="a in p.andon.filter((x) => !x.resolved)" :key="a.id" class="alert" role="alert" data-test="andon-open">
                <b>LINE STOPPED</b> {{ a.reason }}
                <p>{{ a.item === null ? 'no item' : `item #${a.item}` }}, owner {{ a.owner ?? 'unknown' }}<template v-if="a.since">, since {{ a.since }}</template></p>
                <code>{{ a.ref }}</code> <span class="tag" data-test="provenance">{{ from(a.provenance) }}</span>
              </article>
              <article v-for="a in p.andon.filter((x) => x.resolved)" :key="a.id" class="ok-line" data-test="andon-resolved">
                <b>RESOLVED</b> {{ a.reason }}
                <p>{{ a.item === null ? 'no item' : `item #${a.item}` }}, owner {{ a.owner ?? 'unknown' }}. Countermeasure: {{ a.countermeasure }}</p>
                <code>{{ a.ref }}</code> <span class="tag" data-test="provenance">{{ from(a.provenance) }}</span>
              </article>
            </section>
          </div>

          <div class="col">
            <section class="panel insp" data-test="inspector" aria-label="Inspector" aria-live="polite">
              <h3>Inspector</h3>
              <template v-if="selected(p)">
                <p class="big">
                  <a v-if="selected(p)!.url" :href="selected(p)!.url!" data-test="item-link">#{{ selected(p)!.number }} {{ selected(p)!.title }}</a>
                  <template v-else>#{{ selected(p)!.number }} {{ selected(p)!.title }}</template>
                </p>
                <dl>
                  <dt>Status</dt><dd>{{ selected(p)!.factoryStatus }}</dd>
                  <template v-if="selected(p)!.kind"><dt>Kind</dt><dd data-test="item-kind">{{ selected(p)!.kind }}</dd></template>
                  <template v-if="selected(p)!.role"><dt>Role</dt><dd data-test="item-role">{{ selected(p)!.role }}</dd></template>
                  <template v-if="selected(p)!.effort">
                    <dt>Effort</dt><dd data-test="item-effort">#{{ selected(p)!.effort!.number }}{{ selected(p)!.effort!.title ? ' ' + selected(p)!.effort!.title : '' }}</dd>
                  </template>
                  <template v-if="selected(p)!.blockedBy?.length"><dt>Blocked by</dt><dd data-test="blocked-by">{{ selected(p)!.blockedBy!.map((n) => '#' + n).join(', ') }}</dd></template>
                  <template v-else-if="selected(p)!.factoryStatus === 'Blocked'"><dt>Blocked by</dt><dd data-test="blocked-by">blocker not recorded on the board</dd></template>
                  <dt>Source</dt><dd><span class="tag" data-test="provenance">{{ from(selected(p)!.provenance) }}</span></dd>
                </dl>
              </template>
              <p v-else class="dim">The board is empty.</p>
            </section>
          </div>
        </div>

        <div class="foot">
          <section class="panel" data-test="decisions" aria-label="Decisions made">
            <h3>Decision rail <em>{{ p.decisions.length }} made, {{ p.pendingDecisions.length }} ahead</em></h3>
            <div class="rail" aria-hidden="true">
              <span v-for="(d, k) in p.decisions" :key="d.id" class="seg" :title="d.title">{{ d.order ?? k + 1 }}</span>
              <span v-for="d in p.pendingDecisions" :key="d.id" class="seg ahead" :title="d.title">?</span>
            </div>
            <p v-if="!p.decisions.length" class="dim">No decisions recorded.</p>
            <ol class="scroll">
              <li v-for="d in p.decisions" :key="d.id" data-test="decision">
                <a v-if="d.url" :href="d.url" data-test="decision-link">{{ d.title }}</a><template v-else>{{ d.title }}</template>
                <code>{{ d.ref }}</code> <span class="tag">{{ d.status }}</span> <span class="tag" data-test="provenance">{{ from(d.provenance) }}</span>
              </li>
            </ol>
            <template v-if="p.pendingDecisions.length">
              <h4>Ahead</h4>
              <ul class="scroll">
                <li v-for="d in p.pendingDecisions" :key="d.id" class="ahead-li" data-test="decision-ahead">
                  {{ d.title }} <span class="tag">{{ d.door }} door</span> <span class="tag" data-test="provenance">{{ from(d.provenance) }}</span>
                </li>
              </ul>
            </template>
          </section>

          <section class="panel" data-test="intake-queue" aria-label="Intake queue">
            <h3>Intake signal feed</h3>
            <p v-if="!p.intake.length" class="dim">No ideas have come in.</p>
            <ul v-else class="scroll feed">
              <li v-for="e in p.intake" :key="e.id" :class="{ waiting: e.waitingOnHuman }" :data-test="e.waitingOnHuman ? 'intake-waiting' : 'intake-entry'">
                <strong data-test="intake-title">{{ e.title }}</strong>
                <span class="tag" data-test="intake-channel">{{ e.channel }}</span>
                <span class="tag" data-test="intake-outcome">{{ e.waitingOnHuman ? 'Needs you' : e.outcome }}</span>
                <span v-if="e.provenance.kind === 'in-flight'" class="tag" data-test="provenance">{{ from(e.provenance) }}</span>
                <p v-if="e.reason" class="dim" data-test="intake-reason">{{ e.reason }}</p>
              </li>
            </ul>
          </section>
        </div>
      </template>
    </section>
  </div>
</template>

<style scoped>
.orbit {
  --bg: #04060c; --ink: #d8f6ff; --dim: #93a4c6; --cy: #3df5ff; --mg: #ff6fa8; --am: #ffc233; --lm: #8dff7a; --rd: #ff7676;
  background: radial-gradient(1000px 600px at 50% 30%, #0c2240, transparent 70%), var(--bg);
  color: var(--ink);
  font: 13px/1.5 ui-monospace, 'SF Mono', Menlo, Consolas, monospace;
  min-height: 100vh;
  padding: 0 1rem 2rem;
}
.orbit a { color: var(--cy); }
.orbit code { color: var(--am); overflow-wrap: anywhere; }
.orbit h1, .orbit h2, .orbit h3, .orbit h4 { margin: 0; font-weight: 600; letter-spacing: 0.14em; text-transform: uppercase; }
.top { display: flex; align-items: center; gap: 1rem; flex-wrap: wrap; padding: 0.6rem 0; border-bottom: 1px solid rgba(61, 245, 255, 0.35); }
.brand { font-size: 15px; color: var(--cy); }
.brand span { color: var(--dim); }
.chip, .tag { display: inline-block; border: 1px solid currentColor; padding: 0 0.5rem; font-size: 11px; letter-spacing: 0.08em; text-transform: uppercase; margin: 0 0.2rem; }
.lens { color: var(--lm); margin: 0; }
.sync { display: flex; align-items: center; gap: 0.5rem; color: var(--dim); margin-left: auto; }
.sync-track { fill: none; stroke: rgba(61, 245, 255, 0.25); stroke-width: 2; }
.sync-arc { fill: none; stroke: var(--cy); stroke-width: 2; stroke-dasharray: 100; transform: rotate(-90deg); transform-origin: center; animation: drain linear infinite; }
@keyframes drain { from { stroke-dashoffset: 0; } to { stroke-dashoffset: 100; } }
.panel { position: relative; border: 1px solid rgba(61, 245, 255, 0.4); background: rgba(7, 14, 28, 0.8); padding: 0.7rem 0.9rem; margin: 0.8rem 0; min-width: 0; }
.panel h2, .panel h3 { font-size: 11px; color: var(--cy); margin-bottom: 0.5rem; display: flex; justify-content: space-between; gap: 0.5rem; flex-wrap: wrap; }
.panel em { font-style: normal; color: var(--dim); letter-spacing: 0.05em; text-transform: none; }
.needs { border-color: var(--mg); border-left-width: 6px; }
.needs h2 { color: var(--mg); }
.needs-list { padding-left: 1.2rem; margin: 0; }
.needs-list li { margin-bottom: 0.6rem; }
.needs-list .tag { color: var(--mg); }
.dim { color: var(--dim); margin: 0.2rem 0; overflow-wrap: anywhere; }
.ok-line { color: var(--lm); }
.project-name { color: #fff; font-size: 18px; margin-top: 1.2rem; text-shadow: 0 0 14px rgba(61, 245, 255, 0.5); }
.grid { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1.6fr) minmax(0, 1fr); gap: 0 1rem; align-items: start; }
.col { min-width: 0; }
.lbl { color: var(--dim); text-transform: uppercase; letter-spacing: 0.1em; margin-right: 0.4rem; }
.goal { font-size: 15px; color: #fff; margin: 0.2rem 0; }
.head { color: var(--am); margin: 0.2rem 0; }
.log { margin: 0.4rem 0; padding-left: 1.2rem; color: var(--dim); }
.glitch { border: 1px dashed var(--am); background: repeating-linear-gradient(45deg, rgba(255, 194, 51, 0.08) 0 6px, transparent 6px 12px); }
.glitch h3 { color: var(--am); }
.glitch p { margin: 0.2rem 0; overflow-wrap: anywhere; }
.alert { border: 2px solid var(--rd); background: rgba(255, 118, 118, 0.1); padding: 0.6rem; margin: 0.5rem 0; overflow-wrap: anywhere; }
.alert b { color: var(--rd); letter-spacing: 0.15em; }
.andon .ok-line { border-top: 1px dashed rgba(141, 255, 122, 0.4); padding-top: 0.5rem; margin-top: 0.5rem; }
.map { width: 100%; height: auto; max-height: 80vh; display: block; }
.orb { fill: none; stroke: var(--cy); stroke-opacity: 0.4; }
.s-waiting-on-you { --c: var(--mg); } .s-blocked { --c: var(--rd); } .s-running { --c: var(--cy); }
.s-ready { --c: var(--lm); } .s-backlog { --c: var(--dim); } .s-done { --c: #55c2b6; }
.ring .orb { stroke: var(--c, var(--cy)); }
.s-backlog .orb { stroke-dasharray: 2 6; } .s-done .orb { stroke-dasharray: 1 3; }
.ringlbl { font-size: 9px; fill: var(--dim); letter-spacing: 0.15em; }
.node { cursor: pointer; color: var(--c, var(--cy)); }
.node .body { fill: #04101c; stroke: currentColor; stroke-width: 2; }
.node.foreign .body { stroke-dasharray: 3 3; }
.node text { font-size: 9px; fill: #fff; text-anchor: middle; pointer-events: none; }
.node .glyph { fill: currentColor; font-size: 8px; font-weight: 700; }
.node.sel .body { stroke: #fff; stroke-width: 3; }
.node:focus-visible { outline: none; }
.node:focus-visible .body { stroke: #fff; stroke-width: 4; stroke-dasharray: none; }
.node:hover .body { filter: drop-shadow(0 0 6px currentColor); }
.more .body { fill: rgba(61, 245, 255, 0.15); stroke-dasharray: none; }
.pulse { fill: none; stroke: currentColor; stroke-width: 1.5; transform-box: fill-box; transform-origin: center; animation: pulse 1.8s ease-out infinite; }
@keyframes pulse { from { transform: scale(1); opacity: 0.9; } to { transform: scale(2.4); opacity: 0; } }
.sweep path { fill: rgba(61, 245, 255, 0.12); }
.sweep { transform-origin: 0 0; animation: spin 10s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.core-body { fill: #04101c; stroke: var(--cy); stroke-width: 1.5; }
.core-t { fill: #fff; font-size: 7px; letter-spacing: 1.5px; text-anchor: middle; }
.core-s { fill: var(--dim); font-size: 5px; text-anchor: middle; }
.legend { list-style: none; padding: 0; margin: 0.4rem 0 0; display: flex; gap: 0.3rem 1rem; flex-wrap: wrap; color: var(--dim); }
.legend li { color: var(--c, var(--dim)); }
.legend b { display: inline-block; min-width: 1.4em; border: 1px solid currentColor; text-align: center; }
.overflow { margin-top: 0.6rem; border-top: 1px dashed rgba(61, 245, 255, 0.4); padding-top: 0.5rem; }
.overflow ul, .scroll { list-style: none; padding: 0; margin: 0.3rem 0; max-height: 14rem; overflow: auto; }
ol.scroll { padding-left: 0; }
.overflow li, .scroll li { padding: 0.25rem 0; border-top: 1px dashed rgba(61, 245, 255, 0.18); overflow-wrap: anywhere; }
.overflow button { font: inherit; color: var(--cy); background: transparent; border: 0; text-align: left; cursor: pointer; padding: 0; text-decoration: underline; }
.insp dl { display: grid; grid-template-columns: 6.5rem 1fr; gap: 0.2rem 0.6rem; margin: 0.5rem 0 0; }
.insp dt { color: var(--dim); } .insp dd { margin: 0; overflow-wrap: anywhere; }
.big { color: #fff; font-size: 14px; margin: 0.3rem 0; overflow-wrap: anywhere; }
.foot { display: grid; grid-template-columns: 1fr 1fr; gap: 0 1rem; }
.rail { display: flex; gap: 4px; flex-wrap: wrap; margin: 0.4rem 0; }
.seg { min-width: 26px; height: 26px; padding: 0 4px; display: inline-flex; align-items: center; justify-content: center; background: rgba(61, 245, 255, 0.7); color: #001317; font-weight: 700; font-size: 10px; border: 1px solid var(--cy); }
.seg.ahead { background: transparent; color: var(--mg); border: 1px dashed var(--mg); animation: flicker 2.4s infinite; }
@keyframes flicker { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }
.waiting { border-left: 3px solid var(--mg); padding-left: 0.5rem; }
.orbit :focus-visible, .overflow button:focus-visible { outline: 3px solid #fff; outline-offset: 2px; }
@media (max-width: 1100px) {
  .grid, .foot { grid-template-columns: 1fr; }
  .centre { order: -1; }
}
@media (max-width: 40rem) { .orbit { padding: 0 0.5rem 1rem; font-size: 12px; } .insp dl { grid-template-columns: 1fr; } }
@media (prefers-reduced-motion: reduce) {
  .sync-arc, .pulse, .sweep, .seg.ahead { animation: none; }
  .sync-arc { stroke-dashoffset: 0; }
}
</style>
