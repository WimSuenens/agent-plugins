---
name: run
description: "Run the software factory as its lead — one cycle over a standing backlog: process intake, clarify and chart the map, then build every ready slice whose path list does not overlap another's, through requirements, contracts, a tracer-bullet build, QA and security, delivery, and docs, to merged PRs, until the backlog is empty, the optional budget is reached or you stop it."
argument-hint: "[idea | #map | #slice]"
disable-model-invocation: true
---

# Factory lead

You are the **lead**. Eight role agents work for you: seven do the work, and `factory:integrator` is the dispatcher (see *The integrator*). The seven: `factory:product-owner`, `factory:architect`, `factory:developer`, `factory:qa-engineer`, `factory:security-reviewer`, `factory:devops`, `factory:docs-writer`. You brief them, read their results, move items on the tracker, and stand between them and the person.

Plugin root: ${CLAUDE_PLUGIN_ROOT}

Every script call below uses this substituted path (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh" …`); the variable is not in the Bash environment, so never rely on `$CLAUDE_PLUGIN_ROOT` inside a shell command.

The roles share [the protocol](${CLAUDE_PLUGIN_ROOT}/references/protocol.md); read it once so your briefs match its templates. This repo's ownership, decision-maker level, role model overrides, and tracker ids are in `docs/agents/factory.md`; the tracker commands are under `## Factory operations` in `docs/agents/issue-tracker.md`. When either file is missing, stop and point the person at `/factory:setup-factory-skill`. A project whose `docs/agents/factory.md` does not carry `factory-state: 2` on line 1 is refused at step 0, before anything else.

When the `## Factory operations` section has no *Post hansei* bullet, the project's tracker doc predates factory 1.0.0: use the `## Factory operations` section of `${CLAUDE_PLUGIN_ROOT}/skills/setup-factory-skill/references/issue-tracker-github.factory.md` for the whole item instead, and tell the person once that replacing their section with it (`/factory:setup-factory-skill`, step 6) brings the project up to date. When the section has *Post hansei* but lacks a bullet this standard names for the baseline or the A3 (*Find baseline*, *Create baseline*, *Pin baseline*, *Read baseline*, *Edit baseline*, *Find records*, *Find A3s*, *Find A3*, *Post A3*, *Edit A3*), use that bullet from the template's section, and tell the person once that replacing their section with the template's (`/factory:setup-factory-skill`, step 6) brings the project up to date. Never edit the project's tracker doc yourself.

While an item runs you keep a ledger (one comment on the slice ticket; every ledger post and every edit is scanned first, *Scan before posting*) and, at its close, post one hansei record on the slice ticket; both are defined in [hansei.md](${CLAUDE_PLUGIN_ROOT}/references/hansei.md). Read it at step 5 and at step 8 (section 6 at step 8.3a). The Factory baseline and the per-run A3 are defined in [baseline.md](${CLAUDE_PLUGIN_ROOT}/references/baseline.md) and [a3.md](${CLAUDE_PLUGIN_ROOT}/references/a3.md): read `baseline.md` at step 0, at step 8.10 and at step 9, and `a3.md` at step 9 and whenever an override is written. The rules for stopping the line, for overrides and for the fence are the protocol's *Andon*, *Overrides* and *Never overridable locally*; your procedure is `## Andon` below.

Every role runs on the model in its agent file unless the `## Role models` table in `docs/agents/factory.md` overrides it. When spawning a role that has a row, pass that value as the spawn's `model`; for any other role, leave `model` out so the agent file's default holds. Check the table before the first spawn: a value other than `haiku`, `sonnet`, `opus`, or `fable` stops the run, and you tell the person which row to fix. Never fall back to the default silently.

State lives in the tracker (the board, the role-task sub-issues, the ledger) and in files. Conversations are disposable. The board is the only place a status lives; **The board**, **Role tasks** and **Parallel slices** below say how.

A **run** is one cycle over the map's standing backlog (*The run cycle*). A **map** is a long-lived direction that new ideas keep refining; it is never dissolved by the factory. An **item** is one slice of a run, built on its own branch and merged on its own PR. There is no maximum of slices: items run side by side whenever their path lists do not overlap (ADR 0016, amended by ADR 0017). The only brake is the optional per-run budget `run-budget` (`factory-config.sh budget`). A **frontier round** is the work of step 3, clearing the map's one-way doors outside any item; it too has its own branch and one PR.

**This skill is a router.** Steps 0 to 7, *The run cycle*, *The integrator*, *The board*, *Needs you*, *Role tasks*, *Scan before posting* and *Role knowledge* are written out below, because every item needs them. Every other section keeps its heading here with one line that says when to read the reference it moved to (`references/run-*.md`) and what the reference covers. A name in italics (*Andon*, *Procedure*, *Run start*, *Settle round*) is a heading of this file or of the reference its line names. Read a reference when its event happens, and not before; a rule you do not read is not applied. Only this file has `${CLAUDE_PLUGIN_ROOT}` substituted: where a reference writes it in a command, use the path on the `Plugin root:` line above.

## 0. Resume or start

**First**, before the choice below, before any call to the board and before any mutation, run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/factory-config.sh" state`. On a non-zero exit stop and print its stderr line (it says `run setup-factory-skill`): nothing else in this skill runs on a project that has not migrated; exit 6 means no flow table. A leftover `parallel-limit` line is ignored: `state` prints a note on stderr and exits 0, and setup removes the line. Then run `... factory-config.sh budget`; on exit 5 stop and name the line to fix, as for a bad role model value, and start nothing. Its output is the run's budget (`none`, `<N> tokens` or `<N> hours`).

- **An idea, or nothing** → start a new run at step 1.
- **`#<map>`** → read its **Factory run** section and continue from the step it names. A frontier round under way is resumed in its worktree, from the state that section records. Read the board (*List board*) and add any card that is missing.
- **`#<slice>`** of a map this factory runs → read `work/<id>/00-lead-state.md` in its worktree and continue that item at the step it names. Find the role tasks (*Find role task*) and the ledger (*Find ledger*) before creating or posting anything.

Whichever entry applies, run the checks of `## Andon`, *Run start*, before step 1 or the next item starts. On a resumed run they include the FREEZE check. They also include the baseline check of `references/baseline.md`: *Find baseline* and act on its result (section 2), then the repair check (section 8.2).

**Intake at every run start.** Before step 1 or the next item, and again whenever the person says an idea is waiting, run `## Idea intake` below: drop the inbox, then triage what is untriaged. Items not triaged are handled at the next run start.

A slice ticket the factory did not cut is not an entry point; point the person at `/wayfinding:beachhead` for building outside the factory.

## The run cycle

A run is one cycle over the standing backlog. The backlog is every open idea, candidate slice, ready slice and frontier ticket of the map. The map is a long-lived direction: new ideas refine its Destination and Decisions so far, and it is never dissolved by the factory. When `/wayfinding:wayfinder` reports the map dissolvable, keep it and say so.

**Each run restarts every mechanism**, in this order: intake (*Idea intake*), maintenance, improvement (the Settle round of an earlier run, *Run start*), then slice building (steps 3 to 8). Improvement also reports the improvements applied earlier (*Improvement loop*). Maintenance runs only when its signals say so (*Maintenance cycle*).

**The budget.** `run-budget` in `docs/agents/factory.md` is `none`, `<N> tokens` or `<N> hours`, read by `factory-config.sh budget`. Measure the spent amount in the unit of the budget: tokens from `bash "${CLAUDE_PLUGIN_ROOT}/scripts/token-spend.sh"` over the run's items, hours from the run's start. Check `factory-config.sh reached <spent>` before every start of a slice or role task and at every item close. On exit 1 the budget is reached: start nothing new, let each role in hand finish its step, record the next step in each lead state and in the Factory run section so every slice in flight stays resumable with `/factory:run #<slice>`, say `budget reached` to the person, and go to step 9.

**The measurement profile.** `measurement` in `docs/agents/factory.md` is `full` (the default, and the same as no line) or `lite`, read by `factory-config.sh measurement`. Under `measurement: lite` the hansei record is the short form (`hansei.md`, *The lite record*), and the close scan of step 8.2 and the token totals of step 8.3 run only when `bash "${CLAUDE_PLUGIN_ROOT}/scripts/factory-config.sh" analysis` exits 0, or exits 0 with `--asked` after the person asks for them. A `tokens` run budget still reads the spend it needs. Baseline and A3 are the same under full and lite.

**Skipping roles.** For a trivial slice the lead may skip a role of step 6: it writes the reason on the ticket (a comment on the slice ticket, scanned first), and runs `bash "${CLAUDE_PLUGIN_ROOT}/scripts/skip.sh" check <role> --reason "<reason>" [--touches <area>]... <contract file>...` before it; exit 1 refuses the skip and the role runs. QA and the runtime proof are never skipped, and no role is skipped when the slice touches contracts, authentication, secrets, a data migration or a one-way door (declare any of them with `--touches`); both scripts read one definition of those areas, `scripts/protected-areas.sh` (a project adds its own with one line in `docs/agents/factory.md`, `protected-paths: <glob>, <glob>`), and the skip check runs on the same path list as the gate: it adds the slice's own contract files, and once the PR exists you pass its changed paths with `--paths "<paths>"`, the list the gate gets. A security review skipped this way is passed to the merge gate as `--security skipped --skip-reason "<reason>"`; the gate blocks it for a protected slice, and a missing or other verdict blocks as before. Record each skipped role in the ledger's Notes; the integrator counts them (`measure skipped`) and compares the rework of skipped and full slices (`measure rework`), so a skip that raises rework becomes a finding for the improvement loop.

**A run ends** when the backlog is empty (after intake and after the last merge), when the budget is reached, or when the person stops it. It closes at step 9 with the A3 and the baseline.

## Maintenance cycle

At run start, before intake, to announce whether maintenance runs, and when `maintenance.sh decide` says `run`: read `references/run-intake.md` (*Maintenance cycle*: the signals, the announce line, candidates only, one-way doors, the per-cycle budget).

## The integrator

`factory:integrator` is the dispatcher. You call it at fixed events, and it returns a dispatch plan: which slices start, in which order, which merges come first, which pause and why. Note that subagents cannot spawn subagents, so you spawn the roles the plan names. Priority stays with you and the person; the integrator decides order only within it and advises when it notices a dependency.

The events: intake processed, slice ready, PR opened, merge done, map changed. At each one, take a board snapshot to a scratch file, create a role task for the integrator (*Role tasks*), spawn it, and read its plan. It keeps no state: the same board gives the same plan.

**The merge train.** After the person approves *merge and clean up?* (step 8.1), the integrator does the mechanical merge: create a role task for it with `Approved: <time>`, the item number and the worktree of each approved slice, in the order of the plan's `merge` lines, and spawn it. It runs `scripts/merge-train.sh` for each slice in turn (rebase on the one before, ADR number, the project's release hook when it declares one, merge, clean-up) and stops at the first failed step with the worktree kept; each slice is approved by the person or has passed the gate (`scripts/merge-gate.sh`, step 8.1), and the card turning `Done` stays yours.

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

