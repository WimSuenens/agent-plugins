# Result: architect — 39
Status: done
Progress:
  Done: options for the merge style written (commit "#39 architect: options for merge style (#48)")
  Next: none; the product-owner turns the options into a decision card, ADR after the person's choice
Summary: Three merge styles compared for PR #40 and factory items (#48). Key fact: agent-plugins is public and item/39's 77 commits are already on refs/pull/40/head, which the owner cannot delete, so squash keeps the one home path (09-brief-qa-engineer.md:7) and session ids out of main's clones but not out of public view. The stage-log cross-check and the hansei post run before the merge, so the record's values are the same under every style; the styles differ in where the evidence can be re-checked later. A (--merge plus a no-home-paths rule for work/) keeps evidence and Progress shas on main and the tag/runbook unchanged; B (squash) moves evidence to a GitHub-only PR ref and needs a head-sha field, a runbook rollback line and a template change; C (rebase) rewrites committer times to the merge time and is rejected. The policy is a two-way door; the merge of #40 itself is the one-way part. Leaning A.
Artifacts: work/39/60-options-architect.md
Decisions:
- Rebase-merge kept as a listed, rejected alternative rather than a live card option / rejected: three live options / undo: add it back to the card.
- If B is chosen: squash subject "#<id> <slice title>" and the record gains the PR head sha / rejected: GitHub's default subject / undo: one template line.
Open questions:
- One-way door for the person: merge style for PR #40 and factory items. A keep --merge, add a no-home-paths rule for work/ and a security-checklist line / B squash-merge, the record cites the PR head sha / (C rebase, rejected). Leaning A: the exposure squash avoids is already public on refs/pull/40/head; what squash gives up (re-checkable evidence on main) cannot be recovered.
- Whichever is chosen changes standard work (the template's Merge PR line, plus for A a path rule, for B the hansei head-sha field and contract §6): decide whether it goes into 1.0.0 in this PR or a later minor.
Missing: none
