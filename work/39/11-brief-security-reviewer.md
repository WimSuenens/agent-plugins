# Brief: security-reviewer — 39
Goal: Independent security review of slice #39 before merge.
Inputs: PR for item/39 (`gh pr diff item/39`); `docs/requirements/39-hansei-record.md`; `contracts/39-*.md`; ADR 0011 and 0012.
Constraints: focus on the three new shell scripts (input handling, quoting, path handling, what they read under ~/.claude, temp files, exit codes), on data handling (no project or personal data written to agent-plugins; what the hansei comment exposes on a project's tracker, including transcript-derived data), and on whether the standard can be steered into skipping a fenced gate. Use throwaway copies only.
Output: `reviews/security-39.md`; result `work/39/12-result-security-reviewer.md`. Commits `#39 security-reviewer: <what>`.
Done: your role's Done list; verdict `pass` or findings with severity.
