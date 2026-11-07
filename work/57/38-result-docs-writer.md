# Result: docs-writer — 57

Status: done
Progress:
  Done: 18c2557 tracker doc (Factory operations section now equals the setup template: ten new bullets); 991787c reference entries for the five 57-* contracts, index moved to 1.2.0; 2decf46 README (baseline and A3 section, 1.2.0 status, 1.2.0 checks); 5725724 CHANGELOG entry factory 1.2.0; 6c6f258 wording checked against the demo outcome (pin, paper-only security check, stopped-run marking)
  Next: none. Handed back to the lead; the install, setup and run steps are open (see Missing and Open questions).
Summary:
- Four files edited, all in the docs scope of the brief; nothing under plugins/, hooks/, scripts/, tests/, contracts/ touched.
- CHANGELOG: one `factory 1.2.0 (#57)` entry above 1.1.0, same sections as the file's existing entries. Known limitations are the open verdict items (QA round 3 pass with the human-only and post-merge list; security round 3 pass with info I1 and I2) and the demo's not-exercised criteria.
- reference.md: index at 1.2.0 with fourteen contracts; five new entries for the 57-* contracts (baseline, A3, records and overrides, run close, standard changes); 39-hansei-record and 49-overrides entries say what changed.
- issue-tracker.md: the Factory operations section replaced by the setup template's section (diff is ten added lines).
- README: new "The baseline and the A3" section, status paragraphs for 1.2.0 and 1.1.0, hansei v4 marker, stale "no baseline yet" line replaced, a 1.2.0 "What was tested" block from commands run today.
- Demo outcome as recorded on #57: AC-10 pass, AC-21 pass (no experiment), AC-31 pass, AC-30 first half pass. Not exercised: experiment before and after, keep/promote/drop on a real override, paused-agent context (#49 AC-9), AC-30 second half. The cancelled-agent refusal was enforced by the harness, and the docs say so.
- Commands run (read-only or validate-only): claude plugin validate on ., ./plugins/factory and ./plugins/factory/skills (all pass); claude plugin list --json (factory still 9147301f75c3); git fetch origin main and check-bump.sh (pass 1.1.0 -> 1.2.0, exit 0); fingerprint.sh (release 1.2.0; tooling equals 1.1.0; standard equals QA's); bash tests/run.sh (ALL PASSED, 1436 passed, 0 skipped, exit 0); the four tracker lookups from the new template against this repo (each exit 0, no line).
Artifacts:
- /Users/wimsuenens/Projects/portfolio/wt/57/README.md
- /Users/wimsuenens/Projects/portfolio/wt/57/CHANGELOG.md
- /Users/wimsuenens/Projects/portfolio/wt/57/docs/factory/reference.md
- /Users/wimsuenens/Projects/portfolio/wt/57/docs/agents/issue-tracker.md
- /Users/wimsuenens/Projects/portfolio/wt/57/work/57/38-result-docs-writer.md
Decisions:
- Two-way: the tracker doc takes the whole template section, not only the ten bullets, so that this repo's copy and the template stay byte-equal in that section. Chosen over a bullets-only insert. Cost to undo: revert 18c2557.
- Two-way: CHANGELOG and README cite this repo's #57 and #34 by link, as the 1.0.0 and 1.1.0 entries do. No sandbox name, sandbox issue number or sandbox URL appears in any of the four files; the demo's one agent-plugins issue is not cited. Cost to undo: text only.
- Two-way: the README "What was tested" block for 1.2.0 records only what I ran today; the 1.1.0 block is kept as history. Cost to undo: text only.
- Two-way: security I1 (failed `gh api user` reads as none) and I2 (cosmetic span overshoot) and the one unexplained suite failure (QA R3-O3) are listed as known limitations, not dropped, because their verdicts keep them open. Cost to undo: text only.
Open questions:
1. AC-16 second half: QA round 3 lists it as open. The Lead's comment of 19:50 on #57 reports it passed (two fresh readers, same 21 line keys). I followed the Lead's comment and did not list it as open. Please confirm, or ask QA to record it in the verdict.
2. Runbook (devops-owned, not edited): "Monitoring added by 1.2.0" in docs/factory/release-runbook.md says the Factory baseline issue and the A3 are "written by the Lead at run close". The contract (57-baseline AC-1) creates the baseline at run start, and it is updated at each item close (step 8.10) and at run close (9.1, 9.3). Proposed fix for devops: "created at run start (step 0), updated at each item close, at run close and after the settle merge; the A3 is written at run close".
3. Demo-script findings recorded on #57 (for the product owner and the lead, not docs): the developer finished 13 s after the note, too fast to stop; the third slice had no developer stage; the script needs a slice that writes an override, for AC-28 and AC-30. The next demo needs these before its results can be read as passes.
4. Install, setup and run steps are not executed (see Missing). The docs' quick starts that change user-scope or repo state were not run, because the install is frozen.
Missing:
- The Done item "setup, run and deploy steps executed exactly as documented" is open. Not run, with reasons: `claude plugin marketplace add`, `claude plugin install`, `/plugin` and `/reload-plugins` (frozen install 9147301f75c3, ADR 0012, and the freeze holds for every project on the machine); `git init` and `gh repo create` (repo state, and the repo already exists); `/wayfinding:setup-wayfinding-skill` and `/factory:setup-factory-skill` (interactive, they write to the repo); `/factory:run` (interactive, runs the factory). I read the setup skill and the run skill's start and close text, but none of these was run against this release. A person with a shell on an unfrozen machine should run the install and the setup once after the freeze ends, and `/factory:run` on a scratch project.
