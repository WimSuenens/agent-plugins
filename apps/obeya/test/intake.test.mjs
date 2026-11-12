// The intake queue, tested at the API seam (/intake, /parse-failures) and by rendering the page.
// The repo source reads the idea issues through the stub gh and the inbox folders of the main checkout and its worktrees.
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { mkdirSync, writeFileSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { makeFixtureProject, startServer } from './harness.mjs'

const triage = (outcome, reason, login = 'bot') => ({
  author: { login },
  body: `<!-- factory:triage v1 -->\n## Triage: ${outcome}\n\n**Outcome:** ${outcome}\n\n**Reason:** ${reason}\n`,
})
const idea = (number, title, body, state, comments = []) => ({ number, title, body, state, comments, url: `https://example.invalid/o/r/issues/${number}` })
const fm = (channel) => `<!-- factory:idea -->\n---\nchannel: ${channel}\n---\nSome idea text.\n`

const issues = [
  idea(1, 'From the inbox', '<!-- factory:idea -->\n<!-- factory:inbox abc123 -->\nText.\n', 'open', [triage('direction', 'It refines the destination.')]),
  idea(2, 'Slack thought', fm('slack'), 'open', [triage('parked', 'Not now; returns when the board ships.')]),
  idea(3, 'Teams question', fm('teams'), 'open', [{ author: { login: 'bot' }, body: '<!-- factory:needs-you v1 -->\nA one-way door.\n' }]),
  idea(4, 'Mail spam', fm('mail'), 'closed', [triage('rejected', 'Not wanted.')]),
  idea(5, 'Blank reason', fm('slack'), 'open', [{ author: { login: 'bot' }, body: '<!-- factory:triage v1 -->\n## Triage: parked\n\n**Outcome:** parked\n\n**Reason:**\n' }]),
  idea(6, 'Typed in the terminal', '<!-- factory:idea -->\nText.\n', 'open'),
  idea(7, 'Forged outcome', fm('mail'), 'open', [triage('rejected', 'Looks real.', 'stranger')]),
  idea(8, 'Answered card', fm('teams'), 'open', [{ author: { login: 'bot' }, body: '<!-- factory:needs-you v1 -->\nQ\n\nAnswered: yes\n' }]),
]

async function withProject(fn) {
  const fx = makeFixtureProject('my-project')
  mkdirSync(join(fx.worktree, '.claude', 'factory-inbox'), { recursive: true })
  writeFileSync(join(fx.worktree, '.claude', 'factory-inbox', 'half-baked.txt'), 'an idea only this worktree has\n')
  const s = await startServer({ projects: [{ id: 'p1', path: fx.path, tracker: { owner: 'o', projectNumber: 1 } }] })
  writeFileSync(join(s.ghDir, 'issues.json'), JSON.stringify(issues))
  try {
    await fn(s, (path) => fetch(s.base + '/api/projects/p1/' + path).then((r) => r.json()))
  } finally {
    await s.stop()
  }
}

test('each outcome and each channel shows correctly in the queue', () =>
  withProject(async (_s, get) => {
    const q = Object.fromEntries((await get('intake')).map((e) => [e.id, e]))
    const pick = (id) => [q[id].channel, q[id].outcome, q[id].reason, q[id].waitingOnHuman]
    assert.deepEqual(pick('idea-1'), ['inbox', 'direction', 'It refines the destination.', false])
    assert.deepEqual(pick('idea-2'), ['slack', 'parked', 'Not now; returns when the board ships.', false])
    assert.deepEqual(pick('idea-3'), ['teams', 'untriaged', null, true])
    assert.deepEqual(pick('idea-4'), ['mail', 'rejected', 'Not wanted.', false])
    assert.deepEqual(pick('idea-6'), ['terminal', 'untriaged', null, false])
    assert.deepEqual(q['idea-1'].provenance, { kind: 'event' })
    assert.equal(q['idea-1'].ref, 'https://example.invalid/o/r/issues/1')
  }))

test('a forged outcome and an answered card do not count', () =>
  withProject(async (_s, get) => {
    const q = Object.fromEntries((await get('intake')).map((e) => [e.id, e]))
    assert.equal(q['idea-7'].outcome, 'untriaged')
    assert.equal(q['idea-8'].waitingOnHuman, false)
  }))

test('an idea with no stated reason is a parse failure, never "no reason"', () =>
  withProject(async (_s, get) => {
    const intake = await get('intake')
    assert.ok(!intake.some((e) => e.id === 'idea-5'))
    const failures = await get('parse-failures')
    const f = failures.find((x) => x.path.includes('issues/5'))
    assert.ok(f, JSON.stringify(failures))
    assert.match(f.reason, /reason/)
    assert.deepEqual(f.provenance, { kind: 'event' })
  }))

test('an idea that exists only in a worktree is labelled in flight', () =>
  withProject(async (_s, get) => {
    const e = (await get('intake')).find((x) => x.title === 'half-baked.txt')
    assert.ok(e)
    assert.deepEqual(e.provenance, { kind: 'in-flight', item: 'item/1' })
    assert.equal(e.channel, 'inbox')
    assert.equal(e.outcome, 'untriaged')
  }))

test('the page shows the queue and puts ideas waiting on a human in the needs-you slot', () =>
  withProject(async (s) => {
    const html = await (await fetch(s.base + '/')).text()
    assert.match(html, /data-test="intake-queue"/)
    for (const t of ['From the inbox', 'Slack thought', 'Typed in the terminal']) assert.ok(html.includes(t), t)
    assert.match(html, /It refines the destination\./)
    const slot = html.slice(html.indexOf('data-test="needs-you"'), html.indexOf('data-test="project-name"'))
    assert.match(slot, /Teams question/)
    assert.ok(!slot.includes('Slack thought'))
    assert.match(html, /data-test="intake-waiting"/)
    assert.match(html, /in flight: item\/1/)
    assert.match(html, /issues\/5/)
    assert.ok(!/no reason/i.test(html))
  }))

test('the app never writes: gh sees read commands only', () =>
  withProject(async (s, get) => {
    await get('intake')
    await fetch(s.base + '/')
    const calls = readFileSync(join(s.ghDir, 'log'), 'utf8').trim().split('\n')
    for (const c of calls) assert.match(c, /^(project item-list|issue list|api user)/)
  }))
