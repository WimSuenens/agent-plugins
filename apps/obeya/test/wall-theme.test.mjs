import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readdirSync, readFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { appDir, makeFixtureProject, startServer } from './harness.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const wallDir = join(appDir, 'app', 'themes', 'wall')

async function wall(fn, sourceModule = join(here, 'wall-source.mjs')) {
  const fx = makeFixtureProject('wall')
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }], sourceModule })
  try {
    const html = await (await fetch(s.base + '/', { headers: { cookie: 'obeya-theme=wall' } })).text()
    await fn(html, s)
  } finally {
    await s.stop()
  }
}

test('the wall theme is selectable, shows the project name and the parse-failure card', async () => {
  await wall((html) => {
    assert.match(html, /data-theme="wall"/)
    assert.match(html, /data-theme-option="wall"[^>]*aria-pressed="true"/)
    assert.match(html, /wall-project/)
    assert.match(html, /data-test="parse-failure"/)
    assert.match(html, /docs\/adr\/0002-broken\.md/)
  })
})

test('the wall shows every view with provenance', async () => {
  await wall((html) => {
    assert.match(html, /data-test="lens-badge"[^>]*>[^<]*read-only/)
    assert.match(html, /Ship the room/)
    assert.match(html, /Finish the themes/)
    assert.match(html, /Pick the database/)
    assert.match(html, /one-way door/)
    assert.match(html, /Settled choice/)
    assert.match(html, /Add dark mode/)
    assert.match(html, /Slice candidate/)
    assert.match(html, /Stuck thing/)
    assert.match(html, /data-test="blocked-by"[^>]*>[^<]*#91/)
    assert.match(html, /in flight: item\/90/)
    assert.ok(html.indexOf('data-test="needs-you"') < html.indexOf('data-test="project-name"'))
  })
})

test('the andon light tower is red with the open andon on a note, and says so in text', async () => {
  await wall((html) => {
    assert.match(html, /data-test="andon-light"[^>]*data-state="red"/)
    assert.match(html, /Tests red on main/)
    assert.match(html, /Line stopped/)
  })
})

test('a long board and a long ADR list are folded into stacks, not overlapped', async () => {
  await wall((html) => {
    assert.match(html, /data-test="done-stack"/)
    assert.match(html, /data-test="adr-stack"/)
    // the folded notes stay in the page (inside details), so no data is lost
    assert.match(html, /Finished work 1\s*</)
    assert.match(html, /Later choice 41/)
  })
})

test('the tower is green when no andon is open', async () => {
  await wall((html) => assert.match(html, /data-test="andon-light"[^>]*data-state="green"/), join(here, 'stub-source.mjs'))
})

test('the wall works offline and respects reduced motion', () => {
  const files = readdirSync(wallDir)
  assert.ok(files.includes('index.vue'))
  const src = files.map((f) => readFileSync(join(wallDir, f), 'utf8')).join('\n')
  assert.doesNotMatch(src, /https?:\/\/|@import/)
  assert.match(src, /prefers-reduced-motion:\s*reduce/)
  assert.doesNotMatch(src, /\b(useFetch|useAsyncData|\$fetch|fetch\()/)
})
