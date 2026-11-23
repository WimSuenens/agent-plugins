# Result: qa-engineer — 244
Status: done
Abnormality: none
Progress:
  Done: independent verification finished; verdict pass.
  Next: none
Summary: Verdict pass. No blocking defect. Three low observations (below), none against an acceptance criterion or the contract.
  Proof lines for the PR:
  - `node --test tests/site/names.test.mjs`: 26 pass, 0 fail.
  - `node --test tests/site/getting-started.test.mjs`: 9 pass, 0 fail (assertions unchanged; diff is the import and one re-export line).
  - `bash tests/run.sh`: ALL PASSED (about 3.5 min).
  - Off-list: `paths.sh check` of `origin/main...item/244` against the contract's Paths block (ignoring work/244/, reviews, 244 requirement and contract): no `off-list:` line, rc 0.
  - No page edited: the diff holds no file under apps/ or plugins/. No exception list: the source holds no page, token or path list (AC-6 scan test passes; read names.mjs, 139 lines).
  Verdict per criterion (test that covers it, checked by reading it and by mutation):
  - AC-1, AC-2: control tests on inline spans (command, install, marketplace); mutating the marketplace check off made 5 fail.
  - AC-3, AC-10: path tests and the copy-of-plugins tests; path rule off made 6 fail, skillText reading every .md made 2 fail.
  - AC-4 a-d: controls per rule, incl. the Dutch copy; each mutation above failed the matching control.
  - AC-5: handWrittenPages folder tests and real-folder non-empty test; disabling recursion made 1 fail, dropping the language from the label made 2 fail.
  - AC-6: real pages report nothing, source scan finds no list; AC-7: AC-19 input and rendered pre text equal; getting-started suite green.
  - AC-8: look-alike spans give []; path left boundary mutation made 1 fail. AC-9: label and token in faults; order swap made 3 fail.
  Mutations run (10, each restored with git checkout; tree clean): path rule off, skillText any .md, fences dropped from tokens (7 fail), spans dropped (10 fail), marketplace off, no recursion, label without language, path left boundary, front matter not skipped (1 fail), fault order swapped. All were caught.
  My own probes (inputs the controls lack), all behave as the contract table says: backticked path and command inside link text are reported; a path or command in a heading, list-item fence, tilde fence, unclosed fence and CRLF text are read; front matter is skipped; uppercase `/Factory:idea` is not read as a command (AC-19 pattern is lowercase, unchanged).
  Low observations, no action required:
  1. A span wrapped over a line turns the break into a space, so `/factory:` + newline + `no-such` becomes `/factory: no-such` and is not reported; likewise a path wrapped after `docs/agents/`. Matches the contract (line break becomes a space); a page author who wraps inside a name escapes the check. Severity low.
  2. `docs/agents/factory.md.bak` and `docs/agents/factory.mdx` are not reported because the AC-3 pattern matches the existing `docs/agents/factory.md` prefix with no right boundary. Contract does not specify a right boundary; severity low.
  3. Fence indentation of more than 3 spaces still opens a fence (contract says any indent). Intended.
  Human-only criteria: none.
Artifacts: work/244/04-result-qa-engineer.md
Decisions: none
Open questions: none
Missing: none
