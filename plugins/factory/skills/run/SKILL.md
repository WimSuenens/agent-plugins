---
name: run
description: Run the software factory as its lead — take a wayfinder slice (or chart one first) through requirements, contracts, a tracer-bullet build, QA and security, delivery, and docs, to a merged PR.
argument-hint: "[#slice-ticket | idea]"
disable-model-invocation: true
---

# Factory lead

You are the **lead**. Seven role agents do the work: `factory:product-owner`, `factory:architect`, `factory:developer`, `factory:qa-engineer`, `factory:security-reviewer`, `factory:devops`, `factory:docs-writer`. You brief them, read their results, move the item on the tracker, and stand between them and the person.

The roles share [the protocol](${CLAUDE_PLUGIN_ROOT}/references/protocol.md); read it once so your briefs match its templates. This repo's ownership, decision-maker level, and tracker ids are in `docs/agents/factory.md`; the tracker commands are under `## Factory operations` in `docs/agents/issue-tracker.md`. When either file is missing, stop and point the person at `/factory:setup-factory-skill`.

State lives in files and the tracker. Conversations are disposable.

## 1. Get a framed slice

A factory **item** is one `wayfinder:slice` ticket carrying a `/beachhead` frame (Question, Behaviour, Under test, Deliberately faked).

- **A slice ticket with a frame** → that is the item.
- **A slice ticket without a frame** → invoke `/wayfinding:beachhead` to frame it.
- **An idea, or nothing** → look for an open `wayfinder:map`. None that fits: invoke `/wayfinding:wayfinder` to chart one. Then invoke `/wayfinding:beachhead` to pick and frame the next slice.

Both wayfinding skills put choices to the person and wait; that conversation happens here, in the main session.

**Done when** one slice ticket with a complete frame is the item, and its number is `<id>`.

## 2. Start the item

1. Add the ticket to the board and set `Factory status` to Backlog (*Add to board*, *Set status*).
2. `git worktree add ../wt/<id> -b item/<id>` (or the location in `docs/agents/factory.md`), then create `work/<id>/` in it.
3. Write `work/<id>/00-lead-state.md`: the board item id, current status, next step, open questions.

On a resumed item, keep what exists and continue from the lead state.

**Done when** the worktree, the folder, and the lead state exist and the board shows Backlog.

## 3. Run the stages

| Stage | Role | Status on done |
|---|---|---|
| Requirement | product-owner | Ready |
| Contracts and ADRs | architect | Designed |
| Build, tracer bullet first | developer | In progress when it starts, In review when done |
| Verification | qa-engineer and security-reviewer, alongside each other | Ready to deploy when both verdicts are `pass` |
| Delivery | devops | |
| Documentation | docs-writer | |
| Merge | you | Done |

For each stage:

1. Write the brief in `work/<id>/`, filling **Inputs** from the role's *Inputs needed*, and delegate to the role.
2. Read only the result's `Status` and `Summary`. Open an artifact only to check a Done item.
3. On the status:
   - `done`: check the role's Done list against its artifacts, set the next status, post a stage summary (*Stage summary*), and update the lead state.
   - `blocked`: supply what `Missing` lists in the next brief.
   - `needs-decision`: run step 4.
4. QA and security findings go to the developer as feedback; repeat until both verdicts are `pass`.

Open the PR (*Open PR*) when the developer is done, so QA and security review the diff in place.
Production actions wait for the person's explicit approval.

**Done when** every row has run and both verdicts are `pass`.

## 4. Take a one-way door to the person

A role's question that is a two-way door: answer it yourself, or route it to the role that owns it.

A **one-way door** goes to the person:

1. If it is technical, brief the architect for two or three options and a leaning.
2. Brief the product-owner to write a decision card, per [decision-card.md](${CLAUDE_PLUGIN_ROOT}/references/decision-card.md), at the level in `docs/agents/factory.md`.
3. Post the card on the slice ticket (*Decision card*) and put it to the person in chat, in the same words.
4. When they pick a dig-deeper option, run it here: explain with an example, or invoke `/research`, `/prototype`, or `/grilling`. Come back to the card afterwards.
5. Record their choice and reason (*Decision card*), append it to the map's Decisions so far as `[provisional]`, and brief the architect to write the ADR.

The person's choice is final for this item; a later contradiction from running code is a resurvey finding, not a reason to reopen it mid-build.

**Done when** the choice is recorded on the ticket and briefed onward.

## 5. Close

1. Merge the PR once delivery and documentation are done. The last commit on `item/<id>` removes `work/<id>/`; the tracker holds the stage summaries and the ADRs hold the decisions.
2. Set `Factory status` to Done and remove the worktree.
3. Invoke `/wayfinding:wayfinder` to resurvey the map with the frame's **Under test** list in hand.

**Done when** the PR is merged, the board shows Done, and the map is resurveyed.

## 6. Offer factory feedback

Gather what went wrong with the factory itself during this item: briefs that came back `blocked` for a missing input the protocol should have named, a role doing another's work, a decision card the person struggled with, a step in this skill that did not fit. Ask the person what felt clumsy.

When there is anything, draft one issue per finding for `WimSuenens/agent-plugins`, written about the factory and stripped of this project's code, names, and data. Show the drafts and post only those the person approves:

`gh issue create --repo WimSuenens/agent-plugins --label plugin:factory --title "<title>" --body "<body>"`

**Done when** the person has approved, edited, or declined every draft.

## Context

Keep this session lean: delegate anything with verbose output and work from its summary. When the context fills, bring `work/<id>/00-lead-state.md` up to date and continue in a fresh session with `/factory:run #<id>`.
