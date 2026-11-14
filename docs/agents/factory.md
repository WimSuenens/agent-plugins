factory-state: 2

# Factory

How the `factory` plugin runs in this repo. Every factory role reads this after the protocol; `/factory:run` reads it before starting an item.

## Release hook

release-hook: scripts/release.sh

This repository develops the factory plugin, so it declares the hook of the plugin's release: `scripts/release.sh` (see *Releasing the factory plugin*).

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

## Releasing the factory plugin (this repository only)

This repository develops the factory plugin itself. These rules belong to the repository, not to the plugin: a project that only uses the factory does not have them. The tooling is at the repository root, in `scripts/`, and the plugin reaches it only through the `release-hook:` line above.

- **Release class.** When a slice changes files under `plugins/factory/`, the class comes from the bump check, not from anyone's judgement: standard text and the run skill need a minor bump, any other factory file a patch (`scripts/release-lib.sh` holds that one classification; `check-bump.sh` and `release-class.sh` both read it). Before the architect's brief, the lead runs `bash scripts/release-class.sh origin/main <the paths the slice will change>` and puts its answer line in the brief; the architect quotes that line in the contract before the contract names a version or a release class. A change that leaves the meaning of standard text unchanged still counts as standard work.
- **At *Open PR* and before the merge**, the hook's `check` runs `scripts/check-bump.sh`: exit 0 pass, 1 the bump is missing, 2 an unusable repository or base.
- **In the merge train**, the hook resolves a clash in `plugins/factory/.claude-plugin/plugin.json` (it takes main's version) or `CHANGELOG.md` (both entries kept, the branch's above main's), raises the version to the level the check names and moves the entry `## factory <version> (#<id>)` with it, and, after the merge, tags `factory-v<version>` and pushes the tag. A missing changelog entry, or two entries for one version, stops the train (exit 4).
- **The changelog entry** is the plugin's release record: one `## factory <version> (#<id>)` entry per item that changes the plugin, with a `Release:` line and the fingerprints (`plugins/factory/scripts/fingerprint.sh` reproduces them). The docs-writer adds it before the merge.
- The tag scheme `factory-v<semver>`, the fingerprint label, andon kind 6 and the hansei `release` field are fixed: they say which release ran.

## Flow table

The points table the lead sizes each destination and each slice with. The path is the sum of the triggers that fire; the lightest path is zero points. The lead may add and adjust rows within the fence and records every change in the hansei. A row turns `settled` after enough slices without a large calibration error.

table: provisional
confirmed: by merging the pull request that adds this table (slice 3 of #207)
project-type: markdown/LLM plugin
test-depth: proof-only
test-depth-apps: targeted (slices that touch `apps/`; the rest of the repository stays proof-only)
bands: Light 0 to 2, Normal 3 to 6, Heavy 7 or more
floor: never removed by the table: the independent QA verdict, runtime proof, security review and the person's merge approval for protected areas, and one-way doors stay with the person.

`test-depth` is the starting depth for this project type: a markdown/LLM plugin or a static site starts at `proof-only`, a code app at `targeted`; full depth exists only after an escalation or an escaped defect.

| Trigger | Points | Adds | Reason | Status |
|---|---|---|---|---|
| Open one-way door | 3 | decision card, ADR (prototype if visual), stays with the person | a one-way door costs the most to undo, in any project | provisional |
| Unresolved research question | 3 | research before slicing, map | an unknown fact makes the size of a slice a guess | provisional |
| More than 3 expected slices, or dependencies between them | 2 | map, frontier round | slices that depend on each other need an order before the first one starts | provisional |
| Protected area touched | 3 | security review, test depth at least targeted, the person's merge approval | the scan found: contracts/ (53 files), contracts/obeya/ (8 files) | provisional |
| Contract or interface used by others | 2 | architect, contract file | the scan found: contracts/ (53 files), contracts/obeya/ (8 files) | provisional |
| New logic or data behaviour in a code project | 2 | tests-first (targeted) | this repository also holds code apps with their own tests (`apps/obeya/`, `apps/site/`): the row fires for a slice that touches `apps/`; elsewhere in the repository it does not | provisional |
| Visual result | 1 | demo | the scan found: apps/obeya/app/app.vue, apps/obeya/app/components/ (9 files), apps/obeya/app/pages/index.vue, apps/obeya/app/themes/base/index.vue, apps/obeya/app/themes/orbit/index.vue, apps/obeya/app/themes/transit/Station.vue | provisional |
| Deploy, pipeline or production config (project row) | 3 | devops role, environment stage | the scan found: .github/workflows/obeya-image.yml, .github/workflows/site.yml, apps/obeya/Dockerfile, plugins/toolkit/skills/source-to-pptx/assets/docker/Dockerfile | provisional |

## CI

ci: none (no workflow runs `bash tests/run.sh`)

Whether a workflow runs the project's test command on pull requests. With `ci: none` the merge gate accepts, in place of a check, a recorded local run of the full test command on the pull request's head commit (a `## Local run` section in its description: the commit sha, the command, the last line of its output and the time). The gate prints which checks it read, and `ci: none (local run on <sha>)` when it relied on that record.
