# Result: qa-engineer — 156
Status: done
Abnormality: none
Progress:
  Done: tests for every scriptable criterion written in tests/site/ (commits "#156 qa-engineer: ..."); confirmed they fail now because apps/site does not exist
  Next: verification round after the build (full suite, fault copies, review reviews/qa-156.md)
Summary:
  Eight files in tests/site/, run with Node's test runner; they need the site installed first: `cd apps/site && npm ci && npx playwright install chromium`, then from the repo root `node --test tests/site/*.test.mjs`.
  Targeted test (developer's first target): `node --test tests/site/routes.test.mjs`. It builds the site with `npm run build:site` (SITE_OUT_DIR set to an absolute scratch path, SITE_BASE=/agent-plugins) and checks the three routes, base-path references, switcher markup and the single inline script. Today it fails with "npm run build:site failed" because apps/site is absent.
  Other commands: `node --test tests/site/switcher.test.mjs`, `reference.test.mjs`, `look.test.mjs`, `a11y.test.mjs`, `workflow.test.mjs` (the last needs `yaml` from apps/site/node_modules, so also an `npm ci`; today "Cannot find module 'yaml'").
  Expected skill counts are computed from plugins/*/skills/*/SKILL.md and re-parsed with the yaml package; nothing is hard-coded.
  Traceability (AC to file): AC-1,2,3,4,5,12 routes.test.mjs; AC-6 to 11 switcher.test.mjs (AC-10 as the proxy: script in head before body, body hidden while pending, tested with a delayed /nl/); AC-13 to 18 reference.test.mjs (real plugins plus fixtures for rebuild, odd characters, optional and broken fields, zero sources, git status unchanged after build); AC-19 machine part, 20, 21, 22, 23 look.test.mjs; AC-24, 25 a11y.test.mjs (real build, fault copies, usage errors, navigation error); AC-26 workflow.test.mjs (actionlint test is skipped when the binary is missing; it is not installed here).
  Not scripted, left to people or the first deploy: AC-27 (live URL, after the merge on main; the contract's post-merge proof is the check), H-1 look matches prototype A (AC-19 visual), H-2 Dutch reads naturally, H-3 no visible flash on a return visit (AC-10 real device), H-4 VoiceOver pass (AC-23). Visited-link contrast (AC-20) cannot be read in a browser (computed style hides :visited), so it is left to the axe pass and a human glance.
  Assumptions the developer should know: SITE_OUT_DIR may be absolute; the check script is run with cwd apps/site; `npm run check:a11y` reads SITE_OUT_DIR and SITE_BASE; `npm run build` tests expect `a11y: 3 pages checked, 0 violations` as the last stdout line.
Artifacts: tests/site/lib.mjs, routes.test.mjs, switcher.test.mjs, reference.test.mjs, look.test.mjs, a11y.test.mjs, workflow.test.mjs
Decisions: DOM facts are read through Chromium (Playwright from apps/site) rather than an HTML parser, so the suite adds no dependency of its own / rejected: a separate parser package; cost to undo: small
  Tests are plain node:test files, not wired into tests/run.sh (the bash runner), because they need npm ci and Chromium / cost to undo: one line in run.sh
Open questions: none
Missing: none
