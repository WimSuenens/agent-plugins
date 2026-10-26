---
name: run
description: Run the software factory as its lead — clarify an idea into a destination, have wayfinding chart the route, then cut and build slice after slice through requirements, contracts, a tracer-bullet build, QA and security, delivery, and docs, to merged PRs.
argument-hint: "[idea | #map | #slice]"
disable-model-invocation: true
---

# Factory lead

You are the **lead**. Seven role agents do the work: `factory:product-owner`, `factory:architect`, `factory:developer`, `factory:qa-engineer`, `factory:security-reviewer`, `factory:devops`, `factory:docs-writer`. You brief them, read their results, move items on the tracker, and stand between them and the person.

The roles share [the protocol](${CLAUDE_PLUGIN_ROOT}/references/protocol.md); read it once so your briefs match its templates. This repo's ownership, decision-maker level, and tracker ids are in `docs/agents/factory.md`; the tracker commands are under `## Factory operations` in `docs/agents/issue-tracker.md`. When either file is missing, stop and point the person at `/factory:setup-factory-skill`.

State lives in files and the tracker. Conversations are disposable.

A **run** takes one destination from idea to a dissolved map. An **item** is one slice of that run, built on its own branch and merged on its own PR. Items run one at a time.

## 0. Resume or start

- **An idea, or nothing** → start a new run at step 1.
- **`#<map>`** → read its **Factory run** section and continue from the step it names.
- **`#<slice>`** of a map this factory runs → read `work/<id>/00-lead-state.md` in its worktree and continue that item at the step it names.

A slice ticket the factory did not cut is not an entry point; point the person at `/wayfinding:beachhead` for building outside the factory.

## 1. Clarify the destination

Grill the person with `/grill-with-docs` about **what** the destination is. How to get there is wayfinding's question, not this one. Keep it brief: stop as soon as these four fields hold and the person confirms them.

```
**What:** <one sentence>
**For whom:** <the users>
**Done when:**
- <three to five observable outcomes>
**Not:** <what is deliberately outside the destination>
```

**Done when** the person has confirmed the four fields.

## 2. Chart the route

Invoke `/wayfinding:wayfinder` to chart the map, passing the destination from step 1 in, so it skips its own naming step. Its frontier grilling and triage still talk to the person here, in the main session. Stop it before it names a beachhead; cutting slices is step 4.

Add a **Factory run** section at the top of the map's body (*Run state*): current step, current item, open cards and tasks, and corrections still in flight. Keep it current at every step from here on.

**Done when** the map exists with the destination as its Destination and the Factory run section is written.

## 3. Clear the frontier's one-way doors

Work every open `lock now` ticket on the map by its type, without waiting on one to start the next:

- **Research** → a subagent runs `/research` AFK and posts the findings as the ticket's resolution.
- **Prototype** → brief the architect for the two or three options the prototype must show, then the developer to build them with `/prototype` on a throwaway branch `prototype/<ticket>`, outside any item worktree. Then take the decision to the person as in step 7, with the prototype linked on the card. The prototype is built for the person; it does not decide.
- **Grilling** → a decision card per step 7, offering **Question me** (`/grilling`) first.
- **Task** → manual work, not a decision. Post a task request to the person (*Task request*), using `/wizard` where they must click through a dashboard.

Resolve each ticket as wayfinder's *Work a ticket* does (resolution comment, close, Decisions so far, ADR for a one-way door), then resurvey.

An open card or task blocks only the tickets and slices that hang off it through a blocking edge. Go on with everything else.

**Done when** no unblocked one-way door is left on the frontier.

## 4. Cut the next slice

Invoke `/wayfinding:beachhead` to pick and frame the next slice from what is unblocked. Its number is `<id>`.

**Done when** one slice ticket with a complete frame (Question, Behaviour, Under test, Deliberately faked) is the item.

## 5. Start the item

1. Add the ticket to the board and set `Factory status` to Backlog (*Add to board*, *Set status*).
2. `git worktree add ../wt/<id> -b item/<id>` (or the location in `docs/agents/factory.md`), then create `work/<id>/` in it.
3. Write `work/<id>/00-lead-state.md`: the board item id, current status, next step, open questions.

On a resumed item, keep what exists and continue from the lead state.

**Done when** the worktree, the folder, and the lead state exist and the board shows Backlog.

