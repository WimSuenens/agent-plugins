# Context

## Factory

**Lead** — the main session running `/factory:run`; it briefs the roles, reads their results, and stands between them and the person.
_Avoid_: orchestrator, coordinator

**Run** — one destination taken from idea to a dissolved map.

**Item** — one slice of a run, built on its own branch and merged on its own PR.
_Avoid_: task, story

**Frontier round** — the factory work of clearing the map's one-way doors outside any item; it ends in one PR to main carrying its ADRs and glossary changes.

**Role model** — the Claude model a factory role runs on. Its default is the `model:` in the role's agent file; a repo overrides it per role in the `## Role models` table of `docs/agents/factory.md`.
