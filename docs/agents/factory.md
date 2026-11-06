# Factory

How the `factory` plugin runs in this repo. Every factory role reads this after the protocol; `/factory:run` reads it before starting an item.

## Decision-maker

decision-maker: technical

One-way doors reach this person as decision cards. `non-technical`: consequences in everyday words, no mechanism. `technical`: the same card with the technical detail added.

## Role models

None — roles use the plugin defaults (see the factory's README).

Overrides replace a role's default model in this repo, one row per role: `| <role> | <haiku, sonnet, opus, or fable> |` under a `| Role | Model |` header. Roles without a row keep their default.

## Ownership

| Path | Owner |
|---|---|
| `docs/requirements/` | product-owner |
| `contracts/`, `docs/adr/`, `CONTEXT.md` | architect |
| `plugins/` | developer |
| `tests/`, `reviews/qa-*` | qa-engineer |
| `reviews/security-*` | security-reviewer |
| pipeline, infra, deploy scripts, runbooks | devops |
| `docs/` (rest), `README.md`, `CHANGELOG.md` | docs-writer |
| `docs/agents/factory.md` section `## Overrides` | lead |

## Worktrees

Item worktrees live at `../wt/<id>`, on branch `item/<id>`.
Frontier-round worktrees live at `../wt/frontier-<map>`, on branch `frontier/<map>`.

## Tracker

Factory operations are in `docs/agents/issue-tracker.md`, under `## Factory operations`. The board view groups by `Factory status`; the project's built-in `Status` field is not used by the factory.

Resolved ids for the GitHub Project:

| Key | Value |
|---|---|
| owner | WimSuenens |
| project number | 9 |
| project id | PVT_kwHOBIbaa84BqOBF |
| field id (`Factory status`) | PVTSSF_lAHOBIbaa84BqOBFzhomGRs |

| Status | Option id |
|---|---|
| Backlog | e9bba983 |
| Ready | 32b05555 |
| Designed | 3ec995d0 |
| In progress | e692bccd |
| In review | bd97622f |
| Ready to deploy | 3c7e864d |
| Done | bcfb5c1e |