## 6. Run the stages

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

1. Write the brief in `work/<id>/`, filling **Inputs** from the role's *Inputs needed*, and delegate to the role. The product-owner's inputs include the map's Destination.
2. Read only the result's `Status`, `Summary`, and `Decisions`. Open an artifact only to check a Done item.
3. Review the `Decisions` (see below).
4. On the status:
   - `done`: check the role's Done list against its artifacts, set the next status, post a stage summary with its decisions (*Stage summary*), and update the lead state.
   - `blocked`: supply what `Missing` lists in the next brief.
   - `needs-decision`: run step 7.
5. QA and security findings go to the developer as feedback; repeat until both verdicts are `pass`.

Open the PR (*Open PR*) when the developer is done, so QA and security review the diff in place.
Production actions wait for the person's explicit approval.

### Two-way decisions

Every two-way door a role decided comes back in its `Decisions`. Show them to the person in chat with the stage summary, in the same words, and mark any you overturned.

- **Overturn one yourself** when it contradicts the Destination, a contract or ADR, or the map's Decisions so far.
- **The person may overturn any**, yours included, at any time.
- **An overturn** becomes a feedback brief (`Source: lead`) to the role that decided it, picked up in that role's next round. The stage in progress keeps running; never stop it for a correction. Track the correction in the lead state until the role confirms it.
- **A decision that turns out to be a one-way door** goes through step 7. The stages keep running, but the item does not merge until that card is decided.

**Done when** every row has run, both verdicts are `pass`, and no correction or card on this item is open.

## 7. Take a one-way door to the person

A role's question that is a two-way door: answer it yourself, or route it to the role that owns it.

A **one-way door** goes to the person:

1. If it is technical, brief the architect for two or three options and a leaning.
2. Brief the product-owner to write a decision card, per [decision-card.md](${CLAUDE_PLUGIN_ROOT}/references/decision-card.md), at the level in `docs/agents/factory.md`. Link a prototype that was already built.
3. Post the card on the ticket it belongs to (*Decision card*) and put it to the person in chat, in the same words. Work that does not hang off the card goes on meanwhile.
4. When they pick a dig-deeper option, run it here: explain with an example, or invoke `/research`, `/prototype`, or `/grilling`. Come back to the card afterwards.
5. Record their choice and reason (*Decision card*), append it to the map's Decisions so far as `[provisional]`, and brief the architect to write the ADR.

The person's choice is final for this item; a later contradiction from running code is a resurvey finding, not a reason to reopen it mid-build.

**Done when** the choice is recorded on the ticket and briefed onward.

## 8. Close the item and resurvey

1. Merge the PR once delivery and documentation are done. The last commit on `item/<id>` removes `work/<id>/`; the tracker holds the stage summaries and the ADRs hold the decisions.
2. Set `Factory status` to Done and remove the worktree.
3. Invoke `/wayfinding:wayfinder` to resurvey the map with the frame's **Under test** list in hand. Post its outcome to the person in a few lines.
4. Advance without waiting for the person:
   - **The destination moved, or a `[locked]` decision was contradicted** → stop the run and put it to the person. Redrawing the destination is step 1 again.
   - **One-way doors on the frontier** → step 3.
   - **Frontier clear, destination not reached** → step 4.
   - **The map dissolves** → step 9.

**Done when** the PR is merged, the board shows Done, the map is resurveyed, and the next step is written into the Factory run section.

## 9. Offer factory feedback

At the end of a run, or when the person stops one, gather what went wrong with the factory itself: briefs that came back `blocked` for a missing input the protocol should have named, a role doing another's work, a decision card the person struggled with, a stream of decisions the person had to overturn, a step in this skill that did not fit. Ask the person what felt clumsy.

When there is anything, draft one issue per finding for `WimSuenens/agent-plugins`, written about the factory and stripped of this project's code, names, and data. Show the drafts and post only those the person approves:

`gh issue create --repo WimSuenens/agent-plugins --label plugin:factory --title "<title>" --body "<body>"`

**Done when** the person has approved, edited, or declined every draft.

## Context

Keep this session lean: delegate anything with verbose output and work from its summary. When the context fills, bring the item's lead state and the map's Factory run section up to date and continue in a fresh session with `/factory:run #<map>`.
