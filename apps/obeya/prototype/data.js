// PROTOTYPE (throwaway) - spec #121. SAMPLE DATA, not real factory state.
// Shape follows the read model in the spec: every object carries provenance
// ('merged' | 'item/<id>' | 'event') so the UI can show how settled it is.
(function () {
  var O = {};

  O.project = {
    id: 'agent-plugins', name: 'agent-plugins', repo: 'WimSuenens/agent-plugins',
    factory: '2.4.0', bind: '127.0.0.1:4173', mount: 'read-only', refreshed: '12:41:07', pollSec: 15
  };

  O.direction = {
    source: 'docs/direction.md', prov: 'merged',
    goal: 'A factory that keeps a project moving on its own, while the person keeps every decision that cannot be undone.',
    heading: 'Make the factory continuous and project-resident (#108), then make it visible: the Obeya room (#121).',
    history: [
      { date: '2026-10-21', idea: '#94 lean extensions', effect: 'work/ removed; the tracker is the single source of truth' },
      { date: '2026-11-02', idea: '#108 continuous factory', effect: 'Direction: continuous, project-resident, parallel by path list' },
      { date: '2026-11-11', idea: '#121 Obeya room', effect: 'Direction adds: a visible, read-only lens over the factory' }
    ]
  };

  O.statuses = ['Running', 'Waiting on you', 'Blocked', 'Ready', 'Backlog', 'Done'];

  O.adrs = [
    [1, 'Factory roles talk through files'], [2, 'One branch and worktree per item'], [3, 'Roles ship as plugin agents'],
    [4, 'Role memory uses user scope'], [5, 'One-way doors reach the person as decision cards'], [6, 'Factory builds wayfinder slices'],
    [7, 'Factory owns destination and slicing'], [8, 'Two-way decisions flow back to the lead'], [9, 'Work outside an item runs as a frontier round'],
    [10, 'Every factory role has a shell'], [11, 'Local countermeasures stop at a wide fence'], [12, 'Releases carry a semver'],
    [13, 'Items merge with their history'], [14, 'Each role task is a sub-issue'], [15, 'Factory status has six values'],
    [16, 'Slices run in parallel when path lists do not overlap']
  ].map(function (a) { return { id: 'ADR-' + ('000' + a[0]).slice(-4), n: a[0], title: a[1], prov: 'merged' }; });

  O.pending = [
    { id: 'DC-021', title: 'Publish the Obeya image as a public GHCR package?', door: 'one-way', waiting: '2 h', prov: 'item/122',
      ask: 'A public package is visible to everyone and cannot be un-published cleanly.', options: ['Public package', 'Private + pull token'] },
    { id: 'ADR-0017', title: 'The Obeya is a lens over the repo, not a store', door: 'one-way', waiting: '35 min', prov: 'item/122',
      ask: 'Record the lens principle and the source seam as an ADR.', options: ['Accept', 'Change wording'] },
    { id: 'ADR-0018', title: 'Nuxt 4 in a container image on GHCR', door: 'one-way', waiting: '35 min', prov: 'item/122',
      ask: 'Record the stack, the apps/ layout and separate versioning.', options: ['Accept', 'Change wording'] },
    { id: 'DC-022', title: 'Is a write-capable token ever allowed in the container?', door: 'one-way', waiting: 'not yet asked', prov: 'event',
      ask: 'Deferred until interactive decisions are sliced.', options: [] }
  ];

  // kind: slice | research | task ; line: which effort the item belongs to
  O.board = [
    { n: 94,  title: 'lead: remove work/', status: 'Done', kind: 'slice', role: 'lead', line: 'older', prov: 'merged' },
    { n: 106, title: 'Guard awk file operands in post-text and board', status: 'Done', kind: 'slice', role: 'developer', line: 'older', prov: 'merged' },
    { n: 109, title: 'Worktrees in the project .claude/worktrees folder', status: 'Done', kind: 'slice', role: 'devops', line: '108', prov: 'merged' },
    { n: 110, title: 'Idea intake: inbox folder and terminal command', status: 'Running', kind: 'slice', role: 'developer', line: '108', prov: 'item/110' },
    { n: 111, title: 'Integrator role: dispatch and merge order', status: 'Ready', kind: 'slice', role: '-', line: '108', prov: 'merged' },
    { n: 112, title: 'Classify improvements: local or fundamental', status: 'Backlog', kind: 'slice', role: '-', line: '108', prov: 'merged' },
    { n: 113, title: 'Role knowledge as versioned project files', status: 'Backlog', kind: 'slice', role: '-', line: '108', prov: 'merged' },
    { n: 114, title: 'Run the app and attach proof before merge', status: 'Waiting on you', kind: 'slice', role: 'qa-engineer', line: '108', prov: 'item/114', since: '41 min',
      note: 'Needs a run command for this project.' },
    { n: 115, title: 'Clean up branches and worktrees after merge', status: 'Blocked', kind: 'slice', role: '-', line: '108', prov: 'merged', blockedBy: 111 },
    { n: 116, title: 'Use triage and diagnosis skills in maintenance', status: 'Backlog', kind: 'slice', role: '-', line: '108', prov: 'merged' },
    { n: 117, title: 'Maintenance cycle: decide when it pays off', status: 'Backlog', kind: 'slice', role: '-', line: '108', prov: 'merged' },
    { n: 118, title: 'Sanitised proposals to the marketplace', status: 'Backlog', kind: 'research', role: '-', line: '108', prov: 'merged' },
    { n: 119, title: 'Graduate proven skills into domain plugins', status: 'Backlog', kind: 'slice', role: '-', line: '108', prov: 'merged' },
    { n: 122, title: 'Obeya walking skeleton: app, image, CI, command', status: 'Ready', kind: 'slice', role: '-', line: '121', prov: 'item/122' },
    { n: 123, title: 'Board and decisions made, with provenance', status: 'Backlog', kind: 'slice', role: '-', line: '121', prov: 'event' },
    { n: 124, title: 'Direction: docs/direction.md and its schema', status: 'Backlog', kind: 'slice', role: '-', line: '121', prov: 'event' },
    { n: 125, title: 'Pending decisions and andon', status: 'Backlog', kind: 'slice', role: '-', line: '121', prov: 'event' },
    { n: 126, title: 'Intake queue', status: 'Blocked', kind: 'slice', role: '-', line: '121', prov: 'event', blockedBy: 110 }
  ];

  O.andon = [
    { id: 'A-7', item: 114, title: 'Proof step cannot start: no run command in the project config', raised: '41 min ago', open: true, owner: 'lead' },
    { id: 'A-6', item: 110, title: 'Inbox file left behind after issue creation', raised: 'yesterday', open: false, owner: 'developer', fix: 'Countermeasure applied: delete only after the issue exists' }
  ];

  O.intake = [
    { id: 'I-31', src: 'slack', text: 'Let the factory open a maintenance cycle on Fridays', outcome: 'slice candidate', reason: 'Fits #108 maintenance; path list is disjoint', when: '12 min' },
    { id: 'I-32', src: 'mail', text: 'Reference: Toyota Kata coaching cards (PDF)', outcome: 'research ticket', reason: 'Evidence for kaizen views, needs reading first', when: '1 h' },
    { id: 'I-33', src: 'inbox', text: 'Rename the Obeya to Control room', outcome: 'rejected', reason: 'Obeya is the agreed term (#66)', when: '3 h' },
    { id: 'I-34', src: 'teams', text: 'Should a Teams alert pause a running slice?', outcome: 'needs you', reason: 'Touches the fence: only the person can decide', when: '4 h' },
    { id: 'I-35', src: 'terminal', text: 'Show several projects in one Obeya', outcome: 'parked', reason: 'Trigger: after the single-project lens ships', when: 'yesterday' },
    { id: 'I-36', src: 'slack', text: 'Light theme for the board', outcome: 'direction', reason: 'Folded into the direction as a UI preference', when: 'yesterday' }
  ];

  O.parseFailures = [
    { path: '.claude/worktrees/114/docs/decision-cards/DC-019.md', reason: 'front matter: required key "door" is missing', prov: 'item/114' }
  ];

  // helpers
  O.by = function (s) { return O.board.filter(function (b) { return b.status === s; }); };
  O.esc = function (s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (c) { return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]; }); };
  O.provText = function (p) { return p === 'merged' ? 'merged' : p === 'event' ? 'event' : 'in flight - ' + p; };
  O.counts = function () {
    var c = {}; O.statuses.forEach(function (s) { c[s] = O.by(s).length; }); return c;
  };

  window.OBEYA = O;
})();
