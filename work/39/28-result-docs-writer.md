# Result: docs-writer — 39
Status: done
Progress:
  Done: start result (101387c); docs for factory 1.0.0 (542f894): CHANGELOG.md, README.md factory section, docs/agents/issue-tracker.md Factory operations replaced, docs/factory/reference.md; CHANGELOG exit-code wording for check-bump (final commit)
  Next: none
Summary:
  - CHANGELOG.md (new): one entry, factory 1.0.0 (#39). Release and tag factory-v1.0.0 (tag made by the Lead at merge), bump levels and the Lead's refusal, hansei record and stage log, two fingerprints, three scripts, pre-1.0.0 fallback, known limitations.
  - README.md, factory section: new "Measurement: the hansei record" (data stays in the project's tracker) and "Versions and updates" (bump rule, check, installs change only on a version change, calibration freeze). Also: the "Why plugin.json has no version" paragraph notes the factory exception; the ADR range is 0001–0012; the validate table reflects today's runs.
  - docs/agents/issue-tracker.md: `## Factory operations` replaced with the plugin patch, verbatim; other sections untouched (diff is that section only).
  - docs/factory/reference.md (new): one entry per contract (4), each with its governed rules, implementing files and acceptance criteria, plus the maintainer procedure for changing the factory.
  - Ran, in the worktree or read-only: `claude plugin validate .`, `./plugins/factory`, `./plugins/factory/skills` (all pass; `.` warns for the four unversioned plugins); `fingerprint.sh plugins/factory` (release 1.0.0, both fingerprints); `check-bump.sh` after `git fetch origin main` (pass, minor needed, 0.0.0 -> 1.0.0); `token-spend.sh --` on the PO transcript of #39 (reproduces the contract example: spend 387472, peak 53942, 11 messages); `bash tests/run.sh` (ALL PASSED, exit 0); the tracker doc's *Find hansei* command on #39 (prints nothing: no record yet); `claude plugin list --json` (read-only: factory 9147301f75c3, user scope, still the frozen install).
  - Not run, on purpose: deploy step 1 (`git init`, `gh repo create`: this repo exists at origin and re-initialising would touch it); deploy step 2 and the Iterating section's `marketplace add`, `install`, `uninstall`, `marketplace update` (they change user-scope plugin state, which the calibration freeze holds; the freeze holds as of the read-only check above); `/factory:setup-factory-skill` and `/factory:run` (interactive slash commands; this repo is already set up, and the tracker patch was applied by hand from step 6); the maintainer's manual `git tag` step (it creates a tag; the Lead tags at merge); *Post hansei* and *Edit hansei* (they write to this repo's tracker).
  - The acceptance demo (AC-9, 12, 17, 18, 19, 21) has not run; the README status line still says "not yet run end to end" and stays until it does.
Artifacts:
  CHANGELOG.md (new)
  README.md (factory section; validate table; plugin.json paragraph)
  docs/agents/issue-tracker.md (Factory operations section)
  docs/factory/reference.md (new)
  Commits: 101387c (start result), 542f894 (docs), final commit (CHANGELOG wording and this result)
Decisions:
  - Per-contract reference lives in docs/factory/reference.md, a new page, because Done needs one entry per contract and the README is already long. Rejected: a section in README. Cost to undo: move one file and fix one link.
  - The CHANGELOG entry has no date line beyond "the release date is the merge date". Rejected: writing 2026-11-04 (the date of writing, not of release). Cost: one line.
  - Fingerprint hashes are not written into any doc, because they move with every edit to the covered files. Rejected: quoting the values from the QA review. Cost: none.
  - README status "drafted, not yet run end to end" is kept until the human-only demo has run. Cost: one line after the demo.
  - Known limitations are listed in the CHANGELOG as they stand in the verdicts, including the round-3 fixes that no reviewer re-verified.
Open questions:
  - Stale fingerprint values in the reviews: the tooling fingerprint at HEAD is 03cfd2ba1afbf19d02e3b77a84b15615375a843a04ad9176a4a806a2d406b05b, but reviews/qa-39.md (c38d86a7…) and work/39/26 (53634291…) carry older values; scripts changed in round 3. The standard fingerprint 86408723… matches QA. The record of this item and the demo must use the value at the demo. For the Lead: a QA re-verify of round 3 (F4–F6, L1a) would close the gap; security has not re-checked L1a after round 3.
  - The Lead creates tag factory-v1.0.0 in Merge PR; until then `check-bump.sh` on main still reads 0.0.0 and the README and CHANGELOG say so.
  - The README status line ("not yet run end to end") changes after the demo. I own README.md, so I will make that edit on the Lead's next brief, once the demo result is in.
Missing: none
