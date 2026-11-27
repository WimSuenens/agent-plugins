# Result: qa-engineer — 286
Status: done
Abnormality: none
Progress:
  Done: brief checked (5e32599); E5 expected block committed before the replay (5f8423f); E5 rows, scenario, replay comment (b770d23); named skip replaced, docs pin re-pointed (ffe85b0); role knowledge (f8f02a2)
  Next: verification stage, after the build
Summary:
- The skip at test_a3_v4_286.sh:154 is gone. New checks per contract §3 worked example: `c2-out-of-order-v4-two-tracks` (run timing and still uncertain, exit 1), `c2-v4-same-v3-refusals-not-detectable-after-baseline` (v3 keys equal v3 output), `c1-guardrails-after-answer`. Red now: a3-check.sh skips v4 (exit 3).
- Checked on a scratch reference a3-check with the two tracks: all order checks green; 3 of 3 order mutants caught (one track, no upper bound, no start position).
- test_lean_rules.sh:179 re-pointed: `ac17-docs-say-v4-README` and `ac17-docs-say-v4-reference` fail when `factory:a3 v4` is absent. Red until the docs-writer's §2 edit, not the developer's. test_slice2_loop.sh:185 not moved.
- Runs `<reasons>`: fixture E5 (c310 to c312) pins `; ` and first-seen de-duplication (`3 of 3 runs: lite; scan skipped`) plus a partly captured slot. Replay green; 4 of 4 mutants caught (no dedup, `, `, sorted, last-seen).
- Targeted test command unchanged: `for t in run_timing_286 run_state_286 a3_v4_286 baseline_runs_286 run_text_286; do bash tests/factory/test_$t.sh; done`
Artifacts: tests/factory/test_a3_v4_286.sh, tests/factory/test_lean_rules.sh, tests/factory/test_baseline_runs_286.sh, tests/factory/runs_replay.py, tests/factory/fixtures/runs286/E5.expected, tests/factory/fixtures/runs286/a3s.tsv, tests/factory/fixtures/runs286/scenarios.tsv, docs/agents/roles/qa-engineer.md
Decisions:
- soft pin split into two checks, one per file, renamed `ac17-docs-say-v4-<file>` / rejected: one check over both files (passes when only one file says v4; §2 asks both) / cost to undo: three lines
- E5's adjusted slot reads lite, lite, scan skipped (stalled keeps the contract's lite, scan skipped, lite) so first-seen and last-seen orders differ / rejected: the contract's order in both slots (a last-seen mutant survived) / cost to undo: one fixture row
Open questions: none
Missing: none
