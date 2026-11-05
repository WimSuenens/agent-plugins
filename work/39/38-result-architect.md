# Result: architect — 39
Status: done
Progress:
  Done: start (e69e80e); wait kinds, done-then-stopped in 39-stage-log (f235c8d); record v2, FPY, truncated spend, close order in 39-hansei-record (eb492fd); token-spend --require-end in 39-plugin-scripts (7974ca6); Interruptions and step 8 in 39-standard-changes (272b580); result (this commit)
  Next: none
Summary:
  1 (#44) 39-stage-log §3: four wait kinds (person, limits, stalled, interrupted) in a table with detection, start and end for each; new `Agent` column in `## Waits`. stalled = watchdog/no-progress notice, or the Lead stopped mid-step and restarted only by an unprompted person message; interrupted = server/connection error notice, or a gap containing a sleep in `pmset -g log`. Start of both = the stopped transcript's last entry timestamp (recorded clock, no `~`). Measure 1 now: total; agent working; person; limits; stalled; interrupted, held waits only, cross-kind overlaps counted to the first kind in line order, so the five parts add to total.
  2 (#44) Measure 5: spend reads `not captured (transcript truncated by <kind>)` when a stalled/interrupted wait names one of the role's agents (signal a), or `token-spend.sh --require-end` exits 6 (signal b, kind `unlogged`). --require-end = no `[Request interrupted` user entry and the file ends on a final reply (assistant entry without tool_use, or the SubagentHandback tool result). Lead's own transcript: signal a only.
  3 (#45) 39-stage-log §3 *Done, then stopped*: done result complete + its commits on item/<id> + role paths clean → accepted after the Done-list check, no resume, wait logged as its kind, Notes `done, then <kind>`.
  4 (#46) Pass first time = first verdict pass and no finding at or above minor (below minor: low/info/trivial/note; missing severity counts as at or above). Wording `pass first time (<n> low)`.
  5 (#47) Close step 6: `git add -A work/<id>` + commit `#<id> lead: close` when staged, then `git rm -r -q work/<id>`, `rm -rf` for ignored leftovers, commit. Record still posted at step 4, before both.
  Schema bumped to v2: measure 1 grammar and `agent working`'s meaning changed, and <fpy> grammar changed. Worked examples (#12 stage log and record, #39 header) updated to v2 with an interrupted, a stalled-after-done wait and a 2-low pass.
Artifacts: contracts/39-stage-log.md, contracts/39-hansei-record.md, contracts/39-plugin-scripts.md, contracts/39-standard-changes.md
Decisions:
  - Schema v2, not v1 / rejected: keep v1 since 1.0.0 is untagged / cost to undo: marker string in hansei.md and tests; but v1 already exists on factory-sandbox #2 with the old agent-working meaning, so v1 would name two meanings.
  - Measure 1 keys `stalled <dur>; interrupted <dur>` (wait kind names) / rejected: `waiting on interruptions` as one part (#44's text) / cost to undo: one line in hansei.md and tests.
  - Cross-kind overlap goes to the first kind in measure 1's order (person, limits, stalled, interrupted) / rejected: split proportionally, or interrupted first / cost to undo: one sentence.
  - Watchdog notice with a sleep in the gap is `interrupted` (pmset evidence); notice alone decides without pmset / rejected: notice alone always / cost to undo: one sentence.
  - stalled/interrupted start from the transcript's last entry timestamp, not the notice time / rejected: notice time (overstates agent working by the 600s watchdog window) / cost to undo: one table cell.
  - `Agent` column added to `## Waits` / rejected: agent id in free-text What / cost to undo: one column; measure 5 needs it machine-readable.
  - Truncation detected mechanically by `token-spend.sh --require-end` (exit 6) as a second signal / rejected: Lead's own judgement or a jq one-liner in hansei.md / cost to undo: one option and one exit code in a tooling script (patch level). Kind `unlogged` when only the script sees it.
  - Truncated Lead transcript: Lead's peak also `not captured` / rejected: report peak over the remaining messages / cost to undo: one clause.
  - Below-minor severities = low, info, trivial, note; missing severity fails closed / rejected: verdict alone (#46 option 1) / cost to undo: one table cell.
  - No measure-3 count of non-blocking findings routed as feedback (#46's optional part) / rejected: add it now / cost to undo: a v3 field later.
  - Close: commit lead state then plain `git rm -r` + `rm -rf` for ignored leftovers / rejected: `git rm -rf` without the commit (#47 option 1, loses uncommitted close rows from history) / cost to undo: two commands.
Open questions:
  - For the product-owner (docs/requirements/39-hansei-record.md): line 124 (measure 1 split) should read "agent working / waiting for the person / waiting on limits / stalled / interrupted"; line 125 (FPY) should add "pass first time (<n> low)" and define pass by "no finding at or above minor"; line 111's `hansei v1` example → `v2`. Line 91 (stage log) could add "stalls and interruptions" next to limits.
  - For the developer: hansei.md template and examples, run/SKILL.md Interruptions and step 8, token-spend.sh --require-end/exit 6, and tests asserting the `v1` marker (tests/factory/test_standard_text.sh ac14-*) move to v2.
  - Lesson for docs: CHANGELOG 1.0.0 should say the record is schema v2 (v1 appeared only in the demo).
