factory-state: 2

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
| `docs/agents/factory.md` section `## Overrides` | lead |

## Worktrees

Item worktrees live at `../wt/<id>`, on branch `item/<id>`.
Frontier-round worktrees live at `../wt/frontier-<map>`, on branch `frontier/<map>`.

## Parallel slices

parallel-limit: 2

How many slices may run at the same time, when their path lists do not overlap. `1` means one at a time.

## Tracker

Factory operations are in `docs/agents/issue-tracker.md`, under `## Factory operations`. The board view groups by `Factory status`; the project's built-in `Status` field is not used by the factory.

Resolved ids for the GitHub Project:

| Key | Value |
|---|---|
| owner | |
| project number | |
| project id | |
| field id (`Factory status`) | |
| field id (`Kind`) | |
| field id (`Role`) | |
| field id (`Tokens`) | |
| field id (`Minutes`) | |
| field id (`Hours`) | |
| field id (`Rework rounds`) | |
| field id (`Person touches`) | |

| Status | Option id |
|---|---|
| Backlog | |
| Ready | |
| Running | |
| Waiting on you | |
| Blocked | |
| Done | |

| Kind | Option id |
|---|---|
| map | |
| slice | |
| role task | |
| frontier ticket | |

| Role | Option id |
|---|---|
| product-owner | |
| architect | |
| developer | |
| qa-engineer | |
| security-reviewer | |
| devops | |
| docs-writer | |
