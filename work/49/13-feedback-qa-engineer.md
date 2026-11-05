# Feedback: qa-engineer — 49
Source: lead (developer round 2 and architect round 2 applied)
Findings:
1. Six tests pin wording the contract replaced (ac15-rule-in-briefs, ac15-skill-puts-rule-in-briefs, ac18-check-before-write [seven to eight questions], ac23-paused-note, k3-diff-tree [-z], k3-never-flagged [rule 5.6]) — update them to the contract in contracts/49-standard-changes.md section 10; do not weaken them. Turn the named skip qa49-f1-paused-row-lists-the-andon-wait into a plain check.
2. Add fixtures for the new text: rule 5.6 (forged lead subject by a non-Lead author), question E (fixtures 11 and 12 in contracts/49-overrides.md), `git diff-tree -z` with an accented and a newline filename in a scratch repo (S4 reproduction), kind 6(b) FREEZE-line author check, `promote chosen` listed in the stage summary.
3. The model control in contracts/49-abnormality-list.md 4.5 changed to security L4 vs QA F4: re-run the AC-3 replay for that pair only; the 5/5 and 0/7 results stand unless the changed text moves them (say so).
4. Re-quote the final fingerprints for AC-29: standard 683cfb53... expected, tooling 295033f4... expected; give the full values. Update reviews/qa-49.md and the Human-only list (note the two new human-only checks, if any).
Re-verify: bash tests/run.sh exits 0; new verdict.
