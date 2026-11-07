# Brief: security-reviewer — 57

Goal: Review the change of PR #58 (item/57) for security before merge: the baseline issue, the A3, the run close and the new hansei v4, as plugin text the Lead executes with `gh`.

Inputs:
- The diff of `item/57` against main: `plugins/factory/` (new `references/baseline.md`, `references/a3.md`; `skills/run/SKILL.md` steps 8.10 and 9; `references/hansei.md`; `references/protocol.md`; the tracker template), and `contracts/57-*.md`, `docs/requirements/57-per-run-a3-and-baseline.md`.
- ADR 0011 (the fence), ADR 0012, ADR 0013; `reviews/security-49.md` for what was found and accepted before.

Constraints and what to look at:
- The Lead finds, creates, pins and edits the "Factory baseline" issue and the A3 comment through `gh`: can another comment or issue (a forged marker, a look-alike title, another user's comment, a title with markup) be taken for the Lead's own? The contract finds by title and the Lead's own `gh` user; check the shell commands for quoting and injection, and what happens with several matches or none.
- Data egress: the baseline and A3 hold measurements and override texts of the project. Nothing may reach `WimSuenens/agent-plugins` except a step-9 issue the person approved; check that only step 9.4 names `--repo`, that the drafts take only what the A3 lists, and that the baseline or A3 cannot be posted outside the project's tracker (question E of #49 is an accepted limit; say whether this change widens it).
- The fence of ADR 0011: can the experiment override or the settle round cross it (merge and production approvals, decision-card route, QA and security verdicts, the andon, memory and shell-scope rules, the honesty rule)? `promote` must stay a decision card, never a plugin change by the Lead.
- Prompt-injection surface: the Lead reads comments and records into its own text (the records, the A3, override texts); are they treated as data, never instructions?
- Shell-scope: no new script is added; confirm, and confirm `hooks/` and `scripts/` are untouched.
- Findings in your verdict with file, severity, evidence and a required fix; accepted limits stated. You do not edit code. You write only `reviews/security-*`. No absolute home path in any file.
- Commit subjects start `#57 security-reviewer: `.

Output: `reviews/security-57.md` (verdict `pass` or `findings`) and `work/57/12-result-security-reviewer.md` (start with `Status: working`).

Done:
- Every point above has a result.
- Verdict line: `pass` only when no finding above `info` is open.
