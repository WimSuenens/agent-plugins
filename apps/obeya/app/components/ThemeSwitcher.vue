<script setup lang="ts">
import { themes, themeLabel, themeBlurb } from '../themes/registry'

// A gear button floating over every theme opens a settings dialog: the theme choice, and when the page last refreshed.
defineProps<{ active: string; refreshedAt: string | null; refreshSeconds: number }>()
const emit = defineEmits<{ select: [id: string] }>()
const ids = Object.keys(themes).sort()

const dialog = ref<HTMLDialogElement | null>(null)
const gear = ref<HTMLButtonElement | null>(null)
const open = ref(false)
const clock = (iso: string) => iso.slice(11, 19) + ' UTC'

function show() {
  dialog.value?.showModal()
  open.value = true
}
function close() {
  dialog.value?.close()
}
// Fires for the close button, Esc and backdrop alike; focus goes back to the gear.
function closed() {
  open.value = false
  gear.value?.focus()
}
function backdrop(e: MouseEvent) {
  if (e.target === dialog.value) close()
}
</script>

<template>
  <div class="settings">
    <button ref="gear" type="button" class="gear" aria-label="Settings" aria-haspopup="dialog" :aria-expanded="open ? 'true' : 'false'" data-test="settings-button" @click="show">
      <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true" focusable="false">
        <path fill="currentColor" d="M19.4 13a7.5 7.5 0 0 0 0-2l2-1.6a.5.5 0 0 0 .1-.6l-1.9-3.3a.5.5 0 0 0-.6-.2l-2.4 1a7.4 7.4 0 0 0-1.7-1l-.4-2.5a.5.5 0 0 0-.5-.4h-3.8a.5.5 0 0 0-.5.4l-.4 2.5a7.4 7.4 0 0 0-1.7 1l-2.4-1a.5.5 0 0 0-.6.2L2.6 8.8a.5.5 0 0 0 .1.6l2 1.6a7.5 7.5 0 0 0 0 2l-2 1.6a.5.5 0 0 0-.1.6l1.9 3.3c.1.2.4.3.6.2l2.4-1c.5.4 1.1.7 1.7 1l.4 2.5c0 .2.2.4.5.4h3.8c.3 0 .5-.2.5-.4l.4-2.5c.6-.3 1.2-.6 1.7-1l2.4 1c.2.1.5 0 .6-.2l1.9-3.3a.5.5 0 0 0-.1-.6zM12 15.5a3.5 3.5 0 1 1 0-7 3.5 3.5 0 0 1 0 7z" />
      </svg>
    </button>

    <dialog ref="dialog" class="dlg" aria-labelledby="settings-h" data-test="settings-dialog" @close="closed" @click="backdrop">
      <div class="body">
        <h2 id="settings-h">Settings</h2>
        <fieldset>
          <legend>Theme</legend>
          <label v-for="id in ids" :key="id" class="opt">
            <input type="radio" name="obeya-theme" :value="id" :data-theme-option="id" :checked="id === active" @change="emit('select', id)" />
            <span><b>{{ themeLabel(id) }}</b><small v-if="themeBlurb(id)">{{ themeBlurb(id) }}</small></span>
          </label>
        </fieldset>
        <p class="refresh">
          Last refreshed:
          <time data-test="last-refreshed" :datetime="refreshedAt ?? undefined">{{ refreshedAt ? clock(refreshedAt) : 'never' }}</time>
          (every {{ refreshSeconds }}s)
        </p>
        <span role="status" aria-live="polite" class="sr-only">Theme: {{ themeLabel(active) }}</span>
        <button type="button" class="close" data-test="settings-close" @click="close">Close</button>
      </div>
    </dialog>
  </div>
</template>

<style scoped>
.gear { position: fixed; top: 0.6rem; right: 0.6rem; z-index: 1000; width: 2.4rem; height: 2.4rem; padding: 0; display: grid; place-items: center; border-radius: 50%; border: 1px solid rgba(255, 255, 255, 0.7); background: rgba(24, 26, 32, 0.82); color: #fff; box-shadow: 0 1px 6px rgba(0, 0, 0, 0.4); cursor: pointer; }
.gear:hover { background: rgba(24, 26, 32, 0.95); }
.gear:focus-visible, .close:focus-visible, .opt:focus-within { outline: 3px solid #4d9fff; outline-offset: 2px; }
.dlg { border: 1px solid #555; border-radius: 10px; padding: 0; max-width: min(26rem, calc(100vw - 1.5rem)); width: 100%; background: #fff; color: #1a1d24; font: 0.95rem/1.4 system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif; }
.dlg::backdrop { background: rgba(0, 0, 0, 0.55); }
.body { padding: 1rem 1.2rem 1.2rem; }
h2 { margin: 0 0 0.6rem; font-size: 1.1rem; }
fieldset { border: 0; margin: 0; padding: 0; }
legend { font-weight: 600; padding: 0; margin-bottom: 0.3rem; }
.opt { display: flex; gap: 0.6rem; align-items: flex-start; padding: 0.35rem 0.4rem; border-radius: 6px; cursor: pointer; }
.opt:hover { background: #eef1f6; }
.opt small { display: block; color: #4a5160; }
.refresh { margin: 0.8rem 0; color: #3a4150; font-size: 0.85rem; }
.close { font: inherit; padding: 0.35rem 1rem; border: 1px solid #1a1d24; border-radius: 6px; background: #1a1d24; color: #fff; cursor: pointer; }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
</style>
