# Factory reference (release 1.0.0)

One entry per contract that governs the factory, with the file that implements it and the acceptance criteria it answers. The contracts are the source; this page only points at them. Requirements and decisions: [docs/requirements/39-hansei-record.md](../requirements/39-hansei-record.md), [ADR 0011](../adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [ADR 0012](../adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md).

## Contracts

### 39-hansei-record: the hansei record (schema v2)

- **Contract**: [contracts/39-hansei-record.md](../../contracts/39-hansei-record.md)
- **Governs**: the record posted on the slice ticket at merge approval, edited once after the resurvey. First line `<!-- factory:hansei v2 -->`; the reader's rule for the marker, and the rule that a reader skips a version it does not know; the fixed key-value layout; the value grammar (a measured value, `0`, `n/a (did not run)`, `not captured (<reason>)`, `pending resurvey`); the seven measures and their sources. Measure 1 is split into five parts that add up to the total (agent working, person, limits, stalled, interrupted). Measure 2 has `pass first time (<n> low)`, where the findings below minor are `low`, `info`, `trivial` or `note`. Measure 5 reads `not captured (transcript truncated by <kind>)` for a cut transcript. The tracker operations *Find hansei*, *Post hansei* and *Edit hansei*; the order of the close.
- **Implemented in**: `plugins/factory/references/hansei.md` (template, field rules, measure rules); `plugins/factory/skills/run/SKILL.md` step 8 (close order) and *Interruptions*; `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` (the three tracker operations, copied into a project's `docs/agents/issue-tracker.md` by setup step 6).
- **Acceptance criteria**: AC-14 to AC-22 (contract section 8).

### 39-stage-log: the stage log in the lead state

- **Contract**: [contracts/39-stage-log.md](../../contracts/39-stage-log.md)
- **Governs**: four sections the lead adds to `work/<id>/00-lead-state.md`, in order: `## Label` (written once at item start: plugin root, release, standard and tooling fingerprints, dependency versions, lead session ids), `## Stage log` (one row per stage, UTC times from `date -u`), `## Waits` (each wait with its kind, the agent it stopped, and whether it held the item), `## Person's touches`. The four wait kinds are `person`, `limits`, `stalled` and `interrupted`, with how each is detected and where its start and end come from. *Done, then stopped*: an agent that stops after a complete `done` result is accepted, not resumed, when its commits are on the item branch and its paths are clean. The cross-check against git commit times and stage-summary comment times.
- **Implemented in**: `plugins/factory/references/hansei.md` sections 1, 2 and 4; `plugins/factory/skills/run/SKILL.md` steps 5 and 6 and *Interruptions*.
- **Acceptance criteria**: AC-6, AC-11, AC-12, AC-13.

### 39-plugin-scripts: the three scripts

- **Contract**: [contracts/39-plugin-scripts.md](../../contracts/39-plugin-scripts.md)
- **Governs**: the exact stdout lines and exit codes of each script; the two fingerprints and their file sets (standard: `skills/run/SKILL.md`, `references/*.md`, `agents/*.md`; tooling: `hooks/` and `scripts/`, recursively); the bump check's levels and refusal text (a file name with a newline counts as standard work); the token-spend window, the peak rule, and `--require-end` (exit 6 for a transcript that was cut off: a `[Request interrupted` entry, or no final reply at its end).
- **Implemented in**: `plugins/factory/scripts/fingerprint.sh`, `plugins/factory/scripts/check-bump.sh`, `plugins/factory/scripts/token-spend.sh`. All are bash 3.2 compatible; `token-spend.sh` also needs `jq`.
- **Acceptance criteria**: AC-2 to AC-5, AC-8 to AC-10, AC-16.

### 39-standard-changes: where each rule lives

- **Contract**: [contracts/39-standard-changes.md](../../contracts/39-standard-changes.md)
- **Governs**: which file under `plugins/factory/` carries which rule (the table at the top of the contract); the release in `plugin.json`; the bump check in *Open PR*, in the frontier round's PR and in *Merge PR*; the release tag in *Merge PR*; the fallback for projects set up before 1.0.0; the rule that no measurement is written to this repo.
- **Implemented in**: `plugins/factory/.claude-plugin/plugin.json`, `plugins/factory/references/hansei.md`, `plugins/factory/skills/run/SKILL.md`, the tracker patch in `plugins/factory/skills/setup-factory-skill/references/`.
- **Acceptance criteria**: AC-1, AC-7, AC-8, AC-10, AC-20, AC-21.

## Maintainer procedure: changing the factory

Use this when a change touches anything under `plugins/factory/`.

1. Make the change on a branch of its own; for a factory item that is `item/<id>`. Each commit starts with `#<id>`.
2. Bump `version` in `plugins/factory/.claude-plugin/plugin.json` at the level the rule asks: minor for standard work (`skills/run/SKILL.md`, `references/*.md`, `agents/*.md`), patch for anything else under `plugins/factory/`, major only when message formats or the protocol break.
3. From the branch's worktree: `git fetch origin main`, then `bash plugins/factory/scripts/check-bump.sh`. Exit 0 is a pass; exit 1 names the level it needs; exit 2 is a repository or version error to fix first.
4. Run the suite: `bash tests/run.sh`. It prints `ALL PASSED` when every check holds.
5. Run `claude plugin validate ./plugins/factory` and `claude plugin validate ./plugins/factory/skills`.
6. Open the PR. The lead runs the same bump check before `gh pr create`, so a PR that fails it does not open.
7. After the person's merge approval, the lead runs the check again, merges, and tags `factory-v<version>` on the merge commit, unless that tag exists. To tag by hand: `git tag factory-v<version> <merge-commit>` and `git push origin factory-v<version>`. The release steps and the checks after the tag are in [release-runbook.md](release-runbook.md).
8. Add an entry for the item to [CHANGELOG.md](../../CHANGELOG.md).
9. After a release, restart any Claude Code session that runs the factory: a session keeps the skill text it read when it started.

Running the factory itself is in [plugins/factory/skills/run/SKILL.md](../../plugins/factory/skills/run/SKILL.md). Setting up a project is `/factory:setup-factory-skill`, and the project's tracker commands are in its `docs/agents/issue-tracker.md` under `## Factory operations`.
