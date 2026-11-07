# Result: product-owner — 64
Status: done
Abnormality: none
Progress:
  Done: requirement written and committed (docs/requirements/64-board-as-run-state.md, 46 acceptance criteria in six parts)
  Next: none
Summary:
  One requirement for the whole of map #50: A board as status (AC-1 to 8), B role tasks as sub-issues (AC-9 to 19), C hansei fields and the three sections leaving (AC-20 to 26), D parallel slices (AC-27 to 33), E migration (AC-34 to 43), F release 2.0.0 (AC-44 to 46).
  All seven Under test lines of #64 map to criteria; six items are listed Unverified; every live-Project check has an offline twin on a fake gh.
  Scope section lists plugin paths per role. No one-way door found; ten two-way decisions below.
  Needs the lead's eye before the architect stage: the stage-log readers and the not-captured field type (Open questions).
Artifacts: docs/requirements/64-board-as-run-state.md
Decisions:
  1. Role set only on role-task cards / also on slices (duplicates the Running role task) / one rule.
  2. A Waiting-on-you card always gets a what-to-do comment / status alone / one rule.
  3. A second slice may be required and designed before its path list exists, no build role until compared / nothing before, or check at QA / one rule; architect may move the check point.
  4. In flight for the limit = item branch and Running, Waiting on you or Blocked / Running only / one rule.
  5. First-line marker on each role-task sub-issue to find it after a resume / title match / one rule.
  6. Limit error: one retry after the stated wait, then stop and Waiting on you / unbounded retry, pre-counting / one rule.
  7. Migration keeps the first snapshot, later ones under a new name / overwrite / one rule.
  8. Findings, Abnormalities, Label stay in the lead state (brief names only three sections to leave) / move them too / one rule.
  9. Major bump 2.0.0 as the person settled.
  10. Every live-Project criterion has an offline twin plus a Human-only or Unverified mark.
Open questions:
  - Architect: the stage log is read by andon kind 4, the cut-off scan, requirement 60's gemba sample rule and four hansei measures; each needs a new source once the sections leave. If one cannot be replaced without losing a measure, the lead must hear it before the build.
  - Architect: Number fields cannot hold `not captured (<reason>)` and the honesty rule (fenced F7) forbids a blank; pick a field type. If none meets F7, question to the lead.
  - Architect: where person touches and waits are recorded now; Paths block place and check point of AC-30; setting format; whether wayfinding is bumped; check-bump.sh and a major bump.
  - QA: fake gh fixtures. Docs-writer: README, runbook, changelog text. Lead: the scratch Project try after the build.
