import type { ProjectConfig } from '../../shared/types'

export function configuredProjects(): ProjectConfig[] {
  const raw = process.env.OBEYA_PROJECTS
  if (!raw) return []
  try {
    const list = JSON.parse(raw)
    if (Array.isArray(list) && list.every((p) => typeof p?.id === 'string' && typeof p?.path === 'string')) return list
  } catch {}
  return []
}

export function findProject(id: string | undefined): ProjectConfig {
  const project = configuredProjects().find((p) => p.id === id)
  if (!project) throw createError({ statusCode: 404, statusMessage: `no project with id ${id}` })
  return project
}
