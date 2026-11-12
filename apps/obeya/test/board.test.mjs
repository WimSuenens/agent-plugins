// Board and decisions: tested at the API seam (statuses, ordering, provenance, blockers, links, parse failure) and by a render smoke test.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdirSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { makeFixtureProject, startServer } from './harness.mjs'

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
const trackerItems = [
  card(1, 'Backlog thing', 'Backlog'),
  card(2, 'Ready thing', 'Ready'),
  card(3, 'Running thing', 'Running'),
  card(4, 'Needs a human', 'Waiting on you'),
  card(5, 'Stuck thing', 'Blocked', { 'blocked By': '#3, #9' }),
  card(6, 'Finished thing', 'Done', { 'parent issue': 'https://github.com/o/r/issues/2' }),
  card(7, 'Also needs a human', 'Waiting on you'),
]

function makeProject() {
  const fx = makeFixtureProject('my-project')
  const git = (...a) => execFileSync('git', a, { cwd: fx.path, stdio: 'pipe' })
  git('remote', 'add', 'origin', 'git@github.com:o/r.git')
  const adrs = join(fx.path, 'docs', 'adr')
  mkdirSync(adrs, { recursive: true })
  writeFileSync(join(adrs, '0001-first.md'), adr('accepted', 'First decision'))
  writeFileSync(join(adrs, '0002-broken.md'), '# No front matter here\n')
  writeFileSync(join(adrs, '0010-tenth.md'), adr('accepted', 'Tenth decision'))
  git('add', 'docs')
  git('commit', '-q', '-m', 'adrs')
  mkdirSync(join(fx.worktree, 'docs', 'adr'), { recursive: true })
  writeFileSync(join(fx.worktree, 'docs', 'adr', '0003-in-flight.md'), adr('proposed', 'Third decision'))
  return fx
}

async function run(fn) {
  const fx = makeProject()
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path, tracker: { owner: 'o', projectNumber: 1 } }], trackerItems })
  try {
    await fn(s, (path) => fetch(s.base + '/api/projects/p1/' + path).then((r) => r.json()))
  } finally {
    await s.stop()
  }
}

test('every board item keeps its tracker status; a blocked item names its blockers', () =>
  run(async (_s, get) => {
    const items = await get('items')
    assert.deepEqual(
      items.map((i) => [i.number, i.factoryStatus]),
      [[1, 'Backlog'], [2, 'Ready'], [3, 'Running'], [4, 'Waiting on you'], [5, 'Blocked'], [6, 'Done'], [7, 'Waiting on you']],
    )
    assert.deepEqual(items.find((i) => i.number === 5).blockedBy, [3, 9])
    assert.equal(items.find((i) => i.number === 6).effort.number, 2)
  }))

test('ADRs are in numeric order, link to their source, and in-flight ones say so', () =>
  run(async (_s, get) => {
    const ds = await get('decisions')
    assert.deepEqual(ds.map((d) => d.order), [1, 3, 10])
    assert.equal(ds[0].url, 'https://github.com/o/r/blob/HEAD/docs/adr/0001-first.md')
    assert.deepEqual(ds[1].provenance, { kind: 'in-flight', item: 'item/1' })
    assert.equal(ds[1].url, 'https://github.com/o/r/blob/item/1/docs/adr/0003-in-flight.md')
    assert.equal((await get('parse-failures')).filter((f) => f.path.includes('0002')).length, 1)
  }))

test('the page shows needs-you first, the six columns in order, blockers, linked ADRs, in-flight labels and the parse failure', () =>
  run(async (s) => {
    const html = await (await fetch(s.base + '/')).text()
    const at = (re) => {
      const m = html.search(re)
      assert.ok(m > -1, String(re))
      return m
    }
    const needs = at(/data-test="needs-you"/)
    assert.ok(needs < at(/data-test="board"/))
    const slot = html.slice(needs, at(/data-test="project-name"/))
    assert.match(slot, /Needs a human/)
    assert.match(slot, /Also needs a human/)
    const cols = ['Backlog', 'Ready', 'Running', 'Waiting on you', 'Blocked', 'Done'].map((c) => at(new RegExp(`data-column="${c}"`)))
    assert.deepEqual([...cols].sort((a, b) => a - b), cols)
    assert.match(html, /data-test="blocked-by"[^>]*>[^<]*#3[^<]*#9/)
    assert.match(html, /<a[^>]*href="https:\/\/github\.com\/o\/r\/issues\/5"/)
    assert.match(html, /<a[^>]*href="https:\/\/github\.com\/o\/r\/blob\/HEAD\/docs\/adr\/0001-first\.md"/)
    assert.ok(at(/Tenth decision/) > at(/Third decision/) && at(/Third decision/) > at(/First decision/))
    assert.match(html, /data-test="provenance"[^>]*>[^<]*in flight: item\/1/)
    assert.match(html, /data-test="parse-failure"/)
    assert.match(html, /docs\/adr\/0002-broken\.md/)
  }))
