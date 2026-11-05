# Feedback: architect — 39
Source: qa (round 4, block), security (v2, lows) — and a lead countermeasure after an andon
Countermeasure for this round: write the detection rules against the data. Inputs include QA's demo-shaped fixtures in tests/factory/ (test_standard_text.sh, test_token_spend.sh) and the demo's own transcripts named in reviews/qa-39.md (*AC-17 judgement*; read-only, under ~/.claude/projects/). Before you commit, replay your rules on those transcripts and state in your result what each rule yields for the demo's developer, QA and Lead (expected: the developer stall starts ~23:50Z; QA's ~71m of self-recovered cut-offs between 00:08Z and 01:21Z are not agent working; the Lead's ~5h API-error-then-'continue' gap is detected).
Findings:
1. QA F1 (major) — stall start: the last entry *before the gap*, not `tail -n 1` (which returns the watchdog's `[Request interrupted` entry); also for the Lead read after resume.
2. QA F3 (major) — self-recovered cut-offs and sleeps: detect them from transcript markers ("cut off mid-stream" meta entries, `isApiErrorMessage` / `server_error` entries) so measure 1 counts them as stalled/interrupted and measure 5 marks the role's spend truncated; `--require-end` (or a sibling check) must fail on a transcript that had such a cut-off even if it ended normally. These fields are undocumented: say so in the contract and make the rule fail closed.
3. QA F2 (minor) — a Lead detection rule for "API Error entry, then an unprompted person message".
4. Security L8 (low) — close step stages only `work/<id>/[0-9][0-9]-*.md` plus `git add -u`.
5. Security L9 (low) — numeric id check, `git -C <abs worktree>`, `-L` symlink guard, `&&` so `rm -rf` never runs after a failed `git rm`.
6. Security L10 (low) — the exact pmset filter (`awk -F'\t' '$1 ~ /^[0-9-]+ [0-9:]+ [+-][0-9]+ (Sleep|Wake) *$/ {print $1}'`) and the rule "copy only UTC start and end times".
7. QA note — the worked example's stalled transcript ends on `[Request interrupted by user]`, not an unanswered tool call.
Output: contracts/39-*.md; result `work/39/50-result-architect.md` with the replay table. Commit `#39 architect: detection rules from the demo data; L8–L10`. Touch only your paths.
