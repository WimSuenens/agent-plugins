# Result: qa-engineer — 244
Status: done
Abnormality: none
Progress:
  Done: rules module and acceptance tests written, committed; controls mutation-checked; getting-started suite green.
  Next: none
Summary: tests/site/names.mjs holds the three AC-19 rules (moved byte-identical) and the new rules (tokenizer on raw Markdown, path rule, skillText, handWrittenPages, pageFaults), as the contract's signatures say. tests/site/names.test.mjs has 26 tests covering AC-1 to AC-10. getting-started.test.mjs changed by import and re-export only. No real drift found: both pages pass, no page edit needed, no exception list.
  Commands: `node --test tests/site/names.test.mjs` 26 pass, 0 fail. `node --test tests/site/getting-started.test.mjs` 9 pass, 0 fail (assertions unchanged).
  Setup needed in this worktree: `npm ci` in apps/site and `npx playwright install chromium` (node_modules was absent; both are untracked/ignored).
  Control check: each rule was disabled in a copy of names.mjs (git checkout restored it after each run). The path rule, the slash rule, the install-plugin check, the marketplace check, spans dropped from tokens, fences dropped from tokens, skillText reading every .md, handWrittenPages limited to one language, no recursion, path left boundary, path any depth, page label dropped, double-backtick close: each made 1 to 10 tests fail, including the matching AC-4 control.
  AC map: AC-1/2/3/4a-c/8/9 the control tests; AC-4d the Dutch-page test (real nl page with one token changed, per command/install/marketplace/path); AC-5 handWrittenPages tests plus real-folder test; AC-6 real-pages test plus no-list source scan; AC-7 AC-19 input via unknownNames and fenced blocks equal to the rendered pre text (needs the build); AC-10 copy-of-plugins test.
  Human-only criteria: none.
  Paths check: only off-list hit is the contract file itself (my --ignore pattern did not match contracts/244-inline-names-check.md); no real off-list path.
Artifacts: tests/site/names.mjs, tests/site/names.test.mjs, tests/site/getting-started.test.mjs
Decisions: AC-7 rendered comparison reads built HTML <pre> text (no browser), in names.test.mjs / rejected a browser read or a new test in getting-started.test.mjs (its assertions must not change) / cost to undo: one test. Code-span edge cases beyond the contract table (a fence opener whose info string holds a backtick is not a fence; a span does not cross a blank line) follow CommonMark / cost to undo: one line each.
Open questions: none
Missing: none
