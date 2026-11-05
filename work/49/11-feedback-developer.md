# Feedback: developer — 49
Source: architect (round 2 of the contracts), security, qa
Findings:
1. Contract text changed after your build: apply every plugin-text change listed in contracts/49-standard-changes.md section 10 (S1 rule 5.6 and re-read of in-force rules, S2 question E and paraphrased andon-comment fields, S3 F1 coverage and `promote chosen` in stage summaries, S4 `git diff-tree -z`, S5 FREEZE-line author check, QA F1 andon wait id in the paused row's Waits). — medium — required fix: plugin text matches the contracts.
2. The protocol's fence table stays seven rows (E is a question, not an eighth fenced item); keep ADR 0011 unchanged.
3. Version stays 1.1.0. Report the new standard fingerprint (tooling should stay 295033f4...).
Re-verify: bash plugins/factory/scripts/check-bump.sh exits 0; no absolute home paths; tests/ are QA's, so list the tests you expect to change.
