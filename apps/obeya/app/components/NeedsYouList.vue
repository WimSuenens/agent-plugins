<script setup lang="ts">
import type { NeedsYouEntry } from '../../shared/view'
defineProps<{ entries: NeedsYouEntry[] }>()

const waited = (s: number | null) => {
  if (s === null) return 'waiting time unknown'
  if (s < 3600) return `waiting ${Math.floor(s / 60)} min`
  if (s < 86400) return `waiting ${Math.floor(s / 3600)} h`
  return `waiting ${Math.floor(s / 86400)} d`
}
const from = (p: { kind: string; item?: string }) => (p.kind === 'in-flight' ? `in flight: ${p.item}` : p.kind)
</script>

<template>
  <ol class="needs-list">
    <li v-for="e in entries" :key="e.id" :data-test="e.kind === 'decision' ? 'pending-decision' : 'waiting-item'">
      <strong>{{ e.title }}</strong>
      <span class="chip" data-test="waited">{{ waited(e.waitingSeconds) }}</span>
      <template v-if="e.decision">
        <span class="chip" data-test="door">{{ e.decision.door }} door</span>
        <span class="chip" data-test="provenance">{{ from(e.decision.provenance) }}</span>
        <p class="meta">Asked of {{ e.decision.askedOf }}. Options: {{ e.decision.options.join(' / ') }}.</p>
      </template>
      <template v-else><span class="chip">waiting on you</span></template>
      <p class="meta"><a v-if="e.ref.startsWith('http')" :href="e.ref">{{ e.ref }}</a><code v-else>{{ e.ref }}</code></p>
    </li>
  </ol>
</template>

<style scoped>
.needs-list { padding-left: 1.2rem; }
.chip { display: inline-block; margin-left: 0.4rem; font-size: 0.8rem; border: 1px solid currentColor; border-radius: 999px; padding: 0 0.6rem; }
.meta { margin: 0.1rem 0 0.6rem; overflow-wrap: anywhere; }
</style>
