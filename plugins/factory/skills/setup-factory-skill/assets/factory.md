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

Tests. `tests/` is the acceptance suite: QA owns it and the developer never edits it. The developer's own tests (unit tests beside the code) are developer-owned, sit in the path of the developer's `src/` row, and are not the acceptance suite; QA may read, run and ignore them. Where a repo keeps unit tests in a directory of its own, give that directory a row owned by the developer, never a path under the `tests/` row. When the slice's deliverable is a test harness, QA writes it and its first cases in `tests/`.

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

## Maintenance budget

maintenance-budget: 10 candidates

The most candidates one maintenance cycle may file: `maintenance-budget: <N> candidates`. Default 10 when the line is absent.

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
| idea | |

| Role | Option id |
|---|---|
| product-owner | |
| architect | |
| developer | |
| qa-engineer | |
| security-reviewer | |
| devops | |
| docs-writer | |
