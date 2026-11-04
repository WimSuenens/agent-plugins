# Result: qa-engineer — 39
Status: done
Progress:
  Done: start (8852411); check-bump and fingerprint tests (4b5f9a2, b0e17aa); token-spend tests and F4 (3b51fd4); text tests and F5, F6 (7c8ffcd); verdict and result (this commit)
  Next: none. If F4–F6 are fixed, re-run `bash tests/run.sh`: their skips become passes.
Summary:
  Verdict: pass (round 2). F1 (AC-8), F2 and F3 are fixed and re-verified; their tests are now hard checks.
  Feedback 21: leading-zero split (base 1.08.0, "" or v1.0.0 → exit 2; branch 1.08.0 → exit 1 with the contract line), and ac15-m5-script expects `<plugin root>`. Tests added for feedback-15 fixes 5–10: non-ASCII and tab paths, merge re-check and tag check, Find hansei jq run on sample comments, mktemp in Edit hansei, `--` and dash-prefixed names, exit 3 naming the file, basename-only errors.
  Suite: bash tests/run.sh, 322 passed, 3 skipped (F4, F5, F6), 0 failed, in a clean worktree at 7c8ffcd on /bin/bash 3.2. New tests mutation-checked.
  New, non-blocking: F4 (minor) token-spend exit 3 on valid-JSON-wrong-shape passes jq's error with the absolute transcript path to stderr. F5 (low) the Merge PR tag regex accepts 1.08.0 (the merge re-check refuses it first). F6 (low) Post hansei has no mktemp scratch file, as contract 39-hansei-record §5 asks.
  Standard fingerprint at HEAD (plugin files as of be77591): release 1.0.0; standard 864087234702d4aa40e4c0da84d9da7ec6f7fa43b8a2353abb8027024aa52af7; tooling c38d86a73d010d30704352fb19af6592cf7b5d8cf8cb4afb0e230f425d955e95.
Artifacts:
  reviews/qa-39.md
  tests/factory/test_check_bump.sh, test_fingerprint.sh, test_token_spend.sh, test_standard_text.sh
Decisions:
  - F4 rated minor, non-blocking: the Lead writes the fixed form for exit 3, not the stderr line / rejected: block on the contract's no-absolute-path rule / cost to undo: lead can overturn; fix is a stderr redirect.
  - F5, F6 rated low: F5 is unreachable after the merge re-check; F6 is a scratch-file hygiene gap / rejected: minor / cost: none.
  - An empty branch version may print '' or '(absent)'; the test accepts both (contract: "as found") / rejected: pinning one / cost: one line.
  - Pass verdict issued with F4–F6 open, since none blocks / rejected: hold for fixes / cost: lead can schedule a fix round.
Human-only criteria: unchanged list (AC-9, 12, 17, 18, 19, 21, plus prep checks). Prep check 2 now says `<plugin root>` must be filled in, and the demo's fingerprint is the one above (recompute before the demo; a fix for F4 moves tooling).
Open questions: none
