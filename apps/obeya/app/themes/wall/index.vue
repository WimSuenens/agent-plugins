<script setup lang="ts">
import type { PageView } from '../../../shared/view'
import type { Decision, IntakeEntry, Provenance } from '../../../shared/types'

// The Wall: the physical Obeya room on screen. It only presents `view`; it fetches and computes nothing.
defineProps<{ view: PageView }>()

const FOLD_NOTES = 6
const FOLD_CARDS = 8

const from = (p: Provenance) => (p.kind === 'in-flight' ? `in flight: ${p.item}` : p.kind)
const channels: Record<string, string> = { slack: 'Slack', mail: 'Mail', teams: 'Teams', inbox: 'Inbox folder', terminal: 'Terminal', unknown: 'Unknown channel' }
const channelMark: Record<string, string> = { slack: '#', mail: '@', teams: 'T', inbox: '[]', terminal: '>_', unknown: '?' }
const outcomes: Record<string, string> = {
  direction: 'Direction',
  'slice-candidate': 'Slice candidate',
  'research-ticket': 'Research ticket',
  parked: 'Parked',
  rejected: 'Rejected',
  untriaged: 'Not triaged yet',
}
const outcomeLabel = (e: IntakeEntry) => (e.waitingOnHuman ? 'Needs you' : outcomes[e.outcome])
const waited = (s: number | null) => {
  if (s === null) return 'waiting time unknown'
  if (s < 3600) return `waiting ${Math.floor(s / 60)} min`
  if (s < 86400) return `waiting ${Math.floor(s / 3600)} h`
  return `waiting ${Math.floor(s / 86400)} d`
}
const decisionLabel = (d: Decision) => `${d.title} (${d.status})`
</script>

