# Contract 39 — Where each change lives in the factory plugin

Slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39) · Requirement [39-hansei-record](../docs/requirements/39-hansei-record.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md)

The placement contract for the developer: which file under `plugins/factory/` carries which rule. Wording is the developer's; what each file must say is fixed here. Formats are in [39-hansei-record](39-hansei-record.md), [39-stage-log](39-stage-log.md) and [39-plugin-scripts](39-plugin-scripts.md).

| File | Kind | Change |
|---|---|---|
| `.claude-plugin/plugin.json` | other | `"version": "1.0.0"` (§1) |
| `references/hansei.md` | standard work (new) | record template, field definitions, stage-log format (§2) |
| `skills/run/SKILL.md` | standard work | plugin root, label at item start, stage log through the stages, *Open PR* check, step 8 order, step 9 rule, fallback for older tracker docs (§3, §4, §6) |
| `scripts/fingerprint.sh`, `scripts/check-bump.sh`, `scripts/token-spend.sh` | tooling (new) | [39-plugin-scripts](39-plugin-scripts.md) |
| `skills/setup-factory-skill/references/issue-tracker-github.factory.md` | other | *Find / Post / Edit hansei* bullets; tag in *Merge PR* (§4, §5) |
| `references/protocol.md`, `references/decision-card.md`, `agents/*.md` | standard work | no change |
| `hooks/hooks.json`, `scripts/guard-memory.sh` | tooling | no change (the memory guard does not apply to the Lead, so its transcript reads pass) |

Outside `plugins/factory/`: `.claude-plugin/marketplace.json` keeps no `version` in the factory entry (§1).

## 1. Release

