<script setup lang="ts">
import type { IntakeEntry } from '../../shared/types'
// The needs-you slot's entries are tagged by kind; this renders the ideas waiting on a human and ignores the rest.
const props = defineProps<{ items: unknown[] }>()
const ideas = computed(() => props.items.filter((i): i is { kind: 'idea'; entry: IntakeEntry } => (i as { kind?: string })?.kind === 'idea'))
</script>

<template>
  <ul v-if="ideas.length" class="needs-ideas">
    <li v-for="i in ideas" :key="i.entry.id" data-test="needs-you-idea">Idea waiting for you: {{ i.entry.title }}</li>
  </ul>
</template>
