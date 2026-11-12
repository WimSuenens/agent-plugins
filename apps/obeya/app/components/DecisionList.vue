<script setup lang="ts">
import type { Decision } from '../../shared/types'
defineProps<{ decisions: Decision[] }>()
const label = (d: Decision) => (d.provenance.kind === 'in-flight' ? `in flight: ${d.provenance.item}` : d.provenance.kind)
</script>

<template>
  <section class="decisions" data-test="decisions" aria-label="Decisions made">
    <h3>Decisions made</h3>
    <p v-if="!decisions.length">No decisions recorded.</p>
    <ol>
      <li v-for="d in decisions" :key="d.id" data-test="decision">
        <a v-if="d.url" :href="d.url" data-test="decision-link">{{ d.title }}</a>
        <template v-else>{{ d.title }}</template>
        <code>{{ d.ref }}</code>
        <span class="status">{{ d.status }}</span>
        <span class="chip" data-test="provenance">{{ label(d) }}</span>
      </li>
    </ol>
  </section>
</template>

<style scoped>
ol { list-style: none; padding: 0; }
li { display: flex; flex-wrap: wrap; gap: 0.5rem; align-items: baseline; margin: 0.3rem 0; }
.status, .chip { font-size: 0.8rem; border: 1px solid currentColor; border-radius: 999px; padding: 0 0.6rem; }
</style>
