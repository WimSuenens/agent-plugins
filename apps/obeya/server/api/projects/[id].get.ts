import type { ProjectSummary } from '../../../shared/types'

export default defineEventHandler(async (event): Promise<ProjectSummary> => {
  const id = getRouterParam(event, 'id')
  const project = configuredProjects().find((p) => p.id === id)
  if (!project) throw createError({ statusCode: 404, statusMessage: `no project with id ${id}` })
  return summarize(project)
})
