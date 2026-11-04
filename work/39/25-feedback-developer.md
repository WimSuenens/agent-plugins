# Feedback: developer — 39
Source: security, qa
Findings:
1. plugins/factory/scripts/check-bump.sh:13,22-31 — low (security L1a) — a file name containing a newline splits through `tr '\0' '\n'` and passes with a patch bump. Loop with `while IFS= read -r -d '' p` and drop the `tr`, and add a final `*) level=minor ;;` catch-all for unrecognised paths under `plugins/factory/`.
2. plugins/factory/scripts/token-spend.sh — minor (QA F4) — on wrong-shape JSON, exit 3 leaks jq's stderr with the full path and lists all files; send the main jq call's stderr to /dev/null, check each file's shape on its own, and print the contract's one-file basename line.
3. setup-factory-skill/references/issue-tracker-github.factory.md *Merge PR* — low (QA F5) — use the contract's strict semver regex for the tag check.
4. same file, *Post hansei* — low (QA F6) — scratch file via `mktemp`, `rm -f` afterwards.
Re-verify: `bash tests/run.sh` — the F4, F5, F6 named skips must turn into passes unchanged; L1a is hand-checked (or ask QA). Commits `#39 developer: <what>`; result `work/39/26-result-developer.md`.
