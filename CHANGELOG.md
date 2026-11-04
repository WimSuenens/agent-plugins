# Changelog

One entry per item, newest first. Entries are grouped by plugin. The factory is the only plugin with a version so far: its releases are tagged `factory-v<semver>`, and each tag points at the release commit on `main` (ADR 0012). Other plugins install from their current commit and have no entries here yet.

## factory 1.0.0 (#39)

Release: `1.0.0`, the first semver for the factory. Tag: `factory-v1.0.0`, created by the Lead on the merge commit at merge (the release date is the merge date). The version lives in `plugins/factory/.claude-plugin/plugin.json` only; the factory's entry in `.claude-plugin/marketplace.json` has none.

Slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39), map [#34](https://github.com/WimSuenens/agent-plugins/issues/34). Decisions: [ADR 0011](docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md) (local countermeasures, the wide fence) and [ADR 0012](docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) (releases, fingerprint, calibration).

### Added

- **Hansei record.** At the person's merge approval the Lead posts one comment on the slice ticket, in the project's own tracker. Its first line is the marker `<!-- factory:hansei v1 -->`. It carries the release, the two fingerprints, the dependency versions as context, the "Active overrides" field (`none` for now), a stage-log cross-check, and seven measures in a fixed order: lead time, first-pass yield, rework, escaped defects, tokens per role, the person's touches, and doors confirmed or contradicted. Measure 7 reads `pending resurvey` at posting and is filled by editing the same comment after the resurvey. Schema: [contracts/39-hansei-record.md](contracts/39-hansei-record.md).
- **Honesty rule.** A value that could not be captured reads `not captured (<reason>)`. It is never `0`, never blank, and never dropped. `n/a (did not run)` is allowed only for a stage or role that did not run, in measures 2 and 5.
- **Stage log.** The Lead keeps four sections in `work/<id>/00-lead-state.md` while an item runs: `## Label` (written once at item start), `## Stage log` (one row per stage, with UTC times from `date -u`), `## Waits` (waits on the person and on usage limits), and `## Person's touches`. Schema: [contracts/39-stage-log.md](contracts/39-stage-log.md).
- **Stage-log cross-check.** Before posting, the Lead compares each row with the role's commit times on the item branch and with the stage-summary comment times. The largest gap goes into the record.
- **Two fingerprints.** `standard` (sha256 over `skills/run/SKILL.md`, `references/*.md`, `agents/*.md`) and `tooling` (sha256 over `hooks/` and `scripts/`). A change to one of them under the same release means a bump was forgotten. Standard work is the set in ADR 0012 with `references/hansei.md` added. Schema: [contracts/39-plugin-scripts.md](contracts/39-plugin-scripts.md).
- **Three scripts** under `plugins/factory/scripts/`, all bash 3.2 compatible:
  - `fingerprint.sh <plugin root>`: prints the release and both fingerprints.
  - `check-bump.sh [<base-ref>]`: the bump check, run from the branch's worktree (default base `origin/main`). It exits 0 when the bump covers the change, 1 when it does not, and 2 on a usage or repository error.
  - `token-spend.sh [--since T] [--until T] [--] <transcript.jsonl>...`: sums token spend and reports the peak context from transcripts. It needs `jq`.
- **Tracker operations** in the GitHub tracker patch: *Find hansei*, *Post hansei* and *Edit hansei*. They act only in the project's own tracker and never name `--repo`.
- **Release tag** in *Merge PR*: after a merge that changed the version, the Lead tags `factory-v<version>` on the merge commit, when the version is a strict semver and the tag does not exist yet.

### Changed

- **Bump rule.** Every change under `plugins/factory/` needs a version bump in `plugin.json`, checked before a PR opens, before a frontier-round PR opens, and again before a merge:
  - **Minor** or more for standard work (`skills/run/SKILL.md`, `references/*.md`, `agents/*.md`).
  - **Patch** or more for every other path under `plugins/factory/`, including `hooks/`, `scripts/`, `skills/setup-factory-skill/` and the plugin's own `plugin.json`.
  - **Major** when message formats or the protocol break. The check never requires a major; the architect calls it and the developer bumps it when told.
  - The baseline resets on a major or minor release only. A tooling-only patch does not reset it.
- **The Lead's refusal.** When the check fails with exit 1, the Lead does not open or merge the PR. It sends the developer a feedback brief quoting the refusal and logs a `refused` row. Exit 2 goes to the person. Changes outside `plugins/factory/` pass without a bump.
- **Setup skill step 6 writes the new tracker section** into a project's `docs/agents/issue-tracker.md`, replacing the `## Factory operations` section.
- **Installs follow versions, not pushes.** The factory now carries a `version`, so an install of it changes only when that string changes (the README's note on `version` describes the cache behaviour; ADR 0012 gives the reason). Pushes that do not bump the version do not reach other projects.

### Upgrading a project set up before 1.0.0

A project whose `## Factory operations` section has no *Post hansei* bullet predates 1.0.0. The Lead then uses the plugin's copy of the section for the item, and tells the person once. To bring the project up to date, replace that section with the one in `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md`, which is what `/factory:setup-factory-skill` step 6 does. The Lead never edits the project's tracker doc itself.

### Known limitations at release

From the verdicts on #39 (QA [reviews/qa-39.md](reviews/qa-39.md), security [reviews/security-39.md](reviews/security-39.md)):

- **Acceptance demo not yet run.** Six criteria are human-only (AC-9, AC-12, AC-17, AC-18, AC-19, AC-21). They need a real session with `claude --plugin-dir` against a scratch project. Until they pass, the release is ready for deploy but not accepted.
- **Escaped defects** (measure 4) read `not captured` in schema v1. Tracing them back to an item is deferred.
- **Round 3 fixes were not re-verified** by QA or security. They cover QA's F4 to F6 and security's L1a: token-spend's exit-3 message, the Merge PR tag regex, the scratch file for *Post hansei*, and newline file names in `check-bump.sh`. The test suite passes with them.
- **Calibration, not baseline.** Items run on the frozen install `9147301f75c3` are recorded as `calibration (pre-baseline)`. Their numbers show what capture costs and are never used as a before. The baseline opens with the first item run on 1.0.0.
- **Fingerprints move with any edit** to the files they cover. A record made before a change keeps the old values, so compare fingerprints only between records that carry them.
