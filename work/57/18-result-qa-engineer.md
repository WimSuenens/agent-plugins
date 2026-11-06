# Result: qa-engineer — 57 (round 2)
Status: done
Abnormality: 6 version-drift — the standard fingerprint in the developer's round-1 result (c00c8e1d…) is not the value of the committed tree, c32f3fd0861e62ececf7da8052112ea57ddb9ffa347aa7c6fba00cbce36dea0c, at b3310d7 and at HEAD; round 1 had the same mismatch (observation O7) — reviews/qa-57.md, section "Fingerprints"
Progress:
  Done: replay follows a3.md section 6 (b800a1f); pins, fixtures and moved expectations for F1, F2, S1 to S3, O1 to O4 (ca97e22); round 2 verdict and findings (aaba818); mutation check (23 of 23 red); real S5 and S2 replayed again (14 of 14); memory consolidated
  Next: nothing for QA; after the developer fixes R2-1 (and R2-2, R2-3 as the lead routes them) re-run the suite: the one named skip becomes a plain check
Summary:
  Verdict: block (reviews/qa-57.md, "Round 2"). bash tests/run.sh: ALL PASSED, 0 failures, 1 named skip.
  F1 and F2 of round 1 are fixed: ac15-Q2-release-moved and the F2 check are plain checks; a3/P, Q1, Q3 to Q6 give the same results; new P2 fixture covers the order.
  R2-1 (medium, developer): Find baseline's jq filter raises on an empty (or null) body in jq 1.8.1; nothing printed for later issues, which could read as "none" and create a second baseline. Fix verified in a scratch clone: ((.body // "") | split("\n")[0] // "" | test(...)). Test skip: ac1-find-baseline-empty-body-is-no-marker.
  R2-2 (low, developer): the Create baseline sentence "Run only after Find baseline printed nothing" contradicts its own no-marker exception. Brief finding 4: the Create literal is redundant, pin moved to the rule; the Edit literal ("only when they differ") is a real rule, pin kept.
  R2-3 (low, architect and developer): "the calibration line" is named as a place a reason is spanned but holds only the record's plugin text, free text with no grammar; not spanned by the reader.
  Observations R2-O1 to R2-O5 in the review (span per reason, unreadable key per field, bad override line skips the whole record, AC-14 wording against rule 3).
  Fingerprints: tooling equals 1.1.0 (295033f4…); standard moved (c32f3fd0…); release 1.2.0. Human-only list unchanged.
  Real S5 and S2 replayed from a scratch file outside the repository (removed): 14 of 14 rows, nothing quoted.
Artifacts: reviews/qa-57.md; tests/factory/baseline_replay.py; tests/factory/test_baseline_a3.sh; tests/factory/test_baseline_replay.sh; tests/factory/fixtures/baseline/ (a3/P.json, a3/P2.json, records/s3a.md, s3b.md, s3c.md, s3d.md, x5v4.md, expected.tsv, expected-real.tsv, a3-expected.tsv, scenarios.tsv, comments.tsv)
Decisions: P.json #8 changed to the no-X case the architect described, P2 added for the rest (two-way, cost to undo: one fixture); each reason in its own code span, unreadable-line text written per field with the line key, a v4 record with a bad overrides line skipped whole (all three marked READING in the reader; two-way, cost to undo: a few lines of the reader); old Create literal pin moved to the rule (two-way)
Open questions: none
Missing: none
