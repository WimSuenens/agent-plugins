# Result: product-owner — 57
Status: done
Progress:
  Done: requirement amended and committed (`#57 product-owner: align acceptance criteria with the contracts`)
  Next: none; waits for the lead
Summary: Every listed criterion now reads as the contracts do. I adopted the architect's reading in each case; no disagreement.
Changes, one line each (docs/requirements/57-per-run-a3-and-baseline.md):
- AC-3: doors counted per Under test line (need not sum to n); first-pass yield not-captured spelled `not captured <m> (<m> of <n> items: …)`; demo expected values updated (`acceptance demo not captured 1 (1 of 1 items: …)`, `… not captured 2 (2 of 2 items: …)`).
- AC-7: the records-read count and minutes go in the map's Factory run section, not the stage log (removed at 8.6).
- AC-11: measure branch lists ratios above 1, counts the rest in one entry; rule ends in `none chosen (<reason>)`; contradiction is a silent none.
- AC-12: `experiment: none (…)` is the A3's `countermeasure:` line.
- AC-13: same, `countermeasure:` line reads `none (needs a plugin change)`.
- AC-16: lines `other overrides` and `baseline` added to the list; marker is the body's first line.
- AC-20: "first line" means the first field line; a stopped run's `run:` line says `run stopped`.
- AC-26: names the one outside path `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` with its reason.
- Touched for consistency: Decisions item 10 (stage log became the Factory run section). Under test table and demo script needed no change.
Artifacts: docs/requirements/57-per-run-a3-and-baseline.md
Decisions: none
Open questions: none. Note for the lead: the contract also adds one bullet to references/protocol.md (settle worktree); AC-26 already allows any file in references/, so no requirement change.
