# Feedback: developer — 39
Source: architect (contracts a8e338d, 334f6bd), after QA round-4 block and security v2 lows
Findings — build to the contracts; read work/39/50-result-architect.md (Open questions → developer) first:
1. New plugins/factory/scripts/cut-offs.sh per contracts/39-plugin-scripts.md §4 — copy the jq marker test exactly; `--sleep-log -` input.
2. token-spend.sh `--require-end` rule 1 calls cut-offs.sh from its own directory.
3. references/hansei.md §1: wait-kinds table, *Taking the start*, *The Lead's own wait stops a role's*, *Cut-offs at close*, the pmset awk filter with the copy-only-UTC-times rule; §5 close scan and step-6 guard/staging/`git -C`; worked examples (W6, 3h02m, stalled 15m, qa-engineer spend not captured, peak 74480).
4. skills/run/SKILL.md: close scan at step 8.2; step 8.6 guard, staging and `git -C` commands.
Re-verify: test cut-offs.sh against fixtures shaped like the demo (QA's fixtures in tests/factory/ show the shapes) and, read-only, against the demo transcripts named in reviews/qa-39.md: your output must match the replay table in work/39/50-result-architect.md. Run the new close commands in a scratch repo (never in this worktree). `bash tests/run.sh` (list v2-era assertions QA must move). Commits `#39 developer: <what>`; result `work/39/52-result-developer.md`. Touch only plugins/.
