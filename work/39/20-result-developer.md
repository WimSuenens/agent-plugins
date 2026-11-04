# Result: developer — 39
Status: done
Progress:
  Done: feedback 19 findings 1-4 applied.
  Next: QA updates two tests that assert old text.
Summary:
- check-bump.sh: base version not a strict semver (or empty) now exit 2 with stderr reason; branch version like 1.08.0 still refuses (exit 1) with the full contract refuse line. Diff now uses `-z` (NUL-separated) as the contract says.
- hansei.md: `<plugin root>` replaces literal `${CLAUDE_PLUGIN_ROOT}` (3 places), with the note that the Lead fills it from the `Plugin root:` line; Label example path is now `~/...`.
- fingerprint.sh (gap vs contract): error message names root by basename (`not a factory plugin root: <basename>`); unreadable file reads `cannot read <rel>`; version check uses the strict semver regex (leading zeros such as 01.0.0 now exit 2).
- token-spend.sh: exit-5 stderr now `no messages in window`.
Tests now asserting old text (for QA):
- tests/factory/test_check_bump.sh `leading-zero-still-refuses` (base 1.08.0 now wants exit 2, got 2 vs wanted 1).
- tests/factory/test_standard_text.sh `ac15-m5-script` (expects literal `${CLAUDE_PLUGIN_ROOT}` form in hansei.md; now `<plugin root>`).
tests/run.sh: all else passes (these 2 fail as expected).
Artifacts: plugins/factory/scripts/{check-bump,fingerprint,token-spend}.sh, plugins/factory/references/hansei.md
Decisions: none
Open questions: none
