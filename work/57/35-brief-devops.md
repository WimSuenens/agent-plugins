# Brief: devops — 57 (Delivery)

Goal: Update `docs/factory/release-runbook.md` for release 1.2.0 (the first release that carries the per-run A3 and the baseline issue) so the Lead can release, check, roll back and roll forward from it.

Inputs:
- The QA and security verdicts: `reviews/qa-57.md` (final: pass) and `reviews/security-57.md` (round 3: pass; info I1, I2).
- `docs/factory/release-runbook.md` as it stands (written for 1.0.0, extended for 1.1.0 if it says so).
- `plugins/factory/.claude-plugin/plugin.json` (version 1.2.0), `plugins/factory/scripts/check-bump.sh`, `plugins/factory/scripts/fingerprint.sh`.
- `docs/requirements/57-per-run-a3-and-baseline.md` AC-27 (this run is calibration) and the demo outcome comment on issue #57 (the acceptance demo ran on `--plugin-dir`; the install stayed frozen).
- ADR 0012 (releases, freeze) and ADR 0013 (merge style: `--merge`).

Constraints:
- Edit only `docs/factory/release-runbook.md`. No change under `plugins/`, `hooks/`, `scripts/` or `tests/`.
- State for 1.2.0: the release checks (validate, `check-bump.sh` expected `pass: minor bump needed, 1.1.0 -> 1.2.0` or whatever the script actually prints on this branch: run it, do not guess), the tag `factory-v1.2.0` created by the Lead by hand after the merge because the installed factory is frozen; no baseline issue is created in this repository by this run (AC-27: calibration, series pre-baseline); the person restarts sessions to get the new skill text; rollback ends in a new version, never a revert that leaves the string alone.
- Run the read-only release checks and quote their real output in the result; if one fails, say so, do not edit around it.
- Production actions wait for the person's approval relayed by the Lead; you take none.
- No absolute home path in any file. Commit subjects start `#57 devops: `.

Output: the edited runbook and `work/57/36-result-devops.md` (start with `Status: working`, then the protocol's result template; end with Done checked point by point).

Done:
- The runbook names 1.2.0, the tag step, the frozen-install note and the rollback path, each consistent with the checks you ran.
- Blast radius stated.
