# Result: product-owner — 73
Status: done
Abnormality: none
Progress:
  Done: brief checked (author WimSuenens, marker ok); requirement written and committed.
  Next: none
Summary: Requirement for slice #73 written with nine acceptance criteria. Covered: the three Under test lines (AC-1/2/9 for ownership and whose test to change, AC-4 for optional review triggers, AC-3 for test scope), the five Done-when points (AC-1 to AC-5, with AC-6 for the file list and #42's Standard change), the gates-not-weakened check (AC-7, against baseline 4086c9c) and the fenced items (AC-8). Each AC splits into a machine-checkable part and a stated scenario with human review; no broad exact-prose assertions are asked. No one-way door found. This repo's docs/agents/factory.md needs no change; docs/factory/reference.md is optional for docs-writer.
Artifacts: docs/requirements/73-test-ownership-and-tdd-loop.md
Decisions:
  - Where the developer's own tests live: chosen = developer-owned, in the developer's own path (src/ row), not the acceptance suite, QA owns tests/; rejected = developer may write in tests/ during Build with QA taking over at verification; cost to undo = one markdown edit in the template and developer file. #42 left this open between two options. Architect may confirm.
  - Harness-as-deliverable: QA writes the harness and first cases in tests/ (follows from #42 ownership); cost to undo = one text edit.
  - AC-3 lets instruction-following criteria map to a scenario or Human-only entry rather than a test; cost to undo = one edit of the QA Done line.
  - Risk triggers named as in #42 (three); decision recorded in lead state or stage summary; cost to undo = one edit.
Open questions:
  - Architect: confirm the developer's own-test location (AC-6) fits the contracts' Paths blocks.
  - Lead: the existing script test tests/factory/test_standard_text.sh may pin baseline wording the build changes (for example the developer Done line); QA decides which tests update.
Missing: none
