# Result: developer — 156
Status: done
Abnormality: none
Progress:
  Done: added a `heading` string next to `title` in apps/site/src/i18n/ui.mjs (en and nl: "Agent plugins") and the Home h1 now uses it; unit test added. Committed as "#156 developer: separate page headings from document titles".
  Next: QA re-verification.
Summary:
  Home h1 reads "Agent plugins" in English and Dutch; document titles stay "Agent plugins - Home" / "Agent plugins - Thuis" (unique, AC-23).
  Reference page: its h1 is the literal "Reference" and its title "Reference - Agent plugins", so no title string feeds the heading; no change needed. No Dutch Reference page exists.
  Re-verify run: build:site green (scratch plugins copy with the two descriptions quoted); `node --test --test-concurrency=1 tests/site/routes.test.mjs tests/site/look.test.mjs tests/site/a11y.test.mjs`: 39 of 39 pass. Those tests delete PLUGINS_DIR, so I quoted the two SKILL.md files in the worktree plugins/ for the run and restored them with git checkout; nothing under plugins/ is committed. `npm test` in apps/site: 18 of 18 pass.
  No QA test asserts the old heading text; no question needed.
Artifacts: apps/site/src/i18n/ui.mjs, apps/site/src/components/Home.astro, apps/site/test/ui.test.mjs
Decisions: field named `heading`, Reference heading left as a literal / rejected renaming `title` / cost to undo: one string
Open questions: none
Missing: none
