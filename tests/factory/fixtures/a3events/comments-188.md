Requirement: 28 acceptance criteria in six sections, every Under test line mapped to criteria, four human-only criteria, out-of-scope list covers the whole Deliberately faked list; criteria of the skeleton are not repeated.
No one-way door found. Four open technical questions go to the architect; one question is for the owner at the slice review: whether the Dutch Home keeps showing a draft notice until you mark it reviewed (default: draft for both Dutch pages).
promote chosen, still in force: none
Decisions: same slug in both languages so the counterpart is derived; the Dutch tree lists Reference and links to the English Reference, marked as English; Dutch pages carry a draft or reviewed status in the page tree and a visible draft notice; a see-also slug with no page in that language is dropped and a slug missing from the tree fails the build; the tree and contents add no client script; Getting started's commands are checked against the real SKILL.md files.


-----
Contracts and ADRs: three contracts (page tree, wiki components, accessibility landmarks), no ADR (no one-way door found); no other slice in flight to overlap.
code review: no — trigger: no trigger
promote chosen, still in force: none
Decisions: the page tree lives in one data file (src/data/pages.mjs) with derivation and build validation in a lib module; hand-written pages are Markdown with no front matter, an h1 or layout markup is rejected by the build; routes come from two catch-all pages; the navigation tree is always open on a phone and sits in a column beside the text from 48rem, with no script; the contents list is built from the h2 and h3 headings; the accessibility script gains six checks of its own that read stable data hooks (main count, navigation required, named, unique, not empty, current page marked); the Dutch Reference link is labelled in English because it points to an English page; Home carries a breadcrumb that shows only itself; syntax highlighting is off. The lead accepted three deviations from the requirement's wording (tree before main in source, English Dutch-Reference label, Home breadcrumb), the contract governs.


-----
Tests: scriptable acceptance criteria AC-1 to AC-27 have tests in tests/site/ (new: pages, wiki, links, getting-started; the skeleton tests updated, nothing weakened), validated against a throwaway reference site built from the contracts (176 tests, 8 mutants caught); the real tree is red until the build, as intended. Not scripted: AC-28 (live check after merge), visited-link colours, and four human-only criteria. Targeted test: node --test tests/site/pages.test.mjs.
One contract conflict is open and goes to the architect: the accessibility rule site-nav-empty fails any navigation with no link, and Home's breadcrumb is a single plain item with no link, so the build could not pass. QA leans to exempting the breadcrumb.
The owner stopped the run here; the item is resumable with /factory:run #188 and its next step is in the lead state.
promote chosen, still in force: none
Decisions: fixtures are builds of a copy of the site with node_modules linked; Getting started step headings are matched loosely so the owner can reword them.


-----
<!-- factory:needs-you v1 -->
Asked: 2026-11-13T22:47Z
Cause: validation
Ask: Please try the new site pages on your own machine and tell me, per step, pass or fail. Open http://localhost:4781/agent-plugins/ (a local copy is running). 1) Look: on a laptop, the English Home and Getting started should look like prototype A (navigation tree on the left, breadcrumb above the title, contents on the page, related pages at the end), links included after you have visited them. 2) Phone: open the same address on a real phone (or narrow the browser to phone width); the page tree should sit above the text, and the text should not scroll sideways. 3) Keyboard: press Tab from the top; the first stop should be a skip link that jumps past the tree. 4) Language: switch to Dutch with the switcher; Home and Getting started should read naturally and show the draft notice. Tell me which Dutch wording to change. 5) Screen reader: with VoiceOver, open Getting started in English and Dutch; the landmarks (navigation, main) should have clear names. Also still open from earlier: should the Dutch Home keep its draft notice until you mark it reviewed (my default: yes)?
Options: yes or no
After you answer: failed steps go back to the developer to fix and QA checks again; with all steps passed I ask you the merge question.

Answered: 2026-11-13T22:51:30Z


-----
<!-- factory:needs-you v1 -->
Asked: 2026-11-13T22:52Z
Cause: merge approval
Ask: Merge pull request 202 (the wiki shell) and clean up? It adds the page tree, navigation, breadcrumb, contents and see-also, Getting started in English and Dutch, and the landmark checks in the build. QA and security both pass, CI is green, and you tried it and found it good. The deploy runs on its own after the merge; I then check the five live addresses.
Options: yes or no
After you answer: on yes the integrator merges and cleans up, I record the run, and the live site is checked; on no, tell me what to change.

Answered: 2026-11-13T22:54:58Z



-----
Stage summaries for the stages after Tests, posted together at the close (they were not posted one by one while the run moved).

- Contracts, round 2 (architect): the empty-navigation rule exempts the breadcrumb, so Home's breadcrumb stays plain text. Decision: option A, cost to undo one table cell and one condition in the check.
- Build (developer): the page tree, routes, components, Getting started in English and Dutch, and the landmark checks. Targeted test 35 of 35. Decisions (two-way): registry entries carry a third key, validation runs once in a build hook, the Dutch Home's Reference link reads "Reference" marked English.
- Tests, round 2 (QA): the AC-19 helper accepts plugins named in the marketplace file.
- Contracts, round 3 (architect): the contracts now describe the Satteri hast plugin; the paths list gains package.json, its lockfile and the unused url.mjs.
- Build, round 2 (developer): declared the missing dependency at 0.4.9, deleted url.mjs.
- breadth: as expected. The diff stays on the contracts' paths; the three contract files and two role-notes files are the accepted exceptions. code review: no (no trigger). Bump check: pass (no factory paths).
- QA: pass. 177 of 178 tests pass, 1 skipped (actionlint not installed). Human-only: look against prototype A, Dutch reads naturally, VoiceOver, a real phone.
- Security: pass, no critical, high or medium findings. One low note (outside this diff): the language script embeds the build-time base path without escaping a closing script tag; a visitor cannot reach that input.
- Documentation (docs-writer): the README's documentation-site section rewritten for five pages and how to add one.
- Acceptance demo: the owner tried the pages and found them good as is. Overrides in force: none.


-----
