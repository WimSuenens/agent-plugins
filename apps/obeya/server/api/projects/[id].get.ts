import type { ProjectSummary } from '../../../shared/types'
import { getSource } from '../../source'

export default defineEventHandler(async (event): Promise<ProjectSummary> => {
  return (await getSource()).project(findProject(getRouterParam(event, 'id')))
})
