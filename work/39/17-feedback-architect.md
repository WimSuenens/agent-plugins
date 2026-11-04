# Feedback: architect — 39
Source: security
Findings:
1. contracts/39-plugin-scripts.md:171 — low (security L5) — remove this machine's project directory and the real session id; use placeholders.
2. contracts — low (security L5, part 2) — the label's plugin root and session ids land in git history because `work/` is deleted in a commit before a `--merge` merge. Say in your result whether the label should avoid absolute paths/session ids, or whether this is accepted (project's own history); don't change the merge strategy (that's the tracker doc's *Merge PR*, outside this item).
3. Align contracts with the developer's fixes in feedback 15 where they touch contract text (frontier PR bump check; fingerprint exit 2 on unreadable file and empty version; *Find hansei* author filter; *Edit hansei* mktemp; bump re-check before merge/tag).
Re-verify: worked examples still add up. Commit `#39 architect: security L5 and contract alignment`; result `work/39/18-result-architect.md`. Touch only your paths.