<template>
  <div class="wall">
    <header class="top">
      <h1 class="marker">Obeya</h1>
      <p class="lens" data-test="lens-badge">read-only lens &middot; bound to {{ view.bindAddress }}</p>
    </header>

    <section class="needs-you" data-test="needs-you" aria-labelledby="wall-needs-h">
      <h2 id="wall-needs-h" class="marker">Needs you</h2>
      <p v-if="!view.needsYou.length" class="paper">Nothing needs you right now.</p>
      <ol v-else class="notes">
        <li v-for="e in view.needsYou" :key="e.id" class="note flagged" :data-test="{ decision: 'pending-decision', idea: 'needs-you-idea', waiting: 'waiting-item' }[e.kind]">
          <span class="flag">Needs you</span>
          <strong>{{ e.title }}</strong>
          <span v-if="e.kind === 'idea'" class="tag">idea waiting for you</span>
          <span v-else class="tag" data-test="waited">{{ waited(e.waitingSeconds) }}</span>
          <template v-if="e.decision">
            <span class="tag" data-test="door">{{ e.decision.door }} door</span>
            <span class="tag" data-test="provenance">{{ from(e.decision.provenance) }}</span>
            <span class="meta">Asked of {{ e.decision.askedOf }}. Options: {{ e.decision.options.join(' / ') }}.</span>
          </template>
          <span v-if="e.kind !== 'idea'" class="meta"><a v-if="e.ref.startsWith('http')" :href="e.ref">{{ e.ref }}</a><code v-else>{{ e.ref }}</code></span>
        </li>
      </ol>
    </section>

    <p v-if="!view.projects.length" class="paper" data-test="empty">No project is configured.</p>

    <section v-for="p in view.projects" :key="p.id" class="project" :data-project="p.id">
      <h2 v-if="p.state === 'ok'" class="marker" data-test="project-name">{{ p.name }}</h2>
      <p v-else role="alert" class="paper" data-test="project-error">{{ p.id }}: {{ p.error }}</p>

      <!-- Where we are going -->
      <section class="board-white direction" data-test="direction" aria-label="Direction">
        <h3 class="marker">Where we're going</h3>
        <p v-if="!p.directions.length && !p.parseFailures.some((f) => f.path === 'docs/direction.md')" data-test="direction-empty">
          No direction yet. Create <code>docs/direction.md</code> with <code>goal</code> and <code>current</code> in its front matter and a
          <code>## History</code> list of <code>- YYYY-MM-DD: what changed</code> lines; the product-owner keeps it up to date.
        </p>
        <article v-for="d in p.directions" :key="d.id" class="dir-doc">
          <span class="compass" aria-hidden="true">N</span>
          <p class="goal"><strong>Goal:</strong> <span data-test="direction-goal">{{ d.goal }}</span></p>
          <p class="arrow-note"><strong>Heading:</strong> <span data-test="direction-current">{{ d.current }}</span> &rarr;</p>
          <ol aria-label="History" class="history">
            <li v-for="h in d.history" :key="h.date + h.change" data-test="direction-history-entry"><time :datetime="h.date">{{ h.date }}</time> {{ h.change }}</li>
          </ol>
          <p class="meta"><code data-test="direction-source">{{ d.ref }}</code> <span class="tag" data-test="provenance">{{ from(d.provenance) }}</span></p>
        </article>
      </section>

      <!-- Andon light tower -->
      <section class="andon-wrap" data-test="andon" aria-label="Andon">
        <div class="tower" data-test="andon-light" :data-state="p.andon.some((a) => !a.resolved) ? 'red' : 'green'">
          <span class="lamp red" :class="{ on: p.andon.some((a) => !a.resolved) }" aria-hidden="true"></span>
          <span class="lamp green" :class="{ on: !p.andon.some((a) => !a.resolved) }" aria-hidden="true"></span>
          <span class="tower-text">{{ p.andon.some((a) => !a.resolved) ? 'Andon: line stopped' : 'Andon: line running' }}</span>
        </div>
        <article v-for="a in p.andon" :key="a.id" class="note" :class="a.resolved ? 'done-note' : 'open-andon'" :role="a.resolved ? undefined : 'alert'" :data-test="a.resolved ? 'andon-resolved' : 'andon-open'">
          <strong v-if="!a.resolved">Line stopped: {{ a.reason }}</strong>
          <span v-else>Resolved: {{ a.reason }}</span>
          <span class="meta">{{ a.item === null ? 'no item' : `item #${a.item}` }}, owner {{ a.owner ?? 'unknown' }}<template v-if="a.since">, since {{ a.since }}</template></span>
          <span v-if="a.resolved" class="meta">Countermeasure: {{ a.countermeasure }}</span>
          <code>{{ a.ref }}</code>
          <span class="tag" data-test="provenance">{{ from(a.provenance) }}</span>
        </article>
      </section>

      <!-- Factory line -->
      <section class="line" data-test="board" aria-label="Factory board">
        <h3 class="marker">Factory line</h3>
        <div class="cols">
          <div v-for="c in p.board" :key="c.status" class="col" :class="{ you: c.status === 'Waiting on you' }" :data-column="c.status">
            <h4 class="col-head">{{ c.status }} ({{ c.items.length }})<span v-if="c.status === 'Waiting on you'" class="flag">needs you</span></h4>
            <component :is="c.status === 'Done' && c.items.length > FOLD_NOTES ? 'details' : 'div'" class="stack" :data-test="c.status === 'Done' && c.items.length > FOLD_NOTES ? 'done-stack' : undefined">
              <summary v-if="c.status === 'Done' && c.items.length > FOLD_NOTES">{{ c.items.length }} finished notes folded into a stack</summary>
              <div class="stack-body">
                <details v-for="i in c.items" :key="i.id" class="note" :class="{ blocked: i.factoryStatus === 'Blocked', flagged: c.status === 'Waiting on you' }" data-test="item-card">
                  <summary>
                    <span v-if="i.factoryStatus === 'Blocked'" class="stamp">BLOCKED</span>
                    <span v-if="c.status === 'Waiting on you'" class="flag">Needs you</span>
                    #{{ i.number }} {{ i.title }}
                  </summary>
                  <p v-if="i.blockedBy?.length" class="meta" data-test="blocked-by">Blocked by {{ i.blockedBy.map((n) => '#' + n).join(', ') }}</p>
                  <p v-else-if="i.factoryStatus === 'Blocked'" class="meta" data-test="blocked-by">Blocked: blocker not recorded on the board</p>
                  <p class="meta">
                    <span v-if="i.kind" class="tag" data-test="item-kind">{{ i.kind }}</span>
                    <span v-if="i.role" class="tag" data-test="item-role">{{ i.role }}</span>
                    <span v-if="i.effort" class="tag" data-test="item-effort">effort #{{ i.effort.number }}{{ i.effort.title ? ' ' + i.effort.title : '' }}</span>
                    <span class="tag" data-test="provenance">{{ from(i.provenance) }}</span>
                  </p>
                  <a v-if="i.url" :href="i.url" data-test="item-link">Open #{{ i.number }}</a>
                </details>
              </div>
            </component>
          </div>
        </div>
      </section>

      <!-- Decisions: index cards -->
      <section class="cards" data-test="decisions" aria-label="Decisions made">
        <h3 class="marker">Decisions</h3>
        <p v-if="!p.decisions.length" class="paper">No decisions recorded.</p>
        <component :is="p.decisions.length > FOLD_CARDS ? 'details' : 'div'" :data-test="p.decisions.length > FOLD_CARDS ? 'adr-stack' : undefined" class="stack">
          <summary v-if="p.decisions.length > FOLD_CARDS">{{ p.decisions.length }} decisions in the card box</summary>
          <ol class="card-list">
            <li v-for="d in p.decisions" :key="d.id" class="index-card" data-test="decision">
              <span class="tick" aria-hidden="true">&#10003;</span><span class="sr-only">Decided: </span>
              <a v-if="d.url" :href="d.url" data-test="decision-link">{{ decisionLabel(d) }}</a>
              <template v-else>{{ decisionLabel(d) }}</template>
              <code>{{ d.ref }}</code>
              <span class="tag" data-test="provenance">{{ from(d.provenance) }}</span>
            </li>
          </ol>
        </component>
        <ol v-if="p.pendingDecisions.length" class="card-list pending" aria-label="Pending decisions">
          <li v-for="d in p.pendingDecisions" :key="d.id" class="index-card pinned" data-test="pinned-decision">
            <span class="pin" aria-hidden="true">&#9679;</span>
            <strong>Pending: {{ d.title }}</strong>
            <span class="tag">{{ d.door }} door</span>
            <span class="meta">Asked of {{ d.askedOf }}. Options: {{ d.options.join(' / ') }}.</span>
            <code>{{ d.ref }}</code>
            <span class="tag" data-test="provenance">{{ from(d.provenance) }}</span>
          </li>
        </ol>
      </section>

      <!-- Intake tray -->
      <section v-if="p.state === 'ok'" class="tray" data-test="intake-queue" aria-label="Intake queue">
        <h3 class="marker">Intake tray</h3>
        <p v-if="!p.intake.length" class="paper">No ideas have come in.</p>
        <ul v-else class="slips">
          <li v-for="e in p.intake" :key="e.id" class="slip" :class="{ waiting: e.waitingOnHuman }" :data-waiting="e.waitingOnHuman || undefined" :data-test="e.waitingOnHuman ? 'intake-waiting' : 'intake-entry'">
            <span class="source" data-test="intake-channel"><span aria-hidden="true">{{ channelMark[e.channel] }}</span> {{ channels[e.channel] }}</span>
            <strong data-test="intake-title">{{ e.title }}</strong>
            <span class="rubber" data-test="intake-outcome">{{ outcomeLabel(e) }}</span>
            <span class="tag" data-test="provenance">{{ from(e.provenance) }}</span>
            <span v-if="e.reason" class="meta" data-test="intake-reason">{{ e.reason }}</span>
          </li>
        </ul>
      </section>

      <ParseFailureCard v-for="f in p.parseFailures" :key="f.path" :failure="f" class="pf" />
    </section>
  </div>
