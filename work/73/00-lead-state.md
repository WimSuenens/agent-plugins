# Lead state: #73

- board item id: PVTI_lAHOBIbaa84BqOBFzhHDFJY
- next step: 8.7 merge PR 80, tag factory-v2.1.0, then resurvey (approved 2026-11-09T06:30Z)
- code review: yes — trigger: shared protocols (protocol.md and run skill state rules change)
- open questions: none
- frozen on: factory 2.0.0
- ADR number: none
- Running agents: none
- Shared resources: none (no real infrastructure; nothing live to fake)
- Interrupted: none

## Label

- plugin root: ~/Projects/portfolio/agent-plugins/plugins/factory (the repo checkout; the run skill was read from here)
- release: 2.0.0
- standard: 4bb4220e38b793e9a2df0bebb7da9041e94f8f2a1a7f855acd5b4f5b7273e9d0
- tooling: 92746e5d526aeaebcbd1ab94af461c973d1bd417265eb71e940db31b36da324a
- overrides at start: none
- wayfinding: bb9268f0245b (skill base dir)
- mattpocock-skills: not captured (not read at start)
- lead sessions: 0f5a2e66-a4fa-457d-897e-77ac147186f3

## Findings

| Role | Round | Id | Severity | Text |
|---|---|---|---|---|
| architect | 1 | L1 | medium | the three contract files were in no Paths block; fixed in rework #78 |
| developer | 1 | L2 | medium | four text fixes from the optional code review; fixed in rework #79 |
| qa-engineer | 1 | F1 | medium | the Done-list path check names the item's own review files as off-list; QA test now ignores them; the standard gap is open for the feedback offer |

## Abnormalities

| Id | Kind | Seen | Where | Paused | Resumed | Comment |
|---|---|---|---|---|---|---|

## Run notes (pilot)

- Pilot measure: test-to-green time and QA/developer rework rounds. Comparison: release 1.3.0, one item (#64): QA 3 passes, developer 2 feedback briefs (baseline #62).
- Evidence on 2.0.0 (not fixed here): the `factory:run` skill was not loadable as a skill in this session; the lead read it from the repo checkout. FREEZE compares against the last segment of the plugin root, which here is `factory` (see #71, out of scope).

- Evidence (2.0.0, not fixed): adding a new role-task card to the board once failed with "Content already exists" (project auto-add likely raced the add); a retry worked.
