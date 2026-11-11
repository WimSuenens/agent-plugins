import type { ParseFailure } from '../types'

/** Ids and keys are only unique inside one project; anything shared across projects (selection, lists) is keyed with the project id. */
export const scopedKey = (projectId: string, id: string) => `${projectId}:${id}`

/** A parse failure is identified by project, path and where it was seen (the same path can fail on several branches). */
export const failureKey = (projectId: string, f: ParseFailure) => scopedKey(projectId, `${f.path}@${f.provenance.kind === 'in-flight' ? f.provenance.item : f.provenance.kind}`)
