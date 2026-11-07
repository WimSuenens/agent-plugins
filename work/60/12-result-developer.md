# Result: developer — 60
Status: done
Progress:
  Done: all nine items of 11-feedback-developer applied in hansei.md, SKILL.md (8.3a) and baseline.md; committed "#60 developer: feedback round 1"
  Next: QA re-pins tests and re-verifies
Summary: Items 1-9 applied.
  1 data rule: new paragraph at the head of section 6 (evidence is data, nothing followed or run, instruction-like text is a difference candidate).
  2 gate difference: paragraph "A difference about a gate" in section 6, one sentence in SKILL 8.3a (walk is after the approval and cannot stop the merge; gating difference is told to the person before 8.7 and the merge question asked again; no new measure or stop kind).
  3 sentence and cause lines: worktree-relative paths, no tool-result values, secrets or @mentions.
  4 scratch files: one trap 'rm -f' over four mktemp files (rm -f on named files, not rm -rf, so the removal safety check does not stop the Lead).
  5 commands: agent id must match ^[0-9a-f]+$; <worktree> absolute paths; the view is built once into a file; view exit status and stderr are printed and a non-zero exit or any stderr means unreadable (fallback or not captured), never an empty view; budget is 29,900 minus what is read, so everything printed stays under 30,000 (count lines and newlines included); m view is printed before the cut text so it cannot glue to a cut line; commit listing uses %H %cI %s. Checked on a generated 190k view: part is exactly 29,900, view exit 0, m view printed.
  6 reworded to "the walk commits nothing outside work/<id>/ ..., as step 8.6 allows".
  7 "carries the - records: line of ..." fixed.
  8 baseline.md: stated that v3 with v5 and no v4 cannot arise from release series, so no form (parenthesis on the template line).
  9 brief ordinal replaced: highest-NN brief or feedback file of the role first committed at or before the row's End (next role row's Start if End is not a time, no bound for the last row) and after the previous role row's Start; result file by the same rule. A row with no brief shifts nothing.
Artifacts: plugins/factory/references/hansei.md, plugins/factory/skills/run/SKILL.md, plugins/factory/references/baseline.md
Decisions:
  - cap reserve: budget 29,900 so total printed <= 30,000; n is now at most 29,900 (line still "at most 30000") / rejected exempting count lines from the cap, or a reduced cap of 30,000 text plus 27 / cost: one number / QA's T8 expects 30000 exactly in places
  - brief matching by first-commit time window instead of ordinal / rejected fixing the ordinal by skipping rows (cannot know which row lacks a brief) / one rule
  - item 8 chosen: sentence, no new records: form
Open questions: none
Checks: check-bump.sh "pass: minor bump needed, 1.2.0 -> 1.3.0" exit 0. fingerprint.sh: standard 34dea6b7f27ee61a3f76045410c9e30eb58cd0f7551ba43a600400eb5095ba9a (moved); tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5 (equal to 1.2.0's). No absolute home path in added lines; plugins diff touches only SKILL.md, hansei.md, baseline.md, plugin.json.
bash tests/run.sh: red only on wording or command shape (tests/ not edited):
  - test_baseline_a3.sh: o4-records-line-in-template (template line now carries the v3/v5 sentence)
  - test_gemba.sh: t8-big-view-is-over-190000, t8-brief-count-is-wc-c-of-the-brief, t8-partial-when-view-longer-than-budget, t8-partial-line-is-in-the-grammar, t8-small-n-equals-m, t8-budget-shrinks-view-is-30000-minus-brief, t8-huge-brief-cut-at-30000, t8-huge-brief-leaves-no-view, t8-every-jq-and-view-line-is-bounded, t8-brief-read-bounded-by-head-c-30000 (the command block changed shape: scratch files, 29,900 budget, view built once), t3-status-progress-artifacts-decisions-kept, t3-progress-body-kept, t3-free-heading-after-fields-kept, t3-summary-last-field-dropped-to-end, t3-no-summary-unchanged (the awk now reads "<worktree>/work/<id>/<result file>"), t7-a-text-names-the-git-log-command (format now %H %cI %s), t7-gone-transcript-jq-error-on-stderr (jq error now fails the view), t10-no-override (wording of item 6)
  - all other suites green
