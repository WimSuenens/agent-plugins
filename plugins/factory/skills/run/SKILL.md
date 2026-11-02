---
name: run
description: Run the software factory as its lead — clarify an idea into a destination, have wayfinding chart the route, then cut and build slice after slice through requirements, contracts, a tracer-bullet build, QA and security, delivery, and docs, to merged PRs.
argument-hint: "[idea | #map | #slice]"
disable-model-invocation: true
---

# Factory lead

You are the **lead**. Seven role agents do the work: `factory:product-owner`, `factory:architect`, `factory:developer`, `factory:qa-engineer`, `factory:security-reviewer`, `factory:devops`, `factory:docs-writer`. You brief them, read their results, move items on the tracker, and stand between them and the person.

The roles share [the protocol](${CLAUDE_PLUGIN_ROOT}/references/protocol.md); read it once so your briefs match its templates. This repo's ownership, decision-maker level, role model overrides, and tracker ids are in `docs/agents/factory.md`; the tracker commands are under `## Factory operations` in `docs/agents/issue-tracker.md`. When either file is missing, stop and point the person at `/factory:setup-factory-skill`.

Every role runs on the model in its agent file unless the `## Role models` table in `docs/agents/factory.md` overrides it. When spawning a role that has a row, pass that value as the spawn's `model`; for any other role, leave `model` out so the agent file's default holds. Check the table before the first spawn: a value other than `haiku`, `sonnet`, `opus`, or `fable` stops the run, and you tell the person which row to fix. Never fall back to the default silently.

State lives in files and the tracker. Conversations are disposable.

A **run** takes one destination from idea to a dissolved map. An **item** is one slice of that run, built on its own branch and merged on its own PR. Items run one at a time. A **frontier round** is the work of step 3, clearing the map's one-way doors outside any item; it too has its own branch and one PR.

## 0. Resume or start

- **An idea, or nothing** → start a new run at step 1.
- **`#<map>`** → read its **Factory run** section and continue from the step it names. A frontier round in progress is resumed in its worktree, from the state that section records.
- **`#<slice>`** of a map this factory runs → read `work/<id>/00-lead-state.md` in its worktree and continue that item at the step it names.

A slice ticket the factory did not cut is not an entry point; point the person at `/wayfinding:beachhead` for building outside the factory.

## 1. Clarify the destination

Grill the person with `/grilling`, together with `/domain-modeling` for the terms and decisions it settles, about **what** the destination is. How to get there is wayfinding's question, not this one. Keep it brief: stop as soon as these four fields hold and the person confirms them.

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

This step runs as a **frontier round**:

1. From an up-to-date main, `git worktree add ../wt/frontier-<map> -b frontier/<map>` (or the location in `docs/agents/factory.md`).
2. For each ticket you work, create `work/frontier-<ticket>/` in that worktree. Briefs, results, options and cards there use the protocol's templates, and every commit starts with `#<ticket> <role>: <what>`.
3. Track the round only in the map's Factory run section: the branch, the tickets in progress, open cards and tasks, and the running agents as in an item's lead state. There is no lead-state file for a frontier round.

Work every open `lock now` ticket on the map by its type, without waiting on one to start the next (until a usage limit is hit; see *Interruptions*):

- **Research** → a subagent does the reading itself, AFK, following `/research`'s source rules but spawning no background agent of its own. It keeps its report in `work/frontier-<ticket>/` and posts the **full findings** as the ticket's resolution comment, which is the durable source ADRs cite. No `research/<name>` branch is created.
- **Prototype** → brief the architect for the two or three options the prototype must show, then the developer to build them with `/prototype` on a throwaway branch `prototype/<ticket>`, outside any item worktree. Then take the decision to the person as in step 7, with the prototype linked on the card. The prototype is built for the person; it does not decide.
- **Grilling** → a decision card per step 7, offering **Question me** (`/grilling`) first.
- **Task** → manual work, not a decision. Post a task request to the person (*Task request*), using `/wizard` where they must click through a dashboard.

Resolve each ticket as wayfinder's *Work a ticket* does (resolution comment, close, Decisions so far, ADR for a one-way door), then resurvey. ADRs are written in the frontier worktree by the architect, and cite the ticket comment holding the card, the decision, or the findings, never a path under `work/`.

Review every result's `Decisions` as in step 6's *Two-way decisions*: post them on the frontier ticket being worked and in chat, and track corrections in the Factory run section instead of a lead state.

An open card or task blocks only the tickets and slices that hang off it through a blocking edge. Go on with everything else.

When no unblocked one-way door is left and no correction or card on the round's tickets is open, end the round:

