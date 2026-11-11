import { execFile } from 'node:child_process'
import { basename } from 'node:path'
import { promisify } from 'node:util'
import type { ProjectConfig, ProjectSummary } from '../../shared/types'

const run = promisify(execFile)

export function configuredProjects(): ProjectConfig[] {
  const raw = process.env.OBEYA_PROJECTS
  if (!raw) return []
  try {
    const list = JSON.parse(raw)
    if (Array.isArray(list) && list.every((p) => typeof p?.id === 'string' && typeof p?.path === 'string')) return list
  } catch {}
  return []
}

export async function summarize(p: ProjectConfig): Promise<ProjectSummary> {
  const fail = (error: string): ProjectSummary => ({ id: p.id, state: 'error', name: null, error })
  try {
    const { stdout } = await run('git', ['-C', p.path, 'rev-parse', '--show-toplevel'])
    return { id: p.id, state: 'ok', name: basename(stdout.trim()) }
  } catch (e: any) {
    if (e?.code === 'ENOENT') return fail('git is not installed')
    return fail(`project path ${p.path} does not exist or is not a git repository`)
  }
}
