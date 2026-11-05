# Result: security-reviewer — 39
Status: done
Progress:
  Done: final-round re-verify of L8a, L9, L11, L12, I4, git clean, ADR 0013 path rule and the checklist line; reviews/security-39.md updated (commit "#39 security-reviewer: final-round re-verify")
  Next: none; re-check L13 once QA edits reviews/qa-39.md, if the lead wants it
Summary: Verdict pass. No critical, high or medium finding. L8a, L11, L12 and I4 are fixed and L9 still holds. The probes used scratch repos (main checkout + wt/39 + outside/) and ran the close as one script under bash and zsh.
  git clean cannot reach outside the worktree. Untracked and tracked symlinks inside work/39 (absolute, relative, nested) are removed as links, and their targets are untouched. With the guard bypassed and work -> outside committed, git clean deletes nothing and git rm fails, so the && chain stops. A pathspec outside the repo is refused. A nested repo is skipped, and [ ! -e ] stops the close. With w empty, "${w:?}" stops git before it runs (bash rc 127, zsh rc 1).
  Checklist line on item/39 (L14, low): two commits. a3af016 (09-brief-qa-engineer.md:7) is the expected one. 27c8fc3 (60-options-architect.md:8) quotes the same path, so ADR 0013's "one home path" undercounts. No history rewrite.
  New L13 (low): reviews/qa-39.md:199,205 hold the absolute home path. reviews/ stays in main's tree, and neither the protocol rule (message files) nor the checklist line (-- work/) covers it.
  Informational: I5, the -S"$HOME/" check only sees the reviewer's own home. I6, 6.1 is prose and not &&-chained, so without set -e or || exit 1 a failed git add could let git clean delete an uncommitted result file (integrity, not reach).
  bash tests/run.sh at 79e191c: ALL PASSED.
Artifacts: reviews/security-39.md
Decisions:
- L13 rated low, non-blocking. Chosen: low (the username is the public login, one-line fix). Rejected: medium (it lands in main's tree). Cost to undo: low, a re-rating.
- L14 rated low as the checklist line prescribes, with the fix limited to ADR wording. Rejected: asking for a history rewrite (ADR 0013 rules it out). Cost to undo: low.
- I5 and I6 informational. Rejected: low for I6 (no reach outside the worktree; it needs a failed git add plus a Lead who drops the stop-at-first-failure instruction). Cost to undo: low.
Open questions: none
Proposed for other owners:
- qa-engineer: reviews/qa-39.md:199,205, write the plugin dir as ../wt/39/plugins/factory or ~/Projects/portfolio/wt/39/plugins/factory (L13).
- architect: ADR 0013 Consequences, name both work/ files (09-brief, 60-options) (L14). Consider widening the protocol path rule to every committed file and dropping "-- work/" from the checklist line (L13). Consider giving 6.1/6.2 as one fenced block with || exit 1 (I6).
