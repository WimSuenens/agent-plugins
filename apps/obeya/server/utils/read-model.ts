import type { H3Event } from 'h3'
import { getSource, SourceError, type ReadModelSource } from '../source'

type Kind = Exclude<keyof ReadModelSource, 'project'>

/** One endpoint per object kind: ask the source, validate every object against its schema, then answer. */
export async function serveKind(event: H3Event, method: Kind, schema: string): Promise<unknown[]> {
  const project = findProject(getRouterParam(event, 'id'))
  let objects: unknown[]
  try {
    objects = await (await getSource())[method](project)
  } catch (e) {
    if (e instanceof SourceError) throw createError({ statusCode: e.status, statusMessage: e.message })
    throw e
  }
  for (const o of objects) assertValid(schema, o)
  return objects
}
