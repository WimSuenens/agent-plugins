<!-- factory:andon v1 -->
## Andon A2: version drift (#57)

- kind: 6 version-drift (flagged by the QA round 2 result)
- raised by: qa-engineer
- raised at: 2026-11-06T19:30Z
- seen: the standard fingerprint a role reported in its round 1 result is not the value of the committed tree; the Lead recomputed the tree at the round 1 commit, at HEAD and in the worktree as it stands: all three equal, so the script is deterministic and the reported value was stale (round 1 raised the same as an observation, not a finding)
- where to look: reviews/qa-57.md (section "Fingerprints"), work/57/08-result-developer.md, work/57/16-result-developer.md
- fit: n/a
- paused: no agent paused (QA had handed back)
- 5 Whys:
  1. Why did a result carry a fingerprint that does not match the tree? — the value was computed before the role's last commit and written into the result; nothing rechecks it — evidence: work/57/16-result-developer.md against the recompute at b3310d7
  2. Why does a result carry a fingerprint at all? — the brief's Done list asked for test results and the fingerprints were volunteered; no rule says whose fingerprint counts — evidence: work/57/07-brief-developer.md, work/57/15-brief-developer.md
  3. Why is that harmless for the record? — the label is computed by the Lead from the script on the item's tree, and the record uses that value; no consumer reads a role-reported fingerprint — evidence: skills/run/SKILL.md step 5 item 3
  4. Why was it raised as drift? — the abnormality list's kind 6 names a fingerprint difference between two records of the same release, and a role-reported value looks like one — evidence: references/protocol.md, Andon list
  5. Why does the list not separate the two? — kind 6 does not say that only the Lead's computed fingerprints are records — evidence: references/protocol.md, Andon list, kind 6
  process item to change: say in the abnormality list that kind 6 compares only fingerprints the Lead computed with the script, and that a role-reported fingerprint is not a record
- fence check: not run: no override proposed
- countermeasure: none
- supersedes: none
- standard change proposed: kind 6 compares only Lead-computed fingerprints; roles do not report fingerprints in results
- carried on: 2026-11-06T19:31Z
