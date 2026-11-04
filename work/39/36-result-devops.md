# Result: devops — 39
Status: done
Progress:
  Done: validate, check-bump, tests run; runbook committed (25f8978)
  Next: none
Summary:
  Release readiness holds. Runbook at docs/factory/release-runbook.md (release checks, tag, post-merge checks, freeze, rollback A/B, roll forward, monitoring). Nothing under plugins/ touched; no tag, merge or push; no /plugin commands run.
  NOT done: "rollback has run successfully in test" -- cannot be run on the frozen machine; rollback is reasoned, not exercised. Run it in a scratch HOME after the freeze.
Artifacts: docs/factory/release-runbook.md, work/39/36-result-devops.md

## Validate results (worktree item/39, read-only)
- claude plugin validate . : passed, 4 warnings (wayfinding, toolkit, discover, design have no version; intentional)
- claude plugin validate ./plugins/factory : passed, no warning
- claude plugin validate ./plugins/factory/skills : passed
- fingerprint.sh: release 1.0.0; standard 864087234702d4aa40e4c0da84d9da7ec6f7fa43b8a2353abb8027024aa52af7; tooling 03cfd2ba1afbf19d02e3b77a84b15615375a843a04ad9176a4a806a2d406b05b
- check-bump.sh (after fetch): pass: minor bump needed, 0.0.0 -> 1.0.0, exit 0
- tests/run.sh: ALL PASSED
- claude plugin list --json: factory@wimsuenens still at 9147301f75c3 (freeze intact). 9147301f is an ancestor of origin/main. No factory-v* tag exists yet on origin.
- Note: fingerprints move with any later edit to plugins/factory (docs-writer/other changes outside plugins/ do not).

## Tag commands for the Lead (after the person approves merge; PR #40)
git fetch origin main
bash plugins/factory/scripts/check-bump.sh      # in wt/39, expect exit 0
gh pr merge item/39 --merge
git ls-remote --tags origin factory-v1.0.0      # must print nothing
git fetch origin main
git tag factory-v1.0.0 "$(gh pr view item/39 --json mergeCommit --jq .mergeCommit.oid)"
git push origin factory-v1.0.0

## Post-merge checks (AC-7)
- git ls-remote --tags origin 'factory-v*' lists refs/tags/factory-v1.0.0
- git rev-parse 'factory-v1.0.0^{commit}' == gh pr view 40 --json mergeCommit --jq .mergeCommit.oid
- git merge-base --is-ancestor factory-v1.0.0 origin/main
- git show factory-v1.0.0:plugins/factory/.claude-plugin/plugin.json shows "version": "1.0.0"; marketplace.json factory entry has no version

Decisions:
- Rollback documented as new-release (revert + bump, minor if standard work, patch if tooling) or per-session --plugin-dir on a 9147301f worktree / rejected: editing the old version string or moving tags (installs follow the string; tags are cited) / cost to undo: edit the runbook
- Tag taken from the PR's mergeCommit, per contract / rejected: origin/main tip
- Runbook says no real pin of the user-scope install was tried (marketplace entry is a relative path) / cost: none
Open questions: after the freeze, who runs the rollback test in a scratch HOME (Delivery's "rollback exercised" is open).
