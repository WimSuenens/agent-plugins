# Result: devops — 60
Status: done
Progress:
  Done: checks run; runbook gained a "Release 1.3.0" section (commit "#60 devops: runbook release 1.3.0 and result").
  Next: none.
Summary:
- check-bump.sh (after `git fetch origin main`): `pass: minor bump needed, 1.2.0 -> 1.3.0`, exit 0.
- fingerprint.sh plugins/factory: `release: 1.3.0`; standard d146280132f3ad44339ec587ae5ecc93c4b9a4ebf00db4bff5ce5837da256068; tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5. Both equal the QA-quoted values.
- `git ls-remote --tags origin 'factory-v*'` lists v1.0.0, v1.1.0, v1.2.0 only; factory-v1.3.0 does not exist.
- plugin.json `"version": "1.3.0"`, matches the plain MAJOR.MINOR.PATCH pattern.
- The PR for item/60 is #61 (open). Runbook tag steps use 61.
- Runbook: previous releases each have a section, so a Release 1.3.0 section was added (fingerprints, tag steps, post-merge checks, rollback to 1.2.0 via 1.4.0, monitoring: none new, v5 records). The timing lines are unchanged. Nothing installed, tagged, pushed or merged. No home paths added.
Artifacts: docs/factory/release-runbook.md, work/60/22-result-devops.md
Decisions: Add a per-release 1.3.0 section instead of editing the older ones / leave the runbook alone / one commit to revert.
Open questions: none. Rollback of 1.3.0 not exercised (frozen machine; listed under Not verified already for the earlier releases).
Post-merge steps for the Lead (after the person approves the merge):
  git fetch origin main
  bash plugins/factory/scripts/check-bump.sh        # in the item/60 worktree; expect exit 0
  gh pr merge 61 --merge
  printf '%s' "1.3.0" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' && echo semver-ok
  git ls-remote --tags origin factory-v1.3.0        # must print nothing
  git fetch origin main
  git tag factory-v1.3.0 "$(gh pr view 61 --json mergeCommit --jq .mergeCommit.oid)"
  git push origin factory-v1.3.0
Then verify: ls-remote lists the tag; `git rev-parse 'factory-v1.3.0^{commit}'` equals the merge commit; merge-base --is-ancestor factory-v1.3.0 origin/main; `git show factory-v1.3.0:plugins/factory/.claude-plugin/plugin.json` shows 1.3.0.
