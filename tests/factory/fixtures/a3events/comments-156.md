Requirement: 27 Given/When/Then acceptance criteria in five sections, every Under test line mapped to criteria, four human-only criteria, out-of-scope list covers the whole Deliberately faked list.
No one-way door found; two open questions go to the architect (accessibility check tool, Reference page slug).
promote chosen, still in force: none
Decisions: the switcher stores the choice in localStorage (cookie rejected); a return visit redirects only when entering at the English Home, replacing the history entry; on an English-only page the Dutch option goes to Dutch Home; a SKILL.md missing name or description fails the build; the expected skill count is computed in tests; no generated reference data is committed.


-----
Contracts and ADRs: four contracts (site skeleton, reference generator, accessibility check, deploy workflow), no ADR (no one-way door found). Paths parse; no slice in flight to overlap.
code review: no — trigger: no trigger
breadth check follows the build. promote chosen, still in force: none
Decisions: accessibility check is axe-core in headless Chromium through Playwright, failing the build on any violation; one Reference page at /reference/ with a group per plugin; the generator reads plugins/<p>/skills/<s>/SKILL.md with the yaml package and fails on missing fields; switcher storage key site-lang with one inline head script; no motion at all; workflow site.yml builds on pull requests and deploys only from main with narrow permissions; ownership rows added for apps/site (developer) and site.yml (devops).


-----
Tests: scriptable acceptance criteria AC-1 to AC-26 have tests in tests/site/, traceable to the criteria; AC-27 (live URL) and four human-only criteria are not scripted. Targeted test: node --test tests/site/routes.test.mjs. They fail now for the expected reason: apps/site does not exist.
promote chosen, still in force: none
Decisions: DOM facts are read through Chromium so the suite adds no parser dependency; the tests are not wired into tests/run.sh yet (they need npm ci and Chromium).


-----
Build and verification so far: the site builds on the real plugins (a11y check 0 violations) and 81 of 82 tests pass with 1 skipped (actionlint not installed); PR 182 opened with the proof; the docs-writer added a README section, every command run before it was written. breadth: as expected (the ownership rows for apps/site and the workflow are the lead's, in docs/agents/factory.md; the role-knowledge notes are protocol-allowed).
Open: QA verdict and security review next. The first deploy on main proves the live URL (AC-27).
promote chosen, still in force: none
Decisions: README section placed before Deploy; the local viewer is the Astro preview already in the install; no CHANGELOG entry (the site is not a factory release).


-----
<!-- factory:needs-you v1 -->
Asked: 2026-11-12T23:02Z
Cause: run decision
Ask: Please try the site by hand (it runs on your machine at http://127.0.0.1:4781/agent-plugins/) and tell me what you find, for these four checks: (1) look: Home and Reference read as the warm editorial look you chose; (2) Dutch: the Dutch Home reads as natural Dutch; (3) no flash: with Dutch chosen, open the English root and no English page appears first; (4) screen reader: one VoiceOver pass over Home and Reference announces headings, the skip link and the two language options sensibly. Also glance at a visited link for readability. QA and security both pass; these are the checks only a person can do.
Options: pass, or tell me what to fix
After you answer: any fixes go back to the developer and QA re-checks; once these pass I ask you to approve the merge.


Answered: 2026-11-12T23:06Z (pass)


-----
Acceptance demo: the owner ran the four human-only checks (look, Dutch reading, no flash on a return visit, VoiceOver) and passed them; outcome recorded in the ledger as a demo touch.
promote chosen, still in force: none


-----
<!-- factory:needs-you v1 -->
Asked: 2026-11-12T23:06Z
Cause: merge approval
Ask: Merge PR 182 (the documentation-site skeleton: Astro app, English and Dutch Home with the remembered switcher, generated Reference, build-time accessibility check, and the Pages workflow) and clean up? QA and security pass, you passed the four hand checks, and the PR's own checks are green. The merge gate pauses because the change includes contracts. Merging to main starts the first real deploy to https://wimsuenens.github.io/agent-plugins/, which I will watch and report; if it fails I treat it as a finding on this item.
Options: yes or no
After you answer: it merges, the first deploy runs, and I check the live URLs.


Answered: 2026-11-12T23:08:17Z


-----
Resolved: merged in PR 182 and deployed. The first deploy from main succeeded (build and deploy jobs), and the live site answers 200 at https://wimsuenens.github.io/agent-plugins/ (English Home), /nl/ (Dutch Home) and /reference/, with the stylesheet loading under the /agent-plugins/ base path. The live Reference lists 18 skills, the same as the 18 SKILL.md files in the repo.

What the build taught:
- The research on the generator's inputs (#149) was incomplete: two skill descriptions were not strict YAML, and only a real parser found it. The fix shipped as factory 2.13.0 (#168) and the generator now fails the build on bad frontmatter.
- Astro, the base path, the /nl/ scheme with the remembered switcher, the generated Reference and the Actions deploy all held under real load.
- The frame deliberately faked the wiki structure (navigation tree, contents, see-also) while ADR 0022 lists it as part of the chosen look. That gap surprised the owner when the skeleton was viewed. The wiki shell is the next slice.
- The page heading was the browser tab title; the owner found it by viewing the site, and it was fixed in this slice.


-----
