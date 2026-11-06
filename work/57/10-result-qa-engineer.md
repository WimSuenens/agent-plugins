# Result: qa-engineer — 57
Status: done
Abnormality: none
Progress:
  Done: old-wording pins moved (cc9ffc7); controls and expected results committed before the replay (7be7476); fixtures and replay reader (598b649); text, grammar and replay tests (c01d584, 5fc0134); verdict reviews/qa-57.md (7ff58e6)
  Next: nothing for QA until the developer fixes F1 and F2; then remove the two named skips (ac15-Q2-release-moved in test_baseline_replay.sh, ac12-experiment-written-in-step5-before-stamp in test_baseline_a3.sh) and re-run
Summary:
  Verdict: findings. bash tests/run.sh: ALL PASSED, 1297 passed, 2 skipped (the two skips are F1 and F2). Before my edits three files failed on old-wording pins (named in the verdict).
  F1 (medium) a3.md section 6 item 1 vs section 7 item 2: an after-item in another series is dropped first, so "release moved" (AC-15) can never be reported; it reads "no after-item". F2 (medium) SKILL step 5 never says when a between-items experiment is committed; after the Start item stamp the item is a during-item, so a normal run has no after-item.
  Replay: controls written first; all rows as expected except AC-15 release-moved. Real S2 and S5: pass (scratch files removed, nothing quoted).
  Tooling fingerprint did not move (295033f4... equals factory-v1.1.0); standard 897b3fc1...; check-bump exit 0 (1.1.0 -> 1.2.0). AC-26 exception: the setup skill's tracker template.
  Human-only: AC-10, AC-21, AC-29, AC-30, AC-31 (and the two-readers half of AC-16, which the Lead can run with fresh agents). Post-merge: AC-27 second half, AC-28.
Artifacts: reviews/qa-57.md; tests/factory/test_baseline_a3.sh; tests/factory/test_baseline_replay.sh; tests/factory/baseline_replay.py; tests/factory/fixtures/baseline/; tests/factory/test_andon_text.sh; tests/factory/test_fingerprint.sh; tests/factory/test_standard_text.sh
Decisions: replay reader is Python 3 run with -I (two-way; cost to undo: delete one file); synthetic fixtures use invented values rather than S5 copies, real records replayed by hand from a scratch file (two-way)
Open questions: none
Missing: none
