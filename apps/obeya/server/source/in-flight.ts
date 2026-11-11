// Decides whether a worktree's copy of a file is that branch's own work (in flight) or merely a stale copy of main.
import { execFile } from 'node:child_process'
import { promisify } from 'node:util'

const run = promisify(execFile)

/** Resolves the commit a worktree was cut from, once per (main, worktree) pair. */
export function inFlightChecker(mainPath: string) {
  const bases = new Map<string, Promise<string | null>>()
  const baseOf = (treePath: string) => {
    let p = bases.get(treePath)
    if (!p) {
      p = (async () => {
        try {
          const head = (await run('git', ['-C', mainPath, 'rev-parse', 'HEAD'])).stdout.trim()
          return (await run('git', ['-C', treePath, 'merge-base', 'HEAD', head])).stdout.trim() || null
        } catch {
          return null
        }
      })()
      bases.set(treePath, p)
    }
    return p
  }
  /**
   * True when the worktree's branch changed `rel` relative to its merge-base with main (committed or not).
   * When the merge-base cannot be found, a differing copy counts as in flight (the safe, visible side).
   */
  return async (treePath: string, rel: string): Promise<boolean> => {
    const base = await baseOf(treePath)
    if (!base) return true
    try {
      await run('git', ['-C', treePath, 'diff', '--quiet', base, '--', rel])
      return false
    } catch {
      return true
    }
  }
}

/**
 * Merges a main tree's files with worktree copies. A worktree copy is kept only when main lacks the file,
 * or the worktree's branch changed it since its merge-base; a stale or equal copy is dropped.
 */
export async function pickInFlight<T extends { rel: string; text: string; tree: { path: string } }>(
  mainPath: string,
  base: T[],
  others: T[],
): Promise<T[]> {
  const mainText = new Map(base.map((f) => [f.rel, f.text]))
  const changedIn = inFlightChecker(mainPath)
  const kept: T[] = []
  for (const f of others) {
    const m = mainText.get(f.rel)
    if (m === f.text) continue
    if (m === undefined || (await changedIn(f.tree.path, f.rel))) kept.push(f)
  }
  const replaced = new Set(kept.map((f) => f.rel))
  return [...base.filter((b) => !replaced.has(b.rel)), ...kept]
}
