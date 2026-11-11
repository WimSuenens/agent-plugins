<script setup lang="ts">
import type { Andon } from '../../shared/types'
const props = defineProps<{ andon: Andon[] }>()
const open = computed(() => props.andon.filter((a) => !a.resolved))
const resolved = computed(() => props.andon.filter((a) => a.resolved))
const who = (a: Andon) => `${a.item === null ? 'no item' : `item #${a.item}`}, owner ${a.owner ?? 'unknown'}`
</script>

<template>
  <section v-if="andon.length" class="andon" data-test="andon" aria-label="Andon">
    <h3>Andon</h3>
    <article v-for="a in open" :key="a.id" class="open" role="alert" data-test="andon-open">
      <strong>Line stopped: {{ a.reason }}</strong>
      <p>{{ who(a) }}<template v-if="a.since">, since {{ a.since }}</template></p>
      <code>{{ a.ref }}</code>
    </article>
    <article v-for="a in resolved" :key="a.id" class="done" data-test="andon-resolved">
      <span>Resolved: {{ a.reason }}</span>
      <p>{{ who(a) }}. Countermeasure: {{ a.countermeasure }}</p>
      <code>{{ a.ref }}</code>
    </article>
  </section>
</template>

<style scoped>
.andon article { border: 1px solid currentColor; border-left-width: 6px; border-radius: 6px; padding: 0.6rem 0.8rem; margin: 0.5rem 0; overflow-wrap: anywhere; }
.andon .open { border-width: 3px; border-left-width: 10px; }
.andon p { margin: 0.2rem 0; }
</style>