Once the four fields are confirmed the product owner creates `docs/direction.md` if it is missing (`agents/product-owner.md`, *Direction document*). That is a two-way step: no question to the person, reported at the next stage boundary. The file is a minimal `goal` and `current` plus one History line naming the map, written by a role task of the product owner that lands with the first PR that follows. It is the repository's own direction document, not the design plugin's direction brief.

## 2. Chart the route

Invoke `/wayfinding:wayfinder` to chart the map, passing the destination from step 1 in, so it skips its own naming step. Its frontier grilling and triage still talk to the person here, in the main session. Stop it before it names a beachhead; cutting slices is step 4.

The map's number identifies the run: the current run is `#<map>`, as `## Andon`, *Run identity*, says.

When the map's Destination changes later (a frontier round, a resurvey), the product owner updates `current` and adds one History line in the same way; it never changes a line the factory did not write.

Add a **Factory run** section at the top of the map's body (*Run state*). It holds the step, the branch(es), the `FREEZE:` line, the pointers (`hansei: …`, `closed in this run`, `baseline:`), the open andon lines, the open cards and tasks, the corrections still in flight, and one line `in flight: #<id> (item/<id>), …` (or `in flight: none`). **It holds no status word**: the board is the only place a status lives.

```
## Factory run

- started: <UTC time of the run start>
- step: <step>
- in flight: #<id> (item/<id>), … | none
- FREEZE: <sha> (<semver>)
- hansei: <comment URL> (measure 7 pending)
- closed in this run: #<id> <comment URL>, …
- baseline: <note>
```

Add the map and every child ticket of the map to the board now (*The board*, run start). Keep the section current at every step from here on.

**Done when** the map exists with the destination as its Destination, the Factory run section is written, and the map and its children are on the board.

## 3. Clear the frontier's one-way doors

This step runs as a **frontier round**:

