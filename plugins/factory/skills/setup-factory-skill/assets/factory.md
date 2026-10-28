# Factory

How the `factory` plugin runs in this repo. Every factory role reads this after the protocol; `/factory:run` reads it before starting an item.

## Decision-maker

decision-maker: non-technical

One-way doors reach this person as decision cards. `non-technical`: consequences in everyday words, no mechanism. `technical`: the same card with the technical detail added.

## Role models

None — roles use the plugin defaults (see the factory's README).

Overrides replace a role's default model in this repo, one row per role: `| <role> | <haiku, sonnet, opus, or fable> |` under a `| Role | Model |` header. Roles without a row keep their default.

## Ownership

| Path | Owner |
|---|---|
| `docs/requirements/` | product-owner |
| `contracts/`, `docs/adr/` | architect |
| `src/` | developer |
| `tests/`, `reviews/qa-*` | qa-engineer |
| `reviews/security-*` | security-reviewer |
| pipeline, infra, deploy scripts, runbooks | devops |
| `docs/` (rest), `README.md`, `CHANGELOG.md` | docs-writer |

## Worktrees

Item worktrees live at `../wt/<id>`, on branch `item/<id>`.

## Tracker

Factory operations are in `docs/agents/issue-tracker.md`, under `## Factory operations`. Resolved ids for the GitHub Project:

| Key | Value |
|---|---|
| owner | |
| project number | |
| project id | |
| field id (`Factory status`) | |

| Status | Option id |
|---|---|
| Backlog | |
| Ready | |
| Designed | |
| In progress | |
| In review | |
| Ready to deploy | |
| Done | |
