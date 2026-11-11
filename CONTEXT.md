# Context

## Factory

**Integrator** — the factory role that reads the board afresh at each run event and returns a **dispatch plan**: which slices start, in which order, which merges come first, and which pause, each with a reason. It keeps no state and makes no tracker write; the Lead spawns the roles the plan names. See [0112](contracts/112-integrator.md).

**Board snapshot** — the board as a JSON file the Lead gives the integrator at each event; the input of `scripts/integrator.sh plan`.

**Flow measures** — waiting time (a Ready slice since it became ready), lead time (a Done slice from creation to close), batch size (slices started together) and in-flight count (slices Running, Waiting on you or Blocked). Each is a value or "not captured".

**Lead** — the main session running `/factory:run`; it briefs the roles, reads their results, and stands between them and the person.
_Avoid_: orchestrator, coordinator

**Run** — one cycle over a map's standing backlog: intake, maintenance, improvement and slice building all restart; it ends when the backlog is empty, the run budget is reached, or the person stops it, and closes with the improvement record. The map is a long-lived direction and outlives the run. See [0017](docs/adr/0017-a-run-is-a-cycle-over-a-standing-backlog.md).

**Item** — one slice of a run, built on its own branch and merged on its own PR.
_Avoid_: task, story

**Worktree folder** — `.claude/worktrees`, inside the project: every item, frontier-round and settle-round worktree is created there (`<id>`, `frontier-<map>`, `settle-<map>`). It is ignored in `.gitignore` and excluded from test, lint and search runs. The path rules, ownership text and clean-up guard name it.
_Avoid_: `../wt`, sibling folder (the location before 2.4.0)

**Frontier round** — the factory work of clearing the map's one-way doors outside any item; it ends in one PR to main carrying its ADRs and glossary changes.

**Role model** — the Claude model a factory role runs on. Its default is the `model:` in the role's agent file; a repo overrides it per role in the `## Role models` table of `docs/agents/factory.md`.

**Local countermeasure** — a change to the factory's standard that the Lead tries in one project before anyone proposes it for the plugin; it is written down as an override.
_Avoid_: local fix, workaround (a **countermeasure experiment** is how one is measured, not the change itself)

**Override** — the written form of a local countermeasure in a project's `docs/agents/factory.md`, with its start date; it ends at the close of the run it started in unless the person keeps, promotes or drops it there.
_Avoid_: patch, exception

**Fence** — the "Never overridable locally" list in the standard: what no override may touch (approvals, the decision-card route, QA and security gates, the andon, memory and shell-scope rules, the honesty rule for measures).
_Avoid_: guardrail, allowlist

