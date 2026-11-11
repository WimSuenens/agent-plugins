<script setup lang="ts">
import type { PageView } from '../../../shared/view'
const props = defineProps<{ view: PageView }>()
</script>

<template>
  <div class="base">
    <h1>Obeya</h1>
    <p class="lens" data-test="lens-badge">read-only lens &middot; bound to {{ view.bindAddress }}</p>

    <section class="needs-you" data-test="needs-you" aria-labelledby="needs-you-h">
      <h2 id="needs-you-h">Needs you</h2>
      <p v-if="!view.needsYou.length">Nothing needs you right now.</p>
      <NeedsYouList v-else :entries="view.needsYou" />
    </section>

    <p v-if="!view.projects.length" data-test="empty">No project is configured.</p>
    <section v-for="p in view.projects" :key="p.id" :data-project="p.id">
      <h2 v-if="p.state === 'ok'" data-test="project-name">{{ p.name }}</h2>
      <p v-else role="alert" data-test="project-error">{{ p.id }}: {{ p.error }}</p>
      <DirectionPanel :directions="p.directions" :parse-failures="p.parseFailures" />
      <BoardView :board="p.board" />
      <DecisionList :decisions="p.decisions" />
      <IntakeQueue v-if="p.state === 'ok'" :entries="p.intake" />
      <AndonList :andon="p.andon" />
      <ParseFailureCard v-for="f in p.parseFailures" :key="f.path" :failure="f" />
    </section>
  </div>
</template>

<style scoped>
.base { box-sizing: border-box; width: 100%; min-height: 100dvh; padding: 1rem max(1rem, calc((100% - 60rem) / 2)); line-height: 1.5; }
.lens { display: inline-block; border: 1px solid currentColor; border-radius: 999px; padding: 0 0.8rem; font-size: 0.9rem; }
.needs-you { border-left: 6px solid currentColor; padding-left: 0.8rem; margin: 1rem 0; }
@media (max-width: 40rem) { .base { padding: 0.5rem; } }
</style>
