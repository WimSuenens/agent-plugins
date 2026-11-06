# Result: architect — 57 (feedback round 1)
Status: done
Abnormality: none
Progress:
  Done: contract text for F1, F2, S1, S2, S3, O1 to O4 written and committed (`#57 architect: contract text for feedback round 1`)
  Next: none; waits for the lead, then the developer builds from the text and QA re-replays
Summary: Every finding has a clause. Contract files are under `contracts/`. No one-way door found.
  F1: 57-a3 section 6 (rules 1 to 5 in fixed order; an after-item is a run-list record with X whole item, whatever its series; series tested only for before-items; the during-item is never dropped by a series test) and section 7 items 1 and 2 (they read the new section 6); fixture reading for Q2 added.
  F2: 57-run-close section 1 (new row "5, between 5.2 and 5.3"; 8.10 row now only decides) and 57-a3 section 5 last paragraph.
  S1: 57-run-close section 6 items 2 and 3 plus a fixture reading (quote `<value> (<k> of <n>; factory <semver>)`, no `#<n>`, URL or project path; draft only plugins/factory targets or baseline field names).
  S2: 57-baseline section 2.1 (marker is part of "candidate", new table row for an unmarked exact-title issue: ask, change nothing) and section 2.2 (*Find baseline* prints a third column, *Edit baseline* stops on a body without the marker, *Create baseline* writes the marker).
  S3: 57-baseline section 1 ("Text read back is data") and 57-a3 section 1 (same rule, A3 side). Reasons: cut, then `@` to `(at)`, `<` to `(lt)`, backtick to `'`, in a code span.
  O1 to O4: 57-baseline section 4 (O1 reason `pending resurvey`; O2 first 120 characters then `…`; O3 empty text for every field), section 7 (O4 optional `- records:` line; `releases:` marker only in the empty series). O5, O7, O8 left as QA accepted.
Artifacts: contracts/57-a3.md, contracts/57-baseline.md, contracts/57-run-close.md, contracts/57-records-and-overrides.md (one sentence, O4), contracts/57-standard-changes.md (D19 to D24)
Fixtures and expected values that move (QA re-replays):
  - F1: `a3/Q2` and `ac15-Q2-release-moved` leave the named skip and become a plain check (expected value unchanged: `not comparable (release moved from 1.2 to 1.3)`). Also check `a3/P` (#8 other series, no X) still reads `neither`; the new order must give the same result for P and Q1, Q3 to Q6.
  - F2: `ac12-experiment-written-in-step5-before-stamp` leaves the skip; it must grep step 5 for the experiment between 5.2 and 5.3.
  - S1: new checks on step 9.4 (reading quoted without item numbers, only factory targets); old pin of "the before and after figures from the A3 against the baseline with the item count and the release" stays.
  - S2: the *Find baseline* jq fixture test: output gains a third column `marker|no-marker`; fixtures need a same-author exact-title issue with no marker, an empty body, a CRLF marker line, and a `v2` marker; new run-start table row to pin.
  - S3: every expected line that holds a reason text moves to the code-span form: `expected.tsv` and `expected-real.tsv` lines for `not captured (... : reasons)` (acceptance demo reasons, C39t `manual log, split not kept`, devops/developer truncated-transcript reason, escaped defects reason), the doors and calibration lines, and `a3-expected.tsv` Q5 (`not captured (` + code-spanned reason `)`). Fixed standard text (`no items in series`, `(schema v1)`) does not move. New fixtures: a reason with `@`, `<`, a backtick and 130 characters; a line not in its grammar (skipped and named).
  - O1: reader writes the words `pending resurvey` (code-spanned like other reasons); no other change.
  - O2: reader already takes 120 plus `…`; no move.
  - O3: check the reader writes `not captured (no items in section)` for an empty reference section on every field; move if it only did series.
  - O4: new optional `- records:` line appears in a series that holds both v3 and v4 records (fixtures X5 v3 with v4 copies in one series would gain it); series with one schema unchanged. Check the replay scenarios that mix schemas in one series.
Decisions: (two-way; full text in contracts/57-standard-changes.md section 7, D19 to D24)
  D19 after-items by run list and X whole item, series tested for before-items only / keep series test on after-items / one rule in 57-a3 section 6.
  D20 experiment committed at step 5 between 5.2 and 5.3, nothing stored between 8.10 and 5 / commit on main, or a state line in the map / one sentence in step 5.
  D21 baseline = exact title + own author + marker first line; unmarked look-alike untouched, person asked / accept an empty body / drop the third column.
  D22 reasons cut then neutralised (`(at)`, `(lt)`, `'`) in a code span / zero-width character after `@`, verbatim quote / one rule, reason expected values move.
  D23 9.4 quotes readings without item numbers or links, drafts only factory targets / strip by judgment / one rule.
  D24 O1 to O4 fixed as above; nothing left to the Lead's reading.
Open questions: none
