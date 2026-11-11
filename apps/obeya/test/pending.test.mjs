// Pending decisions and andon, tested at the read-model API and with a render smoke test.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdirSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { makeFixtureProject, startServer } from './harness.mjs'

const card = (fm, title = 'Which database?') => `---\n${fm}\n---\n\n## Decision: ${title}\n\nBody.\n`
const goodCard = (since) => card(`door: one-way\nasked: decision-maker\nsince: ${since}\noptions:\n  - Hosted\n  - Self-run`)
const andonFile = (fm) => `---\n${fm}\n---\n\n## Andon A1: other (#7)\n`

const put = (root, rel, text) => {
  mkdirSync(join(root, rel, '..'), { recursive: true })
  writeFileSync(join(root, rel), text)
}

/** Main checkout: a merged open andon. Worktree item/1: an in-flight card, a malformed card, a resolved andon. */
function makeProject() {
  const fx = makeFixtureProject('my-project')
  put(fx.path, 'work/7/01-andon-lead.md', andonFile('andon: A1\nitem: 7\nowner: developer\nstatus: open\nreason: result file missing\nsince: 2026-11-10T08:00:00Z'))
  execFileSync('git', ['add', 'work'], { cwd: fx.path })
  execFileSync('git', ['commit', '-q', '-m', 'work'], { cwd: fx.path })
  put(fx.worktree, 'work/1/03-decision-card-product-owner.md', goodCard('2026-11-11T09:00:00Z'))
  put(fx.worktree, 'work/1/04-decision-card-architect.md', card('door: maybe\nasked: me'))
  put(fx.worktree, 'work/1/05-andon-lead.md', andonFile('andon: A2\nitem: 1\nowner: qa-engineer\nstatus: resolved\nreason: same finding twice\ncountermeasure: guard added to the brief\nsince: 2026-11-09T08:00:00Z'))
  return fx
}

async function run(fn) {
  const fx = makeProject()
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }] })
  try {
    await fn(s, (path) => fetch(s.base + '/api/projects/p1/' + path).then((r) => r.json()))
  } finally {
    await s.stop()
  }
}

test('a card that exists only in a worktree is a pending decision with provenance, door, options and since', () =>
  run(async (_s, get) => {
    const pending = await get('pending-decisions')
    assert.equal(pending.length, 1)
    const d = pending[0]
    assert.equal(d.title, 'Which database?')
    assert.equal(d.door, 'one-way')
    assert.equal(d.askedOf, 'decision-maker')
    assert.equal(d.since, '2026-11-11T09:00:00Z')
    assert.deepEqual(d.options, ['Hosted', 'Self-run'])
    assert.equal(d.item, 1)
    assert.equal(d.ref, 'work/1/03-decision-card-product-owner.md')
    assert.deepEqual(d.provenance, { kind: 'in-flight', item: 'item/1' })
  }))

test('a card that fails its front matter is one parse-failure and no pending decision', () =>
  run(async (_s, get) => {
    const failures = await get('parse-failures')
    assert.equal(failures.length, 1)
    assert.equal(failures[0].path, 'work/1/04-decision-card-architect.md')
    assert.match(failures[0].reason, /door/)
    assert.deepEqual(failures[0].provenance, { kind: 'in-flight', item: 'item/1' })
  }))

test('andon: an open one shows item and owner, a resolved one its countermeasure', () =>
  run(async (_s, get) => {
    const andon = await get('andon')
    const by = Object.fromEntries(andon.map((a) => [a.item, a]))
    assert.equal(by[7].resolved, false)
    assert.equal(by[7].owner, 'developer')
    assert.equal(by[7].reason, 'result file missing')
    assert.deepEqual(by[7].provenance, { kind: 'merged' })
    assert.equal(by[1].resolved, true)
    assert.equal(by[1].countermeasure, 'guard added to the brief')
    assert.deepEqual(by[1].provenance, { kind: 'in-flight', item: 'item/1' })
  }))

test('the page shows the needs-you slot with the pending decision and the board item waiting on you, newest wait last', async () => {
  const fx = makeProject()
  const items = [
    { id: 'PVTI_1', title: 'Wait for review', content: { number: 9, url: 'https://example.invalid/o/r/issues/9', type: 'Issue' }, 'factory Status': 'Waiting on you', kind: 'slice', role: 'developer' },
  ]
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path, tracker: { owner: 'o', projectNumber: 1 } }], trackerItems: items })
  try {
    const html = await (await fetch(s.base + '/')).text()
    const slot = html.slice(html.indexOf('data-test="needs-you"'), html.indexOf('data-test="project-name"'))
    assert.match(slot, /Which database\?/)
    assert.match(slot, /Wait for review/)
    assert.ok(slot.indexOf('Wait for review') < slot.indexOf('Which database?'), 'unknown wait first, dated wait last')
    assert.match(html, /data-test="andon-open"[\s\S]*result file missing/)
    assert.match(html, /data-test="andon-resolved"[\s\S]*guard added to the brief/)
    assert.match(html, /data-test="parse-failure"[\s\S]*04-decision-card-architect\.md/)
  } finally {
    await s.stop()
  }
})
