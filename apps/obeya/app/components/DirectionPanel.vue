<script setup lang="ts">
import type { Direction, ParseFailure } from '../../shared/types'
const props = defineProps<{ directions: Direction[]; parseFailures: ParseFailure[] }>()
// Missing document: no direction and no parse failure for it. A malformed one is shown by its parse-failure card instead.
const empty = computed(() => !props.directions.length && !props.parseFailures.some((f) => f.path === 'docs/direction.md'))
const label = (d: Direction) => (d.provenance.kind === 'in-flight' ? `in flight: ${d.provenance.item}` : d.provenance.kind)
</script>

<template>
  <section class="direction" data-test="direction" aria-label="Direction">
    <h3>Direction</h3>
    <p v-if="empty" data-test="direction-empty">
      No direction yet. Create <code>docs/direction.md</code> with <code>goal</code> and <code>current</code> in its front matter and a
      <code>## History</code> list of <code>- YYYY-MM-DD: what changed</code> lines; the product-owner keeps it up to date.
    </p>
    <article v-for="d in directions" :key="d.id" class="direction-doc">
      <p><strong>Goal</strong> <span data-test="direction-goal">{{ d.goal }}</span></p>
      <p><strong>Heading</strong> <span data-test="direction-current">{{ d.current }}</span></p>
      <ol class="direction-history" aria-label="History">
        <li v-for="h in d.history" :key="h.date + h.change" data-test="direction-history-entry"><time :datetime="h.date">{{ h.date }}</time> {{ h.change }}</li>
      </ol>
      <p class="direction-meta">
        <code data-test="direction-source">{{ d.ref }}</code>
        <span class="direction-chip" data-test="provenance">{{ label(d) }}</span>
      </p>
    </article>
  </section>
</template>

<style scoped>
.direction { margin: 1rem 0; }
.direction-doc { border: 1px solid currentColor; border-radius: 6px; padding: 0.6rem 0.8rem; margin: 0.5rem 0; }
.direction-doc p { margin: 0.2rem 0; overflow-wrap: anywhere; }
.direction-history { margin: 0.4rem 0; padding-left: 1.2rem; }
.direction-chip { display: inline-block; font-size: 0.8rem; border: 1px solid currentColor; border-radius: 999px; padding: 0 0.6rem; margin-left: 0.4rem; }
</style>
