# Factory release runbook

How the `factory` plugin is released, checked, rolled back and rolled forward. First written for release `1.0.0` (slice #39, [ADR 0012](../adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md)).

**Blast radius of any factory release:** every project on a machine where the factory is installed at user scope. A release changes no project's files; it changes how the Lead runs the next item there. The release itself (merge, tag) touches only this repo. Production-like actions (merge, tag, push) wait for the person's approval, relayed by the Lead.

## Facts the steps rest on

- The factory's version lives in `plugins/factory/.claude-plugin/plugin.json` only. The marketplace entry has none (two places would let the manifest win silently).
- With a `version` set, an install changes only when that string changes. A push or revert that leaves the string alone reaches nobody. This is why every rollback below ends in a new version, never in an edited old one.
- Tag `factory-v<semver>` points at the merge commit on `main`. The Lead creates it in *Merge PR*.
- The pre-release factory had no version: its identity is the marketplace commit it was fetched at. The run that produces 1.0.0 is frozen on `9147301f75c3` (full sha `9147301f75c33859f8ad179b6ba336e1690435e6`, an ancestor of `main`).
- An open session keeps the factory skill text it read at start. A new version reaches a session only after a restart; `/reload-plugins` is not relied on (not tested to reload skill text).
- Every merge bump is checked by `plugins/factory/scripts/check-bump.sh` (exit 0 pass, 1 bump missing, 2 unusable repo or base).

## Release checks (before the Lead asks to merge)

Read-only; none of these touch the installed plugin.

1. `claude plugin validate .` passes (four warnings for plugins without a version: wayfinding, toolkit, discover, design; intentional, the factory has none).
2. `claude plugin validate ./plugins/factory` and `./plugins/factory/skills` pass with no warning.
3. `bash plugins/factory/scripts/check-bump.sh` in the branch's worktree, after `git fetch origin main`: `pass: minor bump needed, 0.0.0 -> 1.0.0`, exit 0.
4. `bash tests/run.sh` prints `ALL PASSED`. A tag waits while the suite reports any named skip; the Lead tags only when none is left, or the person accepts them by name.
5. `bash plugins/factory/scripts/fingerprint.sh plugins/factory` prints `release: 1.0.0` and both fingerprints. Note them; any later change to either under the same release is a forgotten bump.

## Tag (the Lead, after the person approved the merge)

Run the bump check once more on the branch, then merge (PR #40, by number; the merge style is `--merge`, per ADR 0013), then tag the PR's merge commit (not `origin/main`, which may have moved):

```
git fetch origin main
bash plugins/factory/scripts/check-bump.sh        # in the item/39 worktree; expect exit 0
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

1. `bash plugins/factory/scripts/check-bump.sh` in the item/49 worktree after `git fetch origin main`: `pass: minor bump needed, 1.0.0 -> 1.1.0`, exit 0.
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
bash plugins/factory/scripts/check-bump.sh        # in the item/49 worktree; expect exit 0
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

## Not verified

- Install and update were not run (frozen machine). `--plugin-dir` use of a pre-release worktree and `marketplace update` behaviour are from the README, ADR 0012 and #35's findings, not exercised here. Rollback (A) was reasoned, not run; the Delivery Done item "rollback has run successfully in test" is therefore open for 1.0.0 and should be run in a scratch HOME after the freeze ends: install 1.0.0, then repeat steps A and B, and confirm the installed version string follows.
- Pinning the user-scope install itself to the pre-release commit (a `ref`/`sha` source for the factory) was not tried; the marketplace entry is a relative path today.