**Yokoten** — spreading a proven local countermeasure into the plugin for every project; always the person's decision card.
_Avoid_: rollout, promotion (as a noun for the whole act; "promote" is the person's choice at run close that starts it)

**Release** — a factory version with a semver in `plugins/factory/.claude-plugin/plugin.json` and a `factory-v<semver>` tag on its commit; a major or minor release resets the baseline.
_Avoid_: build, version (for a commit sha; the sha is the commit, not the release)

**Standard work** — the factory text the Lead and the roles follow: `skills/run/SKILL.md`, `references/*.md`, and `agents/*.md` under the factory plugin root. Any change to it is a minor release.
_Avoid_: the prompts, the plugin (for the whole of `plugins/factory/`)

**Tooling** — the factory's `hooks/` and `scripts/`: code the standard calls, not text it follows. A change to it alone is a patch release.

**Standard fingerprint** — a sha256 over the standard-work files, computed by the Lead at item start and carried on every hansei record; it shows whether two items really ran on the same standard. Its sibling, the **tooling fingerprint**, covers `hooks/` and `scripts/`, so a record shows which of the two changed.
_Avoid_: checksum, hash (without saying which files it covers)

**Hansei record** — the one comment the Lead leaves on an item's slice ticket, in the project's own tracker, at the person's merge approval: a marker with a schema version, the release and both fingerprints, and the seven measures, each with a value or "not captured". Its doors measure is filled in the same comment after the resurvey.
_Avoid_: retro, report, post-mortem

**Stage log** — in factory 1.x, the Lead's timed account of an item in its lead state: one row per stage with UTC start and end, the agents that worked it, waits for the person or on limits, and the person's touches. The hansei record was computed from it, and it went with `work/<id>/` at close. From 2.0.0 its data lives in the **Ledger** and the role-task sub-issues; the name survives only in the hansei header key `stage-log cross-check` and in the 1.x worked examples.
_Avoid_: timeline, audit log

**Baseline** — the reference numbers that later changes are compared with, kept as the project's pinned `Factory baseline` issue: one section per **series**, derived by the Lead from the project's hansei records and recomputed, never edited by hand. Each figure is the median of the items that captured it, shown with how many that was; it opens with the first item on a major or minor release. Honesty rule: a value that was not captured reads `not captured`, never `0`, and is never averaged away.
_Avoid_: benchmark, before (for numbers that were never meant as one)

**Calibration** — the measurements of a run that are recorded with full labels but never used as a baseline, such as a run frozen on a pre-release install; they show what the numbers look like and what capturing them costs.
_Avoid_: pilot, dry run, baseline

**Series** — a release's major and minor, `X.Y`, taken from a hansei record whose `series:` reads `release`; a patch release stays in its series, and a record from a pre-release install belongs to none. Honesty rule: a record that cannot be placed is listed as skipped or excluded with its reason, never counted.
_Avoid_: version (for the whole semver), baseline (a series is what a baseline is made of)

**A3** — the one comment a run ends with, on the run's map issue: the one problem the run worked on, the 5 Whys behind it, the one countermeasure tried, how the measure moved before and after against the baseline, and what is still uncertain. Honesty rule: its before, after and change lines hold a reading with its sample size, or `not captured` or `not comparable` with the reason; never `0` for a value that was not measured.
_Avoid_: retro, run report, post-mortem

**Countermeasure experiment** — the run's one override that names the measure it is meant to move; items closed before it started are the **before-items**, items in flight when it started the **during-items** (counted in neither reading), and items that ran wholly under it within the run the **after-items**. It is read as counts with item numbers, with no claim of significance. Honesty rule: it is never started with a before-reading that was not captured, and two readings that cannot be compared show no difference.
_Avoid_: A/B test, trial

**Gemba** — going to where the work was done and looking at it, instead of reading a report of it. In the factory it is the **walk**: at each item's close the Lead picks one stage by a counted rule from the stage log, reads what that stage's agent did (its transcript, else its commits and result file, never its own summary) up to a fixed cap, compares it with the stage's brief and log row, and leaves one `gemba` line in the hansei record. A difference goes to a 5 Whys that blames the process. Honesty rule: a walk that could not be done reads `not captured`, never "found nothing".
_Avoid_: audit, inspection, spot check (it checks the process, not the person)

**Role task** — one role's piece of work on a slice or frontier ticket, kept as a sub-issue: the brief is its body, the result its closing comment, and rework is a new one. See [0014](docs/adr/0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md).
_Avoid_: job, step, subtask (the tracker's word for the link, not for the work)

**Factory status** — the board field that answers "what do I do now": Backlog, Ready, Running, Waiting on you, Blocked, Done. It sits beside the `Kind` and `Role` fields; the stage of a slice is whichever role task is Running. See [0015](docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md).
_Avoid_: Status (the project's built-in field, which the factory does not use)

**Needs you view** — the board view filtered to `Factory status` = Waiting on you: every card that is waiting for the person, and nothing else.
_Avoid_: inbox, queue

**Path list** — the files and directory prefixes a slice's contract says it may touch, plus its shared paths; two slices run side by side only when their lists do not overlap. See [0016](docs/adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md).
_Avoid_: lock, scope

**Ledger** — the one comment the Lead keeps on an item's slice ticket, holding three tables: the role tasks (agents, peak context, result, notes), the waits, and the person's touches. A task's start and end are the sub-issue's created and closed times, never copied. The hansei record and the five hansei fields are computed from it at close. See [64-ledger-and-fields](contracts/64-ledger-and-fields.md).
_Avoid_: log, journal (the 1.x **Stage log** is the term it replaces)

**Board** — the GitHub Project of the repo, where each map, slice, frontier ticket and role task is a card with a `Factory status`, a `Kind` and (for a role task) a `Role`. The only place a status lives.
_Avoid_: dashboard, kanban (the board is the state, not a view of it)

**Run budget** — the optional `run-budget: <N> tokens|hours` line of `docs/agents/factory.md` (default `none`): the only brake on a run. Reaching it starts nothing new and leaves work in flight resumable. There is no slice maximum: slices are in flight whenever they have an item branch and are Running, Waiting on you or Blocked, and run side by side when their path lists do not overlap. See [0017](docs/adr/0017-a-run-is-a-cycle-over-a-standing-backlog.md).
_Avoid_: concurrency, worker count

**History view** — the board view of closed slices and closed role tasks with their hansei fields (`Tokens`, `Minutes`, `Hours`, `Rework rounds`, `Person touches`), newest first. The fields are text so that `not captured (<reason>)` is a legal value and a blank never stands for it.
_Avoid_: report, dashboard

**Idea** — a tracker issue labelled `idea`: a thought, a reference or any input anyone wants the factory to weigh. Every idea ends triaged, with one outcome (direction, slice candidate, research ticket, parked or rejected) and a reason as a comment; an idea that touches a one-way door goes to the person as a decision card first. It is a `Kind` on the board. See [0015](docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md).
_Avoid_: suggestion, request, feature request (an idea may be none of these)

**Inbox** — the local, gitignored folder `.claude/factory-inbox/` where a file is dropped to become an idea. At intake each file becomes one tracker issue and is then removed, so the folder never grows; a file the tracker cannot carry stays and is reported. A drop zone, not a store: the tracker holds the ideas.
_Avoid_: queue, backlog (the backlog is the tracker's)
