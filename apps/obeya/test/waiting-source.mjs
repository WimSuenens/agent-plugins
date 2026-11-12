// Every project has the same item id waiting on the person, to prove ids are scoped by project.
import stub from './stub-source.mjs'
export default {
  ...stub,
  async items() {
    return [{ id: 'item-5', number: 5, title: 'Same id everywhere', url: null, factoryStatus: 'Waiting on you', kind: 'slice', role: null, effort: null, provenance: { kind: 'event' } }]
  },
}
