// A canned source for the Transit theme tests: two efforts, every status, decisions, a pending decision, an andon, intake and a parse failure.
const P = { kind: 'merged' }
const item = (number, factoryStatus, effort, extra = {}) => ({
  id: `item-${number}`, number, title: `Item ${number}`, url: null, factoryStatus, kind: 'slice', role: 'developer',
  effort: effort ? { number: effort, title: `Effort ${effort}` } : null, provenance: P, ...extra,
})
const many = Number(process.env.TRANSIT_MANY || 0)
export default {
  async project(p) { return { id: p.id, state: 'ok', name: 'transit-project' } },
  async decisions() {
    return [1, 2, 3].map((n) => ({ id: `adr-${n}`, kind: 'adr', title: `Decision ${n}`, status: 'accepted', order: n, date: null, ref: `docs/adr/000${n}.md`, provenance: P }))
  },
  async parseFailures() { return [{ path: 'docs/adr/0009-broken.md', reason: 'missing front matter', provenance: P }] },
  async items() {
    if (many) return Array.from({ length: many }, (_, i) => item(1000 + i, i % 2 ? 'Done' : 'Ready', 5))
    return [
      item(10, 'Done', 1), item(11, 'Running', 1, { provenance: { kind: 'in-flight', item: 'item/11' } }), item(12, 'Waiting on you', 1),
      item(13, 'Blocked', 1, { blockedBy: [11] }), item(14, 'Ready', 2), item(15, 'Backlog', 2), item(16, 'Ready', null),
    ]
  },
  async directions() {
    return [{ id: 'd', goal: 'Reach the coast', current: 'Heading west', history: [{ date: '2026-01-01', change: 'Set out' }], ref: 'docs/direction.md', provenance: P }]
  },
  async andon() { return [{ id: 'a1', item: 13, owner: 'lead', reason: 'Flaky gate', resolved: false, countermeasure: null, since: null, ref: 'andon/1', provenance: P }] },
  async pendingDecisions() {
    return [{ id: 'pd1', item: 12, title: 'Pick a database', door: 'one-way', askedOf: 'you', since: '2026-01-01T00:00:00Z', options: ['A', 'B'], ref: 'card/1', provenance: P }]
  },
  async intake() {
    return [
      { id: 'i1', title: 'An idea', outcome: 'untriaged', channel: 'slack', reason: null, waitingOnHuman: true, ref: 'i/1', provenance: P },
      { id: 'i2', title: 'Parked idea', outcome: 'parked', channel: 'mail', reason: 'later', waitingOnHuman: false, ref: 'i/2', provenance: P },
    ]
  },
}
