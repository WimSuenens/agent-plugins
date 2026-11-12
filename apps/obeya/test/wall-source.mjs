// Canned read model for the Wall theme tests: a long board, an open andon, a pending decision, intake slips, a parse failure.
const merged = { kind: 'merged' }
const items = Array.from({ length: 30 }, (_, i) => ({
  id: `item-${i + 1}`, number: i + 1, title: `Finished work ${i + 1}`, url: `https://example.invalid/issues/${i + 1}`,
  factoryStatus: 'Done', kind: 'slice', role: 'developer', effort: { number: 3, title: 'Effort' }, provenance: merged,
}))
items.push({ id: 'item-90', number: 90, title: 'Stuck thing', url: null, factoryStatus: 'Blocked', kind: 'slice', role: 'developer', effort: null, blockedBy: [91], provenance: { kind: 'in-flight', item: 'item/90' } })
items.push({ id: 'item-92', number: 92, title: 'Needs the owner', url: null, factoryStatus: 'Waiting on you', kind: 'decision', role: null, effort: null, provenance: { kind: 'event' } })
export default {
  async project(p) { return { id: p.id, state: 'ok', name: 'wall-project' } },
  async decisions() {
    return [
      { id: 'adr-0001', kind: 'adr', title: 'Settled choice', status: 'accepted', order: 1, date: null, ref: 'docs/adr/0001.md', provenance: merged },
      ...Array.from({ length: 40 }, (_, i) => ({ id: `adr-${i + 2}`, kind: 'adr', title: `Later choice ${i + 2}`, status: 'accepted', order: i + 2, date: null, ref: `docs/adr/${i + 2}.md`, provenance: merged })),
    ]
  },
  async parseFailures() { return [{ path: 'docs/adr/0002-broken.md', reason: 'missing front matter', provenance: merged }] },
  async items() { return items },
  async directions() {
    return [{ id: 'dir', goal: 'Ship the room', current: 'Finish the themes', history: [{ date: '2026-01-02', change: 'Picked themes' }], ref: 'docs/direction.md', provenance: merged }]
  },
  async andon() {
    return [{ id: 'a1', item: 90, owner: 'lead', reason: 'Tests red on main', resolved: false, countermeasure: null, since: '2026-01-02T10:00:00Z', ref: 'andon/a1', provenance: merged }]
  },
  async pendingDecisions() {
    return [{ id: 'pd1', item: 90, since: '2026-01-02T10:00:00Z', title: 'Pick the database', door: 'one-way', askedOf: 'owner', options: ['A', 'B'], ref: 'cards/1.md', provenance: { kind: 'in-flight', item: 'item/90' } }]
  },
  async intake() {
    return [{ id: 'i1', title: 'Add dark mode', outcome: 'slice-candidate', channel: 'slack', reason: 'small and clear', waitingOnHuman: false, ref: 'intake/1', provenance: merged }]
  },
}
