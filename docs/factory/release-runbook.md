# Factory release runbook

How the `factory` plugin is released, checked, rolled back and rolled forward. First written for release `1.0.0` (slice #39, [ADR 0012](../adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md)), extended for each release since, and for `2.0.0` (slice #64) with the migration of a 1.x project's board.

**Blast radius of any factory release:** every project on a machine where the factory is installed at user scope. A release changes no project's files; it changes how the Lead runs the next item there. The release itself (merge, tag) touches only this repo. Production-like actions (merge, tag, push) wait for the person's approval, relayed by the Lead.

## Facts the steps rest on

- The factory's version lives in `plugins/factory/.claude-plugin/plugin.json` only. The marketplace entry has none (two places would let the manifest win silently).
- With a `version` set, an install changes only when that string changes. A push or revert that leaves the string alone reaches nobody. This is why every rollback below ends in a new version, never in an edited old one.
- Tag `factory-v<semver>` points at the merge commit on `main`. The Lead creates it in *Merge PR*.
- The pre-release factory had no version: its identity is the marketplace commit it was fetched at. The run that produces 1.0.0 is frozen on `9147301f75c3` (full sha `9147301f75c33859f8ad179b6ba336e1690435e6`, an ancestor of `main`).
- An open session keeps the factory skill text it read at start. A new version reaches a session only after a restart; `/reload-plugins` is not relied on (not tested to reload skill text).
- Every merge bump is checked by `scripts/check-bump.sh` (exit 0 pass, 1 bump missing, 2 unusable repo or base).

## Release checks (before the Lead asks to merge)

Read-only; none of these touch the installed plugin.

1. `claude plugin validate .` passes (four warnings for plugins without a version: wayfinding, toolkit, discover, design; intentional, the factory has none).
2. `claude plugin validate ./plugins/factory` and `./plugins/factory/skills` pass with no warning.
3. `bash scripts/check-bump.sh` in the branch's worktree, after `git fetch origin main`: `pass: minor bump needed, 0.0.0 -> 1.0.0`, exit 0.
4. `bash tests/run.sh` prints `ALL PASSED`. A tag waits while the suite reports any named skip; the Lead tags only when none is left, or the person accepts them by name.
5. `bash plugins/factory/scripts/obeya.sh check-pin` prints `pinned image ... exists` (needs Docker; #125). It fails when the image tag pinned in `plugins/factory/obeya/compose.yml` is not in the registry: publish the app first (see *Obeya image* below) or move the pin.
6. `bash plugins/factory/scripts/fingerprint.sh plugins/factory` prints `release: 1.0.0` and both fingerprints. Note them; any later change to either under the same release is a forgotten bump.

## Tag (the Lead, after the person approved the merge)

Run the bump check once more on the branch, then merge (PR #40, by number; the merge style is `--merge`, per ADR 0013), then tag the PR's merge commit (not `origin/main`, which may have moved):

```
git fetch origin main
bash scripts/check-bump.sh        # in the item/39 worktree; expect exit 0
gh pr merge 40 --merge
printf '%s' "1.0.0" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' && echo semver-ok
git ls-remote --tags origin factory-v1.0.0        # must print nothing, else the tag exists: stop
git fetch origin main
git tag factory-v1.0.0 "$(gh pr view 40 --json mergeCommit --jq .mergeCommit.oid)"
git push origin factory-v1.0.0
```

Use the branch's own `check-bump.sh` because the frozen install predates the script.

## Post-merge checks (AC-7)

- `git ls-remote --tags origin 'factory-v*'` lists `refs/tags/factory-v1.0.0`.
- `git rev-parse 'factory-v1.0.0^{commit}'` equals `gh pr view 40 --json mergeCommit --jq .mergeCommit.oid`, and that commit is on `main` (`git merge-base --is-ancestor factory-v1.0.0 origin/main`).
- `git show factory-v1.0.0:plugins/factory/.claude-plugin/plugin.json` shows `"version": "1.0.0"`; `git show factory-v1.0.0:.claude-plugin/marketplace.json` has no `version` in the factory entry.

## What the freeze means here

The machine stays on install `9147301f75c3` until this run's last item closes. Until then no `/plugin` command, no `claude plugin install|update|marketplace update`, no `/reload-plugins`. The freeze holds for every project on the machine and also holds back `wayfinding` and the other plugins of this marketplace. Consequences for release and rollback:

- Merging and tagging 1.0.0 changes nothing on this machine. The release reaches it only after the freeze ends and someone runs `claude plugin marketplace update wimsuenens` (then restart running sessions: an open session keeps the skill text it read at start).
- Before that point, "rollback" is free: do not update. Nothing was installed, nothing to undo. The repo-side rollback below is still available.
- An urgent mid-run fix ends the calibration (ADR 0012, point 8): the items after it are recorded as such. Lifting the freeze is the person's call.
- Items run during the freeze carry the label `calibration (pre-baseline)` and are never a "before".

## Roll back 1.0.0 to the pre-release factory

Decide first whether it is needed. A version-pinned install cannot go "down" by editing history: installs follow the version string, and the pre-release factory has none. So a rollback is a new release whose content equals the pre-release plugin, or a machine-local pin. Pick by scope.

**A. One machine or project, now (no repo change).** Run the factory from a checkout of the pre-release commit instead of the installed 1.0.0:

```
git worktree add ../factory-pre 9147301f75c3          # from the agent-plugins clone
claude --plugin-dir ../factory-pre/plugins/factory     # per session
```

Per-session, nothing installed or changed; closing the session ends it. The `--plugin-dir` flow is the same one the acceptance demo uses. Making it permanent (reinstalling from a pinned source) is not exercised here: see *Not verified*.

**B. Everyone, via the repo.** Revert on a branch and release the revert as a new version:

1. `git revert -m 1 <merge commit of PR #40>` on an `item/<id>` branch, or restore `plugins/factory/` from `9147301f75c3`: `git checkout 9147301f75c3 -- plugins/factory`.
2. Set `"version"` in `plugin.json` to the next number above the broken one. Restoring the old files restores the old (absent) version; leaving it that way ships nothing to a 1.0.0 install, and `check-bump.sh` refuses it. Reverting standard work (`skills/run/SKILL.md`, `references/*.md`, `agents/*.md`) needs at least a minor bump (`1.1.0`); a tooling-only revert needs a patch (`1.0.1`).
3. Run the release checks, then the Tag step with the new version. The old tag `factory-v1.0.0` stays; tags are never moved or deleted (they map a semver to its commit, and records cite them).
4. Machines receive it with `claude plugin marketplace update wimsuenens` once any freeze is over.

A minor or major release resets the baseline (ADR 0012, point 3), so a revert-as-minor starts a new baseline. That is accurate: the standard changed.

### What happens to hansei records already posted

- They stay. A hansei record is one comment on a slice ticket in the project where the item ran, marked `<!-- factory:hansei v2 -->`. Rolling back the plugin does not remove comments and nothing should: they carry the release and fingerprints they were measured on, and that label is what keeps them honest.
- The pre-release Lead does not read or write them; it ignores the comments. They do not break it.
- Records from before the rollback are not comparable with items run on the restored text, as the fingerprints differ. Do not mix them into one baseline.
- A project whose `docs/agents/issue-tracker.md` was brought up to date with the 1.0.0 *Factory operations* section keeps the *Post hansei* bullets. The pre-release Lead does not use them; leaving them is harmless. Remove them only if they confuse; that is the docs-writer's path in the project.
- If rolled forward later, the Lead finds old records by the marker (*Find hansei*) and the item's measure 7 can still be edited.

## Roll forward after a bad patch release

Prefer rolling forward to rolling back: a fix is a new version, which is the only thing installs follow.

1. Stop: tell the person which release is bad and its blast radius (every project on an updated machine). Do not delete or move the bad tag.
2. Build the fix on `item/<id>` as usual. The bump level follows the change, not the urgency: tooling-only is a patch (`1.0.0 -> 1.0.1`, baseline kept); anything in standard work is at least a minor (baseline resets).
3. If the fix is not ready and the damage continues, ship the revert (B above) as the new version first, then the real fix as the next one.
4. Release checks, Tag step with the new version, and a new line in `CHANGELOG.md` (docs-writer) that names the bad release.
5. Machines pick it up on `claude plugin marketplace update wimsuenens`, then restart open sessions. Until a machine updates, its installed bad release stays, and per-session `--plugin-dir` (A above) is the stopgap.
6. Records made on the bad release stay as they are; they carry its version. The kaizen note for the next run names what slipped past the checks.

An unnoticed bad edit under the same version is not a patch release: the fingerprint changes without a bump and the Lead raises an andon (ADR 0012, point 4). The fix is a bump.

## Monitoring and alerts

The factory ships no service: no process, port, queue or scheduled job. The new components and what watches them:

| Component | Watched by | Alert |
|---|---|---|
| Version string in `plugin.json` | `check-bump.sh` at PR open, frontier PR open, and before merge | exit 1 or 2: the Lead does not open or merge, feedback to the developer or a question to the person |
| Standard and tooling fingerprints | `fingerprint.sh` at item start, copied into each hansei record | fingerprint moved under the same release: andon, never a silent new baseline |
| Install sha / version | the Lead's item-start comparison with the frozen sha (ADR 0012, point 7) | mismatch: andon |
| `token-spend.sh` | its exit code at item close | non-zero (3 unreadable transcript, 4 jq missing, 5 no messages in window, 6 `transcript truncated by <kind>`): measure reads `not captured (<reason>)`, never `0` |
| Release tag | post-merge checks above | tag missing or on the wrong commit: the Lead fixes it before the next release, never by moving a published tag without the person's approval |
| Hansei record | the honesty rule: `not captured (<reason>)` | a blank or `0` where nothing was measured is itself a finding |

There is no pager. "Alert" means a message to the Lead's next decision card or question.

## Release 1.1.0 (slice #49, Andon)

Minor release (standard work changed, ADR 0012 point 3: the baseline resets). Same blast radius as above. Item #49 runs on the frozen install `9147301f75c3`, whose text has no tag step, so the Lead tags by hand at the merge, as for #39 (AC-30).

**Release checks** (as above, with these values):

1. `bash scripts/check-bump.sh` in the item/49 worktree after `git fetch origin main`: `pass: minor bump needed, 1.0.0 -> 1.1.0`, exit 0.
2. `bash tests/run.sh` prints `ALL PASSED`; the two named skips (docs-writer items) are gone or accepted by name before tagging.
3. `bash plugins/factory/scripts/fingerprint.sh plugins/factory` prints exactly:

```
release: 1.1.0
standard: 683cfb53180122ef3307b5d00d04adf37c141076985d212941925d4a908429c2
tooling: 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5
```

`tooling` equals 1.0.0's (no script or hook changed). Any edit under `plugins/factory/` after these were noted moves `standard`: re-read and update this entry.

**Tag by hand (the Lead, after the person approved the merge).** `56` is the number of the item/49 pull request (56).

```
git fetch origin main
bash scripts/check-bump.sh        # in the item/49 worktree; expect exit 0
gh pr merge 56 --merge
printf '%s' "1.1.0" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' && echo semver-ok
git ls-remote --tags origin factory-v1.1.0        # must print nothing, else the tag exists: stop
git fetch origin main
git tag factory-v1.1.0 "$(gh pr view 56 --json mergeCommit --jq .mergeCommit.oid)"
git push origin factory-v1.1.0
```

**Post-merge checks (AC-30).** `git ls-remote --tags origin 'factory-v*'` lists `refs/tags/factory-v1.1.0`; `git rev-parse 'factory-v1.1.0^{commit}'` equals the PR's merge commit and `git merge-base --is-ancestor factory-v1.1.0 origin/main` succeeds; `git show factory-v1.1.0:plugins/factory/.claude-plugin/plugin.json` shows `"version": "1.1.0"`. Do not move or delete a published tag.

**Rollback of 1.1.0.** As *Roll back* above, with 1.0.0 as the target: per session, `git worktree add ../factory-1.0.0 factory-v1.0.0` and `claude --plugin-dir ../factory-1.0.0/plugins/factory`; for everyone, restore `plugins/factory` from `factory-v1.0.0` and release it as `1.2.0` (standard work again, so a minor; a version at or below 1.1.0 ships nothing to a 1.1.0 install). Andon comments and `hansei v3` records already posted stay; a 1.0.0 Lead ignores them, and they are not comparable with v2 records. Overrides in a project's `## Overrides` section are inert for a 1.0.0 Lead.

**Monitoring added by 1.1.0.** No new process or service. The andon is watched by the Lead itself: kind 3 and kind 4 checks at each result, andon comments on the slice ticket, and the `## Abnormalities` section of the hansei record. The fence (F1 to F7) is the alert for overrides: an override across it is refused, never applied.

**Human-only checks** run only in `WimSuenens/factory-sandbox` (Project #10), never in this repo: the list is in `reviews/qa-49.md`, section *Human-only criteria*.

## Release 1.2.0 (slice #57, per-run A3 and baseline)

Minor release (standard work changed, ADR 0012 point 3: the baseline resets to a new 1.2 section). Same blast radius as above: every project on a machine where the factory is installed, after that machine updates; the release itself (merge, tag) touches only this repo. Item #57 runs on the frozen install `9147301f75c3`, whose text has no tag step, so the Lead tags by hand at the merge, as for #39 and #49 (AC-28). The acceptance demo ran on `--plugin-dir` (a worktree of this branch); the install stayed frozen and was not touched.

**This run is calibration (AC-27).** No `Factory baseline` issue is created in this repository by this item's work; the series is pre-baseline here, and the 1.2 baseline begins with the first item run on 1.2.0. The baseline issue and the A3 comment of the acceptance demo live in `WimSuenens/factory-sandbox`, not here. The one new issue in this repository from the demo is #59, approved by hand.

**Release checks** (read-only; run on the branch at 33b521d plus this runbook edit, after `git fetch origin main`):

1. `claude plugin validate .` passes with the same four version warnings as before (wayfinding, toolkit, discover, design); `./plugins/factory` and `./plugins/factory/skills` pass with no warning.
2. `bash scripts/check-bump.sh` prints `pass: minor bump needed, 1.1.0 -> 1.2.0`, exit 0.
3. `bash tests/run.sh` prints `ALL PASSED` (`test_token_spend.sh: 93 passed, 0 skipped, fail=0`); no named skip is left.
4. `bash plugins/factory/scripts/fingerprint.sh plugins/factory` prints exactly:

```
release: 1.2.0
standard: b0f96401e7e4f5fe46aab86ab7dff5ecf50e92f7cd2b9d5e6d85b8b8841cbc67
tooling: 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5
```

`tooling` equals 1.0.0's and 1.1.0's (no script or hook changed). Any edit under `plugins/factory/` after these were noted moves `standard`: re-read and update this entry.

**Tag by hand (the Lead, after the person approved the merge).** `58` is the number of the item/57 pull request. Tags `factory-v1.0.0` and `factory-v1.1.0` exist; `factory-v1.2.0` must not.

```
git fetch origin main
bash scripts/check-bump.sh        # in the item/57 worktree; expect exit 0
gh pr merge 58 --merge
printf '%s' "1.2.0" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' && echo semver-ok
git ls-remote --tags origin factory-v1.2.0        # must print nothing, else the tag exists: stop
git fetch origin main
git tag factory-v1.2.0 "$(gh pr view 58 --json mergeCommit --jq .mergeCommit.oid)"
git push origin factory-v1.2.0
```

**Post-merge checks (AC-28).** `git ls-remote --tags origin 'factory-v*'` lists `refs/tags/factory-v1.2.0`; `git rev-parse 'factory-v1.2.0^{commit}'` equals the PR's merge commit and `git merge-base --is-ancestor factory-v1.2.0 origin/main` succeeds; `git show factory-v1.2.0:plugins/factory/.claude-plugin/plugin.json` shows `"version": "1.2.0"`. Also (AC-27): no issue titled `Factory baseline` exists in this repository (`gh issue list --state all --search 'Factory baseline in:title'`). Do not move or delete a published tag.

**Frozen install.** Merging and tagging 1.2.0 changes nothing on this machine; the install stays on `9147301f75c3` until the freeze ends. Then someone runs `claude plugin marketplace update wimsuenens`, and the person restarts running sessions: an open session keeps the skill text it read at start, so the per-run A3 and baseline steps appear only in sessions started after the update. Until then, `--plugin-dir` on a checkout of the tag is the way to run 1.2.0.

**Rollback of 1.2.0.** Rollback ends in a new version, never a revert that leaves the string alone: an install follows the version string, and a push or revert under `1.2.0` reaches nobody. Target is 1.1.0.

- Per session, now: `git worktree add ../factory-1.1.0 factory-v1.1.0` and `claude --plugin-dir ../factory-1.1.0/plugins/factory`. Nothing installed or changed.
- Before any machine has updated: do not update; nothing was installed, nothing to undo.
- For everyone: on an `item/<id>` branch, `git checkout factory-v1.1.0 -- plugins/factory`, then set `"version"` to `1.3.0` (standard work again, so a minor; a version at or below 1.2.0 ships nothing to a 1.2.0 install and `check-bump.sh` refuses it). Run the release checks and the tag step for 1.3.0. `factory-v1.2.0` stays.
- Roll forward is preferred when the fault is small: tooling-only is `1.2.1`; anything in standard work is `1.3.0` or higher.
- Records stay: `hansei v4` records, `factory:a3 v1` comments and the `Factory baseline` issue in projects where 1.2.0 ran are not removed. A 1.1.0 Lead ignores the A3 and baseline issue (it does not read them), and v4 records are not comparable with v3 ones. Do not mix them in one baseline. The baseline issue is the project's to close or leave.
- Rollback has not been exercised in a scratch HOME (the machine is frozen): see *Not verified*.

**Monitoring added by 1.2.0.** No new process, port or service. The `Factory baseline` issue (one per project, found by title and the Lead's gh user) and the `factory:a3 v1` comment on the map issue are written by the Lead: the baseline issue is created at run start (step 0) and updated at each item close (step 8.10), at run close and after the settle merge (9.1 and 9.3), while only the A3 comment is written at run close; the alert for a missing or unreadable one is the Lead's own report at close: it says so and writes `not captured (<reason>)`, never `0`. `check-bump.sh` and `fingerprint.sh` keep watching the version and fingerprints as in *Monitoring and alerts*.

**Review notes carried from the verdicts.** QA (`reviews/qa-57.md`): final pass. Security (`reviews/security-57.md`): round 3 pass; info items I1 and I2 do not block. I1: a failed `gh api user` lookup of the Lead's login could read as "no baseline" and create a duplicate `Factory baseline` issue (spurious, nothing overwritten); if two appear in a project, close the newer one by hand. I2: a cosmetic span-length overshoot.

## Release 1.3.0 (slice #60, gemba line)

Minor release (standard work changed, ADR 0012 point 3: the baseline resets to a new 1.3 series). Same blast radius as above: every project on a machine where the factory is installed, after that machine updates; the release itself (merge, tag) touches only this repo. Item #60 runs on the frozen install `9147301f75c3`, whose text has no tag step, so the Lead tags by hand at the merge, as for #57. No new process, port or service; no timing measure moved (no change to the timing lines).

**Release checks** (read-only; run on the branch after `git fetch origin main`):

1. `bash scripts/check-bump.sh` prints `pass: minor bump needed, 1.2.0 -> 1.3.0`, exit 0.
2. `bash plugins/factory/scripts/fingerprint.sh plugins/factory` prints exactly:

```
release: 1.3.0
standard: d146280132f3ad44339ec587ae5ecc93c4b9a4ebf00db4bff5ce5837da256068
tooling: 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5
```

`tooling` equals 1.0.0's, 1.1.0's and 1.2.0's (no script or hook changed). Any edit under `plugins/factory/` after these were noted moves `standard`: re-read and update this entry.

**Tag by hand (the Lead, after the person approved the merge).** `61` is the number of the item/60 pull request. Tags `factory-v1.0.0`, `factory-v1.1.0` and `factory-v1.2.0` exist; `factory-v1.3.0` must not.

```
git fetch origin main
bash scripts/check-bump.sh        # in the item/60 worktree; expect exit 0
gh pr merge 61 --merge
printf '%s' "1.3.0" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' && echo semver-ok
git ls-remote --tags origin factory-v1.3.0        # must print nothing, else the tag exists: stop
git fetch origin main
git tag factory-v1.3.0 "$(gh pr view 61 --json mergeCommit --jq .mergeCommit.oid)"
git push origin factory-v1.3.0
```

**Post-merge checks (AC-10).** `git ls-remote --tags origin 'factory-v*'` lists `refs/tags/factory-v1.3.0`; `git rev-parse 'factory-v1.3.0^{commit}'` equals the PR's merge commit and `git merge-base --is-ancestor factory-v1.3.0 origin/main` succeeds; `git show factory-v1.3.0:plugins/factory/.claude-plugin/plugin.json` shows `"version": "1.3.0"`. The close of #60 carries no gemba line and creates no `Factory baseline` issue in this repo. Do not move or delete a published tag.

**Frozen install.** Merging and tagging 1.3.0 changes nothing on this machine; the install stays on `9147301f75c3` until the freeze ends. After `claude plugin marketplace update wimsuenens` and a session restart, the gemba line appears in `hansei v5` records.

**Rollback of 1.3.0.** A new version, never an edit under `1.3.0`. Target is 1.2.0.

- Per session, now: `git worktree add ../factory-1.2.0 factory-v1.2.0` and `claude --plugin-dir ../factory-1.2.0/plugins/factory`. Before any machine has updated: do not update.
- For everyone: on an `item/<id>` branch, `git checkout factory-v1.2.0 -- plugins/factory`, set `"version"` to `1.4.0` (standard work again, so a minor), run the release checks and the tag step for 1.4.0. `factory-v1.3.0` stays.
- Records stay: `hansei v5` records are not removed. A 1.2.0 Lead reads v3 and v4 only and skips v5 records (they are not in its series); do not mix v5 with v4 in one baseline.
- Rollback has not been exercised in a scratch HOME (the machine is frozen): see *Not verified*.

**Monitoring added by 1.3.0.** None. The gemba line is a record field read by no script; the baseline's presence check (one `- gemba: ` line in a v5 record) reports `skipped ... (gemba line missing)` or `(gemba line repeated)` in the `records:` line, which is the alert.

## Release 2.0.0 (slice #64, the board as run state)

**Major release.** Every project on a machine where the factory is installed, after that machine updates, must migrate before `/factory:run` accepts it: `factory-config.sh state` exits 3 and names `run setup-factory-skill` on a 1.x project, and the run stops at its first step. The migration changes the **live GitHub Project** (the `Factory status` options and the views), not the files of the project's repository. It is run by `/factory:setup-factory-skill`, after the person's yes; `/factory:run` never runs it. Merging and tagging 2.0.0 changes nothing on the frozen machine (user-scope install factory 1.3.0 for this run) until the freeze ends. Item #64 itself ran on the 1.3.0 mechanism: **no new-series baseline** is written, and the `2.0` series starts with the next run.

**Release checks** (read-only; run on the branch after `git fetch origin main`, in the item/64 worktree):

1. `claude plugin validate .` exits 0 with the four version warnings for wayfinding, toolkit, discover and design (intentional).
2. `claude plugin validate ./plugins/factory` and `claude plugin validate ./plugins/factory/skills` exit 0 with no warning.
3. `bash scripts/check-bump.sh` prints `pass: minor bump needed, 1.3.0 -> 2.0.0`, exit 0. The script is unchanged; its word "minor" is a floor, and the major level is the architect's decision (decision 8 of [64-release](../../contracts/64-release.md) §6).
4. `bash plugins/factory/scripts/fingerprint.sh plugins/factory` prints exactly:

```
release: 2.0.0
standard: 4bb4220e38b793e9a2df0bebb7da9041e94f8f2a1a7f855acd5b4f5b7273e9d0
tooling: 92746e5d526aeaebcbd1ab94af461c973d1bd417265eb71e940db31b36da324a
```

`tooling` moved from 1.3.0's `295033f4…` because the four new scripts are tooling; the two values above match the round 3 verdict of [reviews/qa-64.md](../../reviews/qa-64.md). Any edit under `plugins/factory/` after these were noted moves `standard` (or `tooling`, for a file under `scripts/`): re-read and update this entry.

5. `bash tests/run.sh` prints `ALL PASSED` with **seven** named skips, and no failure. The skips are: `ac29-no-script-changed` (test_andon_text), `ac26-no-path-outside-the-list`, `ac26-no-agent-changed`, `ac26-no-new-script`, `ac27-tooling-did-not-move` (test_baseline_a3), `ac1-repo-own-docs-agents-factory-md` (test_board_status) and `t13-release-delta-vs-1.2.0` (test_gemba). Six are retired release-delta pins replaced by `test_release64.sh`; the seventh keeps this repository's own `docs/agents/factory.md` in its 1.x table until the step after the run closes. As the *Tag* rule of the 1.0.0 section requires, the Lead tags only when none is left or the person accepts these seven by name.

**Tag by hand (the Lead, after the person approved the merge).** `<pr>` is the number of the item/64 pull request. Tags `factory-v1.0.0` to `factory-v1.3.0` exist; `factory-v2.0.0` must not.

```
git fetch origin main
bash scripts/check-bump.sh        # in the item/64 worktree; expect exit 0
gh pr merge <pr> --merge
printf '%s' "2.0.0" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' && echo semver-ok
git ls-remote --tags origin factory-v2.0.0        # must print nothing, else the tag exists: stop
git fetch origin main
git tag factory-v2.0.0 "$(gh pr view <pr> --json mergeCommit --jq .mergeCommit.oid)"
git push origin factory-v2.0.0
```

**Post-merge checks.** `git ls-remote --tags origin 'factory-v*'` lists `refs/tags/factory-v2.0.0`; `git rev-parse 'factory-v2.0.0^{commit}'` equals the PR's merge commit, and `git merge-base --is-ancestor factory-v2.0.0 origin/main` succeeds; `git show factory-v2.0.0:plugins/factory/.claude-plugin/plugin.json` shows `"version": "2.0.0"`. Do not move or delete a published tag.

**The migration try on a scratch Project (the Lead, before the merge): outcome of 2026-11-08.** The try ran on the real GitHub API, on a scratch Project that was deleted afterwards, so nothing remains on any real Project. The live Project was not used. The token needed the `project` scope.

What was verified:

- `board.sh plan` read the board: a seven-option board, 8 items to change and 4 staying.
- `board.sh apply --yes` moved the 8 items by the mapping (Designed to Ready; In progress and In review to Running; Ready to deploy to Waiting on you) and left the other 4. It kept every `Priority` value, identical before and after. It dropped the four old options last, created the `Kind` and `Role` fields, and wrote a snapshot outside the repository with mode 600.
- A second `plan` read "migration in progress", because the views were not yet made.
- `board.sh finish --views-confirmed` refused while a view was missing. Once the views were made, it wrote `factory-state: 2`, the new option ids and the 2.0.0 operations section into scratch copies of the two docs. It ran twice with the same result, and `plan` then read "already migrated".

What was found: `CreateProjectV2ViewInput` has no `filter` field. So the single create mutation always fails, and `apply` always ends with exit 10 and the hand-build instructions for both views. The designed fallback works. By hand, creating a view with name and layout and then calling `updateProjectV2View` with the filter works, and the filter reads back. A fix (create, then update) is a candidate for a later release; it is **not** in 2.0.0.

What to expect when the try is run again:

1. `bash plugins/factory/scripts/board.sh plan --owner <owner> --project <scratch number> --project-id <scratch id>`: prints the mapping and the snapshot file it would write; changes nothing.
2. `bash plugins/factory/scripts/board.sh apply --owner <owner> --project <scratch number> --project-id <scratch id> --yes`: writes the snapshot first, then changes the field and the items. It ends with exit 10 and the two hand-build instructions (`Needs you`: table layout, filter `factory-status:"Waiting on you"`; `History`: table layout, filter `is:closed kind:slice,"role task"`, with the fields and order shown).
3. Build the two views by hand from those instructions on the scratch Project.
4. `board.sh apply --owner <owner> --project <scratch number> --project-id <scratch id> --yes --views-confirmed`, then `board.sh finish --owner <owner> --project <scratch number> --project-id <scratch id> --views-confirmed`.
5. `board.sh plan` again: it prints `already migrated`. Keep the snapshot file path it printed.

Still unverified after the try: that the view filters correctly in the UI with the `factory-status:` token (only the stored text was read back), and the fields shown and their order (the API call sets only name, layout and filter). A failed try is an andon (the protocol's kind 7), not a changelog line. The scratch Project was deleted after the try.

**Rollback.** There are two kinds, and the board one is not automatic.

- **The board (after a live migration).** The snapshot is the only record of the old `In progress` and `In review` difference. The restore is the one in the setup skill, step 7: add the four old option names back to `Factory status` (they get new ids), keeping every present id; set each item to its recorded old option with `gh project item-edit`; drop what the old workflow did not have. A real restore is not rehearsed (see *Not verified*).
- **The plugin.** Installs follow the version string, so the rollback is a **new version above 2.0.0** whose content is the 1.3.0 text (the 1.x rule: a version at or below 2.0.0 ships nothing to a 2.0.0 install). Per session, now, with nothing installed: `git worktree add ../factory-1.3.0 factory-v1.3.0` and `claude --plugin-dir ../factory-1.3.0/plugins/factory`. The 1.3.0 Lead does not know the board and reads the 1.x stage log, so on a project that has already migrated it is not a working rollback without the board restore above. Records stay: `hansei v5` records are read by 1.3.0 as before, and the ledger comments stay on the tickets.

**What to check by hand, after the run closes.** These are the person's checks; no acceptance demo gated this release.

1. Run the migration on the live Project (`/factory:setup-factory-skill` on this repository, which is still on the 1.x table and migrates through that step), and confirm the two views as the skill asks.
2. Open the **Needs you** view and confirm it lists exactly the cards with `Factory status` `Waiting on you`, and that a card's needs-you comment says what to do next. This is the check of the requirement's AC-5 and AC-6; it is the human-only check of the Unverified list.
3. Open the **History** view and confirm it lists closed slices and role tasks, newest first.
4. Confirm the board view groups by `Factory status`.
5. Keep the snapshot file the migration printed until the first full run on 2.0.0 has closed.

**Monitoring added by 2.0.0.** No process, port or service. The alerts are the exit codes of `board.sh` (2 usage or a missing `gh` or `jq`, 3 a failed read, 5 a verification difference, 6 an item still holds an old value, 7 a failed mutation, 10 the views need the person's confirmation), `factory-config.sh state` (exit 3 on a 1.x project) and `paths.sh check` (an off-list path at review). No port is opened; the scripts run only short-lived commands and leave no process running.

## Release 2.3.0 (slice #94, the A3 at v2 and the lean extensions)

**Minor release 2.3.0, no migration.** Standard work changed (the run skill and the references), so the baseline starts a new `2.3` series with its first item run on 2.3.0; the `2.2` series stays as history (`references/baseline.md`, section 3, item 2). Nothing in a project has to change: A3 v1 comments, hansei v3 to v5 records, and 2.2.0 ledgers and overrides are read as before. New runs post an A3 v2, which adds the lines `waste`, `gemba (targeted)` and `target`, and the hansei record gains two derived sub-lines under measure 1 (`flow efficiency`, `per stage`), which are never stored. A 2.2.0 install reads a v2 A3 as a version it does not know: it skips the comment and says so.

**Release checks** (read-only; on the branch after `git fetch origin main`, in the item/94 worktree):

1. `claude plugin validate ./plugins/factory` and `claude plugin validate ./plugins/factory/skills` exit 0 with no warning.
2. `bash scripts/check-bump.sh` prints `pass: minor bump needed, 2.2.0 -> 2.3.0`, exit 0.
3. `bash plugins/factory/scripts/fingerprint.sh plugins/factory` prints `release: 2.3.0`. The two fingerprints are kept on the last line of the 2.3.0 entry in [CHANGELOG.md](../../CHANGELOG.md), not repeated here: they move with any edit under `plugins/factory/`, and any later change under the same release is a forgotten bump.
4. `bash tests/run.sh` prints `ALL PASSED` with no named skip. The three checks that waited for this release's changelog, runbook and docs (`ac19-changelog-2.3.0`, `ac19-runbook-2.3.0-note`, `ac17-docs-say-v2`) are passes.
5. `bash plugins/factory/scripts/a3-check.sh <file>` on an A3 saved to a file prints `ok v2` (exit 0) for a v2 A3 and `ok v1` for a v1 A3 of 2.2.0. It is a format check; the *Scan before posting* step stays the gate for secrets and paths.

**Tag (the Lead, after the person approved the merge).** Tags on origin run from `factory-v1.0.0` to `factory-v2.1.0`. The 2.2.0 release has no tag on origin (`git ls-remote --tags origin 'factory-v*'`, read on 2026-11-10). `factory-v2.3.0` must not exist before the merge. In the item/94 worktree, with `<pr>` the number of the item/94 pull request:

```
git fetch origin main
bash scripts/check-bump.sh        # expect exit 0
gh pr merge <pr> --merge
printf '%s' "2.3.0" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' && echo semver-ok
git ls-remote --tags origin factory-v2.3.0        # must print nothing, else the tag exists: stop
git fetch origin main
git tag factory-v2.3.0 "$(gh pr view <pr> --json mergeCommit --jq .mergeCommit.oid)"
git push origin factory-v2.3.0
```

**Post-merge checks.** `git ls-remote --tags origin 'factory-v*'` lists `refs/tags/factory-v2.3.0`, and `git show factory-v2.3.0:plugins/factory/.claude-plugin/plugin.json` shows `"version": "2.3.0"`. Do not move or delete a published tag.

**Frozen install.** `claude plugin list --json`, read on 2026-11-10, reports `factory@wimsuenens` at version 2.2.0 with user scope: the frozen install of this run. Merging and tagging 2.3.0 changes nothing on this machine until the freeze ends. Then `claude plugin marketplace update wimsuenens` brings the release in, and the person restarts running sessions: an open session keeps the skill text it read at start.

**Rollback.** There is nothing to roll back in a project: the A3 v2 lines and the derived sub-lines are additions, and the 2.2.0 text skips the one and does not read the other. To put the plugin back on the 2.2.0 text, publish a new version above 2.3.0 whose content is the 2.2.0 text, as the *Release 2.0.0* section describes for its own rollback; installs follow the version string.

## Obeya image (slice #124, [ADR 0020](../adr/0020-the-obeya-is-a-nuxt-4-container-image-on-ghcr.md))

The Obeya app ships as `ghcr.io/wimsuenens/obeya:<semver>`, built for `linux/amd64` and `linux/arm64` by `.github/workflows/obeya-image.yml`. The app is versioned apart from the plugin: a plugin release does not rebuild the image.

**Bump.** To publish a new image, raise `version` in `apps/obeya/package.json` and merge to `main`. The workflow runs on a push to `main` that touches `apps/obeya/**`, or by hand (Actions, `obeya-image`, Run workflow). It publishes only when the version has no tag yet; otherwise it ends green with a notice. It never pushes a moving tag, so a tag always names one build.

**Check after the merge.**
1. The `obeya-image` run is green. A failed build or publish fails the run; nothing partial is tagged.
2. `docker buildx imagetools inspect ghcr.io/wimsuenens/obeya:<semver>` lists `linux/amd64` and `linux/arm64` under the one tag.
3. First publish only: a package created by a workflow is private. In the repository's Packages, set `obeya` to public and link it to this repository, then check once from a machine that is not logged in to GHCR: `docker logout ghcr.io && docker pull ghcr.io/wimsuenens/obeya:<semver>`. If the person turns the ADR decision to private, document the pull token instead (ADR 0020, way back).
4. The plugin pins the tag in `plugins/factory/obeya/compose.yml` (#125). It is released only after step 2 passes for that tag; release check 5 (`obeya.sh check-pin`) enforces it.

Rollback: a published tag is never overwritten or deleted; publish a fixed version and move the plugin's pin.

## Not verified

- **2.3.0:** nothing ran in a live factory session. Not run: the install and update path and the rollback (the machine is frozen), a run that closes with a v2 A3, and a settle answer on an experiment with a `target:`. The three unverified items of [CHANGELOG.md](../../CHANGELOG.md) under *2.3.0* are the full list. The checks above are offline.
- **2.0.0:** no migration, view check or board write was run against a live Project; `board.sh plan` was run read-only against the live Project. The scratch-Project try ran on 2026-11-08 (outcome in *Release 2.0.0*). Not run: a restore from a snapshot, a first run on 2.0.0 and an install. The Unverified list of [CHANGELOG.md](../../CHANGELOG.md) under *2.0.0* names every item.
- Install and update were not run (frozen machine). `--plugin-dir` use of a pre-release worktree and `marketplace update` behaviour are from the README, ADR 0012 and #35's findings, not exercised here. Rollback (A) was reasoned, not run; the Delivery Done item "rollback has run successfully in test" is therefore open for 1.0.0 and should be run in a scratch HOME after the freeze ends: install 1.0.0, then repeat steps A and B, and confirm the installed version string follows.
- Pinning the user-scope install itself to the pre-release commit (a `ref`/`sha` source for the factory) was not tried; the marketplace entry is a relative path today.