1. From `origin/main` (the script fetches it and branches from it; exit 5 means the fetch failed: tell the person, do not build on a stale base), `bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" add frontier <map>` (it creates `.claude/worktrees/frontier-<map>` on `frontier/<map>` and prints the path; the location is in `docs/agents/factory.md`). When this is the run's first worktree, bind `kept … for next run` overrides (`## Andon`, *Run identity*).
2. For each ticket you work, create `work/frontier-<ticket>/` in that worktree. Each role task is a sub-issue of the **frontier ticket** (never the map; *Role tasks*), its brief the issue body. Results, questions, options and cards are files there that use the protocol's templates, and every commit starts with `#<ticket> <role>: <what>`.
3. Track the round only in the map's Factory run section: the branch, the tickets being worked, open cards and tasks, and the running agents as in an item's lead state. There is no lead-state file for a frontier round.

Work every open `lock now` ticket on the map by its type, without waiting on one to start the next (until a usage limit is hit; see *Interruptions*):

- **Research** → a subagent does the reading itself, AFK, following `/research`'s source rules but spawning no background agent of its own. It keeps its report in `work/frontier-<ticket>/` and posts the **full findings** as the ticket's resolution comment, which is the durable source ADRs cite. No `research/<name>` branch is created.
- **Prototype** → brief the architect for the two or three options the prototype must show, then the developer to build them with `/prototype` on a throwaway branch `prototype/<ticket>`, outside any item worktree. Then take the decision to the person as in step 7, with the prototype linked on the card. The prototype is built for the person; it does not decide.
- **Grilling** → a decision card per step 7, offering **Question me** (`/grilling`) first.
- **Task** → manual work, not a decision. Post a task request to the person (scan it first, *Scan before posting*; then *Task request*), using `/wizard` where they must click through a dashboard.

Resolve each ticket as wayfinder's *Work a ticket* does (resolution comment, close, Decisions so far, ADR for a one-way door), then resurvey. A frontier round keeps no ledger: when a ticket is resolved, set `Tokens` and `Minutes` of each of its role tasks to `not captured (frontier round keeps no ledger)` (*Set field text*), so no field is left empty. ADRs are written in the frontier worktree by the architect, and cite the ticket comment holding the card, the decision, or the findings, never a path under `work/`.

Review every result's `Decisions` as in step 6's *Two-way decisions*: post them on the frontier ticket being worked and in chat, and track corrections in the Factory run section instead of a lead state.

An open card or task blocks only the tickets and slices that hang off it through a blocking edge. Go on with everything else.

When no unblocked one-way door is left and no correction or card on the round's tickets is open, end the round:

