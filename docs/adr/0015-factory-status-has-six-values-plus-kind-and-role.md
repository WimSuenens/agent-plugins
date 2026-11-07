---
status: proposed
---

# `Factory status` has six values, plus `Kind` and `Role` fields

Amends [0002](0002-one-branch-and-worktree-per-item.md): its rule that status lives in the tracker stays, but the seven values are replaced by six and the item's stage no longer lives in the lead state.

Issue [#54](https://github.com/WimSuenens/agent-plugins/issues/54) asked what the board shows as status. Existing projects hold cards in the old values, and moving back loses information, which makes this a one-way door. The person decided it on the same combined card as [0014](0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md): [decision on #54](https://github.com/WimSuenens/agent-plugins/issues/54#issuecomment-6706120825), option B1, from [the card](https://github.com/WimSuenens/agent-plugins/issues/53#issuecomment-6706052982) on 2026-11-07, with no reason beyond picking the recommended option. Research on what a board can do by script: [#52 findings](https://github.com/WimSuenens/agent-plugins/issues/52#issuecomment-6671511111) and [resolution](https://github.com/WimSuenens/agent-plugins/issues/52#issuecomment-6671514755).

## Context

- Today seven values (Backlog, Ready, Designed, In progress, In review, Ready to deploy, Done); the stage and waits are in `00-lead-state.md`, which the person cannot see.
- The person's one question is "what do I do now". Targets served: **maintainability** (one list, one view), **performance** (the lead's state files shrink), **security** (no new access).
- The migration table was settled by the person on 2026-11-07 and was not offered again: Designed to Ready, In progress and In review to Running, Ready to deploy to Waiting on you. The run keeps the old mechanism until it closes; no acceptance demo.

## Decision

1. **`Factory status`: Backlog, Ready, Running, Waiting on you, Blocked, Done.**
2. **`Kind`** (map, slice, role task, frontier ticket) and **`Role`** are two further single-select fields. The stage is "which role task is Running", not a status.
3. **The "Needs you" view** is the filter `status:"Waiting on you"`. #52 found no stable API for the view and the Insights chart; the migration step creates the view and the person checks it once by hand.
4. **The lead state keeps only the lead's memory** (running agents, shared resources, the interrupted role's `Progress` pointer). Status, stage log, waits and the person's touches move to the board and the sub-issues of 0014.
5. **Migration is a `setup-factory-skill` step in three phases**, so it never relies on the undocumented effect of dropping an in-use option (#52): (1) snapshot the items to a scratch file outside the repo, never committed, then add the new options while sending every old option with its id; (2) re-set each affected item per the table; (3) when no item holds a dropped value, drop the four old options. The step prints the table and item count and applies nothing until the person confirms. It runs first on a scratch Project.

## Considered options

- **B2: the same six plus a `Stage` field.** Rejected. Two fields the lead must keep in step can disagree, and the stage duplicates what the Running role task says. Keeps the old distinction in flight; the person accepted losing it.
- **B3: keep seven, add Blocked and Waiting on you (nine).** Rejected. A slice cannot be "In review" and "Waiting on you" at once, which is the signal the person reads; it fails the Destination's six values.

## Consequences

- The many-to-one step (In progress and In review both become Running) loses the old distinction on a card in flight; it is restorable only from the snapshot. Done and Backlog cards are untouched.
- Every project's option-id table in `docs/agents/factory.md` changes.
- The stage is readable only through the sub-issues of 0014, so this depends on 0014.
- **Undo cost.** Back to seven values is 2 to 3 days of plugin work plus about half a day to re-run the migration in reverse (estimates). **After 2.0.0 ships, undoing this is itself a 3.0.0 release.**

## Decided inside, overturnable

- **Three-phase migration with a snapshot.** Rejected: overwrite the option list in one call (undocumented effect on items). Undo: none, it is a procedure.
- **A first line `factory-state: 2` in `docs/agents/factory.md`** makes `/factory:run` in 2.0.0 stop with "run setup-factory-skill" on an unmigrated project. Rejected: run and write a status that does not exist. Undo: under a day.

**Provisional** until the migration has run on a real Project.
