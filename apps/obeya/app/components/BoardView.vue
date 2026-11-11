<script setup lang="ts">
import type { BoardColumn } from '../../shared/view'
defineProps<{ board: BoardColumn[] }>()
</script>

<template>
  <section class="board" data-test="board" aria-label="Factory board">
    <h3>Board</h3>
    <div class="cols">
      <div v-for="c in board" :key="c.status" class="col" :data-column="c.status">
        <h4>{{ c.status }} ({{ c.items.length }})</h4>
        <ItemCard v-for="i in c.items" :key="i.id" :item="i" />
      </div>
    </div>
  </section>
</template>

<style scoped>
.cols { display: grid; grid-template-columns: repeat(auto-fit, minmax(13rem, 1fr)); gap: 0.8rem; }
.col h4 { margin: 0 0 0.4rem; }
</style>
