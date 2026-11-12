import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { appDir, makeFixtureProject, startServer } from './harness.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const source = join(here, 'transit-source.mjs')
const count = (html, re) => (html.match(re) || []).length

async function transit(env, fn) {
  const fx = makeFixtureProject('x')
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }], sourceModule: source, env })
  try {
    const html = await (await fetch(s.base + '/', { headers: { cookie: 'obeya-theme=transit' } })).text()
    await fn(html, s)
  } finally {
    await s.stop()
  }
}

test('transit is selectable and shows the project name, lens badge, needs-you and the parse-failure card', async () => {
  await transit({}, (html) => {
    assert.match(html, /data-theme="transit"/)
    assert.match(html, /<input[^>]*data-theme-option="transit"[^>]*checked/)
    assert.match(html, /data-test="project-name"[^>]*>transit-project/)
    assert.match(html, /data-test="lens-badge"[^>]*>[^<]*read-only[^<]*127\.0\.0\.1/)
    assert.match(html, /data-test="needs-you"/)
    assert.match(html, /data-test="parse-failure"/)
    assert.match(html, /docs\/adr\/0009-broken\.md/)
    assert.match(html, /data-test="provenance"[^>]*>[^<]*merged/)
  })
})

test('the map is generated from the read model: a line per effort, a station per item, decisions behind and pending ahead', async () => {
  await transit({}, (html) => {
    assert.equal(count(html, /data-line="1"/g), 1)
    assert.equal(count(html, /data-line="2"/g), 1)
    assert.match(html, /data-line="none"/)
    for (const n of [10, 11, 12, 13, 14, 15, 16]) assert.match(html, new RegExp(`data-station="item-${n}"`))
    assert.equal(count(html, /data-station-kind="decision"/g), 3)
    assert.equal(count(html, /data-station-kind="pending"/g), 1)
    assert.match(html, /data-test="you-are-here"/)
    assert.match(html, /data-test="feeder"/)
    assert.equal(count(html, /data-station-kind="idea"/g), 2)
    assert.match(html, /data-test="interchange"/)
  })
})

test('status is carried by text, not colour or animation alone, and provenance is on every station', async () => {
  await transit({}, (html) => {
    assert.match(html, /data-station="item-11"[^>]*aria-label="[^"]*Running[^"]*in flight: item\/11/)
    assert.match(html, /data-station="item-12"[^>]*aria-label="[^"]*Waiting on you/)
    assert.match(html, /data-station="item-10"[^>]*aria-label="[^"]*merged/)
  })
})

test('an open andon closes the track at the affected station, and the departures board lists needs-you first', async () => {
  await transit({}, (html) => {
    assert.match(html, /data-test="closure"[^>]*data-closure-for="item-13"/)
    assert.match(html, /data-test="andon-open"/)
    const board = html.indexOf('data-test="departures"')
    assert.ok(board > -1)
    assert.ok(html.indexOf('data-test="pending-decision"', board) > -1)
    assert.ok(html.indexOf('data-test="pending-decision"', board) < html.indexOf('data-test="departure-item"', board))
  })
})

test('every other view renders: direction, decisions made, intake queue', async () => {
  await transit({}, (html) => {
    assert.match(html, /data-test="direction-goal"[^>]*>Reach the coast/)
    assert.equal(count(html, /data-test="decision"[ >]/g), 3)
    assert.match(html, /data-test="intake-queue"/)
  })
})

test('a long board is aggregated into one station, never one station per item', async () => {
  await transit({ TRANSIT_MANY: '60' }, (html) => {
    const stations = count(html, /data-station="item-/g)
    assert.ok(stations <= 16, `got ${stations}`)
    assert.match(html, /data-station-kind="aggregate"/)
    assert.equal(count(html, /data-test="departure-item"/g), 60)
  })
})

test('the theme is offline and motion is guarded', () => {
  const dir = join(appDir, 'app', 'themes', 'transit')
  const files = ['index.vue', 'Station.vue'].map((f) => readFileSync(join(dir, f), 'utf8'))
  for (const vue of files) {
    assert.doesNotMatch(vue, /@import|url\(\s*['"]?https?:|fonts\.googleapis|<link/)
    const outside = vue.replace(/@media \(prefers-reduced-motion: no-preference\)\s*\{[\s\S]*?\n\}/g, '')
    assert.doesNotMatch(outside, /animation\s*:|@keyframes/)
  }
  assert.match(files.join(''), /prefers-reduced-motion/)
})

test('the header carries the roundel, the goal as the headline and the status counts; the legend has graphical keys', async () => {
  await transit({}, (html) => {
    const hd = html.slice(html.indexOf('<header'), html.indexOf('</header>'))
    assert.match(hd, /class="roundel"/)
    assert.match(hd, /class="goal big"/)
    assert.match(hd, /\d+ running[\s\S]*waiting on you[\s\S]*blocked/)
    assert.match(html, /<ul[^>]*class="legend"[^>]*aria-label="Legend"[\s\S]*track closed/)
    assert.ok(html.indexOf('data-test="needs-you"') > -1)
  })
})
