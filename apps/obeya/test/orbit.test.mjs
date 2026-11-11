// Orbit theme (#132): a render smoke test through the existing API seam, plus checks on the theme folder's source.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdirSync, writeFileSync, readdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { appDir, makeFixtureProject, startServer } from './harness.mjs'

const adr = (status, title) => `---\nstatus: ${status}\n---\n\n# ${title}\n\nBody.\n`
const card = (n, title, status, extra = {}) => ({
  id: `PVTI_${n}`,
  title,
  content: { number: n, url: `https://github.com/o/r/issues/${n}`, type: 'Issue' },
  'factory Status': status,
  kind: 'slice',
  role: 'developer',
  ...extra,
})
const small = [card(1, 'Ready thing', 'Ready'), card(2, 'Running thing', 'Running'), card(3, 'Needs a human', 'Waiting on you'), card(4, 'Stuck thing', 'Blocked', { 'blocked By': '#2' })]
const many = Array.from({ length: 60 }, (_, i) => card(100 + i, `Backlog item ${i}`, 'Backlog'))

function makeProject() {
  const fx = makeFixtureProject('my-project')
  const git = (...a) => execFileSync('git', a, { cwd: fx.path, stdio: 'pipe' })
  git('remote', 'add', 'origin', 'git@github.com:o/r.git')
  mkdirSync(join(fx.path, 'docs', 'adr'), { recursive: true })
  writeFileSync(join(fx.path, 'docs', 'adr', '0001-first.md'), adr('accepted', 'First decision'))
  writeFileSync(join(fx.path, 'docs', 'adr', '0002-broken.md'), '# No front matter here\n')
  writeFileSync(join(fx.path, 'docs', 'direction.md'), '---\ngoal: A factory that runs itself\ncurrent: Make the work visible\n---\n\n## History\n\n- 2026-11-10: Added the Obeya.\n')
  git('add', 'docs')
  git('commit', '-q', '-m', 'docs')
  return fx
}

async function orbit(trackerItems, fn) {
  const fx = makeProject()
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path, tracker: { owner: 'o', projectNumber: 1 } }], trackerItems })
  try {
    const html = await (await fetch(s.base + '/', { headers: { cookie: 'obeya-theme=orbit' } })).text()
    await fn(html, s)
  } finally {
    await s.stop()
  }
}

test('orbit is selectable and renders the project, lens badge, needs-you first, and a parse-failure card', () =>
  orbit(small, async (html) => {
    assert.match(html, /data-theme="orbit"/)
    assert.match(html, /<button[^>]*data-theme-option="orbit"[^>]*aria-pressed="true"/)
    assert.match(html, /data-test="project-name"[^>]*>[^<]*my-project/)
    assert.match(html, /data-test="lens-badge"[^>]*>[^<]*read-only/)
    assert.ok(html.indexOf('data-test="needs-you"') > -1 && html.indexOf('data-test="needs-you"') < html.indexOf('data-test="project-name"'))
    assert.match(html, /data-test="parse-failure"/)
    assert.match(html, /docs\/adr\/0002-broken\.md/)
    assert.match(html, /missing front matter/)
  }))

test('orbit shows direction, board rings with counts, decisions, a sync ring and provenance', () =>
  orbit(small, async (html) => {
    assert.match(html, /data-test="direction-goal"[^>]*>[^<]*A factory that runs itself/)
    assert.match(html, /data-test="direction-current"[^>]*>[^<]*Make the work visible/)
    assert.match(html, /data-ring="Waiting on you"[^>]*data-count="1"/)
    assert.match(html, /data-ring="Blocked"[^>]*data-count="1"/)
    assert.match(html, /data-test="orbit-node"[^>]*data-item="3"/)
    assert.match(html, /data-test="decision"[\s\S]*First decision/)
    assert.match(html, /data-test="sync-ring"/)
    assert.match(html, /data-test="provenance"[^>]*>[^<]*merged/)
    assert.match(html, /data-test="inspector"/)
    assert.match(html, /Needs a human/)
  }))

test('a long ring shows capped nodes plus a +N node, never overlapping nodes', () =>
  orbit(many, async (html) => {
    const nodes = html.match(/data-test="orbit-node"/g) ?? []
    assert.ok(nodes.length > 0 && nodes.length < 60, `visible nodes ${nodes.length}`)
    const more = html.match(/data-test="orbit-more"[^>]*data-hidden="(\d+)"/)
    assert.ok(more, '+N node present')
    assert.equal(Number(more[1]) + nodes.length, 60)
    assert.match(html, /data-ring="Backlog"[^>]*data-count="60"/)
  }))

test('the theme folder is offline, motion-safe and presentation only', () => {
  const dir = join(appDir, 'app', 'themes', 'orbit')
  const src = readdirSync(dir).map((f) => readFileSync(join(dir, f), 'utf8')).join('\n')
  assert.doesNotMatch(src, /https?:\/\/(?!www\.w3\.org)/, 'no network URLs')
  assert.doesNotMatch(src, /@import|@font-face|fonts\.googleapis/)
  assert.match(src, /prefers-reduced-motion:\s*reduce/)
  assert.match(src, /focus-visible/)
  assert.match(src, /max-width:\s*\d+(px|rem)/, 'phone fallback')
})
