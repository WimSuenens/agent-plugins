# Role file: qa-engineer

Project rules, checks and knowledge for the qa-engineer role, kept under version control. Only the qa-engineer role reads this file and its skills folder, `docs/agents/skills/qa-engineer/`.
It may add rules, checks and knowledge. It never lifts a protocol guard, an ownership rule or a one-way-door rule; such a line has no effect and the lead reports it.

## Rules and checks

- Site acceptance suite (`tests/site/`): fixtures are builds of a copy of `apps/site` (`lib.siteCopy` + `buildCopy`, node_modules symlinked, a build is about 2 s); never edit the real pages. Expected pages, tree, breadcrumbs, see-also and counterparts come from `oracle.mjs` reading `src/data/pages.mjs`, never from a typed-in count.
- Before the build exists, validate new site tests against a throwaway reference site in the scratchpad (copy of repo `tests/`, `apps/site`, `plugins/`, `.github/`), then kill-test it with 3 to 6 one-line mutants.

## Knowledge

- Reference-build trap (188): a contract pair can contradict (a11y rule "nav must hold a link" vs a breadcrumb that is one plain item); the reference build is where it shows. Ask the lead before pinning either side.
- A source-scan test for "no hard-coded URLs" must look for quoted URL strings (`"reference/"`, `/agent-plugins/`), not bare slugs: slugs are legitimate data keys (component keys, model calls). Keep a control that the scan can fail.
- Helpers shared by two site test files go in a non-`.test.mjs` module (`oracle.mjs`, `oracle-agents.mjs`): importing one test file from another registers its tests and hooks again.
- Run the site suite as `node --test --test-concurrency=1 tests/site/*.test.mjs` (a directory argument runs nothing; the whole suite takes about 4 minutes). A loader written as a plain `.mjs` is tested directly by `import()` for exact messages, and through `PLUGINS_DIR` builds for the page.
- A worktree has no `apps/site/node_modules` until `npm ci` there; a throwaway reference worktree can symlink it.
- `paths.sh check` takes the contract glob as a quoted literal prefix argument; an unquoted `contracts/<id>-*.md` is expanded by the shell and every contract then reads as off-list.

## Skills used

## Migrated memory

<!-- migrated: factory-qa-engineer/feedback_clean_checkout.md -->
---
name: verify-in-clean-checkout
description: In a shared factory worktree, run the verdict suite in a temporary detached git worktree at HEAD plus only QA's own test files
metadata:
  type: feedback
---

When another role (developer) may have uncommitted changes in the same item worktree, verify on the committed build: `git worktree add --detach <scratchpad>/wt-qa HEAD`, copy only QA's changed test files in, run the test suite there (set any env vars the suite needs explicitly, since sibling-path discovery breaks outside the usual layout), then `git worktree remove --force` + `prune`.

**Why:** the lead warned mid-task that the developer was building the next iteration in the same worktree; a run there tests a moving target and the verdict would not match any commit.

