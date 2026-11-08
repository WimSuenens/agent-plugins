factory-state: 2

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

## Parallel slices

parallel-limit: 2

How many slices may run at the same time, when their path lists do not overlap. `1` means one at a time.

## Tracker

Factory operations are in `docs/agents/issue-tracker.md`, under `## Factory operations`. The board view groups by `Factory status`; the project's built-in `Status` field is not used by the factory.

Resolved ids for the GitHub Project:

| Key | Value |
|---|---|
| owner | WimSuenens |
| project number | 9 |
| project id | PVT_kwHOBIbaa84BqOBF |
| field id (`Factory status`) | PVTSSF_lAHOBIbaa84BqOBFzhomGRs |
| field id (`Kind`) | PVTSSF_lAHOBIbaa84BqOBFzhpGe7I |
| field id (`Role`) | PVTSSF_lAHOBIbaa84BqOBFzhpGe8A |
| field id (`Tokens`) | PVTF_lAHOBIbaa84BqOBFzhpGe8E |
| field id (`Minutes`) | PVTF_lAHOBIbaa84BqOBFzhpGe8I |
| field id (`Hours`) | PVTF_lAHOBIbaa84BqOBFzhpGe8M |
| field id (`Rework rounds`) | PVTF_lAHOBIbaa84BqOBFzhpGe88 |
| field id (`Person touches`) | PVTF_lAHOBIbaa84BqOBFzhpGe-I |

| Status | Option id |
|---|---|
| Backlog | e9bba983 |
| Ready | 32b05555 |
| Running | f70eb8b9 |
| Waiting on you | f30b7d41 |
| Blocked | f9652a0a |
| Done | bcfb5c1e |

| Kind | Option id |
|---|---|
| map | b7758e72 |
| slice | 15ba4ed6 |
| role task | 3642c2d4 |
| frontier ticket | f436c911 |

| Role | Option id |
|---|---|
| product-owner | 893b6258 |
| architect | 1fc8203f |
| developer | 5754670b |
| qa-engineer | 749d6144 |
| security-reviewer | f858a981 |
| devops | 582eb3ea |
| docs-writer | f9753564 |
