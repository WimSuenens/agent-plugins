---
andon: A3
item: 286
owner: architect
status: resolved
reason: contract 286-release section 3 omits a test pin that the sister contract changes
since: 2026-11-27T23:50Z
countermeasure: none; QA moved the pin; architect adds it to the table in the same role task as A2
---

<!-- factory:andon v1 -->
## Andon A3: blocked-input (#286)

- kind: 1 blocked-input
- raised by: qa-engineer
- raised at: 2026-11-27T23:50Z
- seen: the release contract's pin table leaves out a test check (test_slice2_loop.sh line 195) on the sentence `when its marker is v2 or v3`, which the A3 contract changes; QA found and moved it
- where to look: contracts/286-release.md section 3 (pin table) and line 56 (search terms); contracts/286-release.md line 63 (the same sentence in the stale-text table); tests/factory/test_slice2_loop.sh line 195
- fit: n/a
- paused: qa-engineer had handed back; no agent paused
- 5 Whys:
  1. Why was the pin missing? — the term `v2 or v3` was not in the search terms run over tests/factory/, although the stale-text table lists the same sentence in a3.md — evidence: contracts/286-release.md line 56 and line 63
  2. Why did the two tables use different terms? — the pin table and the stale-text table were built from separate searches; the contract has no rule that each changed sentence of the stale-text table is also searched over the tests — evidence: contracts/286-release.md section 3 opening line (search over tests/factory/ for each sentence changed)
  3. Why does no rule tie them? — the architect's Done asks for the repo to be searched for every text stating a changed rule, but does not name the test suite as a place whose pins follow from that same list — evidence: agents/architect.md, *Done* (the `grep -rn` item)
  process item to change: the pin table of a release contract is not derived from the same stale-text list, so a sentence found in the plugin text can be missed in the tests
- fence check: not run: no override proposed
- countermeasure: none
- supersedes: none
- standard change proposed: the architect's search item says each stale-text sentence is also searched over the test suite and every hit becomes a pin row
- carried on: 2026-11-27T23:51Z
- waste: defects

## Refused drafts

none
