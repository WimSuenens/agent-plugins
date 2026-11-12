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
| `docs/requirements/`, `docs/direction.md` | product-owner |
| `contracts/`, `docs/adr/`, `CONTEXT.md` | architect |
| `plugins/` | developer |
| `apps/obeya/` (the app; its `Dockerfile` and CI files stay with devops) | developer |
| `apps/site/` (the documentation site app) | developer |
| `.github/workflows/site.yml` | devops |
| `tests/`, `reviews/qa-*` | qa-engineer |
| `reviews/security-*` | security-reviewer |
| pipeline, infra, deploy scripts, runbooks | devops |
| `docs/` (rest), `README.md`, `CHANGELOG.md` | docs-writer |
| `docs/agents/factory.md` section `## Overrides` | lead |

## Worktrees

Item worktrees live at `.claude/worktrees/<id>`, on branch `item/<id>`.
Frontier-round worktrees live at `.claude/worktrees/frontier-<map>`, on branch `frontier/<map>`.

The folder is inside the project, in the agent tool's own worktree folder, and is ignored in `.gitignore`. Every test, lint and search run excludes `.claude/worktrees`, so the main checkout never scans the worktrees (for example `grep -rn --exclude-dir=worktrees`, `git grep`, or the runner's ignore setting).

## Measurement

measurement: full

`full` (the default, and the same as no line) is the whole measurement. `measurement: lite` gives a short hansei record and computes cut-offs and token spend only when asked. The baseline and the A3 are the same under both.

## Run budget

run-budget: none

An optional brake on one run, in tokens or hours: `run-budget: <N> tokens` or `run-budget: <N> hours`. `none` means no brake.

## Obeya

obeya: on

Set `obeya: on` to opt in to the Obeya, a read-only browser view of this project. `/factory:obeya` then starts and stops it in a container on loopback; without `on` the command refuses. A project that does not opt in keeps the existing workflow untouched.

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
