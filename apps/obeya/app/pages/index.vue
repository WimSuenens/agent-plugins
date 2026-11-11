<script setup lang="ts">
import type { ProjectSummary } from '../../shared/types'
const { data: projects } = await useFetch<ProjectSummary[]>('/api/projects')
</script>

<template>
  <main>
    <h1>Obeya</h1>
    <p v-if="!projects?.length" data-test="empty">No project is configured.</p>
    <section v-for="p in projects" :key="p.id" :data-project="p.id">
      <h2 v-if="p.state === 'ok'" data-test="project-name">{{ p.name }}</h2>
      <p v-else role="alert" data-test="project-error">{{ p.id }}: {{ p.error }}</p>
    </section>
  </main>
</template>
