<script setup lang="ts">
import type { PageView } from '../../../shared/view'
import type { Decision, IntakeEntry, Provenance } from '../../../shared/types'

// The Wall: the physical Obeya room on screen. It only presents `view`; it fetches and computes nothing.
defineProps<{ view: PageView }>()

const FOLD_NOTES = 6
const FOLD_CARDS = 8
const EFFORT_COLOURS = 6

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
/** A small steady tilt per note so the wall looks hand-placed; the same note always leans the same way. */
const tilt = (n: number, k = 0) => (((n * 37 + k) % 7) - 3) * 0.7
/** One accent colour per effort. */
const effortClass = (e: { number: number } | null | undefined) => (e ? `eff-${e.number % EFFORT_COLOURS}` : 'eff-none')
const roleClass = (r: string | null) => (r ? `r-${r.toLowerCase().replace(/[^a-z0-9]+/g, '-')}` : 'r-none')
/** The last words of a long goal are marked with a highlighter; short goals are left whole. */
const goalParts = (g: string) => {
  const w = g.split(' ')
  return w.length > 5 ? { head: w.slice(0, -3).join(' ') + ' ', tail: w.slice(-3).join(' ') } : { head: g, tail: '' }
}
const isOpen = (p: { andon: { resolved: boolean }[] }) => p.andon.some((a) => !a.resolved)
</script>

