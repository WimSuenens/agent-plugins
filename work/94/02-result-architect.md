# Result: architect — 94
Status: done
Abnormality: none
Progress:
  Done: brief verified (author WimSuenens, marker architect 1); contracts/94-a3-v2.md, contracts/94-hansei-lean.md, contracts/94-release.md written; paths.sh list passes on all three and `check` flags an off-list name as it should.
  Next: nothing; the lead compares path lists, decides on code review and briefs QA.
Summary: Three contracts, no ADR. 94-a3-v2: v2 template (waste and gemba (targeted) after evidence, target after change), grammars, reason tables, targeted walk at step 9.2, settle line, new script scripts/a3-check.sh (the 2.2.0 "check" was prose only; no script existed), v1 never rewritten. 94-hansei-lean: waste token in four places, flow efficiency (half-up integer rule) and a per-stage minute rule with worked examples (#12, #73 figures, overlap case); two sub-lines under measure 1, marker stays v5. 94-release: 2.3.0 confirmed, both fingerprints move (scripts/ is tooling), changelog shape, repo-wide search table, pins QA must change, criterion map for all 19.
Artifacts: contracts/94-a3-v2.md, contracts/94-hansei-lean.md, contracts/94-release.md
Decisions:
  - Open Q1: waste tags are read from andon comments (new optional last line), ledger Waits `What` and Tasks `Notes` tokens; `## Findings` gets an optional Waste column but the A3 never reads it (work/ is gone at merge), the tag is copied to Tasks Notes / chosen: yes / rejected: reading the lead state from git history, a new ledger column / cost to undo: one edit of the standard.
  - Open Q2: per-stage = first covering row in table order, else next-starting row, else pseudo-stage `Merge approval`; working and waiting counted by minute so both sums equal measure 1 exactly / rejected: assigning waits by id through the Waits column (cannot place the merge wait, double counts overlaps), row-level working sums (break with parallel rows) / cost: one edit.
  - Open Q3: v2 order is waste, gemba (targeted) after evidence; target after change / rejected: all three at the end, target next to measure targeted / cost: one edit plus fixtures.
  - Open Q4: reason tables in 94-a3-v2 section 4; target and gemba have extra reasons; the six old rows and their pins stay.
  - Open Q5: the settle line lives in SKILL.md Settle round item 1 only; step 9.3 and Run start point to it.
  - Two sub-lines on the record without a v6: no reader reads them; reopened by #92 / rejected: v6 now (breaks 2.2.0 readers for nothing) / cost: a later bump.
  - Targeted walk runs at step 9.2 (not at the andon), has no `changes` part, raises no andon, its fallback reads main; pending v2 A3 rewrite copies the posted line / rejected: walk at each andon / cost: one edit.
  - Settle line shows the override's own target figure (the A3 target line says none when readings are unusable) / rejected: A3-only figure, which would print `target none` for a set target.
  - a3-check.sh as a script (bash 3.2, exit 0/1/2/3) so AC-1, 2, 15, 16 are testable / rejected: prose check with pins only / cost: delete the script.
  - Targeted line adds an item prefix (`item #<id> row <#> …`) to the sample walk's grammar because row numbers repeat across items.
Open questions: none for the person. For the lead, two points to look at: (1) AC-11 as written makes the A3 `target` line `none (<reason>)` when the after reading is unusable, which hides a set target in the A3; I followed the AC and show the target in the settle line from the override. (2) AC-4 names an andon comment as taggable; the comment is posted once and never edited, so the tag is a last optional line written at posting.
Missing: none
Decision card: none
