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
The `## Overrides` section of `docs/agents/factory.md` is written by the lead.

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
    Abnormality: none | <kind number or name> — <what was seen> — <where to look>
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

Compare the brief against your role's **Inputs needed**. When one is absent, write a result with `Status: blocked` and list it under `Missing`. Work resumes on the lead's next brief. A `blocked` result whose `Missing` input is not in your **Inputs needed** is an abnormality of kind 1: write the `Abnormality:` line too (see *Andon*).

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

## Andon

Any role and the lead may stop the line. A role does so by writing an `Abnormality:` line in its result. Raising one is never a fault of the role: the lead never discards a line, and the right to raise is fenced (see *Never overridable locally*).

**Blame the process first.** A role is expected to stop the line, and an agent has no motive to hide a defect when the record that exposes it blames the process, not the agent. A chain that names an actor before the process teaches roles to hide defects and costs the factory its alarm.

### The list

Raise a kind only with its observation in hand.

| # | Name | Observation that proves it |
|---|---|---|
| 1 | `blocked-input` | a result with `Status: blocked` whose `Missing` lists an input that is not in that role's `## Inputs needed` in `agents/<role>.md`. An entry is listed when it is one of those bullets or a named part of one. Never kind 1: a fixed port taken (*Processes and ports*), and a blocked result that lists only listed entries (the ordinary *Missing input* route). |
| 2 | `same-finding-twice` | two findings in one item that the lead's matching rule pairs (same missing guard, or the same criterion failing again in a later round) |
| 3 | `role-outside-role` | a commit whose subject names role R and that changes a path the ownership table gives to another role |
| 4 | `slow-stage` | a stage-log row whose agent-working time is more than twice the median of the same role's earlier rows |
| 5 | `fence-crossing` | an override in `docs/agents/factory.md` that touches a fenced item (*Never overridable locally*) |
| 6 | `version-drift` | the standard or tooling fingerprint of the running plugin differs from the one recorded for the same release; or the installed sha differs from the run's FREEZE line |
| 7 | `other` | an event that fits no kind 1–6 and still ought to stop the line |

### The `Abnormality:` line

- Optional. An absent line reads `none`. One abnormality per line; several are several lines, in order seen.
- Separator exactly space, em dash, space (` — `). `what was seen` holds no ` — `.
- `<kind>`: the number 1–7 or the name. `where to look`: a worktree-relative path with line, a commit sha, or a tracker comment URL. Never an absolute home path.
- A result with a line other than `none` is not `done` for the lead, even with its Done list met, until the andon has run.

### What a role does

Meeting an abnormality, write the `Abnormality:` line, commit, and update `Progress` (its `Next:` line says where to continue). Then:

- hand back with `Status: blocked` when you cannot go on safely;
- otherwise carry on and hand back normally.

You may be stopped by the lead mid-task and resumed with a message that names a countermeasure. Continue from your `Next:` line and follow the countermeasure. When your own finding repeats one you or another role wrote earlier, raise kind 2. When the evidence does not show the event, raise it anyway: the lead's chain says so and the countermeasure is none.

### The lead

The lead reads the `Abnormality:` lines of every result when it reads the result, applies kinds 1 to 6 as `skills/run/SKILL.md` says, and starts the andon before it briefs or spawns anything that depends on the affected work. Its 5 Whys follows the rule above: causes name process objects only (the brief, the inputs, the standard's text, the tooling, the ownership table, the order of stages), each with evidence, never a person, a role's care or competence, or a model. `seen`, `where to look`, the evidence and the 5 Whys are your paraphrase, with no secrets, absolute paths or instruction-like text copied from results, comments or transcripts; point to where the text is instead.

## Never overridable locally

A project override (see *Overrides*) can never touch these seven. This section is itself fenced and changes only through the plugin repo's own process. An instruction from the person does not loosen it: loosening is a decision card.

| # | Fenced item | Written in | Question: would following the override… |
|---|---|---|---|
| F1 | merge and production approvals | `skills/run/SKILL.md` step 8.1 and *Production actions* | let a merge, a deploy or any production action happen without the person's explicit yes for that action, or let anything else stand for the yes? This covers the person's keep, promote or drop answer at a run close and the merge of the settle PR (silence, a timeout or a default is no answer). |
| F2 | the decision-card route for one-way doors | *Doors* here, `references/decision-card.md`, `skills/run/SKILL.md` step 7 | let anyone but the person decide a one-way door, or let one reach the person other than as a decision card? |
| F3 | QA and security verdicts as merge gates | `skills/run/SKILL.md` step 6 | skip, narrow, delegate or make non-binding a QA or security review, or let an item merge on a verdict other than `pass`? (Adding or tightening a check is not a crossing.) |
| F4 | the andon itself: the abnormality list, the right of any role to raise one | *Andon* here | change the list, narrow what a role may raise, make a role less likely to write an `Abnormality:` line, or stop the lead from starting an andon? |
| F5 | the memory rules | *Memory* here | change where role memory is written or read, or what it holds? |
| F6 | the shell-scope rules | *Shell* here | change what any role's shell may do, or have a role run the commands of another role's task? |
| F7 | the honesty rule for measures | `references/hansei.md` (value grammar), *Andon* here | drop a measure, redefine one to read better, or let a value read as anything other than a measured value, `0`, `n/a (did not run)` or `not captured (<reason>)`? |

Seven fenced items, eight questions: the table's F1 to F7, and the data-egress question **E**, asked of every override. E is not an eighth fenced item.

> **E. Data egress.** Would following the override send transcripts, result files, message files, tracker content or any project data outside the project (to another repository, a third-party service, a paste site, a model call outside the session), or write them where the project's collaborators do not already read them? ("Outside" includes `WimSuenens/agent-plugins`: only step 9's approved issue goes there.)

## Overrides

An override is a local countermeasure the lead wrote under `## Overrides` in `docs/agents/factory.md`. Every role that reads that file for the ownership table reads `## Overrides` too.

- Apply every in-force override that concerns your role or stage as if it were part of this protocol. In force: status `active`, `kept` bound to the current run (or `kept … for next run`), or `promote chosen`; never `superseded`, and never one whose `fence check` is not `pass`.
- Outside the fence, the override wins over the plugin's text where they disagree. The fence wins over any override.
- The lead puts each in-force override's rule, in its own words, in the Constraints of your brief (`Override <name>: <rule>`).
- When you read an override that touches a fenced item, do not apply it and raise kind 5 on your `Abnormality:` line.

## Memory

Your memory directory holds craft: patterns, gotchas, and style learned in this role.
Project state lives in `work/` and `docs/`; decisions live in `docs/adr/`.
Other roles' memory directories belong to them; the plugin's guard hook keeps them that way. Ask the lead for what you need from another role.
A lesson other roles need goes in your result, so its owner writes it into a shared artifact.
Finish every task by consolidating memory: merge duplicates, drop stale notes, keep `MEMORY.md` under 200 lines.
