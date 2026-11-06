# Result: qa-engineer — 57
Status: done
Abnormality: none
Progress:
  Done: round 3 re-verify; controls first (commit "round 3 controls first"), reader and pins, mutation check, review section
  Next: none
Summary:
- Verdict pass. `bash tests/run.sh`: ALL PASSED, 0 failures, 0 skips, four consecutive full runs.
- Create pin moved to the contract's rule (exit 0 and no `marker` line; `no-marker` only after `create`; never after non-zero); null-body fixture, failed-lookup pins, calibration `plugin:` span (`(at)`, `(lt)`, one span, 120 cut), once-per-field and v4 skip pins added.
- Kept old sentences: none contradicts a new rule. Observations R3-O1 (redundant empty-body rule) and R3-O2 (section 3 item 4 "nothing else" beside the plugin text) for the architect/developer, not blocking.
- Real S2/S5 replayed from a scratch file outside the repo: 14 of 14 rows, nothing quoted, file removed.
- Mutation check: 15 mutants, control 0 red, all 15 red.
- Fingerprints (my tree): release 1.2.0; tooling equals the 1.1.0 value (unchanged); standard see reviews/qa-57.md.
- One unexplained single failure of k3z-accented-name in a first full run, not reproducible (R3-O3).
Artifacts: reviews/qa-57.md, tests/factory/test_baseline_a3.sh, tests/factory/test_baseline_replay.sh, tests/factory/baseline_replay.py, tests/factory/fixtures/baseline/
Decisions: reader spans the calibration plugin text as one code span with `factory ` outside (two-way; follows baseline.md section 1 and the section 7 skeleton)
Open questions: none
