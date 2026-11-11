import type { ProjectSummary } from '../../../shared/types'

export default defineEventHandler(async (): Promise<ProjectSummary[]> => {
  return Promise.all(configuredProjects().map(summarize))
})
