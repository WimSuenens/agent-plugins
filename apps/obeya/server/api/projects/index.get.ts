import type { ProjectSummary } from '../../../shared/types'
import { getSource } from '../../source'

export default defineEventHandler(async (): Promise<ProjectSummary[]> => {
  const source = await getSource()
  return Promise.all(configuredProjects().map((p) => source.project(p)))
})
