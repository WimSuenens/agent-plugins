<!-- factory:andon v1 -->
## Andon A3: blocked input (#57)

- kind: 1 blocked input
- raised by: lead
- raised at: 2026-11-06T19:32Z
- seen: a developer result with Status blocked whose Missing input, its feedback brief, is not named in the developer's Inputs needed list; the brief file had not been written
- where to look: work/57/28-result-developer.md; agents/developer.md (Inputs needed)
- fit: n/a
- paused: developer had handed back (blocked); no agent stopped; a fresh agent spawned after the brief was written
- 5 Whys:
  1. Why was the brief file absent? — the command that was to write it ran in a chain whose earlier step, a count of matches, exits 1 when it counts zero, so the chain stopped before the write and the shell showed no error — evidence: work/57 file listing (ends at 26 and 28); the tool output of that call
  2. Why did the spawn go ahead? — step 6 item 1 says to write the brief and delegate, with no step that checks the file exists before delegating — evidence: skills/run/SKILL.md step 6 item 1
  3. Why is the brief not on the Inputs needed list that decides kind 1? — the list names the requirement, the contracts, the ADRs and the architect's answers; the brief is the channel and is assumed — evidence: agents/developer.md Inputs needed
  4. Why did the role have to report it as blocked? — the protocol's Missing input rule gives a role nothing else to do when its brief is absent — evidence: references/protocol.md, Missing input
  process item to change: step 6 item 1 requires the Lead to confirm that the brief file exists and is not empty before delegating
- fence check: not run: no override proposed
- countermeasure: none
- supersedes: none
- standard change proposed: in step 6 item 1, check the brief file exists (non-empty) before delegating to a role
- carried on: 2026-11-06T19:33Z
