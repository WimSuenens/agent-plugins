# Result: developer — 286
Status: done
Abnormality: none
Progress:
  Done: brief checked (WimSuenens, marker developer 3); the four developer rows of contract section 6.1 (5ad4dac); five targeted tests exit 0; `bash tests/run.sh` run; check-bump pass
  Next: none (QA re-pins slice286-added.txt lines 4 and 5 and adds the L1/L2 cases)
Summary:
- run-timing.sh: a cut-offs line out of format now reads `run-timing: a cut-offs line not in its format: line <k>` (k = line number in the cut-offs input, from 1); the line's text is never printed. Probe: a bad 4th line gives `line 4`, exit 2. Header comment updated.
- run-close-run.md 9.2 b: adds `lead-sessions` reading empty (`no lead session recorded`) and exiting 2 (`lead sessions line not in its format`). 9.2 c: `--what '<what>'`, single-quoted, with the reason.
- hansei.md section 8, *Not captured*: "adds four", the empty value beside `none yet`, and the new reason with its exit.
- run-state.sh is unchanged (already as section 2.4, 964bc25). The section 6.1 search terms find no other stale text outside contracts, QA's allow-file and history.
- Targeted tests: all five exit 0. check-bump: pass (3.10.0).
- `bash tests/run.sh` FAILURES, only the expected ones: test_lean_rules ac17-docs-say-v4-README, ac17-docs-say-v4-reference, ac19-changelog-has-the-standard-fingerprint, ac19-changelog-has-the-tooling-fingerprint (Documentation); test_release64 ac45-no-home-path-or-token-in-changed-files (reviews/security-286.md:31); test_run_split a2-no-line-added-but-pointers-stubs-headers and a2b-every-pinned-slice4-line-is-present (9.2 b and c, QA re-pins next).
Artifacts: plugins/factory/scripts/run-timing.sh, plugins/factory/references/run-close-run.md, plugins/factory/references/hansei.md
How to run: `for t in run_timing_286 run_state_286 a3_v4_286 baseline_runs_286 run_text_286; do bash tests/factory/test_$t.sh; done`; `bash tests/run.sh`.
Decisions:
- `<k>` counts every line of the cut-offs input, blank lines included (awk FNR) / rejected: counting only non-blank lines / cost to undo: one counter.
Open questions: none
Missing: none
