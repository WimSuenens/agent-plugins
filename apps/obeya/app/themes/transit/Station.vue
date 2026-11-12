<script setup lang="ts">
import type { Station } from './layout'
defineProps<{ station: Station; colour: string; selected: boolean }>()
const emit = defineEmits<{ pick: [id: string]; peek: [id: string | null] }>()
</script>

<template>
  <g
    class="st"
    :class="{ sel: selected, flight: station.provenance.startsWith('in flight') }"
    role="button"
    tabindex="0"
    :data-station="station.id"
    :data-station-kind="station.kind"
    :data-status="station.status"
    :aria-pressed="selected ? 'true' : 'false'"
    :aria-label="`${station.title}. ${station.detail}. Provenance: ${station.provenance}`"
    @click="emit('pick', station.id)"
    @keydown.enter.prevent="emit('pick', station.id)"
    @keydown.space.prevent="emit('pick', station.id)"
    @mouseenter="emit('peek', station.id)"
    @mouseleave="emit('peek', null)"
    @focus="emit('peek', station.id)"
    @blur="emit('peek', null)"
  >
    <title>{{ station.title }} ({{ station.provenance }})</title>
    <circle class="halo" :cx="station.x" :cy="station.y" r="17" />
    <circle v-if="station.provenance.startsWith('in flight')" class="flightring" :cx="station.x" :cy="station.y" r="14" />
    <template v-if="station.kind === 'aggregate'">
      <rect :x="station.x - 17" :y="station.y - 10" width="34" height="20" rx="10" fill="#fff" :stroke="colour" stroke-width="3" />
      <text class="agg" :x="station.x" :y="station.y + 4">{{ station.label }}</text>
    </template>
    <template v-else-if="station.kind === 'pending'">
      <circle :cx="station.x" :cy="station.y" r="9" fill="#fff" stroke="#1c1c1c" stroke-width="3.5" stroke-dasharray="4 3" />
      <circle class="badge" :cx="station.x + 11" :cy="station.y - 11" r="8" fill="#b34700" stroke="#fff" stroke-width="1.5" />
      <text class="bang" :x="station.x + 11" :y="station.y - 7">!</text>
    </template>
    <template v-else-if="station.kind === 'decision'">
      <circle :cx="station.x" :cy="station.y" r="7" fill="#fff" stroke="#1c1c1c" stroke-width="3.5" />
    </template>
    <template v-else-if="station.kind === 'idea'">
      <circle :cx="station.x" :cy="station.y" r="6" :fill="station.status === 'waiting' ? '#b34700' : '#fff'" stroke="#0a7a41" stroke-width="3" />
    </template>
    <template v-else>
      <circle v-if="station.status === 'running'" class="pulse" :cx="station.x" :cy="station.y" r="10" fill="none" :stroke="colour" stroke-width="3" />
      <template v-if="station.status === 'done'">
        <circle :cx="station.x" :cy="station.y" r="9" :fill="colour" stroke="#1c1c1c" stroke-width="3" />
        <path :d="`M${station.x - 4} ${station.y} l3 3.5 l5.5 -7`" stroke="#fff" stroke-width="2.2" fill="none" />
      </template>
      <template v-else-if="station.status === 'blocked'">
        <circle :cx="station.x" :cy="station.y" r="9" fill="#1c1c1c" stroke="#1c1c1c" stroke-width="3" />
        <path :d="`M${station.x - 4} ${station.y - 4} l8 8 M${station.x + 4} ${station.y - 4} l-8 8`" stroke="#fff" stroke-width="2.2" />
      </template>
      <circle v-else-if="station.status === 'backlog'" :cx="station.x" :cy="station.y" r="6" fill="#f4efe3" stroke="#6f6a5c" stroke-width="3" />
      <template v-else>
        <circle :cx="station.x" :cy="station.y" r="9" fill="#fff" stroke="#1c1c1c" stroke-width="4" />
        <circle v-if="station.status === 'running'" :cx="station.x" :cy="station.y" r="4" :fill="colour" />
      </template>
      <template v-if="station.status === 'waiting'">
        <circle class="badge" :cx="station.x + 11" :cy="station.y - 11" r="8" fill="#b34700" stroke="#fff" stroke-width="1.5" />
        <text class="bang" :x="station.x + 11" :y="station.y - 7">!</text>
      </template>
    </template>
    <text v-if="station.kind !== 'aggregate' && station.label" class="lbl" :x="station.x" :y="station.y + 27">{{ station.label }}</text>
  </g>
</template>

<style scoped>
.st { cursor: pointer; outline: none; }
.halo { fill: none; stroke: #1c1c1c; stroke-width: 2; stroke-dasharray: 2 3; opacity: 0; }
.st:hover .halo, .st.sel .halo { opacity: 1; }
.st:focus-visible .halo { opacity: 1; stroke-width: 3; stroke-dasharray: none; stroke: #0a3d99; }
.flightring { fill: none; stroke: #1c1c1c; stroke-width: 1.5; stroke-dasharray: 3 2; }
.lbl { font-size: 10px; font-weight: 700; fill: #1c1c1c; text-anchor: middle; }
.agg { font-size: 11px; font-weight: 800; fill: #1c1c1c; text-anchor: middle; }
.bang { font-size: 11px; font-weight: 800; fill: #fff; text-anchor: middle; }
@media (prefers-reduced-motion: no-preference) {
  .pulse { transform-box: fill-box; transform-origin: center; animation: ring 1.8s ease-out infinite; }
  @keyframes ring { 0% { transform: scale(0.8); opacity: 0.9; } 100% { transform: scale(2); opacity: 0; } }
}
</style>