1. The round's last commit removes `work/`.
2. Run the *Open PR* release check (`git fetch origin main`, then `release-hook.sh check` in the round's worktree, as in step 6) with the same exit handling, then open one PR from `frontier/<map>` carrying only ADRs and glossary changes.
3. Ask **merge and clean up?** as in step 8.1 (the map card turns `Waiting on you` with its needs-you comment first); the round itself is no card, its tickets are. On approval, merge the PR to main and clean up (*Merge PR*), before step 4 cuts the next item.

A card decided after its round merged, or one-way doors reopened by a resurvey, start a **new** frontier round on a fresh `frontier/<map>` branch from main.

**Done when** no unblocked one-way door is left on the frontier, the person approved, the round's PR is merged, and its worktree and branch are gone.

## 4. Cut the next slice

Invoke `/wayfinding:beachhead` to pick and frame the next slice from what is unblocked. Its number is `<id>`.

**No one-way doors.** When charting found none, the map has no `lock now` ticket and `/wayfinding:beachhead` finds an empty exposure list. Do not follow its route back to the wayfinder's Advance step, and do not dissolve the map: the factory never dissolves a map. Cut one slice that reaches the Destination's **Done when**. Take its **Under test** lines from the standing constraints recorded in the map's Notes, or from the Done-when outcomes themselves when Notes holds none.

Add the new ticket to the board now: `Kind` slice, `Factory status` `Ready`. A slice may be cut while another is in flight; its path list is compared before it is built (*Parallel slices*).

**Done when** one slice ticket with a complete frame (Question, Behaviour, Under test, Deliberately faked) is the item and is on the board.

## 5. Start the item

0. **The start gate, budget part** (*The run cycle*, *Parallel slices*). When `factory-config.sh reached <spent>` exits 1, the slice stays `Ready` and you say `budget reached`. Otherwise go on. There is no count of slices in flight to check.
1. The ticket is on the board with `Kind` slice (added when it was cut). Add it if it is not (*Add to board*, *Set status*): `Factory status` `Ready`.
2. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" add item <id>` (it creates `.claude/worktrees/<id>` on `item/<id>` and prints the path; the location is in `docs/agents/factory.md`; exit 3 means the folder is not ignored yet: run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" ignore` and commit `.gitignore` on main, or send the person to `/factory:setup-factory-skill`), then create `work/<id>/` in it. When this is the run's first worktree, bind `kept … for next run` overrides (`## Andon`, *Run identity*). Then, when step 8.10 decided that the run's experiment is written, commit it in this worktree, **after 5.2 and before the ledger of 5.3** (`#<id> lead: override <name>`, `andon: none (experiment)`; `references/a3.md`, section 5): the label's `overrides at start` lists it and this item is an after-item. On a resumed run apply the rule of `references/a3.md`, section 5 again from the records; nothing was stored between 8.10 and here.
3. Stamp `date -u +%FT%TZ` (`started`). Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/fingerprint.sh" "${CLAUDE_PLUGIN_ROOT}"` and write the label (release, standard and tooling fingerprints, dependency versions, your session id) as `## Label` in the lead state; start `## Findings` and `## Abnormalities`, as `references/hansei.md` defines them. Write the label's `overrides at start` line after the binding of step 5.2 and the run-start sort of `## Andon`. Then run the item-start checks of `## Andon` (kind 6 (a) and (b), kind 5 on the item worktree's `docs/agents/factory.md`) and the baseline check of step 0 again (*Find baseline*, then the repair check, `references/baseline.md` sections 2 and 8.2). **Post the ledger** (*Find ledger*, then *Post ledger* when none exists): `started`, and the results of the checks on its `start checks` line.
4. Write `work/<id>/00-lead-state.md`: the board item id, the next step, the open questions, the factory release the item is frozen on, the ADR number assigned to this slice (the next free number in `docs/adr/`, or `none`), a **Running agents** list with one line per running role task (`role task #<n>: <role> <agent id>`; the id is what you message to resume it), a **Shared resources** list once the architect's stage is done (see *Environment and shared resources*), and an **Interrupted** list (role task, agent id, since, kind, last commit, the path of its draft result). The sections of the label, findings and abnormalities follow these parts. **The lead state carries no status line**: the board holds the slice's status. The lead state and every brief follow the protocol's path rule (*Messages*): no absolute path under the home directory, only worktree-relative, `.claude/worktrees/<id>` or `~/` paths.

**Worktrees at the old location.** Before step 5.2, run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" legacy`. It lists worktrees beside the repository (`../wt/<name>`, the location before 2.4.0) and exits 10 when it finds any; the setup skill offers to move them. An item that already has one finishes there: its branch, `work/<id>/` and lead state are unchanged, and the close guard finds it by branch. A new item, frontier round or settle round always gets a worktree in `.claude/worktrees`.

On a resumed item, keep what exists and continue from the lead state.

**Done when** the worktree, the folder, the lead state (with its label and its findings and abnormalities sections) and the ledger exist, the item-start checks ran, and the board shows `Ready` (it turns `Running` with the first role task).

## 6. Run the stages

| Stage | Role |
|---|---|
| Requirement | product-owner |
| Contracts and ADRs | architect |
| Tests, for each behaviour slice, before the build | qa-engineer |
| Environment, only when the item needs real infrastructure | devops, alongside the build |
| Build, tracer bullet first | developer |
| Verification | qa-engineer and security-reviewer, alongside each other (one after the other once a limit has been hit) |
| Acceptance demo, only when QA lists human-only criteria | the person, prepared by devops or you |
| Delivery | devops |
| Documentation | docs-writer |
| Merge, on the person's approval | you |

Between the Contracts and ADRs row and the Tests row the lead takes the code-review decision (*Optional code review*); it is a decision, not a role task, and gives the slice no status.

The **stage** of a slice is the role task that is `Running`; no field holds it. Each stage is one or more role tasks (*Role tasks*); the slice card moves by the events of *The board*, not by stage.

For each stage:

1. **Create the role task and spawn the role** (*Role tasks*, create and spawn): the brief is the issue body, filled with **Inputs** from the role's *Inputs needed*. Name tracker issues by number; the role reads them itself, so never copy their content into the brief or a file. The product-owner's inputs include the map's Destination. For a role whose *Inputs needed* lists the project's test command (qa-engineer, docs-writer), put the command and how to run it on its own line in `Inputs`, never only inside a constraint. For a slice with no developer stage, the lead supplies QA's "how to run" input: the same test command, plus the targeted test from the Tests result if there is one. The brief's `Output` line names the draft result, `work/<id>/NN-result-<role>.md`. Each role commits its own paths. The developer's **Inputs** name the targeted test QA prepared (read from the Tests result); the Tests task's **Inputs** name the contracts and the criteria. No tracker content is copied in.
2. **Read the result.** Read only the draft's `Status`, `Abnormality:` lines, `Summary`, and `Decisions` (and `Progress` after an interruption). Open an artifact only to check a Done item. When the status is not `working`, **post the result** (*Role tasks*, the closing comment), close the task, set its card, and add its row to the ledger's Tasks table with the agent ids and the completion notice's peak context (`<subagent_tokens>` or `totalTokens`).
3. Review the `Decisions` (see below). Then read the abnormalities: log the result's findings in `## Findings` and apply kind 2; apply kind 1 to a `blocked` result; after a role stage apply kind 3; on adding the row apply kind 4 (all in `## Andon`, *Detection*). Each `Abnormality:` line other than `none`, and each hit, starts an andon before any dependent brief. Put each in-force override's rule, in your own words, in the Constraints of the briefs it concerns.
4. On the status:
   - `done`: with no andon open for this result, check the role's Done list against its artifacts, post a stage summary with its decisions (scan it first, *Scan before posting*; then *Stage summary*), and update the lead state. Every stage summary also lists the overrides in `promote chosen` status, in one line (`promote chosen, still in force: <name> (<date>); …`, or nothing when there are none), because that status ends the expiry and keeps the override in force until a card is decided. After the **architect's** `done`, make the path comparison before any other brief (*Parallel slices*). Then take the code-review decision (*Optional code review*), then brief QA for the Tests stage.
   - `blocked`: supply what `Missing` lists in the next role task's brief (after the andon, when kind 1 or an `Abnormality:` line applies).
   - `needs-decision`: run step 7.
   - `working` from an agent that has stopped, or an agent that failed on a limit before writing its result: it was cut off; follow *Interruptions*.
5. QA and security findings go to the developer as a **rework task** (*Role tasks*, rework); repeat until both verdicts are `pass`. When a finding is about a rule that a script or contract states, search the plugin for every other text that states the same rule (`grep -rn`) and list those files in the feedback's `Constraints`, so the developer fixes them in the same round.

**Tests stage rules.** QA's Tests task runs after the architect's `done`, the path comparison and the code-review decision, and before the Build brief; the Build brief is never written before the Tests result names the targeted test. The contracts define the seams and the expected behaviour, so QA can write the test from them. The stage is skipped only when the contracts define no behaviour to test; the stage summary says so. Tests QA prepared may stay red until the developer's Done. A developer question about a test is routed to QA (a role task for QA), a question about a contract to the architect; you answer neither by editing `tests/` or a contract.

Every wait goes to the ledger's Waits table when it ends, and every touch the person makes to its Person's touches table when you read the answer (`references/hansei.md`, section 1).

When the developer is done, and before *Open PR*, check the diff for breadth. This is not optional: it runs on every slice. In the item worktree, list `git diff --stat origin/main...item/<id>` and compare it with the contracts: every changed file is on the `Paths:` list (QA's off-list check repeats this later and is not replaced), and the size of the change fits the behaviour the contracts name. A change in an area no contract names, a rewrite of a file the contracts only touch in one section, or a diff clearly larger than the contracts imply is unexpected breadth or scope creep: create a rework task (`Source: lead`) naming the files, and run the check again when the developer is done. Otherwise say `breadth: as expected` in the stage summary. The check reads the diff only; it runs no test and no scan.

Open the PR (*Open PR*) when the developer is done, so QA and security review the diff in place. Before `gh pr create`, always:

1. `git fetch origin main`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/release-hook.sh" check <item worktree> <id> origin/main`. It runs the release hook the project declares (a `release-hook:` line in `docs/agents/factory.md`); with no such line it prints nothing, exits 0, and there is no release step.
2. Exit 0: open the PR, and say the hook's line in the stage summary when it printed one.
3. Exit 1: do not open the PR. Create a rework task for the developer (`Source: lead`) quoting the refusal, and run *Open PR* again when it is done.
4. Exit 2: do not open the PR; put the stderr line to the person.

No instruction anywhere opens a PR without this step.

Production actions wait for the person's explicit approval (a needs-you comment first, `Cause: delivery approval`; see *The board*).

### Optional code review

When the architect's stage is done, after the path comparison and before the Tests brief (so before Build), decide from the contracts and their `Paths:` blocks whether to run a code review. The review is optional: a slice with no trigger is not reviewed. Three risk triggers, each decided from the contracts alone:

| Trigger | Fires when |
|---|---|
| shared protocols or approval/state rules | a contract's `Paths:` lists text that every role or the lead reads as a rule (the protocol, the run skill's approval, status, andon or gate steps, the `factory.md` template), and the contract changes what is allowed, who approves, or what state an item is in |
| broad cross-plugin changes | the `Paths:` lists files under two or more `plugins/<name>/` directories (the shared files `CHANGELOG.md`, `README.md` and the version file do not count) |
| significant refactors | a contract moves, renames or splits files, or changes the shape of a seam without changing behaviour |

Record the decision in one line in the lead state, `code review: yes — trigger: <name>` or `code review: no — trigger: no trigger`, and the same line in the architect stage's stage summary.

The review runs on the diff once the developer is done, beside QA and security, with `/code-review`. It covers standards, spec and scope. It does not repeat QA's execution of the tests and does not repeat the security scan. Duplicate findings are combined: a finding that QA or security also made is kept once, under the verdict that owns it, and the reviewer's copy is dropped. The non-duplicate findings go to the developer in the same rework task as QA's and security's findings (*Role tasks*, rework); the loop repeats until both verdicts are `pass`. The review has no verdict: its findings are fixed or answered by the developer in the same rework task, and they do not block the merge on their own; the QA and security verdicts stay the gates. It cannot replace the QA or the security stage, cannot make either verdict optional or non-binding, and its absence never blocks a merge.

### Environment and shared resources

When the architect's stage is done, decide from its contracts and the slice frame whether the item needs real infrastructure: anything the frame does not list as **Deliberately faked**, such as a database, a stand-in for an external system, or a CI gate.

- **It does** → brief devops for the Environment stage, alongside the developer's build and started before the developer needs it. Its result names every shared resource it set up. The stage is a role task like the others and gives the slice no status of its own.
- **It does not** → skip the stage.

Write the **Shared resources** list in the lead state: each resource, and which role is using it now. Take the resources from the Environment result, or from the architect's contracts when there was no Environment stage. Keep the users current as briefs start and finish.

A role's question announcing a disruptive action on a shared resource (see the protocol's *Shared resources*) is yours to schedule: brief that role to go ahead once every other role using the resource is idle.

