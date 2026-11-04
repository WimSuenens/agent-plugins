# Feedback: qa-engineer — 39
Source: lead
Findings:
1. tests/factory/test_check_bump.sh `leading-zero-still-refuses` — update: a base (origin/main) of 1.08.0 now exits 2 (contract 39-plugin-scripts.md §2 as of ed0e627); a branch version of 1.08.0 is still refused with exit 1 — test both.
2. tests/factory/test_standard_text.sh `ac15-m5-script` — update: hansei.md now writes `<plugin root>` (overturned literal `${CLAUDE_PLUGIN_ROOT}`).
3. Add tests for the developer's hand-checked fixes 5–10 of feedback 15: non-ASCII paths in check-bump (`references/café.md` → minor), bump re-check before merge, Find hansei author filter (jq on sample comments), mktemp in Edit hansei (text), '-'-prefixed transcript names and exit 3 naming the file in token-spend, basename-only error messages.
Re-verify: the whole suite against item/39 HEAD and contracts as of ed0e627; then issue an updated verdict in `reviews/qa-39.md` with the Human-only criteria list (unchanged unless the fixes changed it). Note the new standard fingerprint at HEAD for the demo. Commits `#39 qa-engineer: <what>`; result `work/39/22-result-qa-engineer.md`.
