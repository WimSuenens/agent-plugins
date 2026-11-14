# Result: qa-engineer — 225
Status: done
Abnormality: none
Progress:
  Done: stale assertions replaced; acceptance tests written (agents.test.mjs, section.test.mjs, oracle-agents.mjs, reference.test.mjs moved to Skills); validated against a throwaway reference site (full tests/site suite green there: 264 tests, 1 skip for actionlint) and mutation-checked with 7 mutants (all killed).
  Next: the lead puts the targeted test in the developer's brief.
Summary:
  Targeted test (start here, no build needed): `node --test --test-name-pattern="^loader: the shape" tests/site/agents.test.mjs`
  Now fails with ERR_MODULE_NOT_FOUND for apps/site/src/lib/agents.mjs (the loader does not exist yet). Next ones, in order: the other `loader:` and `AC-5 loader:` tests in the same file (also no build), then the `AC-` tests of agents.test.mjs and section.test.mjs (need the build), then the full suite: `node --test --test-concurrency=1 tests/site/*.test.mjs` from the repo root.
  The suite needs `cd apps/site && npm ci` and playwright chromium first.
  Everything that builds is red until the developer finishes (the Agents page, Skills and Reference routes do not exist). Old assertions that contradicted the contracts are replaced: pages (lines 28, 54, 194), routes (AC-3, AC-4), switcher (AC-4, AC-15, 320px label Naslag), getting-started (AC-20), wiki (tree, AC-24), links (control), look (tab order), a11y (count), oracle (top bar link), lib (ROUTES now ten).
  The developer's own `apps/site/test/pages.test.mjs` and `ui.test.mjs` still need their updates (section 8 of the section contract).
  AC map: AC-1,2,3,4,5,6 agents.test.mjs (loader called directly for exact messages; builds for the page and for failing builds); AC-7 agents.test.mjs (rebuild fixture, English and Dutch, plus back); AC-8 agents.test.mjs (real, fixture, rebuild, typed-count scan with a control); AC-9 section.test.mjs (git diff against the merge-base with main, checked against the Paths blocks and the frozen file list); AC-10 section.test.mjs plus oracle verifyBuild on all pages; AC-11 section.test.mjs (overview) plus oracle see-also; AC-12 section.test.mjs (drafts line, notices, the reviewed edit on a site copy); AC-13 section.test.mjs, routes, switcher; AC-14 agents.test.mjs and reference.test.mjs; AC-15 reference.test.mjs (Skills, both languages) and agents.test.mjs (ids); AC-16 a11y.test.mjs (real `npm run build`, ten pages); AC-17 agents.test.mjs (320 px, real and a fixture with a very long unbreakable tool name); AC-18 section.test.mjs and oracle (one script); AC-19 untestable before merge (post-merge, deployed site).
  Human-only criteria: none. (The Dutch intro text is an agent draft; its quality is not judged by a test and the draft notice says so.)
Artifacts: tests/site/agents.test.mjs, tests/site/section.test.mjs, tests/site/oracle-agents.mjs, tests/site/reference.test.mjs, tests/site/oracle.mjs, tests/site/lib.mjs, and edits to pages, routes, switcher, getting-started, wiki, links, look, a11y tests.
Decisions: Dutch Reference tests pin the label "Naslag" (decided in the requirement) and the Dutch tools label by pattern /hulpmiddel/i (contract gives "Hulpmiddelen:"); the top bar's Dutch Reference link is asserted to go to /nl/reference/ with no hreflang=en, label from the page tree. The contract's loose points (error text for a non-mapping frontmatter) are asserted only by the `reference: <rel>: ` prefix. Reversible by editing tests/site.
Open questions: none
Missing: none
