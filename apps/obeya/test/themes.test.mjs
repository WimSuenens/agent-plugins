import { test, before } from 'node:test'
import assert from 'node:assert/strict'
import { cpSync, mkdtempSync, mkdirSync, writeFileSync, symlinkSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { execFileSync } from 'node:child_process'
import { tmpdir } from 'node:os'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { appDir, makeFixtureProject, startServer } from './harness.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const stub = join(here, 'stub-source.mjs')
const page = async (base, cookie) => (await fetch(base + '/', { headers: cookie ? { cookie } : {} })).text()

// A copy of the app with one trivial extra theme dropped in. Nothing outside app/themes changes.
let copy
before(() => {
  const root = mkdtempSync(join(tmpdir(), 'obeya-themed-'))
  copy = join(root, 'obeya')
  mkdirSync(copy)
  for (const f of ['app', 'server', 'shared', 'bin', 'nuxt.config.ts', 'package.json']) cpSync(join(appDir, f), join(copy, f), { recursive: true })
  symlinkSync(join(appDir, 'node_modules'), join(copy, 'node_modules'))
  mkdirSync(join(copy, 'app', 'themes', 'trivial'))
  writeFileSync(
    join(copy, 'app', 'themes', 'trivial', 'index.vue'),
    `<script setup lang="ts">
defineProps<{ view: any }>()
</script>
<template>
  <div data-test="trivial-theme"><section v-for="p in view.projects" :key="p.id"><p>TRIVIAL {{ p.name }}</p>
    <ParseFailureCard v-for="f in p.parseFailures" :key="f.path" :failure="f" /></section></div>
</template>
`,
  )
  execFileSync(join(copy, 'node_modules', '.bin', 'nuxt'), ['build'], { cwd: copy, stdio: 'pipe' })
})

async function withServer(opts, fn) {
  const fx = makeFixtureProject('my-project')
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }], sourceModule: stub, ...opts })
  try {
    await fn(s)
  } finally {
    await s.stop()
  }
}

test('base theme is the default and shows header, lens badge, needs-you slot first, and the parse-failure card', async () => {
  await withServer({}, async (s) => {
    const html = await page(s.base)
    assert.match(html, /data-theme="base"/)
    assert.match(html, /<h2[^>]*data-test="project-name"[^>]*>my-project/)
    assert.match(html, new RegExp(`data-test="lens-badge"[^>]*>[^<]*read-only[^<]*127\\.0\\.0\\.1:${s.base.split(':').pop()}`))
    assert.ok(html.indexOf('data-test="needs-you"') > -1, 'needs-you slot present')
    assert.ok(html.indexOf('data-test="needs-you"') < html.indexOf('data-test="project-name"'), 'needs-you comes first')
    assert.match(html, /data-test="parse-failure"/)
    assert.match(html, /docs\/adr\/0002-broken\.md/)
    assert.match(html, /missing front matter/)
    assert.match(html, /data-test="provenance"[^>]*>[^<]*merged/)
  })
})

test('a missing or unknown theme cookie renders the base theme', async () => {
  await withServer({}, async (s) => {
    assert.match(await page(s.base, 'obeya-theme=nope'), /data-theme="base"/)
    assert.match(await page(s.base, 'obeya-theme=../../etc'), /data-theme="base"/)
  })
})

test('the switcher is keyboard accessible, lists themes and announces the active one', async () => {
  await withServer({}, async (s) => {
    const html = await page(s.base)
    assert.match(html, /<button[^>]*data-theme-option="base"[^>]*aria-pressed="true"/)
    assert.match(html, /role="status"[^>]*>[^<]*Theme: Base/)
  })
})

test('a theme folder dropped in is chosen by cookie, keeps the same data, and is rendered server-side (no flash)', async () => {
  await withServer({ app: copy }, async (s) => {
    const base = await page(s.base)
    const triv = await page(s.base, 'obeya-theme=trivial')
    assert.match(base, /data-theme="base"/)
    assert.match(triv, /data-theme="trivial"/)
    assert.match(triv, /TRIVIAL my-project/)
    assert.doesNotMatch(triv, /data-test="project-name"/)
    for (const html of [base, triv]) assert.match(html, /docs\/adr\/0002-broken\.md/)
    assert.match(triv, /<button[^>]*data-theme-option="trivial"[^>]*aria-pressed="true"/)
    assert.match(triv, /data-theme-option="base"/)
  })
})

test('the page declares its refresh interval (default 15s, tunable) and the last refresh time', async () => {
  await withServer({}, async (s) => {
    const html = await page(s.base)
    assert.match(html, /data-refresh-seconds="15"/)
    assert.match(html, /data-test="last-refreshed"[^>]*>[^<]*\d\d:\d\d:\d\d/)
  })
  await withServer({ env: { OBEYA_REFRESH_SECONDS: '5' } }, async (s) => {
    assert.match(await page(s.base), /data-refresh-seconds="5"/)
  })
})

test('a failed read is shown as an error banner, not hidden', async () => {
  await withServer({ sourceModule: join(here, 'failing-source.mjs') }, async (s) => {
    const html = await page(s.base)
    assert.match(html, /role="alert"[^>]*data-test="refresh-error"/)
    assert.match(html, /Refresh failed/)
  })
})

test('themes only present: no theme fetches or reaches the server', () => {
  const dir = join(appDir, 'app', 'themes')
  const files = []
  const walk = (d) => readdirSync(d).forEach((n) => (statSync(join(d, n)).isDirectory() ? walk(join(d, n)) : files.push(join(d, n))))
  walk(dir)
  assert.ok(files.length > 0)
  for (const f of files.filter((f) => /\.(vue|ts|js)$/.test(f))) {
    assert.doesNotMatch(readFileSync(f, 'utf8'), /\b(useFetch|useAsyncData|\$fetch|fetch\(|useLazyFetch|XMLHttpRequest)/, f)
  }
})
