# Feedback: qa-engineer — 39
Source: acceptance demo (AC-17 fail) → schema v2
Findings: verify the v2 fix against `docs/requirements/39-hansei-record.md` (3b2d8e2), contracts (9f7825b) and the build (187b5a9+).
1. Update the v1-era assertions in tests/factory/test_standard_text.sh: ac11-waits-kinds, ac11-limits-wait, ac11-interruption-limits-wait, ac14-marker-first-line, ac14-example-marker, ac15-m1-split, example-lead-time.
2. Add tests for `token-spend.sh --require-end` (exit 6 on an unanswered tool call and on `[Request interrupted`; 0 on a final reply and on a SubagentHandback result; basename-only message).
3. Check the v2 worked example adds up (five parts = total) and that the FPY grammar and done-then-stopped rule are in the standard.
4. AC-17: the person accepts AC-17 on your word unless you demand a demo re-run. Judge AC-17 against the v2 template and fixtures — including a fixture shaped like the demo's situation (a stall, a sleep interruption, a truncated developer transcript) — and state explicitly: **AC-17 pass / fail**, and **demo re-run: demanded / not demanded**, with your reason.
Re-verify: full suite; updated verdict in reviews/qa-39.md with the fingerprint at HEAD. Commits `#39 qa-engineer: <what>`; result `work/39/44-result-qa-engineer.md`. Security and docs-writer commit in parallel: touch only tests/ and reviews/qa-*; retry on index.lock.