</template>

<style scoped>
.wall {
  --ink: #1f1a10;
  --cork: #b98b57;
  --paper: #fffdf5;
  --sticky: #fff3a0;
  --alert: #8a1010;
  --font-hand: 'Segoe Print', 'Bradley Hand', 'Marker Felt', 'Comic Sans MS', cursive;
  --font-body: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
  background: var(--cork);
  background-image: radial-gradient(rgba(0, 0, 0, 0.12) 1px, transparent 1.5px);
  background-size: 9px 9px;
  color: var(--ink);
  font-family: var(--font-body);
  line-height: 1.45;
  padding: 1rem;
  min-height: 100vh;
}
.marker { font-family: var(--font-hand), var(--font-body); background: var(--paper); display: inline-block; padding: 0.1rem 0.7rem; margin: 0.4rem 0; border-radius: 3px; color: var(--ink); }
.top { display: flex; align-items: center; gap: 1rem; flex-wrap: wrap; }
.lens { background: var(--paper); border: 2px solid var(--ink); border-radius: 999px; padding: 0 0.8rem; margin: 0; font-size: 0.9rem; }
.paper, .board-white, .index-card, .tray, .cards { color: var(--ink); }
.paper { background: var(--paper); display: inline-block; padding: 0.3rem 0.7rem; }
.needs-you { border: 4px dashed var(--ink); border-radius: 8px; padding: 0.5rem 0.8rem; margin: 1rem 0; background: rgba(255, 253, 245, 0.35); }
.project { margin-top: 1.5rem; }
.board-white { background: #fff; border: 8px solid #d8d8d8; border-radius: 4px; padding: 0.5rem 1rem; margin: 0.8rem 0; }
.dir-doc { position: relative; padding-left: 3.4rem; margin: 0.4rem 0; }
.compass { position: absolute; left: 0; top: 0.2rem; width: 2.6rem; height: 2.6rem; border: 3px solid var(--ink); border-radius: 50%; display: grid; place-items: center; font-weight: bold; }
.goal { font-family: var(--font-hand), var(--font-body); font-size: 1.2rem; margin: 0.2rem 0; overflow-wrap: anywhere; }
.arrow-note { background: var(--sticky); display: inline-block; padding: 0.2rem 0.8rem; margin: 0.2rem 0; overflow-wrap: anywhere; }
.history { margin: 0.4rem 0; padding-left: 1.2rem; }
.andon-wrap { display: flex; gap: 1rem; flex-wrap: wrap; align-items: flex-start; margin: 0.8rem 0; }
.tower { background: #333; color: #fff; border-radius: 8px; padding: 0.5rem 0.8rem; display: flex; align-items: center; gap: 0.5rem; }
.lamp { width: 1.4rem; height: 1.4rem; border-radius: 50%; border: 2px solid #fff; background: #555; }
.lamp.red.on { background: #e03030; }
.lamp.green.on { background: #2fb85a; }
.lamp.on::after { content: ''; }
.tower[data-state='red'] .lamp.red { box-shadow: 0 0 0 3px #fff, 0 0 12px 4px #e03030; animation: swing 1.6s ease-in-out infinite alternate; }
@keyframes swing { from { opacity: 1; } to { opacity: 0.6; } }
.note { background: var(--sticky); color: var(--ink); padding: 0.5rem 0.7rem; margin: 0.5rem 0; box-shadow: 2px 3px 6px rgba(0, 0, 0, 0.35); display: block; overflow-wrap: anywhere; list-style: none; }
.note.open-andon { border: 3px solid var(--alert); max-width: 28rem; }
.note.blocked { background: #ffd2c9; }
.note.flagged { border: 3px solid var(--alert); }
.note summary { cursor: pointer; font-weight: bold; }
.note summary:focus-visible, .stack > summary:focus-visible, a:focus-visible { outline: 3px solid #0b3d91; outline-offset: 2px; }
.stamp { display: inline-block; border: 2px solid var(--alert); color: var(--alert); transform: rotate(-4deg); padding: 0 0.3rem; margin-right: 0.4rem; font-weight: bold; letter-spacing: 0.05em; }
.flag { display: inline-block; background: var(--alert); color: #fff; padding: 0 0.4rem; margin-right: 0.4rem; font-size: 0.75rem; font-weight: bold; text-transform: uppercase; }
.notes { list-style: none; padding: 0; display: flex; flex-wrap: wrap; gap: 0.6rem; }
.notes .note { max-width: 24rem; margin: 0; }
.line .cols { display: grid; grid-template-columns: repeat(auto-fit, minmax(13rem, 1fr)); gap: 0.8rem; align-items: start; }
.col { background: rgba(255, 253, 245, 0.35); padding: 0.4rem; border-radius: 6px; min-width: 0; }
.col.you { border: 4px solid var(--alert); background: rgba(255, 253, 245, 0.6); }
.col-head { margin: 0 0 0.3rem; background: var(--paper); padding: 0.1rem 0.4rem; font-size: 0.95rem; }
.stack > summary { cursor: pointer; background: var(--paper); padding: 0.3rem 0.6rem; font-weight: bold; }
.stack-body { max-height: 26rem; overflow-y: auto; }
.card-list { list-style: none; padding: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(15rem, 1fr)); gap: 0.6rem; max-height: 30rem; overflow-y: auto; margin: 0.4rem 0; }
.index-card { background: var(--paper); border: 1px solid #999; border-top: 4px solid #c33; padding: 0.5rem 0.7rem; display: flex; flex-direction: column; gap: 0.2rem; overflow-wrap: anywhere; }
.index-card.pinned { border-top-color: var(--alert); border: 2px dashed var(--alert); }
.tick { color: #0a5a2a; font-weight: bold; }
.pin { color: var(--alert); }
.slips { list-style: none; padding: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(14rem, 1fr)); gap: 0.6rem; max-height: 30rem; overflow-y: auto; }
.slip { background: var(--paper); padding: 0.5rem 0.7rem; display: flex; flex-direction: column; gap: 0.2rem; border-left: 6px dotted var(--ink); overflow-wrap: anywhere; }
.slip.waiting { border: 3px solid var(--alert); border-left-width: 8px; }
.source { font-size: 0.8rem; font-weight: bold; }
.rubber { align-self: flex-start; border: 2px solid #1a3f8a; color: #1a3f8a; padding: 0 0.4rem; font-weight: bold; text-transform: uppercase; transform: rotate(-2deg); }
.tag { display: inline-block; font-size: 0.78rem; border: 1px solid currentColor; border-radius: 999px; padding: 0 0.5rem; margin-right: 0.3rem; }
.meta { display: block; font-size: 0.85rem; margin: 0.2rem 0; }
.pf { background: var(--paper); color: var(--ink); }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
a { color: #0b3d91; }
@media (max-width: 40rem) {
  .wall { padding: 0.5rem; }
  .line .cols { grid-template-columns: 1fr; }
  .dir-doc { padding-left: 0; }
  .compass { position: static; margin-bottom: 0.3rem; }
}
@media (prefers-reduced-motion: reduce) {
  .tower .lamp, .tower[data-state='red'] .lamp.red { animation: none !important; }
}
</style>
