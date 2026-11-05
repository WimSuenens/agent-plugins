# Result: developer — 39
Status: done
Progress:
  Done: cut-offs.sh + token-spend --require-end rule 1 via cut-offs.sh; hansei.md section 1/3/4/5; run/SKILL.md steps 8.2, 8.3, 8.6 and Interruptions (commits on item/39 starting "#39 developer:")
  Next: none
Summary:
  scripts/cut-offs.sh per contract section 4, jq marker test copied verbatim; --sleep-log file or -; output buffered so a failing file prints nothing.
  Replay on the demo transcripts (a37df, a85f55 with the machine's pmset log; Lead 61c45656 with --since/--until) prints exactly the architect's contract table (7 + 2 lines). Without the sleep log the cut-mid-stream and request-interrupted lines read stalled. Also checked: silent-gap, limits, missing timestamp -> exit 3.
  token-spend.sh --require-end: rule 1 runs cut-offs.sh from its own directory; any line that is not limits and not silent-gap -> exit 6; cut-offs exit 3/4 passed on with the stderr prefix changed. Demo developer and QA both exit 6.
  hansei.md: wait-kinds table and bullets, Taking the start, Lead's own wait stops a role's, Cut-offs at close, exact pmset filter, measure 1/5 wording, worked examples (W6, 3h02m, stalled 15m, QA not captured, peak 74480), section 5 step 2 and step 6 (guard, staging, git -C, &&).
  run/SKILL.md: 8.2 close scan, 8.6 guard/staging/git -C, Interruptions start via cut-offs.sh. Old sentences "The last commit on `item/<id>` removes `work/<id>/`" and "The record is posted before this commit." kept.
  Close commands run in a scratch repo (item worktree, shell in the main checkout): guard resolves the worktree, only NN-*.md and tracked changes staged, .env/dump.txt/.DS_Store deleted not committed, symlink guard stops.
  bash tests/run.sh: token_spend, check_bump, fingerprint all pass. check-bump: minor, 0.0.0 -> 1.0.0.
  v2-era assertions in tests/factory/test_standard_text.sh QA must move: ac11-interrupted-sleep, ac11-stall-start-from-transcript, ac13-cross-check-before-post (step 2 now starts "Complete `## Waits` with the close scan"), example-waits-rows (6 now), example-lead-time-value, close-add-before-commit, close-commit-staged-only, close-lead-state-before-rm, close-rm-before-untracked, close-untracked-before-last-commit, close-ha-commit-before-rm, close-ha-post-before-remove (hansei.md section 5 step 6 now has sub-step 0 and a different step 6 heading), stall-start-command-present. The two skipped (stall-start-is-last-entry-before-gap, in-run-cutoffs-detected) can be enabled.
Artifacts: plugins/factory/scripts/cut-offs.sh, plugins/factory/scripts/token-spend.sh, plugins/factory/references/hansei.md, plugins/factory/skills/run/SKILL.md
Decisions:
  - token-spend.sh merges cut-offs.sh stdout and stderr (2>&1) and splits by line shape, not a temp file / rejected: temp file for stderr (contract: no writes) / cost to undo: one block
  - cut-offs.sh prints nothing until every file is read (exit 3 leaves stdout empty) / rejected: streaming per file / cost to undo: a few lines
  - silent-gap window test uses the gap's start as its "first marker" time / rejected: the end / cost to undo: one expression
Open questions: none
