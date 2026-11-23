# Result: docs-writer — 245

Status: done
Abnormality: none
Progress:
  Done: brief read (author and marker match); protocol, role file and skills read; owner files read for the getting-started claims (EN and NL), the setup skills, the factory and wayfinding manifests, the run skill steps 1 and 7; `docs/agents/docs-claims.md` written (commit 18aaf2d); role-file rule added to `docs/agents/roles/docs-writer.md` (commit 18aaf2d); `bash tests/run.sh` ALL PASSED; link check clean.
  Next: none. Lead decides the Open questions.
Summary: The claims list `docs/agents/docs-claims.md` has nine rows: six behaviour or relation claims verified against their owner files (C1 to C6) and three Claude Code claims (C7 to C9) that the repo can only echo. A rule in the docs-writer role file says when to reread rows. Two sentences on the getting-started page are not true today and are left out of the list, see Open questions. Names and paths in backticks are checked by `tests/site/names.test.mjs` and stay out. Nothing was installed or run from the quick start.
Artifacts: docs/agents/docs-claims.md; docs/agents/roles/docs-writer.md (section Rules and checks); work/245/01-result-docs-writer.md
Decisions:
  - Left two claims out of the list because they are not true today (the "only for the one-way doors" sentence, and the plugin list in the Home page). Chosen: leave them out and raise them under Open questions. Rejected: listing them as rows that are known false. Cost to undo: add rows once the page or the claim is fixed. Two-way door.
  - Left the Home lede slogan ("Agents do the work; you decide only what can't be undone.") out of the list: it is judgement, not a plugin behaviour the list can check. Cost to undo: add a row if the person wants it watched. Two-way door.
  - Kind `Claude Code` for C7 to C9, with the owner recorded as Claude Code docs. Cost to undo: change the kind column. Two-way door.
  - No changelog entry: no file under `plugins/` changed, so no release (per the brief).
Open questions:
  1. Getting-started, EN and NL, "It comes back to you only for the one-way doors." This is not true today. `plugins/factory/skills/run/SKILL.md` line 88 says the person is also asked in the Heavy band ("the person is asked only on an open one-way door (step 7) or in the Heavy band"). The page is owned by the developer (`apps/site/`). Proposed fix for the developer or the product owner: add "or a Heavy-band slice", or drop "only". Which wording the person wants is theirs to choose.
  2. `apps/site/src/i18n/ui.mjs`, Home `whatP` (EN and NL): "the software factory, wayfinding, design and toolkit plugins". The marketplace (`.claude-plugin/marketplace.json`) lists six plugins; `discover` and `mattpocock-skills` are not named, and the sentence reads as complete. The build check does not cover plugin names in prose. Owner: developer (`apps/site/`). Proposed fix: add `discover`, or say "among others".
  3. No minimum Claude Code version is recorded in this repository. The `Run against Claude Code 2.1.287` lines in `README.md` are test records. C7 to C9 therefore have no version to watch. The lead or the person should say where the minimum lives (for example a line in `README.md`). I did not invent one.
  4. C7 to C9 were not checked against Claude Code's own documentation in this run; the repo has no source for them. They stay in the list as Claude Code rows, unverified here, until someone with that source confirms them.
  5. Not run: the quick start (`/plugin marketplace add`, `claude plugin install`, `/wayfinding:setup-wayfinding-skill`, `/factory:setup-factory-skill`, `/factory:run`). These are install, setup or interactive commands that write user-scope or repo state; the brief's Done list does not ask for them and the run is frozen. The newcomer check of the quick start needs someone with a shell who may run them.
Missing: none
