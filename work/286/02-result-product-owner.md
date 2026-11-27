# Result: product-owner — 286
Status: done
Abnormality: none
Progress:
  Done: brief checked (author WimSuenens, marker product-owner 1); requirement written with ACs per Under test line, known-answer fixture, out of scope and open questions; role file consolidated
  Next: none (lead reads this result; Q1 to the lead, Q2 to Q5 into the architect brief)
Summary:
- Requirement `docs/requirements/286-run-level-timing.md`: 15 ACs in groups A (ADR 0024), B (ADR 0025), C (ADR 0026); each Under test clause maps to a tagged AC.
- AC-B6 is a known-answer fixture (two items, overlapping held waits, an andon, a not-held wait, two Run waits rows) with the hand count and two one-field controls.
- ACs are tagged [fixture], [runtime-proof] or [post-merge] so QA can sort them.
- The before-reading (AC-C6) is [post-merge]: the run in flight is frozen on 3.9.x and posts a v3 A3, so it cannot be it (Q1 to the lead).
- Four questions for the architect (Q2 to Q5): in-flight instants, Lead gaps during an item, the source of the Runs guardrails, script or procedure for the computation.
- No one-way door found; no decision card. `docs/direction.md` unchanged (Destination unchanged).
Artifacts: docs/requirements/286-run-level-timing.md
Decisions:
- A section with no `started:` closes with `run timing: not captured (run section has no started: line)` and is named, not counted, in Runs / rejected: writing `started:` at resume time (understates raw) / cost to undo: one AC and one contract line.
- `run compared` beyond `none (…)` is out of acceptance here (grammar only in a3-check) / rejected: testing medians and `not comparable` now / cost to undo: add fixture ACs in the next slice.
- A3 v4's four lines go after `calibration experiments` when that line is present / rejected: between `not detectable` and `calibration experiments` / cost to undo: one contract line and the a3-check order rule.
Open questions:
- Q1 (lead): which run is the before-reading; leaning the first run started on the released version, with the sandbox runtime proof as "the run this slice is proven on".
- Q2 (architect): the two instants that bound an item in flight.
- Q3 (architect): where a Lead gap during an item in flight is recorded, so no minute lands twice.
- Q4 (architect): Runs guardrails from the A3's `guardrails` line (leaning) or from the hansei records.
- Q5 (architect): run-close computation as a script (leaning) or a procedure in the text.
Missing: none
