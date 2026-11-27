---
andon: A1
item: 286
owner: lead
status: resolved
reason: installed factory 3.9.1, FREEZE line 3.9.0
since: 2026-11-27T23:17Z
countermeasure: none, needs a plugin change; carried on under 3.9.1 (patch, standard unchanged)
---

<!-- factory:andon v1 -->
## Andon A1: version-drift (#286)

- kind: 6 version-drift
- raised by: lead
- raised at: 2026-11-27T23:17Z
- seen: installed 3.9.1, FREEZE line 3.9.0
- where to look: the Factory run section of #278 (FREEZE line); tag factory-v3.9.1 (merge 2a0219b); CHANGELOG.md entry factory 3.9.1
- fit: n/a
- paused: no agent paused
- 5 Whys:
  1. Why does the install differ from the FREEZE line? — the FREEZE line was written at run start (23:12Z) from the install that session ran, 3.9.0, although 3.9.1 had been merged at 22:02Z; the resumed session runs the 3.9.1 cache — evidence: #278 Factory run section; merge commit 2a0219b at 2026-11-27T22:02Z
  2. Why can the install change inside one run? — the run skill continues a run in a fresh session, and a fresh session loads the newest installed release, so a run can span installs — evidence: skills/run/SKILL.md, *Context*; plugin cache holds 3.9.0 and 3.9.1 side by side
  3. Why does a patch release stop the line here? — kind 6 (b) compares the FREEZE token as an exact string, while the release-change rule compares only major and minor and asks nothing on a patch, because a patch changes no standard text — evidence: references/run-andon-detect.md, kind 6 (b); references/run-route.md line 52; CHANGELOG.md factory 3.9.1 ("standard text is unchanged")
  process item to change: kind 6 (b) has no rule for a patch release reached by a fresh session of the same run, and disagrees with the release-change rule, which treats a patch as the same release
- fence check: not run: no override proposed
- countermeasure: none: needs a plugin change
- supersedes: none
- standard change proposed: kind 6 (b) compares major and minor like the release-change rule, and a patch difference with the same standard fingerprint goes on the start-checks line instead of stopping the line
- carried on: 2026-11-27T23:17Z
- waste: waiting

## Refused drafts

none
