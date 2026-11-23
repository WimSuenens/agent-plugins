# Result: qa-engineer — 244
Status: done
Abnormality: none
Progress:
  Done: independent verification finished; verdict pass.
  Next: none
Summary: Verdict pass, no blocking defect; Human-only criteria: none.
  Commands: `node --test tests/site/names.test.mjs` 26 pass, 0 fail; `node --test tests/site/getting-started.test.mjs` 9 pass, 0 fail (assertions unchanged); `bash tests/run.sh` ALL PASSED.
  Off-list: `paths.sh check` against the contract's Paths block printed no `off-list:` line, rc 0. No page edited (no apps/ or plugins/ change); no exception list in tests/site/names.mjs.
  Mutations: 10 run, all caught, files restored, tree clean.
  Low 1: a span wrapped over a line becomes `/factory: no-such` and escapes the check (matches the contract).
  Low 2: `docs/agents/factory.md.bak` and `.mdx` are not reported (path pattern has no right boundary; contract silent).
  Low 3: a fence indented more than 3 spaces still opens a fence (contract says any indent).
  Per-criterion mapping and probe details: see Details below.
Artifacts: work/244/04-result-qa-engineer.md
Decisions: none
Open questions: none
Missing: none

Details
Verdict per criterion (test, checked by reading and by mutation):
- AC-1, AC-2: controls on inline spans (command, install, marketplace); marketplace check off made 5 fail.
- AC-3, AC-10: path tests and copy-of-plugins tests; path rule off made 6 fail, skillText reading every .md made 2 fail.
- AC-4 a-d: one control per rule incl. the Dutch copy; each mutation failed the matching control.
- AC-5: handWrittenPages folder tests and real-folder non-empty test; no recursion made 1 fail, label without language made 2 fail.
- AC-6: real pages report nothing, source scan finds no list. AC-7: AC-19 input and rendered pre text equal; getting-started suite green.
- AC-8: look-alike spans give []; path left boundary removed made 1 fail. AC-9: label and token in faults; fault order swap made 3 fail.
Mutations: path rule off (6 fail), skillText any .md (2), fences dropped (7), spans dropped (10), marketplace off (5), no recursion (1), label without language (2), path left boundary (1), front matter not skipped (1), fault order swapped (3).
Probes beyond the controls, all as the contract table says: path and command in link text reported; heading, list-item fence, tilde fence, unclosed fence and CRLF text read; front matter skipped; uppercase `/Factory:idea` not read as a command (AC-19 pattern is lowercase).
