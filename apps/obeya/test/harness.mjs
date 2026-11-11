// Test harness: a throwaway fixture project (git repo + a real worktree), the stub gh first on PATH, and a server started against it.
import { execFileSync, spawn } from 'node:child_process'
import { mkdtempSync, mkdirSync, writeFileSync, realpathSync } from 'node:fs'
import { createServer } from 'node:net'
import { tmpdir } from 'node:os'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
export const appDir = join(here, '..')
const stubGhDir = join(appDir, '..', '..', 'tests', 'factory', 'stub-gh')

const git = (cwd, ...args) => execFileSync('git', args, { cwd, stdio: 'pipe' })

/** A git repository named `name` with one commit and one worktree at .claude/worktrees/item-1. */
export function makeFixtureProject(name = 'fixture-project') {
  const root = realpathSync(mkdtempSync(join(tmpdir(), 'obeya-fixture-')))
  const path = join(root, name)
  mkdirSync(path)
  git(path, 'init', '-q', '-b', 'main')
  git(path, 'config', 'user.email', 't@example.invalid')
  git(path, 'config', 'user.name', 'test')
  writeFileSync(join(path, 'README.md'), '# fixture\n')
  git(path, 'add', '.')
  git(path, 'commit', '-q', '-m', 'init')
  mkdirSync(join(path, '.claude', 'worktrees'), { recursive: true })
  const worktree = join(path, '.claude', 'worktrees', 'item-1')
  git(path, 'worktree', 'add', '-q', '-b', 'item/1', worktree)
  return { root, path, worktree }
}

function freePort() {
  return new Promise((resolve, reject) => {
    const s = createServer()
    s.listen(0, '127.0.0.1', () => {
      const { port } = s.address()
      s.close(() => resolve(port))
    })
    s.on('error', reject)
  })
}

/** Runs bin/start.mjs against the built app. Resolves once the server answers, or with the exit if it stops first. */
export async function startServer({ projects, host = '127.0.0.1' }) {
  const port = await freePort()
  const env = {
    ...process.env,
    PATH: `${stubGhDir}:${process.env.PATH}`,
    STUB_GH_DIR: mkdtempSync(join(tmpdir(), 'obeya-gh-')),
    OBEYA_PROJECTS: JSON.stringify(projects),
    OBEYA_HOST: host,
    OBEYA_PORT: String(port),
  }
  const child = spawn('node', [join(appDir, 'bin', 'start.mjs')], { env, stdio: ['ignore', 'pipe', 'pipe'] })
  let output = ''
  child.stdout.on('data', (d) => (output += d))
  child.stderr.on('data', (d) => (output += d))
  const exited = new Promise((resolve) => child.on('exit', (code) => resolve({ code, output })))
  const base = `http://127.0.0.1:${port}`
  for (let i = 0; i < 100; i++) {
    const early = await Promise.race([exited, new Promise((r) => setTimeout(() => r(null), 100))])
    if (early) return { exit: early }
    try {
      await fetch(base + '/api/projects')
      return { base, stop: () => { child.kill(); return exited } }
    } catch {}
  }
  child.kill()
  throw new Error('server did not start:\n' + output)
}
