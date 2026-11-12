<script setup lang="ts">
import { themes, resolveTheme } from '../themes/registry'

const { state, refreshSeconds } = await useObeyaView()
const cookie = useCookie<string>('obeya-theme', { maxAge: 60 * 60 * 24 * 365, sameSite: 'lax', path: '/' })
const active = computed(() => resolveTheme(cookie.value))
const clock = (iso: string) => iso.slice(11, 19) + ' UTC'
</script>

<template>
  <main :data-refresh-seconds="refreshSeconds">
    <ThemeSwitcher :active="active" :refreshed-at="state.refreshedAt" :refresh-seconds="refreshSeconds" @select="(id) => (cookie = id)" />
    <p v-if="state.error" role="alert" data-test="refresh-error" class="banner">
      Refresh failed: {{ state.error }}. Last good refresh: {{ state.refreshedAt ? clock(state.refreshedAt) : 'never' }}.
    </p>
    <component :is="themes[active]" :view="state.view" :data-theme="active" />
  </main>
</template>

<style scoped>
.banner { margin: 0; padding: 0.5rem 3.5rem 0.5rem 1rem; border-bottom: 2px solid #8a0f14; background: #fff1f0; color: #5c0a0e; font-weight: bold; }
</style>