<template>
  <div class="wall">
    <header class="sign">
      <h1 class="plank marker">Obeya</h1>
      <p class="postit" data-test="lens-badge">read-only lens &middot; bound to {{ view.bindAddress }}</p>
      <p class="postit b">{{ view.needsYou.length }} note{{ view.needsYou.length === 1 ? '' : 's' }} waiting on <b>you</b></p>
    </header>

    <section class="needs-you" data-test="needs-you" aria-labelledby="wall-needs-h">
      <h2 id="wall-needs-h" class="marker">Needs you</h2>
      <p v-if="!view.needsYou.length" class="paper">Nothing needs you right now.</p>
      <ol v-else class="notes">
        <li v-for="(e, k) in view.needsYou" :key="e.id" class="note flagged" :style="{ '--tilt': tilt(k, 5) + 'deg' }" :data-test="{ decision: 'pending-decision', idea: 'needs-you-idea', waiting: 'waiting-item' }[e.kind]">
          <i class="pin" aria-hidden="true"></i>
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
      <h2 v-if="p.state === 'ok'" class="marker project-name" data-test="project-name">{{ p.name }}</h2>
      <p v-else role="alert" class="paper" data-test="project-error">{{ p.id }}: {{ p.error }}</p>

      <div class="north-row">
        <!-- Where we are going: a whiteboard with a compass -->
        <section class="wb direction" data-test="direction" aria-label="Direction">
          <i class="tape tl" aria-hidden="true"></i><i class="tape tr" aria-hidden="true"></i>
          <h3 class="wb-h">Where we're going</h3>
          <p v-if="!p.directions.length && !p.parseFailures.some((f) => f.path === 'docs/direction.md')" data-test="direction-empty">
            No direction yet. Create <code>docs/direction.md</code> with <code>goal</code> and <code>current</code> in its front matter and a
            <code>## History</code> list of <code>- YYYY-MM-DD: what changed</code> lines; the product-owner keeps it up to date.
          </p>
          <article v-for="d in p.directions" :key="d.id" class="dir-doc">
            <div class="goalrow">
              <svg class="compass" viewBox="-75 -75 150 150" width="110" height="110" aria-hidden="true" focusable="false">
                <circle r="66" fill="#fff" stroke="#22303c" stroke-width="3" />
                <circle r="56" fill="none" stroke="#22303c" stroke-width="1.5" stroke-dasharray="3 5" />
                <path d="M0 -52 L9 0 L0 52 L-9 0Z" fill="none" stroke="#22303c" stroke-width="2" />
                <path d="M0 -52 L9 0 L-9 0Z" fill="#d63b2f" />
                <path d="M-52 0 L0 -7 L52 0 L0 7Z" fill="none" stroke="#22303c" stroke-width="1.5" />
                <text y="-56" text-anchor="middle" font-size="16" font-weight="700" fill="#22303c">N</text>
              </svg>
              <p class="goal"><strong class="sr-only">Goal: </strong><span data-test="direction-goal">{{ goalParts(d.goal).head }}<em v-if="goalParts(d.goal).tail">{{ goalParts(d.goal).tail }}</em></span></p>
            </div>
            <p class="arrow-note"><strong>Heading:</strong> <span data-test="direction-current">{{ d.current }}</span></p>
            <ol aria-label="History" class="history">
              <li v-for="h in d.history" :key="h.date + h.change" data-test="direction-history-entry"><time :datetime="h.date">{{ h.date }}</time> {{ h.change }}</li>
            </ol>
            <p class="meta"><code data-test="direction-source">{{ d.ref }}</code> <span class="tag" data-test="provenance">{{ from(d.provenance) }}</span></p>
          </article>
        </section>

        <!-- Andon: a light tower on a pole next to the notes -->
        <section class="wb andon-wrap" data-test="andon" aria-label="Andon">
          <i class="tape tl" aria-hidden="true"></i>
          <div class="tower-col">
            <h3 class="wb-h">Andon</h3>
            <div class="tower" data-test="andon-light" :data-state="isOpen(p) ? 'red' : 'green'">
              <span class="lamp red" :class="{ on: isOpen(p) }" aria-hidden="true"></span>
              <span class="lamp amber" aria-hidden="true"></span>
              <span class="lamp green" :class="{ on: !isOpen(p) }" aria-hidden="true"></span>
              <span class="pole" aria-hidden="true"></span>
              <span class="base-plate" aria-hidden="true"></span>
              <span class="cord" aria-hidden="true"></span>
              <span class="tower-text">{{ isOpen(p) ? 'Andon: line stopped' : 'Andon: line running' }}</span>
            </div>
          </div>
          <div class="andon-notes">
            <article v-for="(a, k) in p.andon" :key="a.id" class="note" :style="{ '--tilt': (a.resolved ? -1.2 : 1) + k * 0.4 + 'deg' }" :class="a.resolved ? 'done-note' : 'open-andon'" :role="a.resolved ? undefined : 'alert'" :data-test="a.resolved ? 'andon-resolved' : 'andon-open'">
              <strong v-if="!a.resolved">Line stopped: {{ a.reason }}</strong>
              <span v-else>&#10003; Resolved: {{ a.reason }}</span>
              <span class="meta">{{ a.item === null ? 'no item' : `item #${a.item}` }}, owner {{ a.owner ?? 'unknown' }}<template v-if="a.since">, since {{ a.since }}</template></span>
              <span v-if="a.resolved" class="meta">Countermeasure: {{ a.countermeasure }}</span>
              <code>{{ a.ref }}</code>
              <span class="tag" data-test="provenance">{{ from(a.provenance) }}</span>
            </article>
            <p v-if="!p.andon.length" class="meta">No andon pulled.</p>
            <ParseFailureCard v-for="f in p.parseFailures" :key="f.path" :failure="f" class="pf" />
          </div>
        </section>
      </div>

      <!-- Factory line -->
      <section class="wb line" data-test="board" aria-label="Factory board">
        <i class="tape tl" aria-hidden="true"></i><i class="tape tr" aria-hidden="true"></i>
        <h3 class="wb-h">Factory line <small>read left to right</small></h3>
        <div class="cols">
          <div v-for="c in p.board" :key="c.status" class="col" :class="{ you: c.status === 'Waiting on you', done: c.status === 'Done' }" :data-column="c.status">
            <h4 class="col-head">{{ c.status }} ({{ c.items.length }})<span v-if="c.status === 'Waiting on you'" class="flag">needs you</span></h4>
            <component :is="c.status === 'Done' && c.items.length > FOLD_NOTES ? 'details' : 'div'" class="stack" :data-test="c.status === 'Done' && c.items.length > FOLD_NOTES ? 'done-stack' : undefined">
              <summary v-if="c.status === 'Done' && c.items.length > FOLD_NOTES">{{ c.items.length }} finished notes folded into a stack</summary>
              <div class="stack-body">
                <details v-for="i in c.items" :key="i.id" class="note card-note" :class="[roleClass(i.role), effortClass(i.effort), { blocked: i.factoryStatus === 'Blocked', flagged: c.status === 'Waiting on you' }]" :style="{ '--tilt': tilt(i.number) + 'deg' }" data-test="item-card">
                  <summary>
                    <i class="pin" aria-hidden="true"></i>
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

      <div class="lower">
        <!-- Decisions: index cards on a cork board -->
        <section class="cork cards" data-test="decisions" aria-label="Decisions made">
          <h3 class="cork-h">Decisions <small>pinned for everyone to see</small></h3>
          <p v-if="!p.decisions.length" class="paper">No decisions recorded.</p>
          <component :is="p.decisions.length > FOLD_CARDS ? 'details' : 'div'" :data-test="p.decisions.length > FOLD_CARDS ? 'adr-stack' : undefined" class="stack">
            <summary v-if="p.decisions.length > FOLD_CARDS">{{ p.decisions.length }} decisions in the card box</summary>
            <ol class="card-list">
              <li v-for="(d, k) in p.decisions" :key="d.id" class="index-card" :style="{ '--tilt': tilt(k, 3) * 0.6 + 'deg' }" data-test="decision">
                <span class="tick" aria-hidden="true">&#10003;</span><span class="sr-only">Decided: </span>
                <a v-if="d.url" :href="d.url" data-test="decision-link">{{ decisionLabel(d) }}</a>
                <template v-else>{{ decisionLabel(d) }}</template>
                <code>{{ d.ref }}</code>
                <span class="tag" data-test="provenance">{{ from(d.provenance) }}</span>
              </li>
            </ol>
          </component>
          <ol v-if="p.pendingDecisions.length" class="card-list pending" aria-label="Pending decisions">
            <li v-for="(d, k) in p.pendingDecisions" :key="d.id" class="index-card pinned" :style="{ '--tilt': tilt(k, 9) + 'deg' }" data-test="pinned-decision">
              <i class="pin" aria-hidden="true"></i>
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
          <h3 class="tray-h">Inbox <small>the intake tray</small></h3>
          <p v-if="!p.intake.length" class="paper">No ideas have come in.</p>
          <ul v-else class="slips">
            <li v-for="(e, k) in p.intake" :key="e.id" class="slip" :class="{ waiting: e.waitingOnHuman }" :style="{ '--tilt': (k % 2 ? 0.8 : -0.7) + 'deg' }" :data-waiting="e.waitingOnHuman || undefined" :data-test="e.waitingOnHuman ? 'intake-waiting' : 'intake-entry'">
              <span class="source" data-test="intake-channel"><span aria-hidden="true">{{ channelMark[e.channel] }}</span> {{ channels[e.channel] }}</span>
              <strong data-test="intake-title">{{ e.title }}</strong>
              <span class="rubber" data-test="intake-outcome">{{ outcomeLabel(e) }}</span>
              <span class="tag" data-test="provenance">{{ from(e.provenance) }}</span>
              <span v-if="e.reason" class="meta" data-test="intake-reason">{{ e.reason }}</span>
            </li>
          </ul>
        </section>
      </div>
    </section>
  </div>
