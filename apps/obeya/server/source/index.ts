import { pathToFileURL } from 'node:url'
import { GhTracker } from './gh-tracker'
import { createRepoSource } from './repo-source'
import type { ReadModelSource } from './types'

export { SourceError } from './types'
export type { ReadModelSource } from './types'

let source: Promise<ReadModelSource> | undefined

/** The configured source. `OBEYA_SOURCE_MODULE` names a module whose default export replaces the repo source (an event-fed source, or a stub in tests). */
export function getSource(): Promise<ReadModelSource> {
  source ??= process.env.OBEYA_SOURCE_MODULE
    ? import(/* @vite-ignore */ pathToFileURL(process.env.OBEYA_SOURCE_MODULE).href).then((m) => m.default as ReadModelSource)
    : Promise.resolve(createRepoSource(new GhTracker()))
  return source
}
