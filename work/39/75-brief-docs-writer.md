# Brief: docs-writer — 39
Goal: Final docs before merge.
Inputs: reviews/qa-39.md (final verdict, F1); docs/adr/0013-*.md; #48 decision; contracts/39-standard-changes.md §8–9.
Constraints:
- docs/agents/issue-tracker.md *Merge PR*: copy the tracker template's line with its reason clause (`--merge`, never squash or rebase …) verbatim from plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md.
- CHANGELOG.md 1.0.0: replace "The merge style is open (#48)" with the decision (ADR 0013: keep --merge; no absolute home paths in work/); add the path rule; keep known limitations true to the final verdicts (QA pass, security pass with L13/L14 fixed; deferred: path rule for every committed file, chaining close step 6.1).
- README status line: the acceptance demo ran in a scratch project; all human-only criteria passed; AC-17 failed there, was fixed (schema v2, cut-off detection) and passed on QA's verification by replay on the demo's transcripts — no demo re-run.
- No absolute home paths anywhere you write. Touch only your paths.
Re-verify: `bash tests/run.sh` — QA's F1 named skips should now pass. Commit `#39 docs-writer: final docs for 1.0.0`; result `work/39/76-result-docs-writer.md`.
