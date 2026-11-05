# Result: qa-engineer — 39
Status: done
Progress:
  Done: v1-era assertions moved to v2 and v2 text checks ("standard-text tests moved to schema v2"); --require-end tests with demo-shaped fixtures ("token-spend --require-end tests"); close order, stall-start and Lead API-error tests ("close order, stall start…", 9a80153); in-run cut-off tests (3f7073f); verdict (3e8eb2a)
  Next: none. Re-run when F1 and F3 (and F2) are fixed: remove the five skips and replay the rules on the factory-sandbox #2 transcripts
Summary:
  Verdict: block. The v2 text is consistent: marker v2, five parts add up (4h41m = 3h06m+51m+15m+11m+18m, computed from the stage-log example), four kinds + Agent column, FPY grammar and severity rule, Done-then-stopped in hansei.md and SKILL.md, close order clean in a scratch repo. --require-end meets its contract (30 checks; mutation-checked; 66/66 finished real transcripts exit 0).
  Replaying v2 on the demo's own transcripts still leaves most stall and sleep time in agent working:
  F1 major: hansei.md's start command `tail -n 1 <transcript> | jq -r .timestamp` returns the notice's [Request interrupted] entry (00:05:54Z), not the last entry before the gap (23:50:46Z). Every role stall loses its watchdog window, 15m + 18m in the demo.
  F3 major: in-run cut-offs the agent recovered from ("cut off mid-stream" isMeta entries, isApiErrorMessage server_error "went to sleep") send no notice. In the demo that is ~71m of QA time with no wait, and --require-end exits 0 on such a transcript that ends normally.
  F2 minor: the Lead's own demo interruption (API Error line, then the person's "continue", ~5h) matches no Lead detection rule in hansei.md. SKILL.md's "machine sleep" likely covers it.
  AC-17: FAIL. Demo re-run: NOT demanded. The demo transcripts are on disk and the fixtures copy their shapes; a re-run can't produce a stall on demand. AC-17 passes on QA's word once a re-run of the fixtures and the transcript replay passes.
  Suite: 423 passed, 5 skipped (each = F1/F2/F3), 0 failed. Fingerprint at HEAD: standard 0096eaafe94545ee036130c0af71e3db6f8410a8bc15d8956627eeae6fa48cde, tooling 8bb7b3b30fe51006a1beeb83e66f8c3d359f97d32b5172378f4bc097ee50634b, release 1.0.0.
Artifacts: tests/factory/test_standard_text.sh, tests/factory/test_token_spend.sh, reviews/qa-39.md
Decisions:
  - example-lead-time is computed from the stage-log example, not hardcoded / rejected: a fixed string only / cost to undo: one test block.
  - Demo-transcript shapes copied into inline fixtures (no real transcript in the repo) / rejected: reading ~/.claude transcripts in the suite (they expire after 30 days) / cost to undo: none.
  - F3 graded major (not a later-version gap), because it reproduces AC-17's failure mode on the demo's own data / rejected: observation only / cost to undo: the lead may downgrade it.
  - Known defects kept as named skips so the suite stays green while the verdict blocks / cost to undo: none.
Open questions:
  - Architect: F1 and F3 are contract text (39-stage-log §3, 39-hansei-record measure 5, 39-plugin-scripts §3 --require-end rule 3). F3 relies on undocumented transcript fields (isApiErrorMessage, error, the isMeta cut-off text). Which match to use is the architect's call, but it must catch both demo shapes.
  - Lesson for docs / contract worked example: real watchdog stalls end on a "[Request interrupted by user]" user entry written at the notice, not on an unanswered tool call.
