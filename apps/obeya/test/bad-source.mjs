// A source that returns an object breaking the decision schema, to prove responses are validated.
export default {
  async project(p) {
    return { id: p.id, state: 'ok', name: 'bad' }
  },
  async decisions() {
    return [{ id: 'adr-1', title: 'no kind, no provenance' }]
  },
  async parseFailures() { return [] },
  async items() { return [] },
  async directions() { return [] },
  async andon() { return [] },
  async intake() { return [] },
}
