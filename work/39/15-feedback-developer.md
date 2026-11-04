# Feedback: developer — 39
Source: qa, security
Findings:
1. plugins/factory/skills/run/SKILL.md step 3 (~l.82) — major (QA F1, blocks) — run the *Open PR* bump check, with the same exit handling, before opening the frontier round's PR.
2. plugins/factory/scripts/fingerprint.sh:47-50 — minor (QA F2 = security L4) — an unreadable file must fail with exit 2 (no fingerprint printed) so the Lead records "not captured".
3. fingerprint.sh / version parsing — minor (QA F3) — `"version": ""` must exit 2, not give the pre-release label. Also: a leading-zero version (`1.08.0`) gives an empty suggested version in check-bump.sh; reject it clearly.
4. plugins/factory/references/hansei.md — minor (QA observation, demo prep check 2) — `${CLAUDE_PLUGIN_ROOT}` is not substituted in a reference file; make script calls use the plugin root the Lead already has from run/SKILL.md (state how).
5. check-bump.sh:13 — low (security L1) — non-ASCII paths are quoted by `git diff --name-only`; use `-z` / `read -d ''` or treat unclassifiable paths as minor.
6. run/SKILL.md *Merge PR* + tracker patch — low (security L2) — re-run the bump check before merging, and check the semver before tagging.
7. tracker patch *Find hansei* — low (security L3) — also filter by comment author (`.user.login` of the Lead's gh user).
8. fingerprint.sh error text — low (security L5) — no absolute home path in messages that can reach the record.
9. tracker patch *Edit hansei* — low (security L6) — scratch file via `mktemp`, removed afterwards.
10. token-spend.sh — low (security L7 + QA observation) — handle file names starting with `-` (`--`), and name the file on exit 3.
Re-verify: `tests/run.sh` — the three named skips (F1, F2, F3) must turn into passes with no change to the tests; add or ask QA for tests for 5–10 where they're script behaviour. Commits `#39 developer: <what>`; result `work/39/16-result-developer.md`. Bump stays 1.0.0 (nothing released yet).
