import { test } from 'node:test'
import assert from 'node:assert/strict'
import { makeFixtureProject, startServer } from './harness.mjs'

test('page and endpoint show the project name for the configured project', async () => {
  const fx = makeFixtureProject('my-project')
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }] })
  try {
    const api = await (await fetch(s.base + '/api/projects/p1')).json()
    assert.deepEqual(api, { id: 'p1', state: 'ok', name: 'my-project' })
    const html = await (await fetch(s.base + '/')).text()
    assert.match(html, /my-project/)
  } finally {
    await s.stop()
  }
})

test('a project path inside a repository (the fixture worktree) is accepted', async () => {
  const fx = makeFixtureProject('my-project')
  const s = await startServer({ projects: [{ id: 'p1', path: fx.worktree }] })
  try {
    assert.equal((await (await fetch(s.base + '/api/projects/p1')).json()).state, 'ok')
  } finally {
    await s.stop()
  }
})

test('an unknown project id is a 404', async () => {
  const fx = makeFixtureProject()
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }] })
  try {
    assert.equal((await fetch(s.base + '/api/projects/nope')).status, 404)
  } finally {
    await s.stop()
  }
})

test('refuses a non-loopback address with one line and a non-zero exit', async () => {
  const fx = makeFixtureProject()
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path }], host: '0.0.0.0' })
  assert.ok(s.exit, 'server should have exited')
  assert.notEqual(s.exit.code, 0)
  assert.equal(s.exit.output.trim().split('\n').length, 1)
  assert.match(s.exit.output, /loopback/)
})

test('a missing path and a non-git folder give a visible error state, not a crash', async () => {
  const fx = makeFixtureProject()
  const s = await startServer({
    projects: [
      { id: 'gone', path: fx.root + '/does-not-exist' },
      { id: 'plain', path: fx.root },
    ],
  })
  try {
    for (const id of ['gone', 'plain']) {
      const res = await fetch(s.base + '/api/projects/' + id)
      assert.equal(res.status, 200)
      const body = await res.json()
      assert.equal(body.state, 'error')
      assert.match(body.error, /not a git repository|does not exist/)
    }
    const html = await (await fetch(s.base + '/')).text()
    assert.match(html, /role="alert"/)
  } finally {
    await s.stop()
  }
})
