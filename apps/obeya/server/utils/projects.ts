import type { ProjectConfig } from '../../shared/types'

const configError = (why: string) => createError({ statusCode: 500, statusMessage: `OBEYA_PROJECTS is invalid: ${why}` })

/** The configured projects. An unset variable is no projects; a malformed one or a duplicate id is a visible error, never an empty list. */
export function configuredProjects(): ProjectConfig[] {
  const raw = process.env.OBEYA_PROJECTS
  if (!raw) return []
  let list: unknown
  try {
    list = JSON.parse(raw)
  } catch {
    throw configError('not valid JSON')
  }
  if (!Array.isArray(list) || !list.every((p) => typeof p?.id === 'string' && p.id && typeof p?.path === 'string')) {
    throw configError('expected a JSON list of {"id": "...", "path": "..."}')
  }
  const seen = new Set<string>()
  for (const p of list) {
    if (seen.has(p.id)) throw configError(`duplicate project id "${p.id}"`)
    seen.add(p.id)
  }
  return list
}

export function findProject(id: string | undefined): ProjectConfig {
  const project = configuredProjects().find((p) => p.id === id)
  if (!project) throw createError({ statusCode: 404, statusMessage: `no project with id ${id}` })
  return project
}