- `plugins/factory/.claude-plugin/plugin.json` gets `"version": "1.0.0"` on its own line (AC-1).
- The factory entry in `.claude-plugin/marketplace.json` has no `version` (it has none today; keep it so). Two places would let the manifest win silently (#35).

## 2. `references/hansei.md` (new standard work)

Holds, for the Lead:

1. The stage log: the four lead-state sections and their rules ([39-stage-log](39-stage-log.md) §1–§4).
2. The record: marker, layout, value grammar, honesty rule, field definitions and sources ([39-hansei-record](39-hansei-record.md) §2–§4), with the worked example.
3. The rule that measurements stay in the project: every record, log and measure is written to the project's own tracker or its `work/<id>/`, never to `WimSuenens/agent-plugins` (AC-20).

The glob `references/*.md` puts it in the standard fingerprint, and the bump check's minor rule covers it.

## 3. `skills/run/SKILL.md`

- **Plugin root.** One line near the top: `Plugin root: ${CLAUDE_PLUGIN_ROOT}`. Every script call uses that substituted path.
- **Step 5, Start the item.** Stamp `date -u +%FT%TZ`, open the `Start item` row, run `scripts/fingerprint.sh` and write `## Label` (with dependency versions and the lead session id), and start the `## Stage log`, `## Waits` and `## Person's touches` sections, per `references/hansei.md`.
- **Step 6, Run the stages.** At each brief and each result: stamp `date -u +%FT%TZ` and open or close the row, with agent ids and the notice's peak context. Each wait goes to `## Waits` and each touch the person makes goes to `## Person's touches`, as it happens.
- **Interruptions.** A limit failure opens a `limits` wait; the resume closes it.
- **Open PR.** Before `gh pr create`: `git fetch origin main`, then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-bump.sh"`. Exit 0: open the PR. Exit 1: don't open it, send the developer a feedback brief (`Source: lead`) quoting the refusal, log the `refused` row, and run *Open PR* again when the developer is done. Exit 2: don't open it; put the message to the person. No instruction anywhere opens a PR without this check (AC-8).
- **Step 8, Close the item.** The order in [39-hansei-record](39-hansei-record.md) §6, with its *Done when* extended: the hansei record is posted, and after the resurvey its measure 7 is filled.
- **Step 9 rule.** Keep the factory feedback issue to the map's rule: the problem in factory terms, the standard change, before/after numbers against the baseline with item count and release, and no code, names, business content or raw hansei records (AC-20). This is the only instruction that names `--repo WimSuenens/agent-plugins`.

## 4. Tracker operations, including projects set up before 1.0.0

- **Canonical home.** The *Find hansei*, *Post hansei* and *Edit hansei* commands ([39-hansei-record](39-hansei-record.md) §5) go into the plugin's tracker patch, `skills/setup-factory-skill/references/issue-tracker-github.factory.md`, after *Stage summary*. `/factory:setup-factory-skill` step 6 already writes that section into a project's `docs/agents/issue-tracker.md` ("add (or replace)"), so new projects get them with no change to the setup skill.
- **Projects set up before 1.0.0.** Their `## Factory operations` section has no *Post hansei* bullet. `skills/run/SKILL.md` says, where it points at the tracker doc: when that section has no *Post hansei* bullet, it predates factory 1.0.0; use the `## Factory operations` section of `${CLAUDE_PLUGIN_ROOT}/skills/setup-factory-skill/references/issue-tracker-github.factory.md` for the whole item instead, and tell the person once that replacing their section with it (setup's step 6) brings the project up to date. The Lead never edits the project's tracker doc itself.
- So there is one copy of the commands, in the plugin; the project's copy is a snapshot of it. A fallback copy inside `run/SKILL.md` would be a second source to keep in step.

## 5. Release tag in *Merge PR*

The *Merge PR* bullet in the tracker patch gains, between the merge and the clean-up:

> When the merged branch changed the `version` in `plugins/factory/.claude-plugin/plugin.json` (only in the repo that hosts the factory): `git fetch origin main`, then `git tag factory-v<version> "$(gh pr view <branch> --json mergeCommit --jq .mergeCommit.oid)"` and `git push origin factory-v<version>`. Skip when that tag exists already (`git ls-remote --tags origin factory-v<version>` prints a line).

The Lead creates the tag, in *Merge PR* (the lead's decision for this item). It points at the merge commit on `main` (AC-7). Taking the commit from `gh pr view` instead of `origin/main` keeps it right even when something else lands on main between the merge and the tag.

For #39 itself, which runs on the frozen install without this text, the Lead follows this paragraph by hand at its merge: `factory-v1.0.0` on #39's merge commit.

## 6. What reaches agent-plugins

- Every write of a record, a stage-log line or a measure targets the project's own tracker (`gh` inferring the repo from the clone) or `work/<id>/` in the project's worktree. None names `--repo`, and none writes a path in the plugin's repo (AC-20).
- The only cross-repo write stays step 9's feedback issue, under the rule in §3.

## 7. Shared resources

- **Build and QA**: none. The scripts run on temporary copies of the plugin tree and on fixture transcripts; the bump check runs on throwaway git repos created in a temp directory. Nothing needs a tracker.
- **Acceptance demo** (AC-9, 12, 17, 18, 19, 21): a scratch GitHub repository the person owns, with a `wayfinder:map` and one `wayfinder:slice` ticket, set up with `/factory:setup-factory-skill`, and a session started with `claude --plugin-dir <worktree>/plugins/factory`. It must not be `WimSuenens/agent-plugins`. The AC-9 throwaway branch lives in that scratch repo or a local clone and is never pushed to `WimSuenens/agent-plugins`. Which repository is the Lead's question to the person.

## 8. Outside `plugins/`

- This repo's own `docs/agents/issue-tracker.md` (docs-writer's path) should get the new `## Factory operations` section from the patch in this item, so agent-plugins' next item does not need the fallback. Until it does, §4's fallback covers it.
- `README.md` and `CHANGELOG.md` (docs-writer): release 1.0.0, the hansei record, the bump rule for anyone changing the factory.
- The map's Notes define standard work as four paths; with `references/hansei.md` the definition becomes `skills/run/SKILL.md`, `references/*.md`, `agents/*.md` (the Lead's edit on #34).