1. The round's last commit removes `work/`.
2. Open one PR from `frontier/<map>` carrying only ADRs and glossary changes.
3. Ask **merge and clean up?** as in step 8.2; a frontier round sets no `Factory status`. On approval, merge the PR to main and clean up (*Merge PR*), before step 4 cuts the next item.

A card decided after its round merged, or one-way doors reopened by a resurvey, start a **new** frontier round on a fresh `frontier/<map>` branch from main.

**Done when** no unblocked one-way door is left on the frontier, the person approved, the round's PR is merged, and its worktree and branch are gone.

## 4. Cut the next slice

Invoke `/wayfinding:beachhead` to pick and frame the next slice from what is unblocked. Its number is `<id>`.

**Done when** one slice ticket with a complete frame (Question, Behaviour, Under test, Deliberately faked) is the item.

## 5. Start the item

1. Add the ticket to the board and set `Factory status` to Backlog (*Add to board*, *Set status*).
2. `git worktree add ../wt/<id> -b item/<id>` (or the location in `docs/agents/factory.md`), then create `work/<id>/` in it.
3. Write `work/<id>/00-lead-state.md`: the board item id, current status, next step, open questions, and a **Running agents** list with one line per running role: role, brief file, agent handle (the id you message to resume it), last commit. Keep that list current as roles start and finish; it also records interruptions and whether fan-out has gone sequential (see *Interruptions*). Once the architect's stage is done, add a **Shared resources** list too (see *Environment and shared resources*).

On a resumed item, keep what exists and continue from the lead state.

**Done when** the worktree, the folder, and the lead state exist and the board shows Backlog.

## 6. Run the stages

| Stage | Role | Status on done |
|---|---|---|
| Requirement | product-owner | Ready |
| Contracts and ADRs | architect | Designed |
| Environment, only when the item needs real infrastructure | devops, alongside the build | |
| Build, tracer bullet first | developer | In progress when it starts, In review when done |
| Verification | qa-engineer and security-reviewer, alongside each other (one after the other once a limit has been hit) | Ready to deploy when both verdicts are `pass` |
| Acceptance demo, only when QA lists human-only criteria | the person, prepared by devops or you | |
| Delivery | devops | |
| Documentation | docs-writer | |
| Merge, on the person's approval | you | Done |

For each stage:

1. Write the brief in `work/<id>/`, filling **Inputs** from the role's *Inputs needed*, and delegate to the role. Name tracker issues by number; the role reads them itself, so never copy their content into files. The product-owner's inputs include the map's Destination. Each role commits its own paths.
2. Read only the result's `Status`, `Summary`, and `Decisions` (and `Progress` after an interruption). Open an artifact only to check a Done item.
3. Review the `Decisions` (see below).
4. On the status:
   - `done`: check the role's Done list against its artifacts, set the next status, post a stage summary with its decisions (*Stage summary*), and update the lead state.
   - `blocked`: supply what `Missing` lists in the next brief.
   - `needs-decision`: run step 7.
   - `working` from an agent that has stopped, or an agent that failed on a limit before writing its result: it was cut off; follow *Interruptions*.
5. QA and security findings go to the developer as feedback; repeat until both verdicts are `pass`.


Open the PR (*Open PR*) when the developer is done, so QA and security review the diff in place.
Production actions wait for the person's explicit approval.

### Environment and shared resources

When the architect's stage is done, decide from its contracts and the slice frame whether the item needs real infrastructure: anything the frame does not list as **Deliberately faked**, such as a database, a stand-in for an external system, or a CI gate.

- **It does** → brief devops for the Environment stage, alongside the developer's build and started before the developer needs it. Its result names every shared resource it set up. The stage runs within `In progress`; it has no status of its own.
- **It does not** → skip the stage.

Write the **Shared resources** list in the lead state: each resource, and which role is using it now. Take the resources from the Environment result, or from the architect's contracts when there was no Environment stage. Keep the users current as briefs start and finish.

A role's question announcing a disruptive action on a shared resource (see the protocol's *Shared resources*) is yours to schedule: brief that role to go ahead once every other role using the resource is idle.

### Acceptance demo

QA's verdict lists the **Human-only criteria**: acceptance criteria only a person can judge in a real client. When it says `none`, skip this step. Otherwise, within `Ready to deploy` and before Delivery:

1. Have the environment prepared: by devops when the item had an Environment stage, by you otherwise.
2. Write a short script in plain language: what to open, what to do, what to expect, one step per criterion.
3. Put it to the person, let them run it, and post the outcome on the slice ticket (*Stage summary*, stage `Acceptance demo`).
4. A criterion that fails goes to the developer as feedback, like a QA finding; QA re-verifies before the demo runs again. Brief the architect to update any ADR whose status waited on the demo, before the merge.

### Two-way decisions

Every two-way door a role decided comes back in its `Decisions`. Show them to the person in chat with the stage summary, in the same words, and mark any you overturned.

