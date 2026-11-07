# Result: product-owner — 60
Status: done
Progress:
  Done: requirement written and committed (7529e01, "#60 product-owner: requirement 60 gemba sample (10 ACs)")
  Next: none; the architect takes the open questions below
Summary: docs/requirements/60-gemba-sample.md has 10 ACs, all testable offline (no human-only AC). Sample rule: eligible role rows (Result done/pass, not paused by an andon), index = slice number mod count; replayable on W12 (hansei.md worked example), C49 and L57 (real manual stage logs). The Lead reads the transcript, else commits and result file, never the Summary; it compares with the brief (Done, Constraints, Output) and the stage-log row. One `gemba` header line in a v5 record, after `stage-log cross-check`, not a measure; a walk that cannot be done reads `not captured`. A difference goes to the 5 Whys through the existing rule, which is not restated. Cap is 30,000 characters per walk, enforced by the read command, with `partial` when it stops. No eighth measure, no hoshin view, no aggregation. Release 1.3.0. All four Under test lines map to ACs; live-only items are listed as Unverified.
Artifacts: docs/requirements/60-gemba-sample.md
Decisions:
  1. Sample = eligible row at index (ticket number mod n) / rejected: longest row, rotation by previous sample, most findings, random / undo: change one rule.
  2. Eligible = done or pass, not paused by andon / rejected: all rows / undo: one rule.
  3. Evidence order transcript, then commits and result file; Summary never evidence / rejected: commits only / undo: one rule.
  4. Compare with the brief and the stage-log row for three named things / rejected: open "look for anything" / undo: one rule.
  5. `found nothing` carries its counts; partial walks say `partial` / rejected: bare "found nothing" / undo: one grammar line.
  6. Cap 30,000 characters, enforced by the read command / rejected: no cap, a token cap / undo: change one number (a guess, tuned by feedback).
  7. Line is a header line in schema v5 / rejected: a field inside v4 (breaks the standard's own versioning rule), an eighth measure / undo: a v6 moves or drops it.
  8. A difference always goes to a 5 Whys before the record is posted / rejected: only serious ones, or after posting / undo: one rule.
  9. Walk runs after the merge approval, so in no measure / rejected: before approval / undo: move one step.
  10. No gemba line for #60 itself (frozen install, calibration) / undo: none needed.
  No one-way door found; none needs a decision card.
Open questions:
  - Architect: exact grammar of the gemba line; place and number of the walk step in step 8; where the 5 Whys of a difference is written (leaning: kind 7 andon with no paused agent; alternative: a comment of its own); whether a kind 7 andon raised at close, after approval, fits the andon's timing rules; the bounded read command and filter (leaning: text in hansei.md, no script, so only the standard fingerprint moves); baseline.md section 3 and the hansei.md "versions read" text updated to v3, v4, v5; add Gemba to CONTEXT.md.
  - QA: fixtures for AC-1 to AC-7; independent expected rows for W12, C49, L57 before the replay. The author's cross-check (not a substitute): W12 picks row 2, C49 picks row 8.
  - Docs-writer: changelog unverified list (AC-10), README text.
  - Lead: none.
Missing: none