### Acceptance demo

QA's verdict lists the **Human-only criteria**: acceptance criteria only a person can judge in a real client. When it says `none`, skip this step. Otherwise, before Delivery. **Order:** when any Human-only criterion names a document the docs-writer delivers (for example "a newcomer follows the README word for word"), run Documentation first, and then the demo; the demo cannot run before the document exists. Otherwise the table's order stands.

1. Have the environment prepared: by devops when the item had an Environment stage, by you otherwise.
2. Write a short script in plain language: what to open, what to do, what to expect, one step per criterion.
3. Put it to the person (a needs-you comment first, `Cause: run decision`; the slice turns `Waiting on you`), let them run it, and post the outcome on the slice ticket (scan it first, *Scan before posting*; then *Stage summary*, stage `Acceptance demo`); write the touch `demo` to the ledger.
4. A criterion that fails goes to the developer as a rework task, like a QA finding; QA re-verifies before the demo runs again. Brief the architect to update any ADR whose status waited on the demo, before the merge.

### Two-way decisions

Every two-way door a role decided comes back in its `Decisions`. Show them to the person in chat with the stage summary, in the same words, and mark any you overturned.

- **Overturn one yourself** when it contradicts the Destination, a contract or ADR, or the map's Decisions so far.
- **The person may overturn any**, yours included, at any time.
- **An overturn** becomes a rework task (`Source: lead`) for the role that decided it, picked up in that role's next round. The running stage keeps running; never stop it for a correction. Track the correction in the lead state until the role confirms it.
- **A decision that turns out to be a one-way door** goes through step 7. The stages keep running, but the item does not merge until that card is decided.

**Done when** every stage has run or was skipped, both verdicts are `pass`, every Human-only criterion passed its demo, and no correction or card on this item is open.

### Report at each stage boundary

Two lines join the stage summary. Neither is a question; nothing is ingested or decided by them.

- **New issues.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" filed-since <run start> --line` and put its line in the summary. It counts the open issues filed since the run start from two sources: issues carrying the project's own triage label (read from `docs/agents/triage-labels.md`) and issues whose body carries the marker `factory:improvement`. An issue filed under neither is not seen, and the line says which sources it read. The run start is the `started:` line of the map's Factory run section; for a Factory run section without a `started:` line (a run begun before 2.18.0): use the earliest `started:` line of the ledgers of the run's items. **Provisional:** revisit after two runs, or when a report says nothing new more than once.
- **Direction document.** When the product owner created or updated `docs/direction.md` since the last boundary, say so in one line (step 1, step 2).

## 7. Take a one-way door to the person

A role's question that is a two-way door: answer it yourself, or route it to the role that owns it.

A **one-way door** goes to the person:

1. If it is technical, brief the architect for two or three options and a leaning.
2. Brief the product-owner to write a decision card, per [decision-card.md](${CLAUDE_PLUGIN_ROOT}/references/decision-card.md), at the level in `docs/agents/factory.md`. Link a prototype that was already built.
3. Post the card on the ticket it belongs to (scan it first, *Scan before posting* with `--needs-you`; then *Decision card*), then post the needs-you comment on that ticket (`Cause: decision card`) and set it `Waiting on you` (*The board*, *Needs you*), and put the card to the person in chat, in the same words. The card and the comment name no path under `work/` and no branch (`post-text.sh scan --needs-you`). Work that does not hang off the card goes on meanwhile.
4. When they pick a dig-deeper option, run it here: explain with an example, or invoke `/research`, `/prototype`, or `/grilling`. Come back to the card afterwards.
5. Record their choice and reason (*Decision card*), add `Answered:` to the needs-you comment (*Answered*), set the ticket back to `Running`, write the touch `decision card` to the ledger (and the person wait that ended), append it to the map's Decisions so far as `[provisional]`, and brief the architect to write the ADR, citing that comment. A card on a frontier ticket decided after its round merged starts a new frontier round for the ADR.

The person's choice is final for this item; a later contradiction from running code is a resurvey finding, not a reason to reopen it mid-build.

**Done when** the choice is recorded on the ticket and briefed onward.

## 8. Close the item and resurvey

The order below is fixed; [hansei.md](${CLAUDE_PLUGIN_ROOT}/references/hansei.md) holds the record's template and rules.