- **Overturn one yourself** when it contradicts the Destination, a contract or ADR, or the map's Decisions so far.
- **The person may overturn any**, yours included, at any time.
- **An overturn** becomes a feedback brief (`Source: lead`) to the role that decided it, picked up in that role's next round. The stage in progress keeps running; never stop it for a correction. Track the correction in the lead state until the role confirms it.
- **A decision that turns out to be a one-way door** goes through step 7. The stages keep running, but the item does not merge until that card is decided.

**Done when** every row has run or was skipped, both verdicts are `pass`, every Human-only criterion passed its demo, and no correction or card on this item is open.

## 7. Take a one-way door to the person

A role's question that is a two-way door: answer it yourself, or route it to the role that owns it.

A **one-way door** goes to the person:

1. If it is technical, brief the architect for two or three options and a leaning.
2. Brief the product-owner to write a decision card, per [decision-card.md](${CLAUDE_PLUGIN_ROOT}/references/decision-card.md), at the level in `docs/agents/factory.md`. Link a prototype that was already built.
3. Post the card on the ticket it belongs to (*Decision card*) and put it to the person in chat, in the same words. Work that does not hang off the card goes on meanwhile.
4. When they pick a dig-deeper option, run it here: explain with an example, or invoke `/research`, `/prototype`, or `/grilling`. Come back to the card afterwards.
5. Record their choice and reason (*Decision card*), append it to the map's Decisions so far as `[provisional]`, and brief the architect to write the ADR, citing that comment. A card on a frontier ticket decided after its round merged starts a new frontier round for the ADR.

The person's choice is final for this item; a later contradiction from running code is a resurvey finding, not a reason to reopen it mid-build.

**Done when** the choice is recorded on the ticket and briefed onward.

## 8. Close the item and resurvey

1. Once delivery and documentation are done, put the PR to the person with its stage summaries and any open decisions, and ask one question: **merge and clean up?** Merging is never automatic, and this one approval covers the merge and the whole clean-up, the item's environment included. Until then, the item waits.
2. On approval, when the item had an Environment stage, brief devops to tear down the resources in the lead state's **Shared resources** list.
3. The last commit on `item/<id>` removes `work/<id>/`; the tracker holds the stage summaries and the ADRs hold the decisions.
4. Merge the PR and remove the worktree and branch (*Merge PR*), and set `Factory status` to Done. When the merge fails, keep the worktree and put the failure to the person.
5. Invoke `/wayfinding:wayfinder` to resurvey the map with the frame's **Under test** list in hand. Post its outcome to the person in a few lines.
6. Advance without waiting for the person again:
   - **The destination moved, or a `[locked]` decision was contradicted** → stop the run and put it to the person. Redrawing the destination is step 1 again.
   - **One-way doors on the frontier** → step 3, as a new frontier round from main.
   - **Frontier clear, destination not reached** → step 4.
   - **The map dissolves** → step 9.

**Done when** the person approved, the item's environment is torn down, the PR is merged, the worktree and branch are gone, the board shows Done, the map is resurveyed, and the next step is written into the Factory run section.

## 9. Offer factory feedback

At the end of a run, or when the person stops one, gather what went wrong with the factory itself: briefs that came back `blocked` for a missing input the protocol should have named, a role doing another's work, a decision card the person struggled with, a stream of decisions the person had to overturn, a step in this skill that did not fit. Ask the person what felt clumsy.

When there is anything, draft one issue per finding for `WimSuenens/agent-plugins`, written about the factory and stripped of this project's code, names, and data. Show the drafts and post only those the person approves:

`gh issue create --repo WimSuenens/agent-plugins --label plugin:factory --title "<title>" --body "<body>"`

**Done when** the person has approved, edited, or declined every draft.

## Interruptions

A role agent can stop mid-task on a usage or session limit (HTTP 429), often two parallel agents at once.

1. Note the interruption in the lead state (or the Factory run section, in a frontier round): which agent, when, its last commit.
2. After the limit resets, **resume the same agent** by messaging its handle to continue. Its context is intact, and its result's **Progress** says where it stood. With no result file yet, its commits on the branch show how far it got.
3. Only when resuming fails, spawn a fresh agent of that role with the same brief, telling it to continue from the **Next** in its result's Progress and the commits listed there. Update its handle under Running agents.
4. From the first limit hit on, stop running role agents in parallel for the rest of the item (or round): QA before security, Environment before the build, and one frontier ticket's role work at a time. Record this where step 1 noted the interruption, so a resumed session keeps to it.

## Context

Keep this session lean: delegate anything with verbose output and work from its summary. When the context fills, bring the item's lead state and the map's Factory run section up to date and continue in a fresh session with `/factory:run #<map>`.