</template>

<style scoped>
.wall {
  --ink: #22303c;
  --paper: #fffdf5;
  --sticky: #ffe97a;
  --alert: #8a1010;
  --blue: #2a63b8;
  --font-hand: 'Segoe Print', 'Bradley Hand', 'Marker Felt', 'Chalkboard SE', 'Comic Sans MS', cursive;
  --font-type: 'American Typewriter', 'Courier New', Courier, monospace;
  --font-body: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
  box-sizing: border-box;
  width: 100%;
  min-height: 100dvh;
  background-color: #c79d6d;
  background-image:
    radial-gradient(rgba(94, 58, 26, 0.38) 1px, transparent 1.6px),
    radial-gradient(rgba(255, 238, 205, 0.3) 1px, transparent 1.6px),
    radial-gradient(1400px 800px at 50% 0%, rgba(255, 244, 214, 0.35), transparent 70%),
    radial-gradient(1400px 900px at 50% 120%, rgba(60, 30, 8, 0.4), transparent 70%);
  background-size: 7px 7px, 11px 11px, auto, auto;
  background-position: 0 0, 3px 4px, 0 0, 0 0;
  color: var(--ink);
  font-family: var(--font-body);
  line-height: 1.45;
  padding: 1.2rem 1.6rem 4rem;
}
.wall > *, .project > * { max-width: 94rem; margin-left: auto; margin-right: auto; }
.marker, .wb-h, .cork-h, .tray-h { font-family: var(--font-hand); letter-spacing: 0.02em; }
.marker { background: var(--paper); display: inline-block; padding: 0.1rem 0.8rem; margin: 0.4rem 0; border-radius: 3px; color: var(--ink); box-shadow: 1px 2px 4px rgba(0, 0, 0, 0.25); }

