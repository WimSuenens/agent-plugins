import type { Component } from 'vue'
import { DEFAULT_THEME } from './config'

// A theme is a folder in app/themes with an index.vue. Dropping one in registers it; nothing else changes.
const found = import.meta.glob<{ default: Component }>('./*/index.vue', { eager: true })

export const themes: Record<string, Component> = Object.fromEntries(
  Object.entries(found).map(([path, mod]) => [path.split('/')[1], mod.default]),
)

export const themeLabel = (id: string) => id.charAt(0).toUpperCase() + id.slice(1)

/** An unknown or missing id falls back to the default theme, then to the base theme. */
export function resolveTheme(id: unknown): string {
  if (typeof id === 'string' && Object.hasOwn(themes, id)) return id
  return Object.hasOwn(themes, DEFAULT_THEME) ? DEFAULT_THEME : 'base'
}
