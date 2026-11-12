import Ajv from 'ajv'
import schemas from '../../shared/generated/schemas.json'

const ajv = new Ajv({ allErrors: true, strict: false })
for (const [name, schema] of Object.entries(schemas)) ajv.addSchema(schema as object, name)

/** Throws a 500 when `value` does not match the schema file `schema` (for example `item.schema.json`). */
export function assertValid(schema: string, value: unknown): void {
  const validate = ajv.getSchema(schema)
  if (!validate) throw createError({ statusCode: 500, statusMessage: `no schema ${schema}` })
  if (!validate(value)) {
    const why = ajv.errorsText(validate.errors, { dataVar: 'object' })
    throw createError({ statusCode: 500, statusMessage: `response failed schema validation (${schema}): ${why}` })
  }
}
