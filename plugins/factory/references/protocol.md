# Factory protocol

Every role reads this at the start of every task, then `docs/agents/factory.md` for this repo's ownership table and decision-maker level.

## Your place

The lead briefs you and you report to the lead. Your brief names one of two places:

- **An item**: the item's worktree, on branch `item/<id>`, with messages in `work/<id>/`. `<id>` is the slice ticket's number.
- **A frontier round**: the round's worktree, on branch `frontier/<map>`, with messages in `work/frontier-<id>/`. `<id>` is the number of the frontier ticket being worked (a ticket on the map), and `<map>` the map issue's number.

All coordination runs through files in that folder.
Commit only paths you own. Start each commit message with `#<id>`, then `<role>: <what>`. Commit your own paths yourself; the lead does not commit for you.
Commit at every **checkpoint**, not only at the end: a contract written, a test green, a section of a review done. Work cut off mid-way then loses at most the step in hand.

A brief may name tracker issues as inputs by number. Read them yourself (`gh issue view <n>`).

## Ownership

One owner per path, as listed in `docs/agents/factory.md`. Propose changes to other paths in a result or question.
Every role writes its own message files in its `work/` folder.

## Shell

Every role has a shell. How far it reaches depends on the role:

- **architect and product-owner**: read the tracker (`gh issue view`, `gh issue list`), read git (`git status`, `git log`, `git diff`), and `git add` and `git commit` the paths you own. Nothing else: no tracker writes (comments, labels and cards are the lead's), and no processes started.
- **developer, qa-engineer, security-reviewer, devops, docs-writer**: the full shell your task needs, under the same rules for all five, including *Processes and ports* and *Shared resources* below.

This scope is an agreement, not a technical boundary; keep to it.

## Citations

An ADR, requirement, or doc that lands on main never cites a path under `work/`, because `work/` is removed before the merge. Cite the tracker comment that holds the decision card, the decision, or the findings instead.

## Messages

Files in `work/<id>/` (or `work/frontier-<id>/`) are named `NN-<type>-<role>.md`; NN counts up per folder.

Paths in a message file are worktree-relative (`plugins/factory/agents/developer.md`), relative to the repo's parent for another worktree (`../wt/<id>`), or start with `~/` for anything under the home directory (`~/.claude/plugins/cache/...`). Never write an absolute path under the home directory: `work/` is merged into the project's history with every commit and stays there for good. This covers every message type, the lead state included, and commands in a message (`~/` or `"$HOME"/...`). A spawn prompt is chat, not a file, and is outside the rule.

Brief (lead → role):

    # Brief: <role> — <id>
    Goal: <one sentence>
    Inputs: <file paths and tracker issue numbers>
    Constraints: <list>
    Output: <paths>
    Done: <the role's Done list>

Result (role → lead):

    # Result: <role> — <id>
    Status: working | done | blocked | needs-decision
    Progress:
      Done: <steps finished, with their commits>
      Next: <the step in hand, then what follows>
    Summary: <at most 10 lines>
    Artifacts: <paths>
    Decisions: <one line per two-way door you decided: chosen / rejected / cost to undo, or none>
    Open questions: <list, or none>
    Missing: <inputs, when blocked>
    Decision card: <path, when needs-decision>

Write your result file as soon as you start, with `Status: working`, and update **Progress** at every checkpoint commit. When you are cut off, a resumed or fresh agent reads it and continues from **Next**. Fill in the other fields when you stop, whatever the status.

Feedback (lead → role):

    # Feedback: <role> — <id>
    Source: qa | security | architect | lead
    Findings:
    1. <location> — <severity> — <required fix>
    Re-verify: <what>

Question (role → lead):

    # Question: <role> — <id>
    Question: <one concrete question>
    Options: A <…> / B <…>
    Leaning: <your pick and why>

## Missing input

Compare the brief against your role's **Inputs needed**. When one is absent, write a result with `Status: blocked` and list it under `Missing`. Work resumes on the lead's next brief.

## Processes and ports

For every role that starts processes (all but architect and product-owner):

- Stop only processes you started. Keep track of each one you start, and stop it by the end of your work at the latest. A process you did not start is never yours to stop or kill.
- Let the OS pick a port (port 0), or probe for a free one. Never free a port by stopping its owner.
- When a fixed port you need is taken, write a result with `Status: blocked`, naming the port and the process that holds it under `Missing`. The lead asks the person.

## Shared resources

For every role that starts processes, when the item runs against real infrastructure (a database, a stand-in for an external system, a CI gate):

- Use your own database or schema and your own test identities, with random ids. Share no fixtures with other roles.
- Before a disruptive action on a shared resource (restart, reset, destroy, or deleting shared test data), write a question to the lead naming the resource and the action. Hold the action until a brief from the lead schedules it, for when the other roles are idle; go on with the rest of your work meanwhile.

## Doors

Sort every decision you meet with the `/wayfinding:reversibility` door vocabulary.

- A **two-way door** inside your authority: decide it without waiting, and list it under `Decisions` in your result. List every one; the lead does the filtering. The lead or the person may overturn it later through a feedback brief with `Source: lead`; apply that in your next round like any other finding.
- A **one-way door**, or anything outside your authority: write a question to the lead. The lead routes one-way doors to the product-owner, who turns them into a decision card for the person.

## Memory

Your memory directory holds craft: patterns, gotchas, and style learned in this role.
Project state lives in `work/` and `docs/`; decisions live in `docs/adr/`.
Other roles' memory directories belong to them; the plugin's guard hook keeps them that way. Ask the lead for what you need from another role.
A lesson other roles need goes in your result, so its owner writes it into a shared artifact.
Finish every task by consolidating memory: merge duplicates, drop stale notes, keep `MEMORY.md` under 200 lines.
