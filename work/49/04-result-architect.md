# Result: architect — 49
Status: done
Abnormality: none
Progress:
  Done: five contracts written and committed, each with a worked example (contracts/49-abnormality-list.md, 49-andon-process.md, 49-overrides.md, 49-records.md, 49-standard-changes.md); AC-1..AC-30 mapped in 49-standard-changes.md section 7; no ADR needed
  Next: none; the lead routes the proposals to the other owners and briefs the developer
Summary: Detection rules for "same finding twice" (five-slot signature, clauses M1 and M2, replay table spec for QA), "role outside its role" (ownership table, longest match, section rows skipped) and "slow stage" (median of earlier same-role rows, strictly more than 2x, waits excluded) are written before code, each with a worked example QA can replay. Also fixed: the 5 Whys rule with refusal tests, the andon pause/resume procedure, the andon comment (marker `factory:andon v1`), the override format and status grammar, the seven-question fence check with ten fixture overrides, run identity (the map number), the run-close step 10 with a settle round, the `andon` wait kind (five kinds) and hansei schema v3, release 1.1.0. No one-way door found, so no ADR and no question.
Artifacts: contracts/49-abnormality-list.md, contracts/49-andon-process.md, contracts/49-overrides.md, contracts/49-records.md, contracts/49-standard-changes.md
Decisions:
  1. Release 1.1.0 (minor) / rejected major (additive, optional line, versioned marker) and patch / undo: change a string before the tag
  2. Run = one map, id `#<map>`; `kept ... for next run` binds at the run's first worktree / rejected dates, a counter in the file, binding at keep time / undo: status grammar change
  3. Overrides written in the worktree that raised the andon; run close edits the file in a settle worktree with one PR (`settle/<map>`) / rejected main checkout, direct commit to main, close inside the last item / cost: one extra merge approval at a run close with overrides / undo: change step 10
  4. Run close is step 10, after step 9 / rejected renumbering (the requirement cites "step 9") / undo: move a paragraph
  5. `Abnormality:` directly after `Status:`, optional, repeatable, number or name, ` — ` separators / rejected after Decisions and one-per-result / undo: one template line
  6. Kind 2 as a signature of five slots with clauses M1 (same guard and same file or trigger) and M2 (same criterion and field in a later round), `unclear` when a slot is missing / rejected free judgment, file-only and word-only matching / undo: one rule
  7. Kind 3 reads the ownership table, longest matching token, `section` rows skipped; known limit: an edit of the `## Overrides` section by a non-Lead is not visible to it / rejected a hard-coded path list / undo: one rule
  8. Fence check is seven questions of the override's effect, one yes or any doubt refuses / rejected wording matches and accept-on-doubt / undo: the question table
  9. Andon comment marker v1, posted once after the resume, never edited; override written first with `andon: pending`, linked in a second commit / rejected editing later / undo: bump to v2
  10. `andon` wait ranks last in the overlap order; a close-scan line touching an andon wait is that wait; a TaskStop marks the stopped transcript truncated (spend `not captured (transcript truncated by andon)`) / rejected counting the stop as `stalled` or the spend as complete / undo: a table row
  11. Kind 6(a) compares with the latest earlier hansei record of the same release in the project; the first item on a release says so / rejected a table of released fingerprints, the tag's tree / undo: one rule
  12. No new script; rules are text the Lead follows / rejected helpers (tooling fingerprint would move) / undo: add one script
  No overturn of the product-owner's eight decisions.
Open questions: none for me. For the lead:
  - docs-writer (this repo): add the ownership row `| `docs/agents/factory.md` section `## Overrides` | lead |` to docs/agents/factory.md; README, CHANGELOG 1.1.0, docs/factory/reference.md rows for the new contracts.
  - devops: release-runbook entry for 1.1.0 (tag `factory-v1.1.0` from the existing merge-step text; #49 runs frozen, so the Lead tags by hand as for #39) and the fingerprints to note.
  - developer: plugins/factory (protocol.md, run/SKILL.md, hansei.md, setup-factory-skill row, plugin.json 1.1.0) per contracts/49-standard-changes.md; QA: fixtures and the AC-3 replay table per contracts/49-abnormality-list.md section 4.5, with the architect not involved.
  - person (stage summary): overrides are written in the item worktree and land on main with the merge; the run close needs one extra PR and merge approval when overrides exist.
Missing: none
