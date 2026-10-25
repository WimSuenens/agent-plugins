# Factory protocol

Every role reads this at the start of every task, then `docs/agents/factory.md` for this repo's ownership table and decision-maker level.

## Your place

You work in the item's worktree, on branch `item/<id>`. The lead briefs you and you report to the lead.
All coordination runs through files in `work/<id>/`. `<id>` is the slice ticket's number.
Commit only paths you own. Start each commit message with `#<id>`, then `<role>: <what>`.

## Ownership

One owner per path, as listed in `docs/agents/factory.md`. Propose changes to other paths in a result or question.
Every role writes its own message files in `work/<id>/`.

## Messages

Files in `work/<id>/` are named `NN-<type>-<role>.md`; NN counts up per item.

Brief (lead → role):

    # Brief: <role> — <id>
    Goal: <one sentence>
    Inputs: <file paths>
    Constraints: <list>
    Output: <paths>
    Done: <the role's Done list>

Result (role → lead):

    # Result: <role> — <id>
    Status: done | blocked | needs-decision
    Summary: <at most 10 lines>
    Artifacts: <paths>
    Open questions: <list, or none>
    Missing: <inputs, when blocked>
    Decision card: <path, when needs-decision>

Feedback (lead → role):

    # Feedback: <role> — <id>
    Source: qa | security | architect
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

## Doors

Sort every decision you meet with the `/wayfinding:reversibility` door vocabulary.

- A **two-way door** inside your authority: decide it, and note it in your result.
- A **one-way door**, or anything outside your authority: write a question to the lead. The lead routes one-way doors to the product-owner, who turns them into a decision card for the person.

## Memory

Your memory directory holds craft: patterns, gotchas, and style learned in this role.
Project state lives in `work/` and `docs/`; decisions live in `docs/adr/`.
Other roles' memory directories belong to them; the plugin's guard hook keeps them that way. Ask the lead for what you need from another role.
A lesson other roles need goes in your result, so its owner writes it into a shared artifact.
Finish every task by consolidating memory: merge duplicates, drop stale notes, keep `MEMORY.md` under 200 lines.
