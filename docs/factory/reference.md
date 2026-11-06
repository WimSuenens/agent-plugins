# Factory reference (release 1.1.0)

One entry per contract that governs the factory, with the file that implements it and the acceptance criteria it answers. The contracts are the source; this page only points at them. Where a 1.1.0 contract changes what a 1.0.0 contract says, the 1.0.0 entry says so and points at the newer one.

Requirements and decisions: [docs/requirements/39-hansei-record.md](../requirements/39-hansei-record.md), [docs/requirements/49-andon.md](../requirements/49-andon.md), [ADR 0011](../adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [ADR 0012](../adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [ADR 0013](../adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md).

## Contracts

Nine contracts: four from 1.0.0 (`39-*`, the record, the stage log, the scripts and the release rules) and five from 1.1.0 (`49-*`, the andon and local countermeasures). The `49-*` contracts change some `39-*` text; each `39-*` entry below names what changed.

### 39-hansei-record: the hansei record (schema v2, now v3)

- **Contract**: [contracts/39-hansei-record.md](../../contracts/39-hansei-record.md). Changed for 1.1.0 by [49-records](#49-records-the-stage-log-with-the-andon-and-hansei-schema-v3) §5.
- **Governs**: the record posted on the slice ticket at merge approval, edited once after the resurvey. At 1.0.0 the first line was `<!-- factory:hansei v2 -->`. From 1.1.0 it is `<!-- factory:hansei v3 -->`: measure 1 gains an `andon` part, and a header line `abnormalities` follows `active overrides`. A reader skips a version it does not know. The value grammar (a measured value, `0`, `n/a (did not run)`, `not captured (<reason>)`, `pending resurvey`) is unchanged. Measure 1 is split into parts that add up to the total (agent working, person, limits, stalled, interrupted; from 1.1.0 also andon). Measure 2 has `pass first time (<n> low)`, where the findings below minor are `low`, `info`, `trivial` or `note`. Measure 5 reads `not captured (transcript truncated by <kind>)` for a cut transcript. The tracker operations *Find hansei*, *Post hansei* and *Edit hansei*; the order of the close.
- **Implemented in**: `plugins/factory/references/hansei.md` (template, field rules, measure rules, schema v3 layout); `plugins/factory/skills/run/SKILL.md` step 8 (close order) and *Interruptions*; `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` (the three tracker operations, copied into a project's `docs/agents/issue-tracker.md` by setup step 6).
- **Acceptance criteria**: AC-14 to AC-22 (contract section 8). From 1.1.0, AC-24 and AC-25 (in [49-records](../../contracts/49-records.md) §5 and §7).

### 39-stage-log: the stage log in the lead state

- **Contract**: [contracts/39-stage-log.md](../../contracts/39-stage-log.md). Changed for 1.1.0 by [49-records](../../contracts/49-records.md) §1 to §4.
- **Governs**: the sections the lead adds to `work/<id>/00-lead-state.md`, in order. At 1.0.0: `## Label` (written once at item start: plugin root, release, standard and tooling fingerprints, dependency versions, lead session ids), `## Stage log` (one row per stage, UTC times from `date -u`), `## Waits` (each wait with its kind, the agent it stopped, and whether it held the item), `## Person's touches`. From 1.1.0 two more follow: `## Findings` (the ledger the kind 2 rule reads) and `## Abnormalities` (one row per abnormality, with its paused agent and its andon comment). A stage row can be an `Andon A<n>` row. The wait kinds were four at 1.0.0 (`person`, `limits`, `stalled`, `interrupted`); from 1.1.0 there are five, with `andon` for the time the Lead holds the affected work for an andon. *Done, then stopped*: an agent that stops after a complete `done` result is accepted, not resumed, when its commits are on the item branch and its paths are clean. The cross-check against git commit times and stage-summary comment times.
- **Implemented in**: `plugins/factory/references/hansei.md` sections 1, 2 and 4 (the Waits and Abnormalities tables, the close scan); `plugins/factory/skills/run/SKILL.md` steps 5 and 6, *Interruptions* and *Andon*.
- **Acceptance criteria**: AC-6, AC-11, AC-12, AC-13 (1.0.0). From 1.1.0, AC-8 (the andon wait) and AC-23.

### 39-plugin-scripts: the four scripts

- **Contract**: [contracts/39-plugin-scripts.md](../../contracts/39-plugin-scripts.md). Unchanged for 1.1.0: no script changed ([49-standard-changes](../../contracts/49-standard-changes.md) §1).
- **Governs**: the exact stdout lines and exit codes of each script; the two fingerprints and their file sets (standard: `skills/run/SKILL.md`, `references/*.md`, `agents/*.md`; tooling: `hooks/` and `scripts/`, recursively); the bump check's levels and refusal text (a file name with a newline counts as standard work); the token-spend window, the peak rule, and `--require-end` (exit 6 for a transcript that was cut off: a `[Request interrupted` entry, or no final reply at its end); the cut-offs of a transcript (§4: one line per gap of kind `limits`, `stalled` or `interrupted`, with its start, read from the transcript and the optional sleep log).
- **Implemented in**: `plugins/factory/scripts/fingerprint.sh`, `plugins/factory/scripts/check-bump.sh`, `plugins/factory/scripts/token-spend.sh`, `plugins/factory/scripts/cut-offs.sh`. All are bash 3.2 compatible; `token-spend.sh` and `cut-offs.sh` also need `jq`.
- **Acceptance criteria**: AC-2 to AC-5, AC-8 to AC-10, AC-16; `cut-offs.sh` is the evidence for AC-11 (its tests) and AC-17 (the replay of the demo's transcripts).

### 39-standard-changes: where each rule lives

- **Contract**: [contracts/39-standard-changes.md](../../contracts/39-standard-changes.md). The 1.1.0 placement of the andon and override rules is in [49-standard-changes](#49-standard-changes-where-the-andon-lives-the-release-and-the-criteria-map) §0 and §1.
- **Governs**: which file under `plugins/factory/` carries which rule (the table at the top of the contract); the release in `plugin.json`; the bump check in *Open PR*, in the frontier round's PR and in *Merge PR*; the release tag in *Merge PR*; the fallback for projects set up before 1.0.0; the rule that no measurement is written to this repo; the merge style (`--merge`, kept, with its reason) and the path rule for message files (§9, [ADR 0013](../adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md)): worktree-relative or `~/` paths in `work/`, and the security checklist line that goes with it.
- **Implemented in**: `plugins/factory/.claude-plugin/plugin.json`, `plugins/factory/references/hansei.md`, `plugins/factory/references/protocol.md` (*Messages*), `plugins/factory/skills/run/SKILL.md`, `plugins/factory/agents/security-reviewer.md` (step 1), the tracker patch in `plugins/factory/skills/setup-factory-skill/references/`.
- **Acceptance criteria**: AC-1, AC-7, AC-8, AC-10, AC-20, AC-21; the path rule and the merge style answer ADR 0013 (no AC number).

### 49-abnormality-list: the list, the `Abnormality:` line and the detection rules

- **Contract**: [contracts/49-abnormality-list.md](../../contracts/49-abnormality-list.md)
- **Governs**: the seven kinds, each with the observation that proves it: 1 `blocked-input`, 2 `same-finding-twice`, 3 `role-outside-role`, 4 `slow-stage`, 5 `fence-crossing`, 6 `version-drift`, 7 `other`. The `Abnormality:` line in a result (`<kind> — <what was seen> — <where to look>`, optional, read as `none` when absent). A result with a line other than `none` is not `done` for the lead until its andon has run. The detection rules: kind 2 (the ledger of findings, the five-slot signature, the two clauses M1 and M2); kind 3 (the ownership table read from `origin/main`, longest match, `section` rows skipped, `git diff-tree -z`, and the rule that commits touching `## Overrides` or the table must come from the lead); kind 4 (the 2× test against the median of the same role's earlier rows, with at least three earlier rows, waits excluded); kind 6 (fingerprint drift against the latest earlier record of the same release, and the installed sha against the FREEZE line).
- **Implemented in**: `plugins/factory/references/protocol.md` `## Andon` (the list and the line); `plugins/factory/skills/run/SKILL.md` `## Andon`, *Detection*.
- **Acceptance criteria**: AC-1 to AC-7. AC-7 is human-only (a seeded abnormality in the sandbox session).

### 49-andon-process: raise, pause, 5 Whys, resume and the andon comment

- **Contract**: [contracts/49-andon-process.md](../../contracts/49-andon-process.md)
- **Governs**: how a role raises an andon and how the lead handles it: stamp the pause, stop the running agent with `TaskStop` (skipped for an agent that already handed back), run the 5 Whys, decide the countermeasure inside the fence, resume the same agent with `SendMessage`. A refused resume (the person stopped the agent) gets no second attempt: the lead spawns a fresh agent from the role's result file, and the item goes on. The 5 Whys rule, *blame the process first*: each cause names a process object (the brief, the inputs, the standard's text, the tooling, the ownership table, the order of stages), with evidence; a chain that names a person, a role's care or competence, or a model is refused; a model or role swap is allowed only after four `examined … adequate` lines. The andon comment (`<!-- factory:andon v1 -->`), posted once on the slice ticket in the project's own tracker, never in this repo; its text is the lead's paraphrase, with no copied content.
- **Implemented in**: `plugins/factory/references/protocol.md` `## Andon` (the rules every role reads); `plugins/factory/skills/run/SKILL.md` `## Andon`, *Procedure*, *The 5 Whys*, *The comment*.
- **Acceptance criteria**: AC-6 and AC-8 to AC-14, AC-22. AC-9, AC-10, AC-11 and AC-14 are human-only.

### 49-overrides: the override format, the fence, precedence, run identity and expiry

- **Contract**: [contracts/49-overrides.md](../../contracts/49-overrides.md)
- **Governs**: where an override lives (`docs/agents/factory.md`, under `## Overrides`, which the lead owns and writes in the worktree that raised the andon) and its fields: name, `started`, `run`, `rule`, `andon`, `status`, `fence check`. The status grammar (`active`, `kept … for next run` or `for #<map>`, `promote chosen <date>`, `superseded <date> by <name>`). Precedence: an override wins over the plugin's text outside the fence; of two disagreeing overrides the later `started` wins; the fence always wins. The fence: the seven items of ADR 0011 (`## Never overridable locally`, F1 to F7), plus the data-egress question E, which is a question asked of every override and not an eighth fenced item. One yes to any of the eight refuses the override. The run start check (an override that crosses the fence is not applied and starts a kind 5 andon; an earlier run's override with no answer starts a kind 7 andon and waits for the person). The close of the run (step 10): one line per override, and keep, promote or drop, recorded in a settle worktree and merged by the person's yes.
- **Implemented in**: `plugins/factory/references/protocol.md` `## Overrides` and `## Never overridable locally`; `plugins/factory/skills/run/SKILL.md` `## Andon` (*Overrides*, *Run identity*, *Run start*, *Settle round*) and step 10.
- **Acceptance criteria**: AC-15 to AC-21, AC-26 and AC-27. AC-20 and AC-25 and AC-28 are human-only.

### 49-records: the stage log with the andon, and hansei schema v3

- **Contract**: [contracts/49-records.md](../../contracts/49-records.md). Changes [39-stage-log](#39-stage-log-the-stage-log-in-the-lead-state) and [39-hansei-record](#39-hansei-record-the-hansei-record-schema-v2-now-v3).
- **Governs**: the two new lead-state sections `## Findings` and `## Abnormalities`; the stage-log row `Andon A<n>`; the fifth wait kind `andon` and its close scan (an andon wait takes the stop's `request-interrupted` line and the silent gap, and a `TaskStop` marks the transcript truncated: `not captured (transcript truncated by andon)`); the hansei record at schema v3, with measure 1 split into six parts that add up to the total, the `active overrides` field, and the `abnormalities` field (the count per kind and a link to each andon comment, or `raised, no andon recorded`). The record carries no 5 Whys text and no transcript content.
- **Implemented in**: `plugins/factory/references/hansei.md`: `## Findings` and `## Abnormalities`, the wait kinds (*Five kinds*), the record template (`<!-- factory:hansei v3 -->`), the value grammar and the worked example.
- **Acceptance criteria**: AC-8 (the wait), AC-23, AC-24, AC-25 (the read of a real comment is human-only).

### 49-standard-changes: where the andon lives, the release and the criteria map

- **Contract**: [contracts/49-standard-changes.md](../../contracts/49-standard-changes.md)
- **Governs**: which file carries which 1.1.0 rule (the table in §0); the release: `plugin.json` at `1.1.0`, a minor bump for standard work, with the reasons; the release tag, which at 1.1.0 is made by hand because the item runs on the frozen install (§1); the sections `## Andon`, `## Overrides` and `## Never overridable locally` in `references/protocol.md`; the run-start, item-start and close checks in `skills/run/SKILL.md`; the ownership row for `docs/agents/factory.md` section `## Overrides` (§5), written exactly as in the contract, because the kind 3 check reads the word `section`; the demo and the sandbox rules (§6); the map of every criterion to its contract (§7); the twelve two-way decisions (§8).
- **Implemented in**: `plugins/factory/.claude-plugin/plugin.json`, `plugins/factory/references/protocol.md`, `plugins/factory/skills/run/SKILL.md`, `plugins/factory/references/hansei.md`, `plugins/factory/skills/setup-factory-skill/` (the ownership row in its asset `assets/factory.md`).
- **Acceptance criteria**: AC-29 (the release) and AC-30 (the tag after the merge). The criteria map in §7 lists the rest.

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

A project's overrides are not plugin changes. The lead writes them in that project's `docs/agents/factory.md` (contract [49-overrides](../../contracts/49-overrides.md) §1), and the plugin's text is never edited to apply one. A countermeasure that needs a plugin change is recorded in the andon comment and in the step-9 feedback issue, and goes through this procedure.
