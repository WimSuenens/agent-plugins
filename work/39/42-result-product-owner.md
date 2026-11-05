# Result: product-owner — 39
Status: done
Progress:
  Done: feedback 41 applied to docs/requirements/39-hansei-record.md (3b2d8e2); result (this commit)
  Next: none
Summary:
  AC-11 (stage log): adds the time lost to stalls and interruptions, each its own wait kind naming the agent it hit.
  AC-14 (marker): `hansei v2`; v1 only in the demo record, not what 1.0.0 writes.
  AC-15 measure 1: split is agent working / person / limits / stalled / interrupted, the five adding to total.
  AC-15 measure 2: pass first time = first verdict pass and no finding at or above minor (missing severity counts as at or above); `pass first time (<n> low)` for <n> ≥ 1 below-minor findings (low, info, trivial, note).
  AC-15 measure 5: spend reads `not captured (transcript truncated by <kind>)` for a cut transcript.
  AC-17: status note: failed at the demo (factory-sandbox #2, v1; issues #44–#47); re-judged on QA's word after the fix against the v2 template and fixtures, unless QA demands a demo re-run (the person's rule).
  Re-verify: Under test mapping unchanged and complete: ADR 0012 → AC-2, 3, 5, 8, 9; Capture → AC-12, 18, 22; Measures → AC-15, 17, 22; Honesty rule → AC-16; What reaches agent-plugins → AC-20.
Artifacts: docs/requirements/39-hansei-record.md
Decisions:
  - Measure 5 row names the truncated-spend wording (not in brief 41, follows contract 39-hansei-record §4) / rejected: leave measure 5 as before, so QA would have no requirement line for the AC-17 token fix / undo: one table cell, minutes.
  - AC-17 note cites factory-sandbox #2 and issues #44–#47, not work/39/00-lead-state.md (work/ is removed before merge) / rejected: cite the lead state / undo: one line.
Open questions: none new (earlier ones stand as written in the requirement).
