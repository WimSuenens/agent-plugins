<script setup lang="ts">
import { themes, resolveTheme } from '../themes/registry'

const { state, refreshSeconds } = await useObeyaView()
const cookie = useCookie<string>('obeya-theme', { maxAge: 60 * 60 * 24 * 365, sameSite: 'lax', path: '/' })
const active = computed(() => resolveTheme(cookie.value))
const clock = (iso: string) => iso.slice(11, 19) + ' UTC'
</script>

<template>
  <main :data-refresh-seconds="refreshSeconds">
    <div class="chrome">
      <ThemeSwitcher :active="active" @select="(id) => (cookie = id)" />
      <p class="refresh">
        Last refreshed:
        <time data-test="last-refreshed" :datetime="state.refreshedAt ?? undefined">{{ state.refreshedAt ? clock(state.refreshedAt) : 'never' }}</time>
        (every {{ refreshSeconds }}s)
      </p>
    </div>
    <p v-if="state.error" role="alert" data-test="refresh-error" class="banner">
      Refresh failed: {{ state.error }}. Last good refresh: {{ state.refreshedAt ? clock(state.refreshedAt) : 'never' }}.
    </p>
    <component :is="themes[active]" :view="state.view" :data-theme="active" />
  </main>
</template>

<style scoped>
.chrome { display: flex; justify-content: space-between; align-items: center; gap: 1rem; flex-wrap: wrap; padding: 0.5rem 1rem; }
.refresh { margin: 0; font-size: 0.9rem; }
.banner { margin: 0 1rem; padding: 0.5rem 0.8rem; border: 2px solid currentColor; font-weight: bold; }
</style>
