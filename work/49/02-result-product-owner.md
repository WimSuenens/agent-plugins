# Result: product-owner — 49
Status: done
Progress:
  Done: inputs read; requirement written (30 criteria, AC-1 to AC-30); committed
  Next: none; the lead reads the result and routes the open questions
Summary: docs/requirements/49-andon.md holds the user outcome, 30 Given/When/Then criteria in seven groups (raise, pause/resume, 5 Whys, countermeasure and fence, records, expiry, release), an Under-test-to-criteria table, the out-of-scope list (all of Deliberately faked) and eight decisions. Every Under-test line of #49 maps to criteria. The "same finding twice" rule (AC-3) is validated by QA or the developer on the five abnormalities of #39 plus at least five control pairs, with the contract text fixed before code. The 5 Whys rule (AC-12 to AC-14) refuses a chain that ends in a model or role swap before the process is examined. No one-way door found, so no decision card.
Artifacts: docs/requirements/49-andon.md
Decisions:
  1. 2x test: median agent-working time of the same role's earlier rows in the item, needs 3 earlier rows, strictly more than 2x, waits excluded; fewer rows reads "no baseline" / rejected wall-clock, fixed minutes, dropping the test / undo: one rule, minutes
  2. Free-form kind `other` on the list / rejected closed list (two of #39's abnormalities fit no kind) / undo: drop one entry
  3. Pause time is its own wait kind `andon` and a sixth lead-time part, record moves to schema v3 / rejected counting it as agent working or interrupted / undo: template change plus schema bump, no 1.0.0 baseline exists yet
  4. Override beats plugin text outside the fence; later of two disagreeing overrides wins; fence wins always / rejected plugin-wins, andon on every clash / undo: one rule
  5. Seeded abnormalities count in the demo for human-only criteria / rejected waiting for spontaneous ones / undo: none, the resurvey reads real records
  6. List includes ADR 0012's two version-drift entries / rejected leaving them to a later slice / undo: drop two entries
  7. A crossing override found at run start is not applied and the person is told, not auto-removed / undo: one rule
  8. `promote` ends the expiry and leaves the override active until the card is decided / rejected dropping it on promote / undo: one rule
Open questions:
  - Architect: override format, `## Overrides` section, abnormality-list and `Abnormality:` layout, andon comment marker, run identity, fence-list placement, written rules for kinds 2 and 3 before code, run-close step placement, stage-log wait kinds four to five
  - Architect/Lead: docs/agents/factory.md is docs-writer's in the ownership table but the Lead writes overrides there; needs an ownership row, and a choice between writing in the item worktree (lands on main with the merge) and the main checkout
  - Lead with the person: sandbox project for the human-only criteria (AC-7, 9, 10, 14, 20, 25, 28); the person stops the agent from the UI in AC-10
  - Lead: who tags the release (AC-30)
Missing: none
