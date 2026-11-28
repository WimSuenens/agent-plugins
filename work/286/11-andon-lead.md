---
andon: A4
item: 286
owner: architect
status: resolved
reason: release contract's pin table names no move for test_run_split.sh, which the contract-required lines fail
since: 2026-11-28T00:09Z
countermeasure: none; QA adds this slice's allow-file in the verification task (developer's option A)
---

<!-- factory:andon v1 -->
## Andon A4: blocked-input (#286)

- kind: 1 blocked-input
- raised by: developer
- raised at: 2026-11-28T00:09Z
- seen: the split check compares every line of the router and the moved references with allow-files per slice; the lines the contracts require are new there, and the release contract's pin table names no allow-file for this slice
- where to look: contracts/286-release.md section 3; tests/factory/test_run_split.sh line 46; tests/factory/fixtures/split/; the developer's question in the result on #295
- fit: n/a
- paused: developer had handed back; no agent paused
- 5 Whys:
  1. Why did the split check fail? — it allows only the router and reference lines listed in a per-slice allow-file, and none exists for this slice — evidence: tests/factory/test_run_split.sh line 46; tests/factory/fixtures/split/ (slice6-added.txt, slice7-added.txt)
  2. Why was no allow-file named in the pin table? — the pin table was built by searching the tests for changed sentences; a check that guards every added line of the router names no sentence, so no search term finds it — evidence: contracts/286-release.md section 3 opening line and its search terms
  3. Why does no step catch that kind of check? — the architect's search item covers texts that state a changed rule, not tests that guard a file's whole content; the same gap A3 shows, by another path — evidence: agents/architect.md, *Done*; andon A3 on #286
  process item to change: a release contract has no step that lists the tests guarding the whole content of a file the slice changes (allow-files, size caps), so such pins are found only when the build runs
- fence check: not run: no override proposed
- countermeasure: none
- supersedes: none
- standard change proposed: the architect's release contract lists, for each standard file it changes, the tests that guard that file's whole content (allow-files, caps), beside the sentence pins
- carried on: 2026-11-28T00:11Z
- waste: defects

## Refused drafts

none
