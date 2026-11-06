# Context

## Factory

**Lead** — the main session running `/factory:run`; it briefs the roles, reads their results, and stands between them and the person.
_Avoid_: orchestrator, coordinator

**Run** — one destination taken from idea to a dissolved map.

**Item** — one slice of a run, built on its own branch and merged on its own PR.
_Avoid_: task, story

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

**Stage log** — the Lead's timed account of an item in its lead state: one row per stage with UTC start and end, the agents that worked it, waits for the person or on limits, and the person's touches. The hansei record is computed from it, and it goes with `work/<id>/` at close.
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
