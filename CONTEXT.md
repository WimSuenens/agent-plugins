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
_Avoid_: local fix, workaround, experiment (the experiment is how a countermeasure is measured, not the change itself)

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

**Baseline** — the reference numbers that later changes are compared with; it opens with the first item on a major or minor release.
_Avoid_: benchmark, before (for numbers that were never meant as one)

**Calibration** — the measurements of a run that are recorded with full labels but never used as a baseline, such as a run frozen on a pre-release install; they show what the numbers look like and what capturing them costs.
_Avoid_: pilot, dry run, baseline
