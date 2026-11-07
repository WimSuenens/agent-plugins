---
status: proposed
---

# Each role task is a sub-issue: the brief is its body, the result its closing comment

Partly replaces [0001](0001-factory-roles-talk-through-files.md): briefs, results, feedback and the rework loop move from files to the tracker. Questions, the roles' draft results and the lead's memory stay files, on the reasons 0001 gave.

Issue [#53](https://github.com/WimSuenens/agent-plugins/issues/53) asked where a role task's brief and result live. Once released in 2.0.0, moving them again changes where every project's briefs and results live, which makes this a one-way door. The person decided it on a combined card: [decision on #53](https://github.com/WimSuenens/agent-plugins/issues/53#issuecomment-6706120613), option A1, chosen from [the card](https://github.com/WimSuenens/agent-plugins/issues/53#issuecomment-6706052982) on 2026-11-07 with no reason beyond picking the recommended option. Research on the tracker's limits: [#51 findings](https://github.com/WimSuenens/agent-plugins/issues/51#issuecomment-6671497843) and [resolution](https://github.com/WimSuenens/agent-plugins/issues/51#issuecomment-6671502454).

## Context

- Today a brief, result, feedback and question are files in `work/<id>/`, committed on the item branch and kept in main's history ([0013](0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md)). The person must open a branch to read what a role was told and answered.
- The Destination wants a board card per role task, so tokens and minutes have somewhere to sit and rework shows as cards.
- Targets served: **maintainability** (one place the person reads), **security** (the home-path and secret rules of 0013 now cover public issue text), **performance** (a slice has 4 to 8 role tasks plus rework; #51 found the limits of 100 sub-issues per parent, 8 levels and 80 content writes per minute far away).

## Decision

1. **One sub-issue per role task.** The lead creates it under the slice ticket, with the brief as its body, and links it with `addSubIssue`. The role reads its brief from the issue.
2. **The result is the closing comment.** Status and Summary on top, the rest in `<details>`; the lead posts it and closes the sub-issue. A first line `<!-- factory:result v1 -->` lets a resumed lead find it instead of posting twice.
3. **Rework is a new sub-issue** titled `rework <n>: ...`, with the finding as its body.
4. **Only the lead writes to the tracker** (protocol *Shell* is unchanged). A role keeps writing its result as a committed draft `work/<id>/NN-result-<role>.md`, so a role cut off mid-way leaves its `Progress` where a resumed agent finds it, and the git evidence of 0013 stays.
5. **The tracker comment is the record the person reads; the draft commit is the record that cannot be edited.** Where they differ, the commit decides.
6. **Text limits.** A comment holds at most 65,536 characters (#51): Status and Summary stay on top, logs and diffs are linked, not pasted, and an oversize result continues in a second comment. The home-path and secret rules of 0013 apply to issue text; an edited comment keeps its edit history.

## Considered options

- **A2: marker comments on the slice ticket, no sub-issues.** Rejected. One card per slice cannot show which role is running, the role-task fields (tokens, minutes) and the progress bar lose their place, and a ticket with twenty marker comments is hard to read.
- **A3: keep files, the lead only mirrors a summary.** Rejected. It fails the Destination's role-task bullet; the person still cannot read a role task without a branch.

## Consequences

- The person opens any role task from the board without a clone. Rework is visible as cards.
- The record is mutable: the owner can edit or delete a body or comment. QA cannot re-read a brief from a commit; it reads the issue. The hansei cross-check keeps its commit-time evidence on the drafts, and sub-issue created and closed times become a second source.
- Each role task is a public issue the moment it is created.
- **Undo cost.** Back to files is about 4 to 5 days (protocol templates, run skill steps, hansei sources, QA and security briefs, tests), an estimate, not a measurement. The sub-issues stay as closed history. **After 2.0.0 ships, undoing this is itself a 3.0.0 release.**
- Depends on [0015](0015-factory-status-has-six-values-plus-kind-and-role.md): the stage is read from which role task is Running.

## Decided inside, overturnable

Two-way doors the architect decided in this round.

- **Frontier-round role tasks hang under the frontier ticket**, not under the map. Depth is map > ticket > role task, and the map never nears 100 children. Rejected: directly under the map. Undo: under a day.
- **A committed draft result in `work/` stays** while the lead posts the comment. Rejected: result only in the comment, where a cut-off role loses its `Progress`. Undo: a day.
- **The map's "Factory run" section stays** as the run's resume pointer (step, branch, FREEZE line). Rejected: remove it with the lead state sections. Undo: a day.

**Provisional** until a run has exercised it.
