# Result: qa-engineer — 286
Status: done
Abnormality: 1 blocked-input — contract 286-a3-v4-and-runs section 3 (architect) says each v3 refusal fixture as v4 gives the same v3 refused lines (AC-C2), but the suite's out-of-order fixture (not detectable moved after baseline) gives `still uncertain (out of order)` as v3 and `run timing (out of order)` as v4 under the existing order rule; the test is a named skip — tests/factory/test_a3_v4_286.sh:154
Abnormality: 1 blocked-input — contract 286-release section 3 (architect) leaves out the pin test_slice2_loop.sh:195 (`when its marker is v2 or v3`), which section 5 of 286-a3-v4-and-runs changes; QA moved it as well — tests/factory/test_slice2_loop.sh:195
Progress:
  Done: brief checked (81bffa6); run-timing and run-state tests (2bb4031); a3-check v4 tests and Runs expectations committed before the replay (756f44f); Runs replay (5c2247f); pins moved and text pins (5f03c47); order-control fix found on the reference build (482ffe0)
  Next: verification stage, after the build
Summary:
- Targeted tests, each red now for the missing build. Developer's command: `for t in run_timing_286 run_state_286 a3_v4_286 baseline_runs_286 run_text_286; do bash tests/factory/test_$t.sh; done`
- test_run_timing_286.sh: run-timing.sh is missing (exit 127). Covers AC-B6 (the section 4.6 example and controls a to e), the not-captured reasons, `gaps` (S3a), the AC-B5 chain (cut-offs.sh, then gaps, then add-run-wait; a second close adds no row) and AC-B7 (25 generated runs checked against QA's own replay)
- test_run_state_286.sh: add-session, add-run-wait and lead-sessions do not exist yet, and `start` still prints the old section. Covers AC-B3, the B1 paths and the 2.5 example
- test_a3_v4_286.sh: a3-check.sh skips v4 (exit 3). Covers the four lines, every refusal in the section 3 table, the C2 pairs and v1 to v3 unchanged from main
- test_baseline_runs_286.sh and test_run_text_286.sh: baseline.md has no section 9, and the contract's word-for-word sentences are not in the text yet
- Pins moved per 286-release section 3, plus slice2_loop:195. The router cap stays 70,000 bytes; the run-size cap is now 162,000 bytes (re-measure at verification)
- Checked against a throwaway reference build in the scratchpad: all logic checks green, and 5 of 5 mutants of the timing computation caught
- Left for verification: AC-A1 and AC-B4 (runtime proof), AC-C6 (post-merge), the full AC-A2 search for conditions, AC-C5 on the #62 body
Artifacts: tests/factory/test_run_timing_286.sh, tests/factory/test_run_state_286.sh, tests/factory/test_a3_v4_286.sh, tests/factory/test_baseline_runs_286.sh, tests/factory/test_run_text_286.sh, tests/factory/run_timing_oracle.py, tests/factory/runs_replay.py, tests/factory/fixtures/run286/, tests/factory/fixtures/runs286/, tests/factory/fixtures/a3/v4-ok.md; pins in test_slice6_text.sh, test_a3_check.sh, test_baseline_a3.sh, test_lean_rules.sh, test_slice2_loop.sh, test_slice3_table.sh
Decisions:
- run-size cap set to 162,000 before the build (about 3.5 KB of expected growth) / rejected: leaving 158,000 until the build is known, which would turn the developer's build red on a pin they may not move / cost to undo: one line, re-measured at verification
- the Runs section is tested as a QA rule replay (runs_replay.py, with expected blocks committed first) plus text pins, because no script ships / rejected: pinning baseline.md prose / cost to undo: two files
- AC-B7 checked on 25 generated runs against an independent minute-by-minute replay / rejected: hand-written cases only / cost to undo: one block
- the v4 fixture writes `run compared` with its own series (2.3); the contract's example with 3.10 is tested as well, so a3-check.sh must not compare the two series / cost to undo: one line
- the refusal checks that exit 2 already pass now (an unknown subcommand exits 2 too); they are kept as guards next to the positive checks, which do fail
Open questions:
- Q1 (architect, AC-C2): for the out-of-order v3 fixture, may the v4 output differ for the v3 keys (the four lines then sit before `not detectable`), or must the order check keep the v3 keys' result? Options: A narrow AC-C2 to the non-order refusals / B the check tracks the order of v3 keys and v4 keys apart. Leaning A. Until then this is a named skip.
- Q2 (architect, contract 286-a3-v4-and-runs section 4.2): in `not captured (<m> of <j> runs: <reasons>)` the separator between reasons and whether repeats are dropped are not fixed. The replay reads them as `; ` with each reason once. No fixture pins this yet.
Missing: none