Lighter alternative when no build step needs git: `git archive HEAD | tar -x -C "$(mktemp -d <scratchpad>/clean.XXXXXX)"`. It needs no cleanup (removal is under Claude Code's safety check anyway). Tests that need git history will skip there, so note that.

**How to apply:** every factory re-verification round; record in the review which commit the verdict is for. Commit only QA-owned paths (`git add <explicit paths>`), never `-A`, because others' edits sit in the tree.

<!-- migrated: factory-qa-engineer/feedback_extract_and_run_text_commands.md -->
---
name: extract-and-run-text-commands
description: Testing command blocks written inside an instruction file - cut them out and run them on generated inputs; what such runs exposed and how to keep readers independent
metadata:
  type: feedback
---

When a standard's text holds command blocks the Lead runs (factory #60 gemba walk): extract the fenced block from the file itself, fill the `<placeholders>` with sed, run it on generated fixtures (200k transcript, missing file, non-JSON file, brief longer than the cap). Do not re-implement the command in the test.

What it exposed that text pins cannot: counts printed on top of a cap (30027 bytes for a 30000 cap), a cut last line gluing the next `wc -c` number to it, a pipeline (`view | head -c`) hiding the tool's exit status so a missing input looks like an empty-but-valid result, a log format missing the field a later filter needs.

Craft: heading scans must be fence-aware (a template holds `### Measures` inside its fence); fixtures need a trailing newline or numeric lines glue; for a counted rule write the expected rows by hand and commit them before any reader, then two readers in different languages (python, awk) sharing no code, plus a permuted-columns log; derive fixtures from tracker logs keeping only the columns the rule reads, renamed ids. Mutation-check with FACTORY_ROOT pointing at a sed-edited copy of the plugin. A bare home-prefix search flags a sentence that merely names the prefix: require a name segment.

**Why:** the walk's AC-6 and AC-5 held on paper; the runs found four low defects.
**How to apply:** any item where the standard embeds shell/jq/awk. Related: [[text-criteria-in-instruction-files]], [[rule-replay-judgment]].

<!-- migrated: factory-qa-engineer/feedback_known_defect_tests.md -->
---
name: known-defect-tests-as-skips
description: How to keep "the suite passes" while blocking a release — reproduce each defect as a Skip-with-finding-id test
metadata:
  type: feedback
---

When a brief requires "the test suite passes" but QA finds defects, write the reproducing test, run it once to confirm it fails, then mark it skipped with the runner's skip mechanism and a reason such as `QA-<id> finding Fn: <actual vs expected>; <owner> fix`. The verdict (block) lives in the review, not in a red suite. Re-verifying a fix = removing the Skip.

**Why:** factory briefs list both "suite passes" and "verdict given"; the developer used the same convention for a known failure, and it keeps the defect reproducible without breaking other roles' runs.

**How to apply:** any factory QA item. Also: probe the criterion's *own literal fixture* (e.g. "panel filled edge to edge with one colour") — it found a real normaliser defect a friendlier fixture hid. Use word boundaries when grepping code for banned names ("separatorchar" contains "torch").

When the fix lands, turn the `if … else skip` into a plain check and mutation-check it: copy the plugin to a scratch dir, put the pre-fix file back (`git show <fix>^:<path>`), and run the suite against it (for example with a `FACTORY_ROOT`-style override). Tests that pass on both versions prove nothing. Example: macOS `mktemp` with no template ignores `$TMPDIR`, so a "no temp file left behind" test that sets TMPDIR passes even with the trap removed.

Taking over an uncommitted checks script from a stalled agent: before committing it, mutation-check it in a scratch `git clone` (break the code, commit, run the script there) and confirm it prints "not ok" and exits non-zero. Pick mutants that actually differ on the tested inputs. Under bash, `echo "Hello, $x!"` gives the same output as `printf '%s'` for `-n`-free names, so it is an equivalent mutant, not a gap in the checks.

<!-- migrated: factory-qa-engineer/feedback_ports_and_processes.md -->
---
name: ports-and-processes
description: Live-service test harnesses - pick free ports at runtime, bind 127.0.0.1, and never kill a process by port without checking it is yours
metadata:
  type: feedback
---

Never kill a process found by `lsof -ti:<port>` without first checking its command line is one I started. Harnesses that spawn servers (API, web dev server) must take OS-assigned free ports (`net.createServer().listen(0, '127.0.0.1')`) and bind and fetch 127.0.0.1, not `localhost`.

**Why:** in a factory QA round I hard-coded port 5190 for a Vite web server. An unrelated user app already held 127.0.0.1:5190. Vite bound ::1 and my fetches to `localhost` hit the other app, which gave false screen failures. Then I "cleaned up" the port and killed the user's app.

**How to apply:** any suite that starts services. Make after-hooks robust (each cleanup step in its own try, stop servers before anything that can throw), or orphans keep ports busy. Related: [[verify-in-clean-checkout]].

<!-- migrated: factory-qa-engineer/feedback_prebuild_control_impl.md -->
---
name: prebuild-control-implementation
description: Tests stage (before the build exists) - validate new tests against a throwaway reference implementation in the scratchpad so reds are the missing build, not typos
metadata:
  type: feedback
---

When writing tests before the build, write a throwaway reference implementation of the script (from the contract) and minimal contract-conforming text edits in a scratch copy of the plugin (scratchpad, never committed), then run the suite with `FACTORY_ROOT=<scratch copy>`.

**Why:** in #94 this caught awk "move a line" helpers that read the line after it was already passed (empty), a wrong expectation (`none` is a reason-rule refusal, not a grammar one), and tests whose expectation depends on an implementation choice (which key is flagged out-of-order after a move) - all before the developer saw a false red.

**How to apply:** assert exact output only where the contract fixes it; for ambiguous cases assert exit code plus "an out of order line exists". Also grep old tests that compare a template block with `main` or count `   - ` lines; adding lines to a record template breaks them (test_gemba t6, test_standard_text keys()).

<!-- migrated: factory-qa-engineer/feedback_replay_real_evidence.md -->
---
name: replay-real-evidence
description: When re-judging a failed human-only criterion on QA's word, replay the fix on the failed run's real data (transcripts, logs), not just on the spec's own examples; Claude Code transcript shapes for stalls/sleeps
metadata:
  type: feedback
---

When a fix round claims to repair a criterion that failed in a live demo, and the person accepts on QA's word, replay the new rules on the demo's real artifacts (they are often still on disk: `~/.claude/projects/<project>/<session>.jsonl` and `.../subagents/agent-<id>.jsonl`). Also run any command the text embeds against them. Fixtures written from the contract inherit the contract's assumptions.

**Why:** in factory #39 (schema v2) the contract's examples all added up, but the demo's transcripts showed (a) the documented "start = `tail -n 1` timestamp" returned the notice time, because the watchdog writes `[Request interrupted by user]` at the moment of the notice, and (b) agents silently recover from mid-run cut-offs (isMeta user "Your response above was cut off mid-stream…", assistant `isApiErrorMessage: true`, `error: server_error`, "API Error: Your computer went to sleep mid-response"), with no failure notice. That was about 71m invisible to notice-based rules.

**How to apply:** for any metric or detection rule built on observed events, scan the real data for every event shape (`jq` over `type`, `isMeta`, `isApiErrorMessage`, `error`), and run a mechanical detector over a large real sample to count false positives *and* false negatives. Copy the shapes into inline fixtures, because real transcripts expire after `cleanupPeriodDays`. Paths under `~/.claude/projects` start with `-`, so prefix `./` or use absolute paths for jq, grep and basename. When the demo's own state file is incomplete (#39: the lead state stopped at Open PR), rebuild the measure from the replayed detector lines plus git commit times per role, and show the arithmetic in the verdict. Related: [[known-defect-tests-as-skips]], [[text-criteria-in-instruction-files]].

<!-- migrated: factory-qa-engineer/feedback_replay_requirement_examples.md -->
---
name: replay-requirements-own-examples
description: In a rule-replay QA task, write the requirement's own worked cases as controls; contradictions between two rules of the same text show only when the example is run through the written order; also check "when" a step happens
metadata:
  type: feedback
---

When a contract fixes rule text for the Lead (factory #57 baseline/A3), build a small reader of the text (python3 -I, `# READING:` comments at each silent spot) and run the requirement's OWN cases through it in the written order, expected values committed first. Also look for ordering gaps: a rule that says "decide now" but whose worktree/stamp exists only later.

**Why:** #57 passed every contract example, but the requirement's "release moved 1.2 to 1.3" case came out as "no after-item": section 6 dropped the other-series item before section 7 could see it. A second finding came from reading the step order, not the rules: the between-items experiment had no slot before the Start-item stamp, so the next item would be a during-item.

**How to apply:** per rule group, one ledger JSON per case plus an expected tsv; named skip per finding (see [[known-defect-tests-as-skips]]). Real sandbox records: replay from a scratch file, report pass/fail only, delete by `rm -f "${S:?}/${f:?}"` (a bare `"$S/$f"` is blocked). Mutation-check text pins by retargeting: a marker mutant that hits prose instead of the template stays green, so pin template and prose separately. Related: [[rule-replay-judgment]], [[text-criteria-in-instruction-files]].

<!-- migrated: factory-qa-engineer/feedback_round2_reverify.md -->
---
name: round-2-reverify-craft
description: Re-verify rounds in factory items: fixtures the contract lists can hit jq edge cases; reported fingerprints can be stale; moving a pin vs keeping it
metadata:
  type: feedback
---

When a feedback brief asks to add the architect's listed fixtures (empty body, CRLF, other version), run each one alone as well as in the list: jq aborts the whole output on the first error (`"" | split("\n")[0] | test(..)` raises on null), so an empty-body fixture hides every later row. Check the filter with `//` guards before blaming the fixture.

**Why:** round 2 of #57 found the Find baseline filter erroring on an empty body only because the fixture was run alone; a "printed nothing, so create" rule plus a jq error would create a second baseline.

**How to apply:** a contract fixture list is a test list; keep a known defect as a named skip with the finding id, and state the fix expression already verified in the review.

Recompute fingerprints yourself (`git archive <commit>` of the plugin, run the script from the tree under test); the developer's reported standard value was stale in two rounds running. Judge an "old literal kept to keep a pin green" by reading it beside the new text: if the two cannot both be the rule, move the pin to the rule (tolerant of either wording) and file a low finding; if the literal is a real rule, keep it.

When a fixture's old expected value rests on an old rule (an other-series record that carried X), change the fixture to the case the architect describes and add a new fixture for the rest; say so in the review.

<!-- migrated: factory-qa-engineer/feedback_rule_replay_judgment.md -->
---
name: rule-replay-judgment
description: Testing a written rule an LLM Lead applies - commit control pairs before the replay, pin the text, run the mechanical parts, apply the judgment by hand once; what to watch for
metadata:
  type: feedback
---

When a requirement asks QA to "apply the written rule" to real data (factory #49 AC-3, the "same finding twice" rule): (1) write and commit the control pairs alone BEFORE filling signatures, so the order is provable; (2) the ledger fixture holds only the columns the rule reads; (3) fill the judgment slots from the text alone, then let a script apply the clauses mechanically so the table is reproducible; (4) say plainly which parts are judgment and cannot be run without an agent.

Watch for: a contract's own model control that the rule never compares (same role and round); clauses where most hits hang on one judgment (here trigger equality); real repeats the rule misses (list them, do not hide them). Pin the rule's wording with grep tests so a changed rule goes red, and mutation-check those pins.

**Why:** #49 replay: 5 of 5 flagged, 0 of 7 controls, but 4 of 5 hits depended on the "same condition" call, and the contract's example control was uncomparable.

**How to apply:** any QA task on a prompt-text rule (detection rules, fence questions, refusal rules). Related: [[text-criteria-in-instruction-files]], [[replay-real-evidence]].

<!-- migrated: factory-qa-engineer/feedback_shell_harness_gotchas.md -->
---
name: shell-harness-gotchas
description: Bash test-harness traps seen in QA - $? reset by command substitution, Claude Code's removal safety check on rm -rf "$var", variables not persisting across the agent's Bash calls
metadata:
  type: feedback
---

1. Capture `rc=$?` on its own before printing it. `echo "$(basename $f) rc=$?"` prints the substitution's status (0), not the command's.
2. Claude Code's built-in safety check blocks `rm -rf "$var"` and any `bash -c` / `python -c` command whose text contains `rm` (even inside data strings). Never work around it. For scratch work, create a fresh `mktemp -d` dir per run and leave it in place. Run mutation drivers as a Python file (`python3 -I file.py`) that copies the plugin into new temp dirs. Report the leftover dirs.
3. The agent's Bash tool keeps no shell state between calls: variables, functions and `cd` are all lost. When instruction text sets a variable in one code block and uses it in later commands, it only works if everything runs in one call. Test that split as a defect case: an empty var turns `git -C "$w"` into the cwd, and `"$w/x"` into `/x`.
4. zsh (the agent's login shell) reads `$c:r` as a history-style modifier: `git show $c:reviews/x` breaks; write `${c}:reviews/x`. macOS awk (BWK) has no `{n}` regex intervals: validate dates and status grammars with `grep -E` in the shell, not in awk. A section extractor for markdown must track code fences, or a `## ` line inside a fenced template ends the section early.

**Why:** in factory #39 round 5, item 1 almost produced a false "require-end passes cut transcripts" finding. Item 2 blocked two of my own cleanup commands. Item 3 found F4 in the Lead's close commands.

**How to apply:** every QA harness that loops over files, cleans up, or replays instruction-text shell blocks. Related: [[text-criteria-in-instruction-files]], [[known-defect-tests-as-skips]].

<!-- migrated: factory-qa-engineer/feedback_threshold_generalisation.md -->
---
name: check-calibrated-thresholds-across-cases
description: When a threshold is revised on evidence from one case (one scene, one fixture), test it on every other registered case before passing
metadata:
  type: feedback
---

A threshold calibrated or loosened on one case (e.g. a pixel bar judged on one scene) often fails on its siblings. Before the final verdict, parametrise the check over every registered case and report a table. Also look for guards that pass vacuously (a mean over 0 samples reads 0 and passes).

**Why:** in a factory harness item the revised bar (judged on one scene) passed there, but failed on 3 of 5 registered scenes, and one sub-condition was measured over 0 pixels on a whole style — both invisible in the developer's single-case test.

**How to apply:** final-verdict rounds after any "revised on evidence" change. Scope the blocker by the slice's stated scope; record out-of-scope failures as a non-blocking finding with a reproducible skipped test. Build in Release (or a clean worktree) when another role's live instance runs from Debug binaries.

