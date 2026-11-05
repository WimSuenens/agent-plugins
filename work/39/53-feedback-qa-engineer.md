# Feedback: qa-engineer — 39
Source: lead (round 5: detection rules from the demo data)
Findings: verify the build (work/39/52-result-developer.md) against contracts a8e338d/334f6bd and the requirement.
1. Move the 13 assertions listed in work/39/52-result-developer.md; enable stall-start-is-last-entry-before-gap and in-run-cutoffs-detected.
2. Add fixture tests for cut-offs.sh: each marker kind, the silence backstop, strongest-kind-wins, --sleep-log, --since/--until, exit 3 with empty stdout.
3. Replay cut-offs.sh and token-spend --require-end read-only on the demo transcripts (reviews/qa-39.md names them) and compare with the architect's replay table (work/39/50-result-architect.md).
4. Run the guarded close commands in a scratch repo (never in this worktree): dirty lead state, untracked brief, stray .env, a committed `work` symlink.
5. AC-17: judge it against the demo data and state explicitly **AC-17 pass / fail** and **demo re-run: demanded / not demanded** (the person accepts AC-17 on your word unless you demand one).
Re-verify: full suite; updated verdict in reviews/qa-39.md with the fingerprint at HEAD. Commits `#39 qa-engineer: <what>`; result `work/39/54-result-qa-engineer.md`. Security and devops commit in parallel: touch only tests/ and reviews/qa-*; retry on index.lock.
