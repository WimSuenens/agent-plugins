# Feedback: developer — 39
Source: architect (dbfc448, ce920d4) after #48 decision A, QA round 5, security round 5
Findings — build to the contracts (read work/39/66-result-architect.md "Proposed for other owners → developer" first):
1. references/protocol.md *Messages*: the no-absolute-home-path rule (contracts/39-standard-changes.md §9).
2. skills/run/SKILL.md: pointer to that rule; step 8.6 as in contracts/39-hansei-record.md §6 (one shell call, "${w:?}", ':(glob)' pathspec, git clean + existence test).
3. agents/security-reviewer.md: the checklist line (`git log -S"$HOME/" origin/main..HEAD -- work/`, low).
4. setup-factory-skill/references/issue-tracker-github.factory.md *Merge PR*: keep --merge with the reason clause.
5. references/hansei.md §5 step 6: same as 2.
6. scripts/cut-offs.sh: I4 whitelist (^[a-z_]+$, else `other`); `basename --` (security L12). No change for F5.
Re-verify: run the close commands as one call in a scratch repo (never this worktree), including a nested repo under work/<id>/ and a `03-dump/` directory; bash tests/run.sh (list assertions QA must move); check-bump still passes. Commits `#39 developer: <what>`; result `work/39/68-result-developer.md`. Touch only plugins/.
