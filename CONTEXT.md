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
