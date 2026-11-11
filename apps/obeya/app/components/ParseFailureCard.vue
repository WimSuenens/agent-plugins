<script setup lang="ts">
import type { ParseFailure } from '../../shared/types'
const props = defineProps<{ failure: ParseFailure }>()
const label = computed(() => {
  const p = props.failure.provenance
  return p.kind === 'in-flight' ? `in flight: ${p.item}` : p.kind
})
</script>

<template>
  <article class="parse-failure" data-test="parse-failure" role="group" :aria-label="`Could not read ${failure.path}`">
    <p class="pf-path" data-test="pf-path"><code>{{ failure.path }}</code></p>
    <p class="pf-reason" data-test="pf-reason">{{ failure.reason }}</p>
    <span class="pf-chip" data-test="provenance">{{ label }}</span>
  </article>
</template>

<style scoped>
.parse-failure { border: 1px solid currentColor; border-left-width: 6px; border-radius: 6px; padding: 0.6rem 0.8rem; margin: 0.5rem 0; }
.parse-failure p { margin: 0.2rem 0; overflow-wrap: anywhere; }
.pf-chip { display: inline-block; font-size: 0.8rem; border: 1px solid currentColor; border-radius: 999px; padding: 0 0.6rem; }
</style>
