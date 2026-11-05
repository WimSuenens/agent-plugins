# Changelog

One entry per item, newest first. Entries are grouped by plugin. The factory is the only plugin with a version so far: its releases are tagged `factory-v<semver>`, and each tag points at the release commit on `main` (ADR 0012). Other plugins install from their current commit and have no entries here yet.

## factory 1.0.0 (#39)

Release: `1.0.0`, the first semver for the factory. Tag: `factory-v1.0.0`, created by the Lead on the merge commit at merge (the release date is the merge date). The version lives in `plugins/factory/.claude-plugin/plugin.json` only; the factory's entry in `.claude-plugin/marketplace.json` has none.

Slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39), map [#34](https://github.com/WimSuenens/agent-plugins/issues/34). Decisions: [ADR 0011](docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md) (local countermeasures, the wide fence), [ADR 0012](docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) (releases, fingerprint, calibration) and [ADR 0013](docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) (merge style and the path rule). The hansei record is at schema v2. Contracts: [39-hansei-record](contracts/39-hansei-record.md), [39-stage-log](contracts/39-stage-log.md), [39-plugin-scripts](contracts/39-plugin-scripts.md) and [39-standard-changes](contracts/39-standard-changes.md).

**Restart your Claude Code sessions after updating.** A session keeps the factory skill text it read when it started, even when the plugin is loaded with `--plugin-dir`. A session that started before the update kept the pre-1.0.0 run skill until it was restarted. After an install, an update or a change to `plugins/factory/`, start a new session before running an item.

### Added

- **Hansei record, schema v2.** At the person's merge approval the Lead posts one comment on the slice ticket, in the project's own tracker. Its first line is the marker `<!-- factory:hansei v2 -->`. It carries the release, the two fingerprints, the dependency versions as context, the active overrides (`none` for now), a stage-log cross-check, and seven measures in a fixed order:
  1. **lead time**, split into five parts that add up to the total: agent working, waiting for the person, waiting on limits, stalled, and interrupted;
  2. **first-pass yield** per stage (QA, security, acceptance demo); a first pass with findings below minor reads `pass first time (<n> low)`;
  3. **rework**: the feedback briefs each role received, and the two-way decisions overturned;
  4. **escaped defects**: `not captured` in this release;
  5. **tokens** per role, the Lead first;
  6. **the person's touches**;
  7. **doors**: confirmed or contradicted per Under test line, filled by editing the same comment after the resurvey.

  Schema: [contracts/39-hansei-record.md](contracts/39-hansei-record.md). A schema v1 record (the acceptance demo's, from a pre-release build) is not comparable with a v2 record: their measures 1 and 2 mean different things.
- **Four wait kinds.** The stage log's `## Waits` table records every stretch in which an agent or the Lead sat still for a reason other than its own work, as one of four kinds: `person` (the item waits on the person's answer), `limits` (a usage or session limit), `stalled` (no progress while the session stayed up, such as the stream watchdog's `no progress for 600s`), and `interrupted` (the connection or the machine went away, including a machine sleep and an API server error). Each wait names the agent it stopped in an `Agent` column. Overlapping held waits count once, to the first kind in measure 1's order. Schema: [contracts/39-stage-log.md](contracts/39-stage-log.md) §3.
- **Truncated transcripts read `not captured`.** A role's transcript cut by a stall or an interruption lost the request in flight, so its spend is short by an unknown amount. Its spend then reads `not captured (transcript truncated by <kind>)`, never a number. The Lead finds the cut from the logged wait, or from `token-spend.sh --require-end` when no wait was logged.
- **`token-spend.sh --require-end`** (exit 6). With this option the script checks that each transcript ends on a final reply: no `[Request interrupted` entry, and no unanswered tool call at the end. A cut transcript exits 6 and names its file by basename on stderr. The Lead passes it for every role transcript at close, never for its own session. Schema: [contracts/39-plugin-scripts.md](contracts/39-plugin-scripts.md) §3.
- **Done, then stopped.** An agent that stalls or fails after writing a complete `Status: done` result is not resumed, when its commits are on the item branch and its paths are clean. The Lead checks the Done list, accepts the result and logs the wait with its kind. Otherwise the agent is resumed as an ordinary interruption. Schema: [contracts/39-stage-log.md](contracts/39-stage-log.md) §3.
- **Close in two commits.** The Lead commits the lead state (`#<id> lead: close`), then removes `work/<id>/` with `git rm -r` and commits again (`#<id> lead: remove work/`), so the removal never needs `-f`. The record is posted before both commits. Schema: [contracts/39-hansei-record.md](contracts/39-hansei-record.md) §6.
- **Hansei record, honesty rule.** A value that could not be captured reads `not captured (<reason>)`. It is never `0`, never blank, and never dropped. `n/a (did not run)` is allowed only for a stage or role that did not run, in measures 2 and 5.
- **Stage log.** The Lead keeps four sections in `work/<id>/00-lead-state.md` while an item runs: `## Label` (written once at item start), `## Stage log` (one row per stage, UTC times from `date -u`), `## Waits`, and `## Person's touches`. Schema: [contracts/39-stage-log.md](contracts/39-stage-log.md).
- **Stage-log cross-check.** Before posting, the Lead compares each row with the role's commit times on the item branch and with the stage-summary comment times. The largest gap goes into the record.
- **Two fingerprints.** `standard` (sha256 over `skills/run/SKILL.md`, `references/*.md`, `agents/*.md`) and `tooling` (sha256 over `hooks/` and `scripts/`). A change to one of them under the same release means a bump was forgotten. Schema: [contracts/39-plugin-scripts.md](contracts/39-plugin-scripts.md) §1.
- **Four scripts** under `plugins/factory/scripts/`, all bash 3.2 compatible:
  - `fingerprint.sh <plugin root>`: prints the release and both fingerprints. It exits 2 when a file cannot be read, when the version is empty or not a semver, and when the root is not a factory root.
  - `check-bump.sh [<base-ref>]`: the bump check, run from the branch's worktree (default base `origin/main`). It exits 0 when the bump covers the change, 1 when it does not, and 2 when the repository, the base ref or the base version cannot be used. A changed file whose name contains a newline counts as standard work.
  - `token-spend.sh [--since T] [--until T] [--require-end] [--] <transcript.jsonl>...`: sums token spend and reports the peak context from transcripts. It needs `jq`.
  - `cut-offs.sh [--since T] [--until T] [--sleep-log <file> | --sleep-log -] [--] <transcript.jsonl>...`: prints one line per gap in which an agent or the Lead made no progress, with its kind (`limits`, `stalled` or `interrupted`) and its start and end. The Lead takes a wait's start from this output, not from the file's last entry. The `--sleep-log` input is the output of the `pmset` filter in `references/hansei.md`. It needs `jq`.
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
- **Merge style and the path rule (ADR 0013).** The merge style is decided: `*Merge PR*` keeps `gh pr merge <branch> --merge`, with its reason (`--merge`, never squash or rebase: the role commits are the evidence the hansei record is re-checked against). Every item's role commits, `work/<id>/` included, stay in main's history, and that is expected. `protocol.md` (*Messages*) now says how paths in a message file are written: relative to the worktree (`plugins/factory/agents/developer.md`), relative to the repo's parent for another worktree (`../wt/<id>`), or with the home directory as `~` (`~/.claude/plugins/cache/...`). An absolute path under the home directory is not written, because `work/` is merged with every commit. The security checklist (*Steps*, step 1) reads an absolute home path in a `work/` commit as a low finding, and `work/` in history as expected. The rule covers `work/<id>/` and `work/frontier-<id>/`; see *Known limitations*.
- **Installs follow versions, not pushes.** The factory now carries a `version`, so an install of it changes only when that string changes (the README's note on `version` describes the cache behaviour; ADR 0012 gives the reason). Pushes that do not bump the version do not reach other projects.

### Upgrading a project set up before 1.0.0

A project whose `## Factory operations` section has no *Post hansei* bullet predates 1.0.0. The Lead then uses the plugin's copy of the section for the item, and tells the person once. To bring the project up to date, replace that section with the one in `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md`, which is what `/factory:setup-factory-skill` step 6 does. The Lead never edits the project's tracker doc itself.

### Acceptance demo

The acceptance demo ran in a scratch project, with the item's plugin loaded by `claude --plugin-dir`. Every human-only criterion passed except AC-17, which failed: measure 1 counted stalls and machine sleep as agent work, and a stalled transcript's truncated spend was shown as measured. AC-17 was fixed in schema v2 (feedback issues #44 to #47). QA checked the fix by replaying the demo's own transcripts through the scripts, and accepted AC-17 on that replay, without a demo re-run. The close step's live-session check is listed under *Known limitations*.

### Known limitations at release

From the verdicts on #39 (QA [reviews/qa-39.md](reviews/qa-39.md), security [reviews/security-39.md](reviews/security-39.md)) and from the acceptance demo:

- **Escaped defects** (measure 4) read `not captured` in schema v2. Tracing them back to an item is deferred.
- **Calibration, not baseline.** Items run on the frozen install `9147301f75c3` are recorded as `calibration (pre-baseline)`. Their numbers show what capture costs and are never used as a before. The baseline opens with the first item run on 1.0.0.
- **Fingerprints move with any edit** to the files they cover. A record made before a change keeps the old values, so compare fingerprints only between records that carry them.
- **Path rule covers message files only.** The rule in `protocol.md` applies to `work/<id>/` and `work/frontier-<id>/`. Other committed files (`reviews/`, `contracts/`, `docs/`) are not covered, and the security checklist only scans `work/` (its `git log -S` runs on `work/`). #39's own QA review carried one home path in `reviews/`, which QA removed before the merge (security L13). Widening the rule to every committed file is deferred to a later item.
- **Merge style is decided, and its cost stays.** `--merge` keeps every role commit, with the `work/<id>/` files, in the history of `main` (ADR 0013). Item #39's own history holds one absolute home path, in its QA brief, and one quotation of it in the architect's options; both are accepted and not rewritten. Changing the style later is a one-line template change from the next item, but it does not rewrite main.
- **Worktree location.** Two projects that share one parent folder can collide in `../wt/`. The location is left as it is for now.
- **Setup labels.** The acceptance demo found that the setup did not create every label the stages use: after setup only `wayfinder:slice` existed, and the others were created by hand.
- **Unreadable transcripts.** When a role's transcript cannot be read, its spend reads `not captured`, and a stall or interruption whose start is not in the transcript is marked `~` in the stage log.
- **Close step 6.1 is not chained (security I6, informational, deferred).** The close's guard and step 6.2 run as one shell call that stops at the first failure. Step 6.1 (the commits and the `git add`s) is given as prose commands with no `|| exit 1` after each. A failed `git add` could let the chain go on, and a message file never committed would then be removed by `git clean`. Nothing outside the item's worktree is touched. Widening the chain is deferred ([reviews/security-39.md](reviews/security-39.md)).
- **The close's live-session check is open (AC-18).** The close was checked from its text and from scratch runs of its verbatim commands. The acceptance demo ran on an earlier close text (the close was rewritten in QA's round 5). Whether a live session runs it without a permission prompt, and commits only the `NN-*.md` message files under `work/<id>/`, is still for the person to check.
