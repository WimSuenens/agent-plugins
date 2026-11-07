# Result: devops — 57
Status: done
Progress:
  Done: read brief and inputs; ran release checks; added "Release 1.2.0" section to the runbook (commit below)
  Next: nothing; the Lead tags factory-v1.2.0 by hand after the person approves the merge of PR #58
Summary: `docs/factory/release-runbook.md` now has a "Release 1.2.0 (slice #57)" section: checks with real output, fingerprints, the by-hand tag step for PR #58, post-merge checks, the frozen-install note, rollback to 1.1.0 ending in new version 1.3.0, monitoring, and review notes (security I1/I2). AC-27 calibration is stated: no baseline issue in this repo. All checks passed; none edited around.
Blast radius: every project on a machine where the factory is installed, once that machine updates (frozen here, so none now); the release itself (merge, tag, push) touches only this repo. No production action taken; merge and tag wait for the person's approval via the Lead.

Real output of the checks (branch item/57 at 33b521d, after `git fetch origin main`):
- `claude plugin validate .`: "Validation passed with warnings" (4 no-version warnings: plugins[1..4], the expected ones)
- `claude plugin validate ./plugins/factory` and `./plugins/factory/skills`: "Validation passed", no warnings
- `bash plugins/factory/scripts/check-bump.sh`: `pass: minor bump needed, 1.1.0 -> 1.2.0`, exit 0
- `bash tests/run.sh`: `test_token_spend.sh: 93 passed, 0 skipped, fail=0`, `ALL PASSED` (no named skip)
- `bash plugins/factory/scripts/fingerprint.sh plugins/factory`:
  release: 1.2.0
  standard: b0f96401e7e4f5fe46aab86ab7dff5ecf50e92f7cd2b9d5e6d85b8b8841cbc67
  tooling: 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5
- Tags on origin: factory-v1.0.0, factory-v1.1.0; factory-v1.2.0 absent. PR for item/57 is #58.

Artifacts: docs/factory/release-runbook.md, work/57/36-result-devops.md
Decisions: Rollback target 1.1.0 released as 1.3.0 (minor, since standard work changes) / rejected: patch number, which check-bump would refuse / cost to undo: edit one runbook paragraph. Runbook says 1.2.0 rollback was not exercised (machine frozen); no "Not verified" edit beyond that.
Open questions: Rollback "has run successfully in test" is still open (no scratch-HOME run; frozen machine), as for 1.0.0 and 1.1.0. The `Not verified` section still covers it. Developer may want to address security I1 (one-clause fix in the standard); the runbook records the workaround.

Done, point by point:
- Runbook names 1.2.0, the tag step, the frozen-install note and the rollback path, consistent with the checks: yes.
- Blast radius stated: yes (runbook header, 1.2.0 section, and above).
- Edited only the runbook; nothing under plugins/, hooks/, scripts/, tests/; no absolute home path in it (grep checked).

Feedback round (Lead): corrected the 1.2.0 monitoring sentence on baseline timing (created at run start, updated at 8.10, 9.1, 9.3; only the A3 is written at run close).
