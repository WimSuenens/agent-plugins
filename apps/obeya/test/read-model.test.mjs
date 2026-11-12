// The read-model API, tested at HTTP. The same assertions run against the real repo source and against a stub source.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdirSync, writeFileSync, readFileSync, mkdtempSync, copyFileSync, readdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { tmpdir } from 'node:os'
import { fileURLToPath } from 'node:url'
import { makeFixtureProject, startServer, appDir } from './harness.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const schemasDir = join(appDir, '..', '..', 'contracts', 'obeya')

const adr = (status, title) => `---\nstatus: ${status}\n---\n\n# ${title}\n\nBody.\n`
const trackerItems = [
  {
    id: 'PVTI_1',
    title: 'Build the thing',
    content: { number: 7, url: 'https://example.invalid/o/r/issues/7', type: 'Issue' },
    'factory Status': 'In progress',
    kind: 'slice',
    role: 'developer',
    'parent issue': 'https://example.invalid/o/r/issues/3',
  },
]

/** A fixture with a merged ADR, a malformed merged ADR and an ADR that exists only in the item-1 worktree. */
function makeProject() {
  const fx = makeFixtureProject('my-project')
  const adrs = join(fx.path, 'docs', 'adr')
  mkdirSync(adrs, { recursive: true })
  writeFileSync(join(adrs, '0001-first.md'), adr('accepted', 'First decision'))
  writeFileSync(join(adrs, '0002-broken.md'), '# No front matter here\n')
  execFileSync('git', ['add', 'docs'], { cwd: fx.path })
  execFileSync('git', ['commit', '-q', '-m', 'adrs'], { cwd: fx.path })
  mkdirSync(join(fx.worktree, 'docs', 'adr'), { recursive: true })
  writeFileSync(join(fx.worktree, 'docs', 'adr', '0003-in-flight.md'), adr('proposed', 'Third decision'))
  return fx
}

const sources = [
  { name: 'repo source', module: undefined },
  { name: 'stub source', module: join(here, 'stub-source.mjs') },
]

for (const { name, module } of sources) {
  const run = async (fn) => {
    const fx = makeProject()
    const s = await startServer({
      projects: [{ id: 'p1', path: fx.path, tracker: { owner: 'o', projectNumber: 1 } }],
      trackerItems,
      sourceModule: module,
    })
    try {
      await fn(s, (path) => fetch(s.base + '/api/projects/p1/' + path).then((r) => r.json()))
    } finally {
      await s.stop()
    }
  }

  test(`${name}: decisions carry provenance, merged and in flight`, () =>
    run(async (_s, get) => {
      const decisions = await get('decisions')
      assert.deepEqual(
        decisions.map((d) => [d.id, d.title, d.status, d.order, d.provenance]),
        [
          ['adr-0001', 'First decision', 'accepted', 1, { kind: 'merged' }],
          ['adr-0003', 'Third decision', 'proposed', 3, { kind: 'in-flight', item: 'item/1' }],
        ],
      )
    }))

  test(`${name}: a malformed artifact is one parse-failure with path and reason`, () =>
    run(async (_s, get) => {
      const failures = await get('parse-failures')
      assert.equal(failures.length, 1)
      assert.equal(failures[0].path, 'docs/adr/0002-broken.md')
      assert.match(failures[0].reason, /front matter/)
      assert.deepEqual(failures[0].provenance, { kind: 'merged' })
      const decisions = await get('decisions')
      assert.ok(!decisions.some((d) => d.ref.includes('0002')))
    }))

  test(`${name}: items come from the tracker with status, kind, role and effort`, () =>
    run(async (_s, get) => {
      const items = await get('items')
      assert.equal(items.length, 1)
      assert.deepEqual(
        { ...items[0], provenance: undefined },
        {
          id: 'item-7',
          number: 7,
          title: 'Build the thing',
          url: 'https://example.invalid/o/r/issues/7',
          factoryStatus: 'In progress',
          kind: 'slice',
          role: 'developer',
          effort: { number: 3, title: null },
          provenance: undefined,
        },
      )
      assert.equal(items[0].provenance.kind, 'event')
    }))

  test(`${name}: kinds not built yet answer with empty lists`, () =>
    run(async (_s, get) => {
      for (const k of ['directions', 'andon', 'intake']) assert.deepEqual(await get(k), [])
    }))
}

test('the real tracker adapter only runs read commands', async () => {
  const fx = makeProject()
  const s = await startServer({
    projects: [{ id: 'p1', path: fx.path, tracker: { owner: 'o', projectNumber: 1 } }],
    trackerItems,
  })
  try {
    await fetch(s.base + '/api/projects/p1/items')
    const calls = readFileSync(join(s.ghDir, 'log'), 'utf8').trim().split('\n')
    assert.ok(calls.length > 0)
    for (const c of calls) assert.match(c, /^project item-list /)
  } finally {
    await s.stop()
  }
})

test('a project without a tracker has no items', async () => {
  const fx = makeProject()
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }] })
  try {
    assert.deepEqual(await (await fetch(s.base + '/api/projects/p1/items')).json(), [])
  } finally {
    await s.stop()
  }
})

test('a response that fails its schema is refused with a 500, never served', async () => {
  const fx = makeProject()
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }], sourceModule: join(here, 'bad-source.mjs') })
  try {
    const res = await fetch(s.base + '/api/projects/p1/decisions')
    assert.equal(res.status, 500)
    assert.match(JSON.stringify(await res.json()), /schema/)
  } finally {
    await s.stop()
  }
})

test('an unusable project path is a 409 on the object endpoints', async () => {
  const s = await startServer({ projects: [{ id: 'gone', path: '/nonexistent/obeya-x' }] })
  try {
    assert.equal((await fetch(s.base + '/api/projects/gone/decisions')).status, 409)
    assert.equal((await fetch(s.base + '/api/projects/nope/decisions')).status, 404)
  } finally {
    await s.stop()
  }
})

test('only the source seam touches the filesystem or runs gh', () => {
  const walk = (dir) =>
    readdirSync(dir, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(join(dir, e.name)) : [join(dir, e.name)]))
  const outside = [...walk(join(appDir, 'server')), ...walk(join(appDir, 'app'))].filter((f) => !f.includes('/server/source/'))
  for (const f of outside) {
    assert.doesNotMatch(readFileSync(f, 'utf8'), /node:fs|node:child_process|\bexecFile\b|\bspawn\b|'gh'/, f)
  }
})

test('generated types are current, and a stale generated type fails the check', () => {
  const gen = join(appDir, 'scripts', 'gen-types.mjs')
  execFileSync('node', [gen, '--check'])
  const out = mkdtempSync(join(tmpdir(), 'obeya-gen-'))
  execFileSync('node', [gen, '--out', out])
  execFileSync('node', [gen, '--check', '--out', out])
  writeFileSync(join(out, 'read-model.d.ts'), readFileSync(join(out, 'read-model.d.ts'), 'utf8') + '// stale\n')
  assert.throws(() => execFileSync('node', [gen, '--check', '--out', out], { stdio: 'pipe' }))
  // a schema change makes the committed types stale
  const changed = mkdtempSync(join(tmpdir(), 'obeya-schemas-'))
  for (const f of readdirSync(schemasDir)) copyFileSync(join(schemasDir, f), join(changed, f))
  const item = JSON.parse(readFileSync(join(changed, 'item.schema.json'), 'utf8'))
  item.properties.extra = { type: 'string' }
  writeFileSync(join(changed, 'item.schema.json'), JSON.stringify(item))
  assert.throws(() => execFileSync('node', [gen, '--check', '--schemas', changed], { stdio: 'pipe' }))
})
