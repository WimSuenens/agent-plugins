# Result: qa-engineer — 39
Status: done
Progress:
  Done: start; F4-F6 hard checks and L1a newline tests (73d3afc); round-3 verdict (53875cb); result (this commit)
  Next: none
Summary:
  Verdict: pass (round 3). Fix round 3 (9ee1cdc) re-verified: F4, F5, F6 fixed, and their skips are now plain checks. Security L1a is fixed and covered by new check-bump newline-* tests. No finding is open.
  Suite: bash tests/run.sh gives 340 passed, 0 skipped, 0 failed, run in a clean detached worktree at 73d3afc on /bin/bash 3.2.
  Mutation check: putting back the round-2 check-bump.sh turns 7 newline tests red; dropping only the newline case turns 4 red; the round-2 token-spend.sh turns 3 F4 tests red; the round-2 tracker patch turns 6 F5/F6 tests red.
  Fingerprint at HEAD: release 1.0.0; standard 864087234702d4aa40e4c0da84d9da7ec6f7fa43b8a2353abb8027024aa52af7 (unchanged); tooling 03cfd2ba1afbf19d02e3b77a84b15615375a843a04ad9176a4a806a2d406b05b (matches the Lead's).
  Observations (no finding): a refused newline path prints on two lines; a newline name under scripts/ needs a minor bump (fail closed) where the contract says patch.
Artifacts:
  reviews/qa-39.md
  tests/factory/test_check_bump.sh, test_token_spend.sh, test_standard_text.sh
Decisions:
  - F4-F6 tests made unconditional (skip branches removed) / rejected: keep if-else-skip / cost: put back 3 lines.
  - The test asserts fail-closed (minor) for a newline name under scripts/, matching the developer's choice / rejected: assert the contract's patch for scripts / cost: one assertion; the architect may settle it in the contract.
  - Newline display on two lines rated an observation, not a finding: the contract does not cover it and the refusal is right / rejected: low finding / cost: none.
  - Dropped a scratch-file cleanup test: macOS mktemp ignores TMPDIR, so the test passed even with the trap removed / rejected: keep it / cost: none.
Human-only criteria: unchanged (AC-9, 12, 17, 18, 19, 21, plus prep checks 1-2). The demo fingerprint is now tooling 03cfd2ba…6b05b; recompute it right before the demo.
Open questions: none
