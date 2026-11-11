# agent-plugins

A personal Claude Code marketplace. Its main plugins:

- **`mattpocock-skills`** — upstream, unmodified, fetched straight from `mattpocock/skills`.
- **`wayfinding`** — the planning overlay: `wayfinder`, `beachhead`, `reversibility`, `setup-wayfinding-skill`, `ask-me`.
- **`design`** — the design overlay: `ux-psychology`, `ux-review`, `design-system`, `direction`, `setup-design-skill`. See [The design overlay](#the-design-overlay).
- **`factory`** — a lead and seven role agents that take an idea to a destination, slice by slice: `run`, `setup-factory-skill`. See [The factory](#the-factory).

It also lists `toolkit` (`source-to-pptx`) and `discover` (`debrief`).

**Nothing is forked.** A marketplace catalog and a plugin source are independent, so this repo can list a plugin that lives in someone else's repo alongside one that lives in its own. The overlay sits *beside* upstream instead of on top of it: upstream ships, you pull, there is never a merge to resolve.

## What the overlay changes

Upstream `/wayfinder` is plan-only by construction — it resolves every question in the map before anyone builds, using instruments that are all conversational. Its own metaphor argues against that: fog of war clears by *moving units*. And the cost lands on the scarcest input, your attention, because grilling is human-in-the-loop and declared the default.

The overlay keeps the map and changes four things:

1. **Reversibility triage.** Only **one-way doors** — decisions whose reversal costs a rewrite — become tickets before code. Two-way doors are **deferred with a trigger**.
2. **A `slice` ticket type.** A thin vertical cut, shipped to main, whose purpose is to *teach*. Where `task` does in order to unblock a decision, `slice` ships in order to produce one.
3. **Provisional vs locked decisions.** A decision reached by reasoning and never exercised by running code is marked as such, so downstream work knows how much weight it bears.
4. **An incremental exit.** No big-bang collapse of the map into one spec. Each slice carries its own; the map **dissolves** mid-build when no one-way doors remain ahead.

Upstream `/wayfinder` stays installed and stays useful — reach for it when the destination genuinely is a document rather than running software.

## The design overlay

Upstream has no design vocabulary: `/prototype` can generate UI variations and `/code-review` can check code against standards, but neither knows *why* a screen works. The design overlay adds that layer the same way `wayfinding` does — beside upstream, never forked.

| Skill | Invocation | What it does |
|---|---|---|
| `ux-psychology` | model | Glossary by **mechanism** (perception, memory, interaction cost, decisions, motivation, trust, accessibility). Every principle carries an evidence grade — *replicated*, *contested* or *folklore* — never a statistic. Ends with the **three-check test** for dark patterns: truthful framing, symmetric exit, endorsement. |
| `ux-review` | model | Six-pass review of a screenshot, URL or component code. Findings carry severity, principle, evidence, fix, and a dark-pattern flag. Optional outputs: `design/reviews/` and the issue tracker. |
| `design-system` | user | Builds `design/system.md` plus tokens in the repo's stack (DTCG on request), from scratch or extracted from existing UI. Asks the one-way doors, chooses the two-way doors. Reads a `direction` brief when one exists. |
| `direction` | user | Interviews a project into one design direction of counted commitments and writes a reusable brief. |
| `setup-design-skill` | user | Writes `docs/agents/design.md` and its `AGENTS.md` pointer once per repo. |

It reaches upstream two ways:

1. **Vocabulary hook.** `ux-psychology`'s description ends "…or when another skill needs the UX-psychology vocabulary", the same hook `codebase-design` and `reversibility` use.
2. **Upstream artefacts.** `setup-design-skill` adds `docs/agents/design.md`, which every upstream skill reads through `AGENTS.md`: build UI from `design/system.md`, name findings with the vocabulary, record one-way design decisions as ADRs and UI terms in `CONTEXT.md`, file review findings as issues.

The research behind it — every principle traced to primary sources and graded, with corrections to the popular claims (the jam study, "70–90% never change defaults", "losses weigh 2x") — is in [docs/research/ux-psychology.md](docs/research/ux-psychology.md).

```
/design:setup-design-skill    once per repo
/design:direction             optional — when the visual identity is still open
/design:design-system         writes design/system.md + tokens
/design:ux-review             on any screen, flow or component
```

## The factory

The factory decides *what* the destination is and cuts the slices; wayfinding charts *how* to get there. `/factory:run` makes the main session a **lead** that grills the person briefly about the destination, has wayfinding chart the route, then takes slice after slice through seven role agents — product owner, architect, developer, QA engineer, security reviewer, DevOps, docs writer — to merged PRs, resurveying after each. Several slices can run at once when their path lists do not overlap. Every two-way decision a role takes comes back to the lead and to the person at the next stage boundary; overturning one becomes feedback to that role, and the work never stops for it. Long sessions stop filling their context windows because the roles are subagents that report summaries. The board in the project's GitHub Project shows where every card stands; each role's task is a sub-issue of its slice, with the brief as its body and the result as its closing comment. Questions, draft results and the lead's own state stay files.

| Piece | What it does |
|---|---|
| `run` (user) | The lead. Clarifies the destination, has wayfinding chart the map, clears its one-way doors in a frontier round merged as one PR of ADRs (research and prototypes AFK, the decision to the person), cuts each slice, starts a branch and worktree per item, runs every slice whose path list does not overlap another's at once, briefs each role as a sub-issue, reviews their two-way decisions, moves each card across the `Factory status` board, and resurveys after each merge. A run is one cycle over the map's standing backlog: it starts with intake and ends when the backlog is empty, the optional `run-budget` is reached or you stop it. |
| `setup-factory-skill` (user) | Writes `docs/agents/factory.md` (decision-maker level, role model overrides, path ownership, worktree location, optional run budget, tracker ids), patches the tracker doc, and prepares the GitHub Project board. On a 1.x project it runs the migration to 2.0.0, after the person's yes. |
| 7 role agents | `factory:<role>`, each with checkable *Inputs needed* and *Done* lists, sharing one [protocol](plugins/factory/references/protocol.md). |
| Role models | Each role picks a model by the cost of its mistakes: product owner, architect, QA engineer, and security reviewer `inherit` the lead's model; developer and DevOps run on `sonnet`; the docs writer on `haiku`. A repo overrides any role in the `## Role models` table of `docs/agents/factory.md`, with `haiku`, `sonnet`, `opus`, or `fable`. |
| Private role memory | Each role keeps craft notes in its own memory; a plugin hook stops one role reading another's. |
| Decision cards | A one-way door never gets decided by an agent. The product owner writes a [card](plugins/factory/references/decision-card.md) in everyday words — consequences, cost, effort to undo, a recommendation — and the lead offers ways to dig deeper (`/research`, `/prototype`, `/grilling`). |
| Andon and overrides | When a role or the lead sees an abnormality, the lead stops the affected work, writes a 5 Whys that blames the process first, and tries a local countermeasure: an override in the project's own `docs/agents/factory.md`, inside a fence and ending with its run. See [The andon and overrides](#the-andon-and-overrides). |

```
/wayfinding:setup-wayfinding-skill   once per repo (setup-factory-skill runs it if needed)
/factory:setup-factory-skill         once per repo — GitHub trackers only for now
/factory:run [idea | #map]           per destination; #map resumes
```

`/factory:run` is set to `disable-model-invocation: true`: you type it yourself, and a model cannot load it through the Skill tool. A session that has to start the lead without a typed command (a headless or scripted session) reads `plugins/factory/skills/run/SKILL.md` from the plugin root and follows it; everything in it that uses `${CLAUDE_PLUGIN_ROOT}` works from there. This is the working invocation when the skill "cannot be loaded by that name" (#85).

Which model a role runs on, first match wins: the `CLAUDE_CODE_SUBAGENT_MODEL` environment variable (set it and every role uses it, overrides included), then the repo's `## Role models` row, then the agent file's `model:`. `inherit` follows the lead, so a lead started on Sonnet runs the inheriting roles on Sonnet too; override them with `opus` to prevent that.

**Status: release 2.1.0 (test ownership and the TDD loop) has passed QA and security, and no acceptance demo gated it.** The new text is verified by script tests, scenario cards and reviews. Nothing was run in a live factory session. What only real use can show is listed as unverified in [CHANGELOG.md](CHANGELOG.md) under *2.1.0*, *Unverified*. No project has to migrate.

**Status: release 2.0.0 (the board as run state) has passed QA and security, and no acceptance demo gated it.** The board, the role-task sub-issues, the ledger and parallel slices are verified by offline tests, replays and reviews. Nothing was run against a live Project or in a live session. What only real use can show is listed as unverified in [CHANGELOG.md](CHANGELOG.md) under *2.0.0*, *Unverified*. A project on 1.x must migrate before `/factory:run` accepts it; see [Upgrading a project to 2.0.0](#upgrading-a-project-to-200).

**Status of 1.3.0 (the gemba sample): passed QA and security, and no acceptance demo gated it.** The walk of one stage per item, and its line in the record, are verified by offline tests, replays and reviews. What only real use can show is listed as unverified in [CHANGELOG.md](CHANGELOG.md) under *1.3.0*, *Unverified*.

**Status of 1.2.0 (the per-run A3 and the Factory baseline): passed QA and security.** Its acceptance demo ran in a scratch project with `claude --plugin-dir`: the baseline issue appeared at run start and one A3 was posted at run close. It did not exercise a countermeasure (no override was written, so the before and after readings, and the keep, promote and drop answers, were not seen in a session), nor the paused-agent check. The limits are in [CHANGELOG.md](CHANGELOG.md) under *1.2.0*, *Known limitations at release*.

**Status of 1.1.0 (the andon): passed QA and security; its human-only checks are not all done.** The 1.2.0 demo did not exercise the paused-agent check or a keep, promote or drop answer; see [CHANGELOG.md](CHANGELOG.md) under *1.1.0*, *Known limitations at release*.

**Status of 1.0.0: the acceptance demo ran in a scratch project.** Every human-only criterion passed except AC-17, which failed there: lead time counted stalls and machine sleep as agent work. AC-17 was fixed in schema v2 (cut-off detection, measured from the transcripts). QA checked the fix by replaying the demo's own transcripts through the scripts and accepted AC-17 on that replay, without a demo re-run. The close step's live-session check is still open; see [CHANGELOG.md](CHANGELOG.md) under *1.0.0*, *Known limitations at release*. The design, what has been verified, and the extension points are in [docs/research/software-factory.md](docs/research/software-factory.md); the decisions are ADRs 0001–0016 in [docs/adr/](docs/adr/), each with the status line it carries there: 0006 is superseded by 0007, 0007 is amended by 0016, 0001 is partly replaced by 0014, and 0002 is amended by 0015.

**Feedback goes to this repo's issues** with the `plugin:factory` label — use the *Factory feedback* template, or let `/factory:run` draft the issue at the end of an item. It posts only what you approve, and leaves your project's code and names out.

### The board, role tasks and parallel slices

From 2.0.0 the board of the project's GitHub Project holds every status. Its fields are `Factory status` (six values: `Backlog`, `Ready`, `Running`, `Waiting on you`, `Blocked`, `Done`), `Kind` (`map`, `slice`, `role task`, `frontier ticket`), `Role` (on a role task only) and five text fields for the numbers (`Tokens`, `Minutes`, `Hours`, `Rework rounds`, `Person touches`). The project's built-in `Status` field is not used. Two views are set up for the person: **Needs you** (filter `factory-status:"Waiting on you"`) and **History** (filter `is:closed kind:slice,"role task"`, closed newest first). Set *Column by* to `Factory status` on the board view.

A card that waits on the person always has a needs-you comment first, which says the cause, the ask, the options and what happens after the answer. A role task never waits on the person.

Each spawn of a role on an item is one **role task**: a sub-issue of the slice, titled and marked for its role, with the brief as its body and the role's result as its closing comment. Findings from QA or security reach a role as a new `rework <k>` sub-issue; the earlier ones stay closed.

Slices run in parallel whenever their path lists do not overlap, with no count limit (since 2.6.0; the old `parallel-limit` line is ignored and setup removes it). The only brake is the optional `run-budget: <N> tokens|hours` line in the `## Run budget` section of `docs/agents/factory.md` (`none` by default): when it is reached, nothing new starts and work in flight stays resumable. Each contract names its paths in a `Paths:` block; a path that overlaps another slice's list, or its `shared:` entry, keeps the second slice waiting. `factory-state: 2` on line 1 of `docs/agents/factory.md` is what says the project has migrated. Contracts: [64-board-status](contracts/64-board-status.md), [64-role-tasks](contracts/64-role-tasks.md), [64-parallel-slices](contracts/64-parallel-slices.md) and [64-board-script](contracts/64-board-script.md).

### Upgrading a project to 2.0.0

2.0.0 is a **major** release. A project on 1.x cannot run `/factory:run` until it migrates, and `/factory:run` refuses it at its first step.

1. Start a new Claude Code session, so the session reads the 2.0.0 skill text.
2. Run `/factory:setup-factory-skill` in the project. It shows the status mapping and the number of items, and writes a snapshot of every item and field value under `${XDG_STATE_HOME:-$HOME/.local/state}/factory/board-<owner>-<project>/`, outside the repository, before it changes anything. It asks one question: apply this? Only a clear yes goes on. The mapping is `Designed` to `Ready`, `In progress` and `In review` to `Running`, `Ready to deploy` to `Waiting on you`; Backlog, Ready and Done are unchanged.
3. **In progress and In review both become Running.** The old distinction is kept only in the snapshot, and restoring it by hand is described in the setup skill; that restore has not been rehearsed.
4. The setup then asks the person to open the **Needs you** and **History** views and confirm that each exists and filters as printed. Until both are confirmed, `factory-state: 2` is not written and `/factory:run` still refuses the project.
5. Set the board's *Column by* to `Factory status`, as the setup skill asks, and confirm it.

`/factory:run` never runs the migration itself. Exit 5 or 6 from the script stops the migration; the message names the item or field, and the step is run again once the cause is fixed. The script reads the state from the board, so an interrupted migration is simply run again.

### Measurement: the hansei record

Every item the factory runs leaves one **hansei record** in the project where it ran, never in this repo. At the person's merge approval the lead posts one comment on the slice ticket. Its first line is the marker `<!-- factory:hansei v5 -->` (`v4` at 1.2.0, `v3` at 1.1.0, `v2` at 1.0.0), and it holds:

- the release, the two fingerprints (`standard` for the standard work, `tooling` for `hooks/` and `scripts/`), the dependency versions as context, the active overrides (each by name and start date, or `none`), the abnormalities (a count per kind, and a link to each andon comment), a cross-check of the ledger's Tasks table (its header key keeps the 1.x name `stage-log cross-check`), and from 1.3.0 the gemba line below;
- seven measures in a fixed order: lead time, first-pass yield, rework, escaped defects, tokens per role, the person's touches, and doors confirmed or contradicted.

Lead time is split into parts that add up to the total: agent working, waiting for the person, waiting on limits, stalled, interrupted, and, from 1.1.0, andon (the time the lead held the item for an andon). Measure 7 reads `pending resurvey` at posting and is filled by editing the same comment after the resurvey.

While an item runs, the lead keeps a **ledger**: one comment on the slice ticket, with the Tasks table (one row per role task, with its times), the Waits table (the person, usage limits, stalls, interruptions and, from 1.1.0, andon pauses, each naming the agent it stopped) and the Person's touches table. The role tasks are sub-issues, so their own times and closing comments are on the tracker. The lead state, a file the item keeps while it runs and that is removed by the last commit, keeps the lead's memory and nothing the board shows: its label, its findings and its abnormalities. The record is posted before that removal.

A value that could not be captured reads `not captured (<reason>)`. It is never `0`, never blank, and never left out. `n/a (did not run)` is only for a stage or role that did not run. A role whose transcript was cut off by a stall, an interruption or an andon pause reads `not captured (transcript truncated by <kind>)` for its spend. Escaped defects read `not captured` in schemas v2 to v5.

**The gemba line (from 1.3.0).** At each item's close, after the merge approval and before the record is filled, the lead walks one stage of the item. A counted rule picks the stage from the ledger's Tasks table: the ticket number, modulo the count of role tasks that were not flagged. The walk reads what that agent did, in its transcript or, where no transcript can be read, in its commits and result file. It never reads the agent's own summary, and it compares the work with the brief and the stage-log row. The record then carries one header line, `gemba`, that names the stage walked and says whether the walk found a difference. A difference is a question about the process, not about a person, a role or a model, and it gets a 5 Whys as a kind 7 andon. A walk that could not be done reads `not captured (<reason>)`, never `found nothing` and never `0`. The walk comes after the merge approval, so it cannot stop a merge by itself. The rule, the 30,000-character read limit and the grammar of the line are in `plugins/factory/references/hansei.md`, section 6, and in the contracts [60-gemba-sample](contracts/60-gemba-sample.md), [60-gemba-walk](contracts/60-gemba-walk.md) and [60-gemba-line](contracts/60-gemba-line.md). Whether the walk is worth its cost has not been measured yet; [CHANGELOG.md](CHANGELOG.md) lists it under *1.3.0*, *Unverified*.

**The derived lines and the waste tags (from 2.3.0).** Under lead time the record has two sub-lines, computed at the close from the ledger's Tasks and Waits tables and the role-task times, and never stored: `flow efficiency`, the agent working share of the total as a whole percent, and `per stage`, the working and waiting minutes of each stage, so a wait shows at the stage it held. A record posted before 2.3.0 has neither and is read as before. Waste tags are optional: an andon comment, a ledger Waits row, a Tasks row's note or a finding may carry `waste:` and one of eight names (transport, inventory, motion, waiting, overproduction, over-processing, defects, skills); untagged reads `-`. The tagging guide is in `plugins/factory/references/hansei.md`, section 1, *Tagging waste*, and the rules are in [contracts/94-hansei-lean.md](contracts/94-hansei-lean.md).

The data lives in the project's own tracker (the board, the role-task sub-issues, the ledger, the record, the andon comments, and from 1.2.0 the baseline issue and the A3) and in the item's own files while the item runs. No script aggregates the records: the lead reads their comments and keeps the baseline, as [described below](#the-baseline-and-the-a3) explains. The one write this repo receives is the optional factory-feedback issue, which carries the problem in factory terms and never a raw record. Definitions: [contracts/39-hansei-record.md](contracts/39-hansei-record.md) and, for schema v3 and the andon rows, [contracts/49-records.md](contracts/49-records.md); the ledger and the fields of 2.0.0 are in [contracts/64-ledger-and-fields.md](contracts/64-ledger-and-fields.md). The lead's copy of the template is `plugins/factory/references/hansei.md`.

The scripts behind the labels, the bump check, the spend and the cut-offs are described in [contracts/39-plugin-scripts.md](contracts/39-plugin-scripts.md). Run from the repo root:

```bash
bash plugins/factory/scripts/fingerprint.sh plugins/factory          # release, standard and tooling lines
bash plugins/factory/scripts/check-bump.sh                           # in the branch's worktree, after git fetch origin main
bash plugins/factory/scripts/token-spend.sh -- <transcript.jsonl>... # spend and peak context; needs jq
bash plugins/factory/scripts/token-spend.sh --require-end -- <role transcript.jsonl>...  # exit 6 when a transcript was cut off
bash plugins/factory/scripts/cut-offs.sh -- <transcript.jsonl>...    # one line per stall, interruption or limit gap; prints nothing for a clean transcript; needs jq
```

Four scripts were added in 2.0.0. The lead and the setup skill call them, and each file's first lines give its usage:

```bash
bash plugins/factory/scripts/paths.sh overlap <file>... -- <file>...          # do two path lists overlap (rules 1 to 3 of the contract)
bash plugins/factory/scripts/factory-config.sh state [docs/agents/factory.md]  # exit 3 when line 1 is not factory-state: 2
bash plugins/factory/scripts/factory-config.sh budget [docs/agents/factory.md]  # prints the run budget ("none", "<N> tokens" or "<N> hours")
bash plugins/factory/scripts/factory-config.sh reached <spent> [docs/agents/factory.md]  # exit 1 when the budget is reached
bash plugins/factory/scripts/post-text.sh scan [--needs-you] <file>...        # refuses home paths and secrets; with --needs-you, also the names of work folders and branches
bash plugins/factory/scripts/board.sh plan --owner <owner> --project <number>  # reads the board and prints the mapping; changes nothing
```

`board.sh apply --yes` and `board.sh finish --views-confirmed` change the board and the tracker doc. Only the setup skill calls them, after the person's answers. They are described in [contracts/64-board-script.md](contracts/64-board-script.md).

### The baseline and the A3

From 1.2.0 each project keeps two pages of its own, both in its own tracker and neither in this repo.

**The Factory baseline** is one issue, titled exactly `Factory baseline`, whose body starts with the marker `<!-- factory:baseline v1 -->`. The lead finds it at the start of every run by its title, its author (the lead's own `gh` user) and that marker, and creates it when there is none, pinning it when the tracker allows. The body says what "normal" looks like for the release the session runs: the median of each measure over the items that captured it, with how many items that was, and `not captured (<reason>)` where no item did, never `0`. Earlier releases stay below as history, labelled with the date they were replaced. Items run on a frozen install (calibration) and records the lead cannot read are listed, never counted. Nothing is stored: each figure can be recomputed from the hansei records the issue names, and the lead rewrites the whole body after each item.

**The A3** is one comment on the run's map issue, its first line `<!-- factory:a3 v2 -->` from 2.3.0 (`v1` up to 2.2.0; a v1 comment is still read and is never rewritten). It names the one problem the run worked on, the 5 Whys behind it (which end in a process item to change, [blaming the process first](#the-andon-and-overrides)), the one countermeasure tried as an override (the run's *experiment*), how the measure moved before and after against the baseline, with item numbers, release and `k of n`, and what is still uncertain. A run has at most one experiment. From 2.3.0 it also carries three lines: `waste`, the tagged waste counted per type, with the untagged count; `target`, whether the experiment reached the number it was written against; and `gemba (targeted)`, the one walk of the stage the problem points at, made before the 5 Whys. A line with nothing to say reads `none (<reason>)`, and `scripts/a3-check.sh` checks the A3 before it is posted. A run that closed no item writes no A3.

**The run's close** is step 9 of the run skill, in this order: the lead updates the baseline from the records; posts the A3; asks the person, for each override, **keep**, **promote** or **drop**; offers the feedback that the A3 lists; and reports the run closed. `keep` and `promote` make the countermeasure the reference for the next comparison; `drop` removes it and leaves a note in the baseline. `promote` puts a decision card in front of the person, because it would change every project: nothing under `plugins/` changes, and nothing is sent to this repo, until the person decides the card. The feedback issues for this repo are drafted only for what the A3 lists and the person's own remark, and each is posted only when the person approves it.

A run that the person stops after an item has closed still gets its A3, marked `run stopped`, after one yes to *Close the run now?*.

Contracts: [57-baseline](contracts/57-baseline.md), [57-a3](contracts/57-a3.md), [57-run-close](contracts/57-run-close.md), and the record and override fields in [57-records-and-overrides](contracts/57-records-and-overrides.md); and from 2.3.0 [94-a3-v2](contracts/94-a3-v2.md) and [94-hansei-lean](contracts/94-hansei-lean.md). All of them are indexed in [docs/factory/reference.md](docs/factory/reference.md).

### The andon and overrides

An **andon** is the factory's stop-the-line response to an abnormality. A role meets one and writes an `Abnormality:` line in its result, or the lead notices one itself. The list has seven kinds: a blocked input, the same finding twice, a role committing outside its ownership, a stage that took more than twice the usual agent time for its role, a fence crossing, version drift, and *other*, a free-form kind for an event that fits none of the six ([contract](contracts/49-abnormality-list.md)).

The lead then pauses the affected work and stops the running agent. It writes a 5 Whys chain in which each cause names a process object (the brief, the inputs, the standard's text, the tooling, the ownership table, the order of stages) with evidence. A chain that blames a person, a role's care, or a model is refused, and the process is examined first. The lead chooses a countermeasure, resumes the same agent, and carries on. An item is never abandoned by a pause ([contract](contracts/49-andon-process.md)).

A **local countermeasure** is an **override**: a rule under `## Overrides` in the project's own `docs/agents/factory.md`, with a name, a start date, the run it belongs to, the andon comment it came from, and its fence check. An override applies outside the fence, and it never edits a file under `plugins/`. The fence (`## Never overridable locally` in the protocol) lists seven things no override may touch: merge and production approvals, the decision-card route, QA and security verdicts as merge gates, the andon itself, the memory rules, the shell-scope rules, and the honesty rule for measures. Every override also gets one data-egress question, and one yes to any question refuses it. A request from the person does not loosen the fence; loosening is a decision card ([contract](contracts/49-overrides.md)).

Overrides end with their run. At its close the lead shows the person one line per override in force, and the person answers keep, promote or drop. For an experiment that states a `target:` (from 2.3.0), the line also shows the target and whether the after reading reached it. An override from an earlier run with no answer is not applied until the person answers.

Limits, stated plainly: the lead's reading of its results and ledger is the only detection (no hook or watcher raises an andon). The baseline and the A3 are the lead's reading of the comments too. `promote` puts a decision card in front of the person, and a promoted countermeasure is not yet built into the plugin. The rules are text the lead follows. The suite checks that text and replays the rules on invented fixtures and on two real records of a scratch project; a live session has not run every rule, as the 1.2.0 limits in the CHANGELOG list.

### Versions and updates

The factory is versioned with semver in `plugins/factory/.claude-plugin/plugin.json`. Releases: `1.0.0` (the first), `1.1.0` (the andon), `1.2.0` (the per-run A3 and the Factory baseline), `1.3.0` (the gemba sample), `2.0.0` (the board as run state, role tasks as sub-issues, parallel slices; a major release, see [Upgrading a project to 2.0.0](#upgrading-a-project-to-200)), `2.1.0` (test ownership and the TDD loop; a minor release, no migration), and `2.3.0` (the A3 at v2, the waste tags, the derived lines of the hansei record, the target and the targeted walk; a minor release, no migration). Each release commit gets the tag `factory-v<semver>`, so a version maps back to one commit. The marketplace entry carries no version. [CHANGELOG.md](CHANGELOG.md) lists each release, with one entry per item.

Any change under `plugins/factory/` needs a bump in `plugin.json`:

- **minor** or more for standard work: `skills/run/SKILL.md`, `references/*.md`, `agents/*.md`;
- **patch** or more for every other path under `plugins/factory/`, including `hooks/`, `scripts/`, the setup skill and `plugin.json` itself;
- **major** when message formats or the protocol break. The check never requires a major; the architect calls it.

`scripts/check-bump.sh` enforces this. The lead runs it before a PR is opened and again before it is merged, and a PR that fails it does not open or merge. Changes outside `plugins/factory/` pass without a bump.

Installs of the factory change only when its version string changes, so a push without a bump does not reach other projects. The measurement baseline resets on a minor or major release only: from 1.2.0 a project's `1.2` series begins with its first item run on that release, from 1.3.0 its `1.3` series does the same, from 2.0.0 its `2.0` series begins with the first item run on that release, and earlier releases stay in its baseline as history. A run can be frozen on one install (a calibration run): then `/plugin marketplace update` and `/reload-plugins` wait until it closes, because the freeze holds for every project on the machine.

**Restart Claude Code after an update.** A session keeps the factory skill text it read when it started, so a session opened before an install, an update, or a change to `plugins/factory/` still runs the old text. Start a new session before you run an item.

The contract-by-contract reference and the steps for changing the factory are in [docs/factory/reference.md](docs/factory/reference.md). The release, the tag, the checks, the rollback and the roll-forward are in [docs/factory/release-runbook.md](docs/factory/release-runbook.md).

---

## Deploy

### 1. Push this directory to a public GitHub repo

Only for a directory that is not a repo yet. This repo already lives at `WimSuenens/agent-plugins`, so a clone skips this step and goes to step 2. The repo root must be the directory containing `.claude-plugin/`. Public is simplest; private works but complicates background auto-updates.

```bash
cd agent-plugins
git init && git add -A && git commit -m "wayfinding overlay"
gh repo create WimSuenens/agent-plugins --public --source=. --push
```

### 2. Register the marketplace and install the plugins

```bash
claude plugin marketplace add WimSuenens/agent-plugins
claude plugin install mattpocock-skills@wimsuenens
claude plugin install wayfinding@wimsuenens
claude plugin install factory@wimsuenens
```

Or inside a session: `/plugin marketplace add WimSuenens/agent-plugins`, then the installs. If the install summary says `Run /reload-plugins to activate.`, run it. Then restart the session, as the note in *Versions and updates* says. Do not run these during a calibration freeze (see *Versions and updates*): they change the user-scope install that the freeze holds.

> **If the upstream install fails with an SSH error** — `ssh: not found`, or `Could not read from remote repository` — GitHub `owner/repo` shorthand sources clone over SSH by default. Force HTTPS:
>
> ```bash
> CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1 claude plugin install mattpocock-skills@wimsuenens
> ```
>
> This bit me during testing. It affects the `mattpocock-skills` entry only, because that's the one with a `github` source; the overlay uses a relative path and is already local.

### 3. Configure the target repo

Once per repo you want to use this in:

```
/wayfinding:setup-wayfinding-skill
```

It runs upstream's `/setup-matt-pocock-skills` interview first if the repo isn't configured yet (issue tracker, triage labels, doc layout), then deterministically wires the wayfinding conventions into the tracker doc's `## Wayfinding operations` section — the `slice` type, locked/provisional tagging, the Deferred list — and creates the `wayfinder:slice` label on GitHub and GitLab trackers. No manual file patch, no separate `gh label create` step.

In the acceptance demo, the setup left only `wayfinder:slice` among the wayfinder labels; the others (`wayfinder:map`, `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task`) had to be created by hand. Check the project's labels after setup before you run a factory item.

Then, once per repo, the factory's setup, which writes `docs/agents/factory.md` and the `## Factory operations` section of the tracker doc:

```
/factory:setup-factory-skill
```

Use `/wayfinding:ask-me` in this repo instead of `/ask-matt` — it's the same router, with the one flow this overlay changes (the wayfinder on-ramp) pointed at `/wayfinding:wayfinder`.

---

## Use it in a project

Invoke by namespaced name, since plugin skills are registered as `<plugin>:<skill>`:

```
/wayfinding:wayfinder
```

Both wayfinders coexist. `/mattpocock-skills:wayfinder` is upstream's plan-only original; `/wayfinding:wayfinder` is this one. That's why the overlay skill kept the plain name — the namespace already does the disambiguating a `my-` prefix would have done.

`beachhead`, `reversibility`, `setup-wayfinding-skill`, and `ask-me` don't collide with anything, so `/beachhead`, `/reversibility`, `/setup-wayfinding-skill`, and `/ask-me` resolve fine on their own. Use `/ask-me` in place of `/ask-matt` in a repo running this overlay — same router, with the wayfinder on-ramp pointed here.

### The loop

```
1  chart      /wayfinding:wayfinder → grill breadth-first → triage       ~5–7 one-way-door tickets
2  clear      research subagents in parallel, then the rest              each → an ADR
3  beachhead  /beachhead → /to-spec → /to-tickets → /implement           ships to main
4  resurvey   taught / invalidated / triggers / fog / destination        the map moves
5  advance    loop 3–4 until no one-way doors remain ahead
6  dissolve   close the map, drop into the plain main flow
```

Every third slice, run `/improve-codebase-architecture` before picking the next beachhead. Slices accrete; this is what stops the walking skeleton from calcifying into the architecture by default.

### Where the rest of the engineering skills land

**Promoted.** `/domain-modeling` becomes the spine — `CONTEXT.md` and the ADRs are the durable artifacts, the map is scaffolding. `/research` fires generously and in parallel; it's AFK and free. `/improve-codebase-architecture` moves from "when you have a spare moment" to a scheduled step. `/to-questionnaire` becomes load-bearing: a deferred decision whose trigger is "ask a design partner" is exactly what it's for.

**Repositioned.** `/grilling` demoted from default to preference-questions-only — routing is now by *what kind of answer would settle it*. During charting, `/grilling` runs together with `/domain-modeling` (the pair `/grill-with-docs` bundles, which agents cannot invoke), because the paper trail is the point. `/to-spec` runs per slice, not per map. `/prototype` competes with `slice`: prototype when the fake is much cheaper than the real thing, slice when they cost about the same. `/to-tickets`' expand–contract guidance gets more load-bearing, because deferring decisions means migrating shapes later.

**Unchanged.** `/implement` → `/tdd` → `/code-review` is the per-slice engine. `/triage` stays for inbound work only, never map tickets. `/diagnosing-bugs` stays an on-ramp, with one addition: a post-mortem that contradicts a `[locked]` decision is a resurvey trigger. `/wizard` serves `task` tickets. `/resolving-merge-conflicts` gets more use with parallel slices.

---

## Iterating on the overlay

Skip the push entirely while developing — `marketplace add` accepts a local path:

```bash
claude plugin validate .                       # marketplace catalog
claude plugin validate ./plugins/wayfinding    # plugin manifest
claude plugin validate ./plugins/wayfinding/skills   # every SKILL.md frontmatter

claude plugin marketplace add ./agent-plugins
claude plugin install wayfinding@wimsuenens
```

After editing a skill, reinstall to pick it up:

```bash
claude plugin uninstall wayfinding@wimsuenens
claude plugin marketplace update wimsuenens
claude plugin install wayfinding@wimsuenens
```

A directory-sourced marketplace has no commit SHA, so `plugin list` reports `Version: unknown` and update detection doesn't work — hence the uninstall. Once it's on GitHub, `claude plugin marketplace update wimsuenens` is enough.

To try a factory change without installing it, load the plugin from a checkout for one session (the route the acceptance demo used):

```bash
claude --plugin-dir ./plugins/factory      # or <worktree>/plugins/factory
```

This leaves the installed factory alone. The session reads the skill text when it starts, so restart it after every change to `plugins/factory/`. Before you rely on it, check that the loaded run skill is the new one: the `run` skill has had a `Plugin root:` line near its top since 1.0.0, and the pre-1.0.0 text has none. During a calibration freeze, use this route only.

### Why `plugin.json` has no `version`

Deliberate, for every plugin except the factory, which has carried `version` since 1.0.0 (see [Versions and updates](#versions-and-updates)). With `version` omitted, a git-sourced plugin's version resolves to the commit SHA, so every push propagates. With `version` pinned, Claude Code serves the cached copy until the string changes — and forgetting to bump it produces a silent, confusing staleness. `claude plugin validate` emits a non-blocking warning about the missing version; that warning is the cost, and it's the cheaper of the two failure modes.

To pin upstream so its updates arrive on your schedule rather than Matt's, add a `ref` to the `mattpocock-skills` entry in `marketplace.json`:

```json
"source": { "source": "github", "repo": "mattpocock/skills", "ref": "v1.2.3" }
```

### Sharing with a team or across your machines

Commit this to the project's `.claude/settings.json` and the marketplace registers itself for anyone who trusts the folder:

```json
{
  "extraKnownMarketplaces": {
    "agent-plugins": { "source": { "source": "github", "repo": "WimSuenens/agent-plugins" } }
  },
  "enabledPlugins": {
    "mattpocock-skills@wimsuenens": true,
    "wayfinding@wimsuenens": true
  }
}
```

---

## What was tested

Run against Claude Code `2.1.237` on Linux:

| Check | Result |
| --- | --- |
| `claude plugin validate .` | passed |
| `claude plugin validate ./plugins/wayfinding` | passed (version warning, intentional) |
| `claude plugin validate ./plugins/wayfinding/skills` | passed — all five SKILL.md frontmatter blocks parse |
| `claude plugin marketplace add ./agent-plugins` | registered |
| `claude plugin install wayfinding@wimsuenens` | installed, all five skill directories present in cache |
| `claude plugin install mattpocock-skills@wimsuenens` | installed at 1.2.3 after forcing HTTPS |
| Both plugins enabled together | no collision error; both `wayfinder` skills present under separate namespaces |
| Uninstall → marketplace update → reinstall | clean |

**Not tested, because it needs an interactive session against a real repo:** whether the skills fire correctly end to end, and whether bare cross-references inside the skill bodies (`/grilling`, `/to-tickets`, `/implement`) resolve across the plugin boundary. Upstream's own skills reference each other bare and ship as a plugin, so the convention is proven — but proven *within* one plugin, not across two. If a cross-plugin reference doesn't resolve, prefix it: `/mattpocock-skills:to-tickets`.

The `factory` plugin, on macOS with gh `2.94.0`:

| Check | Result |
| --- | --- |
| `claude plugin validate .` | passed; four warnings for the plugins without a `version` (wayfinding, toolkit, discover, design), intentional; the factory has none |
| `claude plugin validate ./plugins/factory` | passed, no warning (version 1.0.0) |
| `claude plugin validate ./plugins/factory/skills` | passed |
| `bash plugins/factory/scripts/fingerprint.sh plugins/factory` | prints `release: 1.0.0` and the standard and tooling fingerprints |
| `bash plugins/factory/scripts/check-bump.sh` on `item/39` | `pass: minor bump needed, 0.0.0 -> 1.0.0` (main has no version yet) |
| `bash plugins/factory/scripts/token-spend.sh -- <PO transcript of #39>` | `spend 387472 …; peak 53942; messages 11`, the figures the contract records |
| `bash tests/run.sh` | the factory's script and standard-text tests: `ALL PASSED`, with no named skip, on 2026-11-05 at the docs commit. The QA verdict is in [reviews/qa-39.md](reviews/qa-39.md) |
| `bash plugins/factory/scripts/cut-offs.sh -- <PO transcript of #39>` | prints nothing (no gap in that transcript), exit 0 |
| `guard-memory.sh` against twelve sample inputs, with and without `jq` | every input allowed or blocked as intended |
| `gh project` flags used by the setup and the tracker patch | present in `--help` |
| acceptance demo, in a scratch project, `claude --plugin-dir` | every human-only criterion passed except AC-17, which failed there; fixed in schema v2 and verified by replay of the demo's transcripts |

The `factory` plugin at 1.1.0, on macOS (Claude Code 2.1.287, `/bin/bash` 3.2.57, `jq` and `gh` present), on 2026-11-06, from `item/49`. Only read-only and validate-only commands were run. The user-scope install is frozen on `9147301f75c3` for the calibration run, so install, marketplace and reload commands were not run; see [Versions and updates](#versions-and-updates).

| Check | Result |
| --- | --- |
| `claude plugin validate ./plugins/factory` | passed, no warning |
| `claude plugin validate ./plugins/factory/skills` | passed |
| `claude plugin validate .` | passed; the same four version warnings for the plugins without a `version` |
| `claude plugin list --json` | the user-scope `factory@wimsuenens` is still `9147301f75c3`; the freeze holds |
| `bash plugins/factory/scripts/fingerprint.sh plugins/factory` | prints `release: 1.1.0` and the standard and tooling fingerprints (not written here: they change with any edit under `plugins/factory/`) |
| `git fetch origin main`, then `bash plugins/factory/scripts/check-bump.sh` | `pass: minor bump needed, 1.0.0 -> 1.1.0` |
| `bash tests/run.sh` | `ALL PASSED`: 952 passed, 0 skipped, exit 0 |
| `bash plugins/factory/scripts/token-spend.sh -- <PO transcript of #39>` | `spend 387472 …; peak 53942; messages 11`, the figures the contract records (unchanged from 1.0.0) |
| `bash plugins/factory/scripts/token-spend.sh --require-end -- <same transcript>` | exit 0 |
| `bash plugins/factory/scripts/cut-offs.sh -- <same transcript>` | prints nothing, exit 0 |

The `factory` plugin at 1.2.0, on macOS (Claude Code `2.1.287`, `/bin/bash` 3.2.57, `jq` 1.8.1, `gh` 2.94.0), on 2026-11-07, from `item/57`. Only read-only and validate-only commands were run, and the user-scope install was not touched: `factory@wimsuenens` is still on `9147301f75c3` because this run is frozen. So install, marketplace and reload commands were not run, and nor were `/factory:run` or `/factory:setup-factory-skill`, which are interactive and write to the repo. The tracker lookups were run read-only against this repo.

| Check | Result |
| --- | --- |
| `claude plugin validate .` | passed; the same four version warnings for the plugins without a `version` (wayfinding, toolkit, discover, design), intentional |
| `claude plugin validate ./plugins/factory` | passed, no warning |
| `claude plugin validate ./plugins/factory/skills` | passed, no warning |
| `claude plugin list --json` | `factory@wimsuenens` is `9147301f75c3`; the freeze holds |
| `git fetch origin main`, then `bash plugins/factory/scripts/check-bump.sh` | `pass: minor bump needed, 1.1.0 -> 1.2.0`, exit 0 |
| `bash plugins/factory/scripts/fingerprint.sh plugins/factory` | prints `release: 1.2.0` and the standard and tooling fingerprints (not written here: they change with any edit under `plugins/factory/`); the tooling line equals 1.1.0's |
| `bash tests/run.sh` | `ALL PASSED`: 1436 passed, 0 skipped, exit 0, across ten test files |
| *Find baseline*, *Find records*, *Find A3s* and *Find A3* from the tracker doc, read-only | each exits 0 and prints no line: this repo holds no `Factory baseline` issue, no hansei record with its marker and no A3, as the calibration run expects |

**Not tested yet, for 1.2.0:** the install and update path, and the rollback, which need an unfrozen machine (see the [release runbook](docs/factory/release-runbook.md)); a live session's run close and its settle answers; and the human-only checks of [CHANGELOG.md](CHANGELOG.md) under *1.2.0*. The 1.2.0 demo ran in a scratch project and is summarised there.

The `factory` plugin at 1.3.0, on macOS (Claude Code `2.1.287`, `/bin/bash` 3.2.57, `jq` 1.8.1, `gh` 2.94.0), on 2026-11-07, from `item/60`. Only read-only and validate-only commands were run, and the user-scope install was not touched: `factory@wimsuenens` is still on `9147301f75c3` because this run is frozen. So install, marketplace and reload commands were not run, nor were `/factory:run` or `/factory:setup-factory-skill`, which are interactive and write to the repo. The tracker's find operations were not run for this release.

| Check | Result |
| --- | --- |
| `claude plugin validate ./plugins/factory` | passed, no warning |
| `claude plugin validate ./plugins/factory/skills` | passed, no warning |
| `claude plugin list --json` | `factory@wimsuenens` is `9147301f75c3`; the freeze holds |
| `git fetch origin main`, then `bash plugins/factory/scripts/check-bump.sh` | `pass: minor bump needed, 1.2.0 -> 1.3.0`, exit 0 |
| `bash plugins/factory/scripts/fingerprint.sh plugins/factory` | prints `release: 1.3.0` and the standard and tooling fingerprints (not written here: they change with any edit under `plugins/factory/`); the tooling line equals 1.2.0's, the standard line does not |
| `bash tests/run.sh` | `ALL PASSED`: 1939 passed, 0 skipped, exit 0, across eleven test files; the changelog check of 1.3.0 runs and passes |
| `bash plugins/factory/scripts/token-spend.sh -- <transcript of this run's docs-writer agent>` | prints spend, peak and message count, exit 0 |
| `bash plugins/factory/scripts/cut-offs.sh -- <same transcript>` | prints nothing, exit 0 |
| `bash plugins/factory/scripts/token-spend.sh --require-end -- <same transcript>` | exit 6: the transcript was read before its agent gave a final reply, which the check reads as cut off; no finished transcript was at hand to re-run it |
| the view part of the walk's command block (`hansei.md`, section 6), on the same transcript | exit 0 with empty stderr; the whole view fits the budget, so it is not partial |

**Not tested yet, for 1.3.0:** the install and update path, and the rollback, which need an unfrozen machine (see the [release runbook](docs/factory/release-runbook.md)); the walk on a real project's transcript and a live close at step 8.3a; and the items listed as unverified in [CHANGELOG.md](CHANGELOG.md) under *1.3.0*.

The `factory` plugin at 2.0.0, on macOS (Claude Code `2.1.287`, `/bin/bash` 3.2.57, `jq` 1.8.1, `gh` 2.94.0), on 2026-11-08, from `item/64`. Only read-only and validate-only commands were run, and the user-scope install was not touched: `factory@wimsuenens` is still factory 1.3.0, the frozen install of this run. So install, marketplace and reload commands were not run; nor were `/factory:run` or `/factory:setup-factory-skill`, and no board write was made. `board.sh plan` ran read-only against this repository's own Project. Its output named the mapping and the snapshot file it would write, and it wrote no snapshot.

| Check | Result |
| --- | --- |
| `claude plugin validate .` | passed with the four version warnings for the plugins without a `version` (wayfinding, toolkit, discover, design), intentional |
| `claude plugin validate ./plugins/factory` | passed, no warning |
| `claude plugin validate ./plugins/factory/skills` | passed, no warning |
| `bash plugins/factory/scripts/fingerprint.sh plugins/factory` | prints `release: 2.0.0`, `standard: 4bb4220e38b7…` and `tooling: 92746e5d526a…` (in full in the runbook, *Release 2.0.0*) |
| `bash plugins/factory/scripts/check-bump.sh`, after `git fetch origin main` | `pass: minor bump needed, 1.3.0 -> 2.0.0`, exit 0 |
| `bash plugins/factory/scripts/board.sh plan --owner WimSuenens --project 9 --project-id <id>` | read-only; prints the status mapping and the snapshot file it would write, exit 0 |
| `bash tests/run.sh` | `ALL PASSED`, no failure, with seven named skips (listed in the runbook, *Release 2.0.0*, check 5) |
| `claude plugin list --json` | `factory@wimsuenens` is 1.3.0, scope user, enabled: the frozen install of this run; nothing was changed |

**Not tested yet, for 2.0.0:** the migration on a Project, including the scratch-Project try the lead runs before the merge; the Needs you and History views; the restore from a snapshot; parallel slices on a real project; the install and update path, and the rollback. The items listed as unverified in [CHANGELOG.md](CHANGELOG.md) under *2.0.0* are the full list.

The `factory` plugin at 2.1.0, on macOS (Claude Code `2.1.287`, `/bin/bash` 3.2.57, `jq` 1.8.1, `gh` 2.94.0), on 2026-11-09, from `item/73`. Only read-only and validate-only commands were run, and the user-scope install was not touched: `factory@wimsuenens` is still factory 2.0.0, the frozen install of this run. So install, marketplace and reload commands were not run; nor were `/factory:run` or `/factory:setup-factory-skill`. The scenario cards were played by QA, as one reader.

| Check | Result |
| --- | --- |
| `claude plugin validate .` | passed with the four version warnings for the plugins without a `version` (wayfinding, toolkit, discover, design), intentional |
| `claude plugin validate ./plugins/factory` | passed, no warning |
| `claude plugin validate ./plugins/factory/skills` | passed, no warning |
| `bash plugins/factory/scripts/fingerprint.sh plugins/factory` | prints `release: 2.1.0` and the standard and tooling fingerprints (not written here: they change with any edit under `plugins/factory/`); the tooling line equals 2.0.0's, the standard line does not |
| `git fetch origin main`, then `bash plugins/factory/scripts/check-bump.sh` | `pass: minor bump needed, 2.0.0 -> 2.1.0`, exit 0 |
| `bash tests/factory/test_ownership_tdd.sh` | `186 passed, 0 skipped, fail=0`; the changelog entry and the README row of this release are checked, and were skipped before they existed |
| `bash tests/run.sh` | `ALL PASSED`: 3315 passed, 15 skipped, 0 failed, exit 0, across 19 test files |
| `claude plugin list --json` | `factory@wimsuenens` is 2.0.0, scope user, enabled: the frozen install of this run; nothing was changed |

**Not tested yet, for 2.1.0:** a live session on the new text, including the Tests stage and the code-review decision; the three risk triggers as a real lead judges them; the pilot's measures; a second reader of the scenario cards; the install and update path, and the rollback, which need an unfrozen machine (see the [release runbook](docs/factory/release-runbook.md)). The items listed as unverified in [CHANGELOG.md](CHANGELOG.md) under *2.1.0* are the full list, and they include QA's open finding F1.

The `factory` plugin at 2.3.0, on macOS (Claude Code `2.1.287`, `/bin/bash` 3.2.57, `jq` 1.8.1, `gh` 2.94.0), on 2026-11-10, from `item/94`. Only read-only and validate-only commands were run, and the user-scope install was not touched: `factory@wimsuenens` is still factory 2.2.0, the frozen install of this run. So install, marketplace and reload commands were not run; nor were `/factory:run` or `/factory:setup-factory-skill`.

| Check | Result |
| --- | --- |
| `claude plugin validate .` | passed with the four version warnings for the plugins without a `version` (wayfinding, toolkit, discover, design), intentional |
| `claude plugin validate ./plugins/factory` and `./plugins/factory/skills` | passed, no warning |
| `bash plugins/factory/scripts/fingerprint.sh plugins/factory` | prints `release: 2.3.0`; the standard and tooling fingerprints are on the last line of the 2.3.0 entry in [CHANGELOG.md](CHANGELOG.md), not written here |
| `git fetch origin main`, then `bash plugins/factory/scripts/check-bump.sh` | `pass: minor bump needed, 2.2.0 -> 2.3.0`, exit 0 |
| `bash plugins/factory/scripts/a3-check.sh <file>` on the v2 and the v1 worked examples of `plugins/factory/references/a3.md`, section 3 | `ok v2` and `ok v1`, exit 0 |
| `bash tests/run.sh` | `ALL PASSED`: 3767 passed, 17 skipped, 0 failed, across 21 test files. The three named skips of the 2.3.0 docs are passes now; the 17 that remain are named skips of older releases, each with its reason in the output |
| `claude plugin list --json` | `factory@wimsuenens` is 2.2.0, scope user, the frozen install of this run; nothing was changed |

**Not tested yet, for 2.3.0:** a live session on the new text, including a run that closes with an A3 v2 and a settle answer for an experiment with a `target:`; the waste tags, the derived lines and the targeted walk as a live lead applies them; the install and update path, and the rollback, which need an unfrozen machine (see the [release runbook](docs/factory/release-runbook.md)). The security pass predates the fix of its low finding, which has not been re-reviewed. The items listed as unverified in [CHANGELOG.md](CHANGELOG.md) under *2.3.0* are the full list.

The `factory` plugin at 2.3.1 (#106), on macOS, on 2026-11-10, from `fix/106-awk-operand-guard`. Only read-only and validate-only commands were run; the user-scope install was not touched (`factory@wimsuenens` is still 2.2.0, the frozen install of this run).

| Check | Result |
| --- | --- |
| `claude plugin validate ./plugins/factory` | passed |
| `bash plugins/factory/scripts/fingerprint.sh plugins/factory` | prints `release: 2.3.1`; the standard fingerprint is the same as for 2.3.0 and the tooling fingerprint moved; both are on the last line of the 2.3.1 entry in [CHANGELOG.md](CHANGELOG.md) |
| `bash plugins/factory/scripts/check-bump.sh` | `pass: patch bump needed, 2.3.0 -> 2.3.1`, exit 0 |
| `bash tests/factory/test_awk_operand_guard.sh` | 17 passed; before the fix it failed 10 checks |
| `bash tests/run.sh` | `ALL PASSED`: 3784 passed, 17 skipped, 0 failed, across 22 test files |

**Not tested yet, for 2.3.1:** a live session; the install and update path. The 2.3.0 note that the same awk file-operand pattern sat in `post-text.sh` and `board.sh` is closed by this release, and the 2.3.0 low finding in `a3-check.sh` is covered by the 2.3.0 fix. The security review of the 2.3.1 branch found nothing. The earlier 2.3.0 notes above stay as they were at that release.

The `factory` plugin at 2.5.0 (#110), on macOS, on 2026-11-11. Ideas can be filed any time (`/factory:idea`, a tracker issue labelled `idea`, or a file in the gitignored inbox `.claude/factory-inbox/`) and are triaged at run start to one of five outcomes with a reason (script `intake.sh`). `bash tests/factory/test_idea_intake.sh` passes, `bash tests/run.sh` prints `ALL PASSED`. **Not tested yet, for 2.5.0:** a live session and real GitHub (tested against a stub `gh`).

Previous: The `factory` plugin at 2.4.0 (#109), on macOS, on 2026-11-11. Worktrees now live in `.claude/worktrees` inside the project (script `worktree.sh`: `add`, `ignore`, `legacy`; setup migrates old `../wt` worktrees). `bash tests/factory/test_worktree_folder.sh` passes (58 checks), `bash tests/run.sh` prints `ALL PASSED`, and `claude plugin validate ./plugins/factory` passes. **Not tested yet, for 2.4.0:** a live session; `git worktree move` on a real project with a running item.

**Not tested yet:** a factory item on a project with real application code. The acceptance demo ran an item end to end in a scratch project; the first run on a real project closes the remaining open questions, or turns them into findings.

## Known costs

- **Triage quality is the whole mechanism.** Mis-sort a one-way door as a two-way door and you get the failure this layer exists to avoid, arriving later and more expensively than upstream's version would have. The `~5–7` count check during charting is a smoke alarm, not a guarantee.
- **The tracker patches are a fork of one section each.** `setup-wayfinding-skill/references/issue-tracker-{github,gitlab,local}.wayfinding.md` each fork one upstream "Wayfinding operations" section; re-check them after a major upstream release, since upstream could change the mechanics they're built on. Applying them is automatic now — only the content itself still needs re-checking.
- **`reversibility`, `wayfinder`, and `beachhead` are model-invoked**, so their descriptions carry permanent context load. `reversibility` pays it for shared vocabulary; `wayfinder` and `beachhead` pay it so `/factory:run` can chart, frame, and resurvey on its own ([ADR 0006](docs/adr/0006-factory-builds-wayfinder-slices.md)).
- **Deferred rots without discipline.** The trigger is the only thing between a deferral and an abandonment. If resurvey step 3 gets skipped, the section becomes a graveyard within a month.

## Lighter alternatives

If the plugin still isn't worth it, the ideas survive without any of this. Put the triage in the map's `## Notes` block, which upstream `/wayfinder` already loads every session:

> Triage every question one-way / two-way. Ticket only the one-way doors; the rest go to a Deferred list, each with an observable trigger. Between tickets, ship a thin slice against real infrastructure and resurvey the map against what it taught.

Roughly 80% of the behaviour change, zero install. Run that on a real effort first, and build the plugin only if you find yourself retyping it.
