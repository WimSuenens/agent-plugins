// A stub source for the swap test: canned read-model objects, no filesystem, no gh. Matches the fixture project's expectations.
export default {
  async project(p) {
    return { id: p.id, state: 'ok', name: 'my-project' }
  },
  async decisions() {
    return [
      { id: 'adr-0001', kind: 'adr', title: 'First decision', status: 'accepted', order: 1, date: null, ref: 'stub/1', provenance: { kind: 'merged' } },
      { id: 'adr-0003', kind: 'adr', title: 'Third decision', status: 'proposed', order: 3, date: null, ref: 'stub/3', provenance: { kind: 'in-flight', item: 'item/1' } },
    ]
  },
  async parseFailures() {
    return [{ path: 'docs/adr/0002-broken.md', reason: 'missing front matter', provenance: { kind: 'merged' } }]
  },
  async items() {
    return [
      { id: 'item-7', number: 7, title: 'Build the thing', url: 'https://example.invalid/o/r/issues/7', factoryStatus: 'In progress', kind: 'slice', role: 'developer', effort: { number: 3, title: null }, provenance: { kind: 'event' } },
    ]
  },
  async directions() {
    return []
  },
  async andon() {
    return []
  },
  async pendingDecisions() {
    return []
  },
  async intake() {
    return []
  },
}
