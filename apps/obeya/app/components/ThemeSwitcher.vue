<script setup lang="ts">
import { themes, themeLabel } from '../themes/registry'
defineProps<{ active: string }>()
const emit = defineEmits<{ select: [id: string] }>()
const ids = Object.keys(themes).sort()
</script>

<template>
  <div class="switcher" role="group" aria-label="Theme">
    <button
      v-for="id in ids"
      :key="id"
      type="button"
      :data-theme-option="id"
      :aria-pressed="id === active ? 'true' : 'false'"
      @click="emit('select', id)"
    >
      {{ themeLabel(id) }}
    </button>
    <span role="status" aria-live="polite" class="sr-only">Theme: {{ themeLabel(active) }}</span>
  </div>
</template>

<style scoped>
.switcher { display: flex; gap: 0.4rem; flex-wrap: wrap; }
button { font: inherit; padding: 0.3rem 0.8rem; border: 1px solid currentColor; border-radius: 6px; background: transparent; color: inherit; cursor: pointer; }
button[aria-pressed='true'] { font-weight: bold; text-decoration: underline; }
button:focus-visible { outline: 3px solid Highlight; outline-offset: 2px; }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
</style>
