// Direction (#129): the goal, the current heading and the history from docs/direction.md, at the API and the page.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdirSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { makeFixtureProject, startServer } from './harness.mjs'

const doc = (goal, current, history = ['- 2026-11-01: Started with the factory core.', '- 2026-11-10: Added the Obeya (#121).']) =>
  `---\ngoal: ${goal}\ncurrent: ${current}\n---\n\n# Direction\n\n## History\n\n${history.join('\n')}\n`

function commit(fx, rel, text) {
  mkdirSync(join(fx.path, rel, '..'), { recursive: true })
  writeFileSync(join(fx.path, rel), text)
  execFileSync('git', ['add', '.'], { cwd: fx.path })
  execFileSync('git', ['commit', '-q', '-m', 'direction'], { cwd: fx.path })
}

async function withProject(setup, fn) {
  const fx = makeFixtureProject('my-project')
  setup(fx)
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }] })
  try {
    await fn((path) => fetch(s.base + '/api/projects/p1/' + path).then((r) => r.json()), s)
  } finally {
    await s.stop()
  }
}
const page = (s) => fetch(s.base + '/').then((r) => r.text())

test('a direction document gives goal, current heading and history, merged', () =>
  withProject(
    (fx) => commit(fx, 'docs/direction.md', doc('A factory that runs itself', 'Make the work visible')),
    async (get, s) => {
      const d = await get('directions')
      assert.equal(d.length, 1)
      assert.equal(d[0].goal, 'A factory that runs itself')
      assert.equal(d[0].current, 'Make the work visible')
      assert.equal(d[0].ref, 'docs/direction.md')
      assert.deepEqual(d[0].provenance, { kind: 'merged' })
      assert.deepEqual(d[0].history, [
        { date: '2026-11-01', change: 'Started with the factory core.' },
        { date: '2026-11-10', change: 'Added the Obeya (#121).' },
      ])
      assert.deepEqual(await get('parse-failures'), [])
      const html = await page(s)
      assert.match(html, /data-test="direction-goal"[^>]*>[^<]*A factory that runs itself/)
      assert.match(html, /data-test="direction-current"[^>]*>[^<]*Make the work visible/)
      assert.match(html, /data-test="direction-history-entry"[\s\S]*?2026-11-10[\s\S]*?Added the Obeya/)
      assert.match(html, /data-test="direction-source"[^>]*>[\s\S]*?docs\/direction\.md/)
      assert.match(html, /data-test="provenance"[^>]*>[^<]*merged/)
    },
  ))

test('no document is an empty state that says how to create it, not an error', () =>
  withProject(
    () => {},
    async (get, s) => {
      assert.deepEqual(await get('directions'), [])
      assert.deepEqual(await get('parse-failures'), [])
      const html = await page(s)
      assert.match(html, /data-test="direction-empty"[\s\S]*?No direction yet[\s\S]*?docs\/direction\.md/)
      assert.doesNotMatch(html, /data-test="parse-failure"/)
    },
  ))

test('a malformed document is a parse-failure with path and reason, and no direction', () =>
  withProject(
    (fx) => commit(fx, 'docs/direction.md', '---\ncurrent: only a heading\n---\n\n# Direction\n'),
    async (get, s) => {
      assert.deepEqual(await get('directions'), [])
      const f = await get('parse-failures')
      assert.equal(f.length, 1)
      assert.equal(f[0].path, 'docs/direction.md')
      assert.match(f[0].reason, /goal/)
      const html = await page(s)
      assert.match(html, /data-test="parse-failure"/)
      assert.doesNotMatch(html, /data-test="direction-empty"/)
    },
  ))

test('a bad history line is a parse-failure naming the history', () =>
  withProject(
    (fx) => commit(fx, 'docs/direction.md', doc('g', 'c', ['- sometime: vague'])),
    async (get) => {
      const f = await get('parse-failures')
      assert.equal(f.length, 1)
      assert.match(f[0].reason, /history/)
      assert.deepEqual(await get('directions'), [])
    },
  ))

test('a direction change that exists only in a worktree is shown as in flight', () =>
  withProject(
    (fx) => {
      commit(fx, 'docs/direction.md', doc('G', 'Old heading'))
      execFileSync('git', ['-C', fx.worktree, 'merge', '-q', 'main'])
      writeFileSync(join(fx.worktree, 'docs', 'direction.md'), doc('G', 'New heading'))
    },
    async (get, s) => {
      const d = await get('directions')
      assert.deepEqual(
        d.map((x) => [x.current, x.provenance]),
        [
          ['Old heading', { kind: 'merged' }],
          ['New heading', { kind: 'in-flight', item: 'item/1' }],
        ],
      )
      assert.match(await page(s), /data-test="provenance"[^>]*>[^<]*in flight: item\/1/)
    },
  ))

test('a document that exists only in a worktree is in flight, not an empty state', () =>
  withProject(
    (fx) => {
      mkdirSync(join(fx.worktree, 'docs'), { recursive: true })
      writeFileSync(join(fx.worktree, 'docs', 'direction.md'), doc('G', 'C'))
    },
    async (get) => {
      const d = await get('directions')
      assert.equal(d.length, 1)
      assert.deepEqual(d[0].provenance, { kind: 'in-flight', item: 'item/1' })
    },
  ))