/* The wooden nameplate and the sticky notes beside it */
.sign { display: flex; align-items: center; gap: 1.1rem; flex-wrap: wrap; margin-bottom: 1.2rem; padding-right: 3rem; }
.plank { margin: 0; font-family: var(--font-hand); font-size: 1.9rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.12em; background: linear-gradient(#7a4f2a, #5e3a1c); color: #ffe9c4; padding: 0.35rem 1.6rem; border-radius: 6px; border: 2px solid #4a2c14; box-shadow: 0 5px 0 #3e2511, 0 10px 18px rgba(0, 0, 0, 0.35); transform: rotate(-1deg); }
.postit { margin: 0; padding: 0.5rem 0.8rem; background: #fff59a; box-shadow: 2px 4px 8px rgba(0, 0, 0, 0.28); transform: rotate(1.6deg); font-family: var(--font-hand); font-size: 0.95rem; line-height: 1.2; }
.postit.b { background: #bfe3ff; transform: rotate(-1.2deg); }

.paper { background: var(--paper); display: inline-block; padding: 0.3rem 0.7rem; box-shadow: 1px 2px 4px rgba(0, 0, 0, 0.2); }
.needs-you { border: 4px dashed rgba(34, 48, 60, 0.7); border-radius: 8px; padding: 0.5rem 1rem 0.8rem; margin: 1rem auto; background: rgba(255, 253, 245, 0.3); }
.project { margin-top: 1.6rem; }
.project-name { font-size: 1.5rem; }

/* Whiteboards held up with masking tape */
.wb { position: relative; background: linear-gradient(135deg, #fdfdfa, #eef0ec); border: 11px solid #b4bac3; border-radius: 6px; box-shadow: 0 0 0 2px #8d939c, inset 0 0 28px rgba(0, 0, 0, 0.08), 0 14px 24px rgba(0, 0, 0, 0.35); padding: 1rem 1.3rem 1.3rem; margin-bottom: 1.6rem; min-width: 0; }
.wb-h { margin: 0 0 0.5rem; font-size: 1.45rem; font-weight: 700; color: var(--blue); }
.wb-h small, .cork-h small, .tray-h small { font-size: 0.9rem; font-weight: 400; margin-left: 0.5rem; color: #6c7a88; }
.tape { position: absolute; width: 86px; height: 24px; background: rgba(255, 239, 160, 0.72); box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2); z-index: 2; }
.tape.tl { left: -30px; top: -6px; transform: rotate(-38deg); }
.tape.tr { right: -30px; top: -6px; transform: rotate(38deg); }
.north-row { display: grid; grid-template-columns: minmax(0, 7fr) minmax(0, 5fr); gap: 1.6rem; align-items: stretch; }

/* Direction */
.dir-doc { margin: 0.2rem 0; }
.goalrow { display: flex; gap: 1.2rem; align-items: center; }
.compass { flex: none; }
.goal { font-family: var(--font-hand); font-size: clamp(1.4rem, 2.6vw, 2.1rem); line-height: 1.15; margin: 0.2rem 0; color: #162330; overflow-wrap: anywhere; }
.goal em { font-style: normal; background: linear-gradient(transparent 55%, rgba(255, 224, 60, 0.8) 55%); }
.arrow-note { position: relative; display: inline-block; background: var(--sticky); padding: 0.5rem 2.6rem 0.5rem 1rem; margin: 0.8rem 0 0.2rem; font-family: var(--font-hand); font-size: 1.1rem; line-height: 1.2; clip-path: polygon(0 0, calc(100% - 28px) 0, 100% 50%, calc(100% - 28px) 100%, 0 100%); box-shadow: 2px 3px 6px rgba(0, 0, 0, 0.2); overflow-wrap: anywhere; }
.history { list-style: none; display: flex; flex-wrap: wrap; gap: 0.9rem; margin: 1rem 0 0.3rem; padding: 0; color: #4a5866; font-size: 0.9rem; }
.history li { flex: 1 1 9rem; border-top: 3px solid #4a5866; padding-top: 0.25rem; position: relative; overflow-wrap: anywhere; }
.history li::before { content: ''; position: absolute; top: -8px; left: -2px; width: 12px; height: 12px; border-radius: 50%; background: #d63b2f; }
.history time { display: block; font-weight: 700; color: var(--ink); }

/* Andon: a three-lamp tower on a pole */
.andon-wrap { display: grid; grid-template-columns: 9.5rem minmax(0, 1fr); gap: 0.8rem; }
.tower { position: relative; width: 6.5rem; margin: 0 auto; padding-top: 0.2rem; display: flex; flex-direction: column; align-items: center; }
.lamp { display: block; width: 4.4rem; height: 3.3rem; margin-bottom: 0.25rem; border-radius: 12px 12px 6px 6px; border: 3px solid #333; background: #3a3a3a; }
.lamp.red.on { background: radial-gradient(circle at 50% 40%, #ff9a8c, #e0261b 60%); box-shadow: 0 0 26px 7px rgba(255, 60, 40, 0.65); animation: lamp-red 1s ease-in-out infinite; }
.lamp.green.on { background: radial-gradient(circle at 50% 40%, #b9ffc9, #22b54e 60%); box-shadow: 0 0 22px 5px rgba(60, 220, 110, 0.55); }
.lamp.amber { background: #5b4a1d; }
@keyframes lamp-red { 50% { box-shadow: 0 0 8px 2px rgba(255, 60, 40, 0.4); filter: brightness(0.8); } }
.pole { display: block; width: 14px; height: 4.5rem; background: linear-gradient(90deg, #666, #bbb, #666); }
.base-plate { display: block; width: 5rem; height: 12px; background: #444; border-radius: 4px; }
.cord { position: absolute; right: 0.2rem; top: 3rem; width: 3px; height: 6rem; background: #2b2b2b; transform-origin: top center; animation: swing 4s ease-in-out infinite; }
.cord::after { content: 'ANDON'; position: absolute; left: -22px; bottom: -22px; font: 700 0.65rem/1 var(--font-body); background: #ffd400; color: #222; padding: 3px 5px; border-radius: 3px; border: 2px solid #222; }
@keyframes swing { 50% { transform: rotate(4deg); } }
.tower-text { margin-top: 1.6rem; font-weight: 700; font-size: 0.8rem; text-align: center; }
.andon-notes { padding-top: 0.2rem; min-width: 0; }

/* Notes */
.note { position: relative; display: block; list-style: none; background: var(--sticky); color: var(--ink); padding: 0.9rem 0.8rem 0.6rem; margin: 0.6rem 0; box-shadow: 2px 4px 8px rgba(0, 0, 0, 0.28); overflow-wrap: anywhere; transform: rotate(var(--tilt, 0deg)); transition: transform 0.18s, box-shadow 0.18s; }
.note:hover { transform: rotate(0deg) scale(1.03); z-index: 3; box-shadow: 4px 8px 16px rgba(0, 0, 0, 0.34); }
.note.open-andon { background: #ff9d92; border: 0; max-width: 28rem; font-family: var(--font-hand); }
.note.done-note { background: #c7f2cf; }
.note.blocked { filter: saturate(0.6); background: #f3d2c9; }
.note.flagged { outline: 3px solid var(--alert); outline-offset: -3px; }
.card-note { border-top: 6px solid var(--accent, #bbb); }
.card-note summary { cursor: pointer; font-family: var(--font-hand); font-weight: 700; list-style-position: inside; }
.note.r-developer { background: #ffe97a; } .note.r-qa-engineer { background: #ffb3c7; } .note.r-architect { background: #a9d3ff; }
.note.r-devops { background: #b5f0b9; } .note.r-lead { background: #ffc78a; } .note.r-none { background: #f6f2e4; background-image: repeating-linear-gradient(transparent 0 21px, rgba(60, 110, 200, 0.25) 21px 22px); }
.note.blocked.r-developer, .note.blocked.r-qa-engineer, .note.blocked.r-architect, .note.blocked.r-devops, .note.blocked.r-lead { background-color: #f3d2c9; }
.eff-0 { --accent: #d63b2f; } .eff-1 { --accent: #2a63b8; } .eff-2 { --accent: #2e8a52; } .eff-3 { --accent: #8a46b8; } .eff-4 { --accent: #d98a12; } .eff-5 { --accent: #1f9aa8; } .eff-none { --accent: #9a9484; }
.pin { position: absolute; left: 50%; top: -6px; width: 14px; height: 14px; border-radius: 50%; background: radial-gradient(circle at 35% 30%, #ff8a80, #c4281c); box-shadow: 1px 3px 3px rgba(0, 0, 0, 0.4); }
.note summary:focus-visible, .stack > summary:focus-visible, a:focus-visible { outline: 3px solid #0b3d91; outline-offset: 2px; }
.stamp { display: inline-block; border: 2px solid var(--alert); color: var(--alert); transform: rotate(-4deg); padding: 0 0.3rem; margin-right: 0.4rem; font-weight: bold; letter-spacing: 0.05em; mix-blend-mode: multiply; }
.flag { display: inline-block; background: var(--alert); color: #fff; padding: 0 0.4rem; margin-right: 0.4rem; font-size: 0.75rem; font-weight: bold; text-transform: uppercase; }
.notes { list-style: none; padding: 0; display: flex; flex-wrap: wrap; gap: 0.8rem; }
.notes .note { max-width: 24rem; margin: 0.4rem 0; }

/* The line */
.cols { display: grid; grid-template-columns: repeat(auto-fit, minmax(13rem, 1fr)); gap: 0; align-items: start; }
.col { border-left: 3px dashed rgba(34, 48, 60, 0.35); padding: 0.2rem 0.7rem 0.8rem; min-width: 0; min-height: 10rem; }
.col:first-child { border-left: 0; }
.col.you { background: repeating-linear-gradient(135deg, rgba(214, 59, 47, 0.06) 0 10px, transparent 10px 20px); outline: 4px solid rgba(214, 59, 47, 0.65); outline-offset: -4px; border-radius: 6px; }
.col.done { opacity: 0.8; }
.col-head { margin: 0 0 0.6rem; font-family: var(--font-hand); font-size: 1.05rem; }
.col.you .col-head { color: var(--alert); }
.stack > summary { cursor: pointer; background: var(--paper); padding: 0.3rem 0.6rem; font-weight: bold; box-shadow: 1px 2px 4px rgba(0, 0, 0, 0.2); }
.stack-body { max-height: 28rem; overflow-y: auto; padding: 0.4rem 0.3rem; }

/* Decisions on cork, intake in a tray */
.lower { display: grid; grid-template-columns: minmax(0, 7fr) minmax(0, 5fr); gap: 1.6rem; align-items: start; }
.cork { background: rgba(120, 78, 34, 0.35); border: 8px solid #7a4f2a; border-radius: 6px; box-shadow: inset 0 0 24px rgba(0, 0, 0, 0.35), 0 14px 22px rgba(0, 0, 0, 0.3); padding: 1rem 1.1rem 1.2rem; min-width: 0; }
.cork-h { margin: 0 0 0.6rem; font-size: 1.4rem; color: #fff3d2; text-shadow: 1px 2px 0 rgba(0, 0, 0, 0.45); }
.cork-h small { color: #f3dcb0; }
.card-list { list-style: none; padding: 0; display: grid; grid-template-columns: repeat(auto-fill, minmax(14rem, 1fr)); gap: 0.8rem; max-height: 30rem; overflow-y: auto; margin: 0.4rem 0; padding: 0.4rem; }
.index-card { position: relative; background: var(--paper) repeating-linear-gradient(transparent 0 20px, rgba(60, 110, 200, 0.2) 20px 21px); border-top: 4px solid #d96b6b; padding: 0.5rem 0.7rem; display: flex; flex-direction: column; gap: 0.2rem; overflow-wrap: anywhere; box-shadow: 1px 3px 6px rgba(0, 0, 0, 0.32); font-family: var(--font-type); font-size: 0.85rem; transform: rotate(var(--tilt, 0deg)); }
.index-card.pinned { border-top-color: var(--alert); padding-top: 0.9rem; font-family: var(--font-body); }
.tick { color: #0a5a2a; font-weight: bold; }
.tray { background: linear-gradient(#e9dfc9, #d9ccb0); border: 8px solid #8a6a3d; border-radius: 4px 4px 14px 14px; box-shadow: inset 0 10px 18px rgba(0, 0, 0, 0.25), 0 14px 22px rgba(0, 0, 0, 0.3); padding: 1rem 1rem 1.2rem; min-width: 0; }
.tray-h { margin: 0 0 0.6rem; font-size: 1.4rem; color: #5b3f1c; }
.slips { list-style: none; padding: 0.3rem; margin: 0; display: grid; gap: 0.7rem; max-height: 30rem; overflow-y: auto; }
.slip { background: #fff; padding: 0.5rem 0.7rem; display: flex; flex-direction: column; gap: 0.2rem; box-shadow: 1px 3px 6px rgba(0, 0, 0, 0.28); overflow-wrap: anywhere; transform: rotate(var(--tilt, 0deg)); }
.slip.waiting { outline: 3px solid var(--alert); outline-offset: -3px; }
.source { font-size: 0.8rem; font-weight: bold; }
.rubber { align-self: flex-start; border: 2px solid #1a3f8a; color: #1a3f8a; padding: 0 0.4rem; font-weight: bold; text-transform: uppercase; transform: rotate(-4deg); mix-blend-mode: multiply; }
.tag { display: inline-block; font-size: 0.78rem; border: 1px solid currentColor; border-radius: 999px; padding: 0 0.5rem; margin-right: 0.3rem; }
.meta { display: block; font-size: 0.85rem; margin: 0.2rem 0; }
.pf { background: #f7f0dd; color: #5a4a2a; margin-top: 0.9rem; transform: rotate(-1deg); border-radius: 0; border-width: 0; clip-path: polygon(0 0, 100% 0, 100% 90%, 94% 100%, 88% 92%, 80% 100%, 70% 91%, 61% 100%, 52% 92%, 44% 100%, 34% 92%, 24% 100%, 14% 92%, 6% 100%, 0 92%); padding-bottom: 1rem; }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
a { color: #0b3d91; }

@media (max-width: 68rem) {
  .north-row, .lower { grid-template-columns: 1fr; }
}
@media (max-width: 40rem) {
  .wall { padding: 0.8rem 0.9rem 3rem; }
  .cols { grid-template-columns: 1fr; }
  .col { border-left: 0; border-top: 3px dashed rgba(34, 48, 60, 0.35); }
  .goalrow { flex-direction: column; align-items: flex-start; }
  .andon-wrap { grid-template-columns: 1fr; }
  .plank { font-size: 1.4rem; }
  .tape.tl { left: -12px; }
  .tape.tr { right: -12px; }
  .wall { overflow-x: clip; }
}
@media (prefers-reduced-motion: reduce) {
  .lamp, .cord, .note { animation: none !important; transition: none !important; }
}
</style>