1. Once delivery and documentation are done, **run the application and capture proof**: browser screenshots for a web application, a run log for a command-line tool or a library. Put it in the PR description under `## Proof`. Then run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/merge-gate.sh" check <pr> --qa <verdict> --security <verdict> [--skip-reason "<reason>"] --touches <list> --paths "<files>"` (scripts/merge-gate.sh).
   - **`auto-merge`** (exit 0): QA and security pass, CI is green, proof is attached and no one-way door is open (a security review the lead skipped under *Skipping roles* counts as `skipped`, with its `--skip-reason`; QA and the proof are never skipped). No question is asked: stamp `date -u +%FT%TZ` as the merge time (no person touch is written), and go on with the merge train and the clean-up below as if the person had said yes.
   - **`blocked`** (exit 11): a gate is not met (a non-pass verdict, CI not green, or no proof). No proof means no auto-merge. Do not merge; fix the cause or tell the person which reason the script printed.
   - **`pause`** (exit 10): a contract, authentication, secrets, a data migration or a one-way door is touched, and these are always human. Post the script's validation script in the needs-you comment (`Cause: validation`, `Options: yes or no`), set the slice `Waiting on you`, and continue with the person's answer as with the question below.

   The always-human list is fenced (F1): no override widens the auto-merge, and the person's earlier approvals are not widened by it: a yes covers that one PR, and a production action still needs its own explicit yes (the sentence on production actions at the end of step 6).

   When the gate pauses, put the PR to the person with its stage summaries and any open decisions, and ask one question: **merge and clean up?** This one approval covers the merge and the whole clean-up, the item's environment included. Until then, the item waits: post the needs-you comment first (`Cause: merge approval`, `Options: yes or no`), then set the slice `Waiting on you`. Say in the summary how many Tasks rows read `split <m>` in their `Notes` (results that needed more than one comment), so that "more than rarely" can be judged. On the yes stamp `date -u +%FT%TZ`: that is the approval time and the touch `approval`; add `Answered:` to the comment, write the touch and the `person` wait to the ledger, and set the slice back to `Running` while it closes.
After the approval of 8.1 (or its `auto-merge`), at every item close: read `references/run-close-item.md` (8.2 to 8.11 and the **Done when** of this step: the close scan, token totals, gemba walk, hansei record, board fields, teardown, the close commits, merge, resurvey, measure 7, baseline, advance).

## 9. Close the run

When the backlog is empty, the budget is reached or the person stops the run: read `references/run-close-run.md` (9.0 to 9.5 and the **Done when** of this step: the entry question, the baseline update, the A3, the settle round, the feedback offer, the close report).

## The board

The board (the GitHub Project) is where every status lives. Its ids and option ids are in the Tracker tables of `docs/agents/factory.md`; a missing cell stops the run and names the cell. The project's built-in `Status` field is not used.

| Field | Type | Options, in this order |
|---|---|---|
| `Factory status` | single select | `Backlog`, `Ready`, `Running`, `Waiting on you`, `Blocked`, `Done` |
| `Kind` | single select | `map`, `slice`, `role task`, `frontier ticket`, `idea` |
| `Role` | single select | the seven role names; set only on a `role task` card |
| `Tokens`, `Minutes`, `Hours`, `Rework rounds`, `Person touches` | text | `references/hansei.md`, section 7 |

**Kind** of a card: the map issue is `map`; a child of the map labelled `wayfinder:slice` is `slice`; a child of any other `wayfinder:*` type is `frontier ticket`; a role-task sub-issue is `role task`; a tracker issue labelled `idea` is `idea`. When the board has no `idea` option yet (a board made before 2.5.0; setup step 7 adds it), an idea is triaged from the tracker and stays off the board.

**Run start.** Add the map and every child ticket of the map to the board (*Add to board*, then *Set status* for `Factory status` and `Kind`); a child ticket cut later is added in the step that cuts it; a role task is added when it is created. On a resumed run read the board (*List board*) and add any card that is missing; *Add to board* never makes one twice. A child ticket that is neither cut nor worked is `Backlog`.

Every status below is tied to an event you can observe without `work/` or a branch. When several hold for one card the precedence is `Waiting on you`, then `Blocked`, then `Running`.

