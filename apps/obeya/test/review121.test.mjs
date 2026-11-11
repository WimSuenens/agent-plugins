// Code-review fixes on spec #121: stale worktrees, producer file names, front matter edge cases, config errors.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdirSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { makeFixtureProject, startServer } from './harness.mjs'

const git = (cwd, ...args) => execFileSync('git', args, { cwd, stdio: 'pipe' })
const put = (root, rel, text) => {
  mkdirSync(join(root, rel, '..'), { recursive: true })
  writeFileSync(join(root, rel), text)
}
const commit = (cwd, msg) => {
  git(cwd, 'add', '-A')
  git(cwd, 'commit', '-q', '-m', msg)
}
const adr = (status) => `---\nstatus: ${status}\n---\n\n# Use a thing\n`
const dir = (goal) => `---\ngoal: ${goal}\ncurrent: now\n---\n\n## History\n\n- 2026-01-01: began\n`
const card = (since) => `---\ndoor: one-way\nasked: decision-maker\nsince: ${since}\noptions:\n  - A\n  - B\n---\n\n## Decision: Which?\n`

async function withProject(fx, fn, opts = {}) {
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }], ...opts })
  try {
    await fn((p) => fetch(s.base + '/api/projects/p1/' + p).then((r) => r.json()))
  } finally {
    await s.stop()
  }
}

/** Main moves after a second worktree is cut: that worktree is stale, not in flight. */
function staleProject() {
  const fx = makeFixtureProject('stale')
  put(fx.path, 'docs/adr/0001-thing.md', adr('proposed'))
  put(fx.path, 'docs/direction.md', dir('old goal'))
  put(fx.path, 'work/3/01-decision-card-product-owner.md', card('2026-01-01T00:00:00Z'))
  commit(fx.path, 'v1')
  const stale = join(fx.root, 'stale-wt')
  git(fx.path, 'worktree', 'add', '-q', '-b', 'item/2', stale)
  put(fx.path, 'docs/adr/0001-thing.md', adr('accepted'))
  put(fx.path, 'docs/direction.md', dir('new goal'))
  put(fx.path, 'work/3/01-decision-card-product-owner.md', card('2026-02-02T00:00:00Z'))
  commit(fx.path, 'v2')
  return { fx, stale }
}

test('a stale worktree copy (cut before main moved) does not replace main', async () => {
  const { fx } = staleProject()
  await withProject(fx, async (get) => {
    const decisions = await get('decisions')
    assert.deepEqual(decisions.map((d) => [d.status, d.provenance.kind]), [['accepted', 'merged']])
    const dirs = await get('directions')
    assert.deepEqual(dirs.map((d) => [d.goal, d.provenance.kind]), [['new goal', 'merged']])
    const pending = await get('pending-decisions')
    assert.deepEqual(pending.map((d) => [d.since, d.provenance.kind]), [['2026-02-02T00:00:00Z', 'merged']])
  })
})

test('a worktree that changed the file since its merge-base is still in flight', async () => {
  const { fx, stale } = staleProject()
  put(stale, 'docs/adr/0001-thing.md', adr('rejected'))
  put(stale, 'docs/direction.md', dir('branch goal'))
  put(stale, 'work/3/01-decision-card-product-owner.md', card('2026-03-03T00:00:00Z'))
  await withProject(fx, async (get) => {
    const decisions = await get('decisions')
    assert.deepEqual(decisions.map((d) => [d.status, d.provenance.kind]), [['rejected', 'in-flight']])
    assert.deepEqual((await get('directions')).map((d) => d.goal).sort(), ['branch goal', 'new goal'])
    const pending = await get('pending-decisions')
    assert.deepEqual(pending.map((d) => d.provenance.kind), ['in-flight'])
  })
})

test('a decision card named NN-decision-<slug>.md (the producers name) is read', async () => {
  const fx = makeFixtureProject('names')
  put(fx.worktree, 'work/1/02-decision-database-choice.md', card('2026-01-01T00:00:00Z'))
  put(fx.worktree, 'work/1/03-decision-card-architect.md', card('2026-01-02T00:00:00Z'))
  await withProject(fx, async (get) => {
    assert.deepEqual((await get('pending-decisions')).map((d) => d.ref).sort(), ['work/1/02-decision-database-choice.md', 'work/1/03-decision-card-architect.md'])
  })
})

test('an empty goal is a parse failure, it does not capture the next line', async () => {
  const fx = makeFixtureProject('empty')
  put(fx.path, 'docs/direction.md', '---\ngoal:\ncurrent: now\n---\n\n## History\n')
  put(fx.path, 'docs/adr/0001-x.md', '---\nstatus:\ntitle: nope\n---\n\n# X\n')
  commit(fx.path, 'x')
  await withProject(fx, async (get) => {
    assert.deepEqual(await get('directions'), [])
    const reasons = (await get('parse-failures')).map((f) => f.reason).sort()
    assert.deepEqual(reasons, ['front matter has no goal', 'front matter has no status'])
  })
})

test('a value containing #NN is not truncated, a trailing " # comment" is', async () => {
  const fx = makeFixtureProject('hash')
  put(fx.path, 'work/7/01-andon-lead.md', '---\nandon: A1\nitem: 7\nowner: developer   # who\nstatus: open\nreason: blocked by #45\n---\n')
  commit(fx.path, 'a')
  await withProject(fx, async (get) => {
    const [a] = await get('andon')
    assert.equal(a.reason, 'blocked by #45')
    assert.equal(a.owner, 'developer')
  })
})

test('malformed OBEYA_PROJECTS and duplicate ids are a visible error, not an empty list', async () => {
  const fx = makeFixtureProject('cfg')
  for (const [projects, re] of [
    [[{ id: 'a', path: fx.path }, { id: 'a', path: fx.path }], /duplicate/],
    [[{ id: 'a' }], /OBEYA_PROJECTS/],
  ]) {
    const s = await startServer({ projects })
    try {
      const r = await fetch(s.base + '/api/projects')
      assert.equal(r.status, 500)
      assert.match(JSON.stringify(await r.json()), re)
      assert.match(await (await fetch(s.base + '/')).text(), /OBEYA_PROJECTS/)
    } finally {
      await s.stop()
    }
  }
  const s = await startServer({ projects: 'not json{' })
  try {
    assert.equal((await fetch(s.base + '/api/projects')).status, 500)
  } finally {
    await s.stop()
  }
})

test('the same item id in two projects gives two needs-you entries, each scoped by its project', async () => {
  const fx = makeFixtureProject('scope')
  const s = await startServer({ projects: [{ id: 'one', path: fx.path }, { id: 'two', path: fx.path }], sourceModule: join(import.meta.dirname, 'waiting-source.mjs') })
  try {
    const html = await (await fetch(s.base + '/')).text()
    assert.equal(html.match(/data-test="waiting-item"/g)?.length, 2)
  } finally {
    await s.stop()
  }
})

test('one project failing its reads is a visible error state of that project; the others still render', async () => {
  const fx = makeFixtureProject('iso')
  const s = await startServer({ projects: [{ id: 'bad', path: fx.path }, { id: 'good', path: fx.path }], sourceModule: join(import.meta.dirname, 'partial-source.mjs') })
  try {
    const html = await (await fetch(s.base + '/')).text()
    assert.match(html, /data-test="project-error"[^>]*>bad: [^<]+</)
    assert.match(html, /Build the thing/)
    assert.doesNotMatch(html, /data-test="refresh-error"/)
  } finally {
    await s.stop()
  }
})
