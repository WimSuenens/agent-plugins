# Feedback: developer — 39
Source: acceptance demo (AC-17), via the architect's contracts as of 9f7825b
Findings — build to the contracts (read work/39/38-result-architect.md first):
1. plugins/factory/references/hansei.md — major — schema v2: marker `v2`, template, measure 1 with five parts, the four wait kinds with detection rules, the `Agent` column in `## Waits`, truncation wording for measure 5, FPY grammar `pass first time (<n> low)`, updated worked examples.
2. plugins/factory/skills/run/SKILL.md — minor — Interruptions: stalled/interrupted kinds and the done-then-stopped rule; step 8 close order (commit the lead state, then `git rm -r`).
3. plugins/factory/scripts/token-spend.sh — minor — `--require-end` with exit 6 per contracts/39-plugin-scripts.md §3.
4. Tests asserting `v1` in tests/factory/test_standard_text.sh belong to QA; list them in your result rather than editing tests/.
Re-verify: `bash tests/run.sh` (expect only v1-marker assertions to fail; list them); check-bump still passes (1.0.0, nothing released). Commits `#39 developer: <what>`; result `work/39/40-result-developer.md`. The product-owner edits docs/requirements/ in parallel: touch only plugins/.