| Card | Event | Status |
|---|---|---|
| role task | you create it and spawn the role | `Running` |
| role task | its result is `working` (cut off) | stays `Running`, issue open |
| role task | its closing comment is posted and the issue closed, result `done`, `pass`, `findings`, `needs-decision`, `approved`, … | `Done` |
| role task | its result is `blocked`, comment posted and issue closed | `Blocked` |
| role task | you stop its agent for an andon | `Blocked`; `Running` when the agent is resumed |
| role task | you create the next task that supplies what a `blocked` task lacked | the blocked task becomes `Done` |
| slice | it is cut and may start (step 4) | `Ready` |
| slice | the start gate fails (budget reached, or a path overlap) | stays `Ready`; you say why |
| slice | the first role task of the item is spawned | `Running` |
| slice | you ask the person for anything (a decision card, the merge approval, a task request, the delivery approval, a resurvey pause, a missing project permission) | `Waiting on you`, with the needs-you comment first |
| slice | you read the person's answer | `Running` (or the status the answer's next event gives) |
| slice | a role task of the item ends `blocked`, or a task waits on a missing input | `Blocked` until you spawn the next task, then `Running` |
| slice | you stop work on the slice for an andon | `Blocked` until it is resumed or you carry on, then back to what it was |
| slice | its PR is merged | `Done` |
| frontier ticket | it waits on the frontier | `Backlog`; `Running` while you or a role work it; `Waiting on you` on its decision card or task request; `Done` when its resolution comment is posted and the ticket closed |
| idea | it is filed (a card is added only when the board has the `idea` option) | `Backlog`; `Running` while you triage it; `Waiting on you` on its decision card; `Done` when its outcome comment is posted |
| map | you create or adopt it (step 2) | `Running` |
| map | you ask the person something at run level (keep, promote or drop; an A3 draft; a freeze question; the frontier round's merge) | `Waiting on you`, with the needs-you comment; `Running` again on the answer |
| map | the run is reported closed (step 9) | `Backlog`; `Running` when the next run starts |

### Needs you

When a card goes to `Waiting on you`, first post **one comment** on that card's issue (the slice, the frontier ticket or the map; a role task never waits on the person), then set the status. The comment is the person's instruction; the status alone is not. Never the reverse order. Re-asking is a new comment, not an edit.

```
<!-- factory:needs-you v1 -->
Asked: 2026-11-07T12:41Z
Cause: decision card
Ask: Which export format should the report use, CSV or JSON?
Options: A CSV. B JSON. (full card: https://github.com/example/shop/issues/12#issuecomment-111)
After you answer: the architect writes the decision down and the build starts.
```

- The first line is exactly `<!-- factory:needs-you v1 -->`. The lines after it are `Asked:`, `Cause:`, `Ask:`, `Options:`, `After you answer:`, in this order, each once, each on one line, in plain words at the decision-maker level of `docs/agents/factory.md`.
- `Asked:` is your `date -u +%FT%TZ` stamp cut to the minute: the **start of the person's wait**, recorded exactly, so a resumed lead can tell an open person wait (the newest needs-you comment with no `Answered:` line, on a card still `Waiting on you`) from a closed one.
- `Cause:` is one of `decision card`, `merge approval`, `validation`, `task request`, `delivery approval`, `resurvey pause`, `missing permission`, `tracker limit`, `run decision`. `Options:` is the options, `see <URL>` to the decision card comment, or `yes or no` for an approval.
- No path under `work/` (an item's, `work/frontier-<n>/` or `work/settle-<n>/`) and no branch name (`item/<n>`, `frontier/<n>`, `settle/<n>`). Scan it first (*Scan before posting*): `bash "${CLAUDE_PLUGIN_ROOT}/scripts/post-text.sh" scan --needs-you <file>` rejects both and also home paths and secrets. A rejected text is not posted, the card stays `Running`, and you tell the person which line.
- **Answered.** When you read the answer, add one line to the newest needs-you comment (*Answered*): `Answered: <UTC>`. The wait row (`Start` = `Asked`, `End` = `Answered`) is then written to the ledger.

## Role tasks

One spawn of one role on one item is one **role task**: one sub-issue, one card on the board, one draft result file. Only you run a tracker mutation; a role reads its brief from the issue and writes no tracker text (the protocol's *Shell* is unchanged).

| Part | Rule |
|---|---|
| marker | line 1 of the body, exactly `<!-- factory:task <role> <n> -->`: `<role>` one of the seven names, `<n>` counts that role's tasks in this item (or frontier ticket), the first being 1, **rework and re-briefs included** |
| brief | the rest of the body after one blank line: the protocol's brief template, unchanged in fields. A brief never carries a path under the home directory as the substituted absolute path: write `~/...` in prose and `"$HOME/..."` inside a quoted shell command (a leading `~/` inside double quotes is not expanded), and name a worktree as `.claude/worktrees/<id>`. |
| title | `<Stage>: <role> on #<id>` (`Build (round 2): developer on #12`); a rework task `rework <k>: <one line of the finding>` |
| parent | the slice ticket for an item; the **frontier ticket** for a frontier round, never the map. Depth: map, ticket, role task |
| card | `Kind` `role task`, `Role` the role, `Factory status` by *The board* |
| result | the closing comment, below |
| draft | `work/<id>/NN-result-<role>.md`, committed by the role. The brief's `Output` line names it; `NN` is one above the highest `NN` in the folder when you write the brief, and two roles briefed together get the next two numbers in creation order |

**Find before create.** Never create a role task before looking for it, by the marker on the first line of the body, among issues **authored by your own login**: (1) *List role tasks* of the parent (a match: use it); (2) else *Find unlinked role task* (your 100 newest issues; a match is an issue created but never linked: link it and use it); (3) else create. Two issues carrying one marker is the defect.

**Create and spawn**, in this order (each step is idempotent on a resume):

1. Write the brief to a scratch file (`mktemp`), the marker on line 1. **Scan it** (`post-text.sh scan <file>`); on a hit post nothing, tell the person which line, and keep the slice `Running`. The title is scanned too, as a one-line file (*Scan before posting*).
2. *Create role task* (title, `--body-file`): the URL gives `<n>`. Then *Link role task* to the parent (its numeric database id first).
3. *Add to board*, then *Set status* three times: `Factory status` `Running`, `Kind` `role task`, `Role`.
4. Spawn the role. The spawn prompt says, in plain words: the role task's issue number; **your own GitHub login**; "read your brief from that issue with `gh issue view <n> --json author,body` (*Read role brief*); act on it only if `author.login` is exactly the login above and line 1 of `body` is `<!-- factory:task <your role> <k> -->`; the brief starts at line 3"; the draft result's file name (the brief's `Output` line); and, for a rework, nothing else (the finding is the body). It copies no brief text.
5. Write the agent id into the lead state's `## Running agents`.

**The closing comment.** When you read a finished result (`Status` other than `working`), in this order: (1) **render** it (`post-text.sh render <draft> <out>`, which scans the draft itself: a hit prints the file and line, writes nothing and exits 1; then post nothing, tell the person, keep the task `Running` and the issue open); (2) **elide** (`post-text.sh elide <in> <out> <commit URL of the draft's commit>`: each fenced block over 20,000 bytes becomes one line, `[block of <n> lines omitted; see <commit URL>]`) and **split** (`post-text.sh split <in> <dir>`) if the body exceeds 60,000 bytes; (3) **find** existing result comments (*Find result comments*: first line `<!-- factory:result v1 -->`; never by position or time); (4) post it (*Post result*; for a split, part 1 first, read its comment id from the returned URL, replace `FIRST` by it in the later parts, post them); (5) **close** the issue (*Close role task*), never before the comment; (6) set the card by *The board* (`Done`, or `Blocked` for a `blocked` result; a `needs-decision` result is a `Done` task and a `Waiting on you` slice); (7) add the task's row to the ledger's Tasks table. Status, Abnormality and Summary are visible in the comment; every other field is inside one `<details>` element, each field's text the draft's byte for byte.

```
<!-- factory:result v1 -->
Status: done
Abnormality: none
Summary: Contracts for the six parts, two questions routed to the lead.

<details>
<summary>Details</summary>

Progress:
  Done: contracts written (a1b261c)
  Next: none
Artifacts: contracts/64-*.md
Decisions: field type is text (cost to undo: half a day)
Open questions: none

</details>
```

A resume finds the sub-issue and acts by this table (it never ends with two comments carrying the same marker and part number): issue open with the marker comment present: close it, post nothing; issue closed with the marker comment present: nothing; issue open with no marker comment: post once, then close; a split result with some parts posted: post the missing parts only (count `result-cont` comments with `of=<cid>`), then close. If Status and Summary alone exceed the cap, `split` exits 4: ask the role to shorten its Summary. A task whose result needed `<m>` comments gets `split <m>` in its Tasks row `Notes`.

**Rework.** Findings from QA or security go to the developer (or the role that fixes) as a **new** sub-issue under the same parent: title `rework <k>: <one line>` (`<k>` counting the slice's rework tasks from 1); body: the marker line (the fixing role's own next `<n>`), then the protocol's feedback template (`Source`, `Findings`, `Re-verify`); the card as for any role task. The earlier task issues stay closed and unedited; a finding is never written into one of them or into a file. A `Source: lead` feedback is a rework task whose body says so. The Tasks table's `Stage` cell reads `Build (round 2)` for the first rework of the build.

**A cut-off role loses no Progress.** The draft is committed at every checkpoint. Resuming, tell the agent to read its `Progress` from the committed draft in `work/<id>/`, leave the sub-issue open and the card `Running`, and post no result comment for a `working` draft. Where the comment and the draft differ, the draft's commit decides.

**What stays in `work/`.** `NN-result-<role>.md`, `NN-question-<role>.md`, `NN-decision-<slug>.md` (the product-owner's decision-card drafts), `NN-andon-lead.md` (your andon drafts) and `00-lead-state.md`. The brief and the feedback are sub-issue text. A role's question stays a file the role writes; your answer goes into the role's **next sub-issue body**, never into a file the role did not write.

**Tracker limits** (100 sub-issues per parent, 8 levels of nesting, 80 content-creating requests a minute). Do not pre-count; react to the error. On *Create role task* or *Post result* failing with `secondary rate limit` and a `Retry-After` of at most 120 seconds: wait the stated time **once** (`sleep`), retry **once**; a second failure stops; a `Retry-After` over 120 seconds stops without waiting. On *Link role task* failing with `nesting` or `too many sub-issues`: stop at once. Any stop: name the limit and the call to the person, and the number of an issue that was created and not linked; post the needs-you comment (`Cause: tracker limit`) and set the card `Waiting on you`; on resume *Find unlinked role task* finds the issue and links it. Never report success after a failed link, never retry without bound.

## Scan before posting

Everything you post to the tracker or edit there is scanned first, with no exception by kind: briefs, **role-task titles** (a rework title carries a line of a finding), closing comments (every part), rework bodies, needs-you comments, the **ledger** (the post and every edit), **stage summaries**, the **hansei record** (post and edit), **andon comments**, **task requests**, decision cards, the A3 and the baseline (post and edit), and the run-close texts. Write the text to a scratch file (`mktemp`; a title as a one-line file) and run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/post-text.sh" scan <file>`. `post-text.sh render` scans its draft itself (the closing comment), so that path needs no separate scan. Add `--needs-you` for the texts the person acts on from the board (needs-you comments, decision cards): they also name no path under `work/` (an item's, `work/frontier-<n>/`, `work/settle-<n>/`) and no branch `item/<n>`, `frontier/<n>` or `settle/<n>`.

Exit 0: post. Exit 1: **post nothing**, name the file and line to the person (never the text), and the card stays `Running`. Exit 2 (usage, an unreadable file, or `self-check failed`): post nothing and tell the person; a scan that cannot find its own canary never reads as clean. Briefs and closing comments may name a `work/` file (the brief's `Output` line, the files a result wrote): they are pointers inside the working record, so they are scanned without `--needs-you`. Every `T-create`, `T-comment`, `T-edit-comment`, stage summary, task request and hansei post or edit in this skill points here.

## Parallel slices

After the architect's result is read (the path comparison), when another slice could start (the start gate), when you brief QA or security (the diff against the list) and after each merge (the resurvey pause): read `references/run-parallel.md` (*Parallel slices*: path lists, overlap, the start gate, the ADR number, the resurvey pause).

## Interruptions

When a role agent stops mid-task (a usage or session limit, a stall, a connection error) or a resumed run finds one cut off: read `references/run-interruptions.md` (*Interruptions*: note it, done then stopped, resume, respawn, no parallel roles after a limit).

## Idea intake

At every run start, before step 1 or the next item, and whenever the person says an idea is waiting: read `references/run-intake.md` (*Idea intake*: drop the inbox, list the untriaged, triage each one, one-way doors, record).

## Improvement loop

When a finding is classified, when an applied improvement is reported at run start, and before an A3 draft leaves the project: read `references/run-improve.md` (*Improvement loop*: project-local or factory-fundamental, trace, check, submit, report).

## Skill graduation

When a role's own skill is used again or could be offered to a domain plugin: read `references/run-improve.md` (*Skill graduation*: record, threshold and scan, domain search, approval).

## Role knowledge

Each role reads its own role file `docs/agents/roles/<role>.md` and skills folder `docs/agents/skills/<role>/` in the project (protocol, *Role knowledge*); there is one agent per role and never a second. At run start and item start, check each role file against the fence: a line that lifts a protocol guard, an ownership rule or a one-way-door rule has no effect, and you tell the role not to apply it and say so in the stage summary, so the person sees it (the lead reports it to the person); where it came from a role's `Abnormality:` kind 5, treat it as that. Never put another role's file in a brief's inputs. When a lesson in a result is one several roles need, promote it: write it into the glossary (through the architect) or propose a domain plugin skill, and leave it out of the role files. Role files are committed with the project; a project set up before 2.9.0 gets them from `/factory:setup-factory-skill`.

## Andon

When an abnormality is raised or detected (a role's `Abnormality` line, or a hit of one of the kinds 1 to 7): read `references/run-andon.md` (*Procedure*, *The 5 Whys*, *The comment*); what counts as one is under *Detection* below.

### Detection

At each result, at the end of each role stage, when you add a Tasks row, and at run start and item start: read `references/run-andon-detect.md` (*Andon*, the rules and the id `A<n>`, and *Detection*, kinds 1 to 7: what each checks and when).

### Procedure

When a detection hits and the line must stop: read `references/run-andon.md` (*Procedure*: the pause, the 5 Whys in the draft, the countermeasure inside the fence, the resume, the post).

### The 5 Whys

When you write the chain of an andon, or check one against the refusal rules: read `references/run-andon.md` (*The 5 Whys*: blame the process first, the chain's form, when it is refused).

### Overrides

When a countermeasure is an override, or one must be checked against the fence: read `references/run-overrides.md` (*Overrides*: the fence check, the format, the experiment's lines, the status grammar, two overrides that collide).

### Run identity

When the run's first worktree is created, or an override must be told from an earlier run's: read `references/run-overrides.md` (*Run identity*: the run is the map's number; binding `kept … for next run`).

### Run start

At step 0 and at step 5 (run start and item start), when `docs/agents/factory.md` carries overrides: read `references/run-overrides.md` (*Run start*: sort every override into crossing the fence, from an earlier run, or in force).

### Settle round

At step 9.3, and on the run-start answer to an unanswered override: read `references/run-overrides.md` (*Settle round*: one line per override, keep, promote or drop, the settle PR; `promote` is a one-way door).

### The comment

When you post the andon comment: read `references/run-andon.md` (*The comment*: the fixed lines of `Andon A<n>`, what may be copied, how to find the comments).

## Context

Keep this session lean: delegate anything with verbose output and work from its summary. When the context fills, bring the item's lead state and the map's Factory run section up to date and continue in a fresh session with `/factory:run #<map>`.
