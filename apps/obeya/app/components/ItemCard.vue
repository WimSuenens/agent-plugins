<script setup lang="ts">
import type { Item } from '../../shared/types'
const props = defineProps<{ item: Item }>()
const effort = computed(() => (props.item.effort ? `#${props.item.effort.number}${props.item.effort.title ? ' ' + props.item.effort.title : ''}` : null))
const blocked = computed(() => props.item.factoryStatus === 'Blocked')
</script>

<template>
  <article class="item-card" data-test="item-card">
    <h4>
      <a v-if="item.url" :href="item.url" data-test="item-link">#{{ item.number }} {{ item.title }}</a>
      <template v-else>#{{ item.number }} {{ item.title }}</template>
    </h4>
    <p class="meta">
      <span v-if="item.kind" data-test="item-kind">{{ item.kind }}</span>
      <span v-if="item.role" data-test="item-role">{{ item.role }}</span>
      <span v-if="effort" data-test="item-effort">effort {{ effort }}</span>
    </p>
    <p v-if="item.blockedBy?.length" class="blocked" data-test="blocked-by">Blocked by {{ item.blockedBy.map((n) => '#' + n).join(', ') }}</p>
    <p v-else-if="blocked" class="blocked" data-test="blocked-by">Blocked: blocker not recorded on the board</p>
  </article>
</template>

<style scoped>
.item-card { border: 1px solid currentColor; border-radius: 6px; padding: 0.4rem 0.6rem; margin: 0.4rem 0; }
.item-card h4 { margin: 0; font-size: 0.95rem; overflow-wrap: anywhere; }
.meta { margin: 0.2rem 0; display: flex; gap: 0.5rem; flex-wrap: wrap; font-size: 0.8rem; }
.meta span { border: 1px solid currentColor; border-radius: 999px; padding: 0 0.5rem; }
.blocked { margin: 0.2rem 0; font-weight: bold; font-size: 0.85rem; }
</style>
