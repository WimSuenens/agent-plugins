# Changelog

One entry per item, newest first. Entries are grouped by plugin. The factory is the only plugin with a version so far: its releases are tagged `factory-v<semver>`, and each tag points at the release commit on `main` (ADR 0012). Other plugins install from their current commit and have no entries here yet.

## factory 2.9.0 (#114 to #119)

Release: `2.9.0`, a **minor** release: six slices of the continuous factory (map [#108](https://github.com/WimSuenens/agent-plugins/issues/108)). The standard text and the tooling change, so both fingerprints change. No `factory-state` change. Restart Claude Code sessions after updating.

Issues [#114](https://github.com/WimSuenens/agent-plugins/issues/114) to [#119](https://github.com/WimSuenens/agent-plugins/issues/119). Contracts [116-improvement-loop](contracts/116-improvement-loop.md) and [119-skill-graduation](contracts/119-skill-graduation.md).

**What changed for the person who runs the factory:**

- **Auto-merge on runtime proof (#114).** The factory runs the application, attaches proof to the PR, and `scripts/merge-gate.sh` merges without you when QA and security pass, CI is green and the proof is there. Contracts, authentication, secrets, data migrations and one-way doors always pause for you, with a plain-language validation script. A security review the lead legitimately skipped counts as `skipped`; QA and the proof are never skipped.
- **Role knowledge in the project (#115).** Each role keeps a role file and a skills folder under `docs/agents/`, under version control; an isolation hook keeps a role out of the others'. Setup migrates old user-scope memory, scanning it first and leaving flagged files behind.
- **Autonomous maintenance cycle (#117).** A maintenance cycle runs only on a concrete signal, files backlog candidates within a per-cycle budget, and never executes a one-way door.
- **Lite measurement and role skipping (#118).** The lead may skip a role for a trivial slice outside the protected areas (`scripts/skip.sh`); the integrator counts skips and compares rework.
- **Improvement loop (#116).** Every finding is classified. A project-local improvement is kept permanently through the role files with a trace row; a factory-fundamental one is drafted as a sanitised proposal and filed only after your approval.
- **Skill graduation (#119).** A project skill used in at least two items or projects can be proposed for a domain plugin, never published, and filed only after your approval.

**Decisions.** ADR [0017](docs/adr/0017-a-run-is-a-cycle-over-a-standing-backlog.md) and [0018](docs/adr/0018-the-factory-merges-its-own-pr-on-runtime-proof.md) are amended; ADR [0004](docs/adr/0004-role-memory-uses-user-scope.md) (role knowledge lives in the project) and [0011](docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md) (local improvements are permanent, overrides still expire) are revised.

**Tests.** New tests cover each script and its text; the version pins move to 2.9.0, and the fences of the run skill are checked as balanced.

Fingerprints for this release, from `scripts/fingerprint.sh` on 2026-11-11: standard `2dfb9cd715b771e99ef16e2e51d65822726cac077a59dcc23720977d032cc0ad`, tooling `5672ca590c7bf5f4134359fadeb2d94c011fa44fdb40701faf4b905e1e346c6c`. Any later change under `plugins/factory/` in this release is a forgotten bump.

## factory 2.8.0 (#113)

Release: `2.8.0`, a **minor** release: the integrator now does the mechanical merge of approved slices (the merge train). The standard text changes, so the fingerprints change. No `factory-state` change. Restart Claude Code sessions after updating.

Issue [#113](https://github.com/WimSuenens/agent-plugins/issues/113), map [#108](https://github.com/WimSuenens/agent-plugins/issues/108). Contract [113-merge-train](contracts/113-merge-train.md).

**What changed for the person who runs the factory:**

- **The integrator merges.** After you approve *merge and clean up?*, the lead gives the integrator the approved slices in the plan's order. For each one, `scripts/merge-train.sh run` rebases on the slice before it, applies the version bump and the changelog line after the rebase, gives a new ADR the next free number when main already uses its own, re-runs the bump check, merges the PR, tags the release, and removes the item's branch and worktree. Parallel slices that share the version or the ADR numbers stop colliding.
- **A clash is resolved or reported, never dropped.** A clash in the version or the changelog is resolved and the line says so; a clash anywhere else, or a missing changelog entry, stops the slice with a message.
- **A failed merge keeps the worktree.** The train stops there, nothing after it runs, and the lead tells you.
- **You still decide.** The integrator never merges a slice the lead did not mark approved, and the lead still sets the card `Done`.

**Tests.** `test_merge_train.sh` covers the script (train order, bump and changelog after the rebase, ADR numbers, failure paths) and the text that says who owns the steps; the version pins move to 2.8.0.

Fingerprints for this release, from `scripts/fingerprint.sh` on 2026-11-11: standard `a97923379320d2f3685648cc9cc34fbd3b029cb6fc0fc335081566d601cc01dd`, tooling `cc109f583e396ab3861aba72bc26c6d95533092e34afc4bacb1c7a64e35e6f0d`. Any later change under `plugins/factory/` in this release is a forgotten bump.

## factory 2.7.1 (#112)

Release: `2.7.1`, a **patch** release: the integrator runs on `sonnet` instead of `haiku`. The standard text changes, so the fingerprints change; no `factory-state` change. Restart Claude Code sessions after updating.

Issue [#112](https://github.com/WimSuenens/agent-plugins/issues/112). Contract [112-integrator](contracts/112-integrator.md).

**What changed for the person who runs the factory:**

- **The integrator's model is `sonnet`.** Its agent file says `model: sonnet`, and the default-model table in `setup-factory-skill` lists it with the developer and devops. The integrator makes the dispatch decisions the lead acts on, so it gets the stronger model. `docs-writer` stays on `haiku`.
- **A project's `## Role models` table** can still override it, as for any role.

**Tests.** `test_integrator.sh` checks the model line; the version pins move to 2.7.1, and the release-delta check in `test_fingerprint.sh` moves its test version to 2.7.2.

Fingerprints for this release, from `scripts/fingerprint.sh` on 2026-11-11: standard `a84cc041001c5d330a836a4466df346656e10dc96d77f172ceeb3329b158f7a5`, tooling `0b4b0e5b78d5d2fab527cc25c0dee0664bde0be2b4c5619a12887bf4b417b0bd`. Any later change under `plugins/factory/` in this release is a forgotten bump.

## factory 2.7.0 (#112)

Release: `2.7.0`, a **minor** release: a new role, the integrator, computes the dispatch plan at each run event. Standard text changes, so the baseline resets. No `factory-state` change. Restart Claude Code sessions after updating: a session keeps the text it read when it started.

Issue [#112](https://github.com/WimSuenens/agent-plugins/issues/112), map [#108](https://github.com/WimSuenens/agent-plugins/issues/108). Contract [112-integrator](contracts/112-integrator.md).

**What changed for the person who runs the factory:**

- **Integrator role.** `factory:integrator` reads the board afresh at each event (intake processed, slice ready, PR opened, merge done, map changed) and returns a plan: which slices start, in which order, which merges come first, and which pause, each with a reason. It keeps no state and writes nothing to the tracker; the lead spawns the roles the plan names.
- **New script `scripts/integrator.sh plan <board.json>`.** It reads a board snapshot and prints the plan and the flow measures (waiting time, lead time, batch size, slices in flight). A value the board does not hold is `not captured`.
- **Priority is unchanged.** The integrator orders slices only within the priority the lead and the person set, and advises a different order when a dependency requires it.

**Not in this release.** The integrator is not yet a value of the board's `Role` field: adding it is left to the next board setup. Its ownership row is in this repo's `docs/agents/factory.md` and in the setup template.

**Tests.** New `tests/factory/test_integrator.sh` (scripts seam and standard-text seam). The version pins, the protocol baseline and the shell-section check now allow the integrator's one shell line.

**Unverified.** Nothing ran in a live factory session; the events are written as text, and the lead's calls to the integrator have not been exercised on a real board.

Fingerprints for this release, from `scripts/fingerprint.sh` on 2026-11-11: standard `e850a6fb09b5f8f1b5243fba24a7525b272706f215e5a6a41907cafc56119bb9`, tooling `0b4b0e5b78d5d2fab527cc25c0dee0664bde0be2b4c5619a12887bf4b417b0bd`. Any later change under `plugins/factory/` in this release is a forgotten bump.

## factory 2.6.0 (#111)

Release: `2.6.0`, a **minor** release: a run becomes one cycle over a standing backlog, and the slice maximum is gone. Standard text changes, so the baseline resets. No `factory-state` change. Restart Claude Code sessions after updating: a session keeps the text it read when it started.

Issue [#111](https://github.com/WimSuenens/agent-plugins/issues/111), map [#108](https://github.com/WimSuenens/agent-plugins/issues/108). [ADR 0017](docs/adr/0017-a-run-is-a-cycle-over-a-standing-backlog.md) revises [0007](docs/adr/0007-factory-owns-destination-and-slicing.md) and [0016](docs/adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md); the glossary terms **Run** and **Parallel limit** are revised (**Run budget** replaces the latter).

**What changed for the person who runs the factory:**

- **A run is a cycle.** It starts with intake and restarts every mechanism (intake, maintenance, improvement, slice building). It ends when the backlog is empty, the budget is reached, or you stop it, and closes with the A3 and baseline as before.
- **A map is long-lived.** It is not dissolved when the backlog empties; the map card goes to `Backlog` and waits for new ideas.
- **No slice maximum.** `parallel-limit` is no longer read. Slices whose path lists do not overlap run side by side with no count limit; overlapping ones wait as `Ready`. A leftover `parallel-limit` line is ignored with a note from `factory-config.sh state`, and setup removes its `## Parallel slices` section.
- **Optional run budget.** `run-budget: <N> tokens` or `<N> hours` in the new `## Run budget` section of `docs/agents/factory.md` (`none` by default). Reaching it starts nothing new; work in flight finishes the step in hand and stays resumable with `/factory:run #<slice>`.
- **`factory-config.sh`** loses `limit` and gains `budget` and `reached <spent>`.

**Tests.** New `tests/factory/test_run_cycle.sh` (scripts seam: budget reading, reaching it, no-limit overlap; standard-text seam: end conditions, map persistence, budget). `test_parallel.sh`, `test_board_script.sh`, `test_board_status.sh`, `test_baseline_a3.sh`, `test_round2_64.sh` and the version pins are updated.

**Unverified.** Nothing ran in a live factory session. Parallel running with no count limit has not been tried on a real project, and the budget is measured by the lead from token and time records, which no script sums for a whole run. This repo's `docs/agents/factory.md` was edited by hand, not by setup.

Fingerprints for this release, from `scripts/fingerprint.sh` on 2026-11-11: standard `cfa85de8fca263c8380b0a71a92b68546e51c53c4d6f199448c9e86f0546595b`, tooling `953bfb2f7e009ee9b44b3a2a9c4103fbe9ce1c44e678d726a6d61115ac25e8c5`. Any later change under `plugins/factory/` in this release is a forgotten bump.

## factory 2.5.0 (#110)

Release: `2.5.0`, a **minor** release: the factory takes ideas in at any time and triages each one to an outcome with a reason. Standard text changes, so the baseline resets. No `factory-state` change. Restart Claude Code sessions after updating: a session keeps the text it read when it started.

Issue [#110](https://github.com/WimSuenens/agent-plugins/issues/110), map [#108](https://github.com/WimSuenens/agent-plugins/issues/108). Contract [110-idea-intake](contracts/110-idea-intake.md). [ADR 0015](docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md) is revised: `Kind` gains `idea`.

**What changed for the person who runs the factory:**

- **File an idea any time.** `/factory:idea <title> -- <details>` files a tracker issue with the label `idea`; so does a plain tracker issue with that label, with no factory installed.
- **Inbox folder.** Files dropped in `.claude/factory-inbox/` (gitignored) become one `idea` issue each at the next run start, and are then removed. A second pass over the same folder creates nothing new. A file the issue body cannot carry (binary, over 60000 bytes, a symlink) or that the secret scan refuses stays in the folder and is reported; nothing is deleted that did not reach the tracker. Setup step 8b asks before it creates the folder and its ignore rule; anything but a clear yes creates nothing.
- **Triage with an outcome and a reason.** At run start the lead reads the upstream triage skill by hand and gives each untriaged idea one of five outcomes, **direction**, **slice candidate**, **research ticket**, **parked** or **rejected**, as a comment with the reason. An idea that touches a one-way door comes to you as a decision card; the lead does not decide it. Ideas not triaged are picked up at the next run start.
- **New script `scripts/intake.sh`**: `dir`, `init`, `file`, `drop`, `untriaged`, `triage`. New skill `idea`.
- **Kind vocabulary.** `Kind` is now map, slice, role task, frontier ticket, idea. A new board is created with it; a board made earlier needs the `idea` option added by hand (setup step 7), and until then ideas are triaged from the tracker and stay off the board. The glossary has **Idea** and **Inbox**.

**Tests.** New `tests/factory/test_idea_intake.sh` with a small stateful `tests/factory/stub-gh/gh`: the scripts seam (every command, removal, idempotence, retry after a failed create, kept files, forged markers, every outcome) and the standard-text seam (outcomes, one-way-door rule, run start, vocabulary, setup, glossary). The `Kind` pins in `test_board_status.sh` and `test_board_script.sh` and the version pins move to 2.5.0.

**Unverified.** Nothing ran in a live factory session or against real GitHub: `intake.sh` was tested against a stub `gh`, so label creation, `--label idea` on `issue create` and the `comments` field of `issue list --json` are as the stub assumes. Adding the `idea` option to an existing board by hand was not tried. This repo's own board does not have the option yet.

Fingerprints for this release, from `scripts/fingerprint.sh` on 2026-11-11: standard `82649bf15f7f1319bf0e0bf1727ca5a8043ddca190e0640a430b335141f48ed9`, tooling `c55b62b6454659b3208f2a58747eff0e2e8f26bb397c5c702aea7b0c4685800a`. Any later change under `plugins/factory/` in this release is a forgotten bump.

## factory 2.4.0 (#109)

Release: `2.4.0`, a **minor** release: factory worktrees move into the project's own agent folder, `.claude/worktrees`, instead of beside the repository at `../wt`. Standard text changes, so the baseline resets. No `factory-state` change, and a project with worktrees at the old location keeps working: setup offers to move them, or the item is finished where it is. Restart Claude Code sessions after updating: a session keeps the text it read when it started.

Issue [#109](https://github.com/WimSuenens/agent-plugins/issues/109), map [#108](https://github.com/WimSuenens/agent-plugins/issues/108). Contract [109-worktree-folder](contracts/109-worktree-folder.md). [ADR 0002](docs/adr/0002-one-branch-and-worktree-per-item.md) is revised on location only.

**What changed for the person who runs the factory:**

- **Worktrees stay inside the project.** An item worktree is `.claude/worktrees/<id>` on `item/<id>`; a frontier round's is `.claude/worktrees/frontier-<map>`, a settle round's `.claude/worktrees/settle-<map>`. Nothing is created outside the project, so no extra permission is asked for.
- **New script `scripts/worktree.sh`.** `add item|frontier|settle <n>` creates the worktree and prints its path; it refuses (exit 3) while the folder is not ignored. `ignore` adds `/.claude/worktrees/` to `.gitignore` and changes nothing the second time. `legacy` lists worktrees at the old `../wt/<name>` (exit 10 when there are any).
- **Setup.** Step 8 of `setup-factory-skill` runs `ignore`, makes the repo's test, lint and search commands exclude the folder, writes the new `## Worktrees` text, and offers **move or finish** for each worktree `legacy` lists. A move is `git worktree move` and needs a yes.
- **Clean-up guard.** Besides the empty path, the close now refuses when the item's worktree is the main checkout (`close: worktree is the main checkout`).
- **Text.** The run skill, the protocol's path rule (`.claude/worktrees/<id>`), the `## Worktrees` section of `docs/agents/factory.md` and its template, the glossary (**Worktree folder**) and ADR 0002 name the new location. This repo ignores the folder in `.gitignore`.

**Tests.** New `tests/factory/test_worktree_folder.sh` covers the script seam (every command, exit codes, `ignore` twice, `legacy`) and the standard-text seam (the location in each text, no `../wt/` left in the standard, the guard run at the new location and against the main checkout). The version pins move from 2.3.1 to 2.4.0 and the path-rule pin in `test_standard_text.sh` reads the new wording.

**Unverified.** Nothing ran in a live factory session, including `git worktree move` on a real project with a running item, and whether Claude Code's own `.claude/worktrees` use collides with the factory's names. The install and update path was not run.

Fingerprints for this release, from `scripts/fingerprint.sh` on 2026-11-11: standard `207df0e9bb4e4788f91fd254ce7ed2b065a50bdb2eb4720ad2f7ae827d06430d`, tooling `cdbfb1d814cbac51c23312b791fc722596d674aeea4b439974aed256e9da2ed0`. Any later change under `plugins/factory/` in this release is a forgotten bump.

## factory 2.3.1 (#106)

Release: `2.3.1`, a **patch** release: `scripts/post-text.sh` and `scripts/board.sh` read a relative file named like `name=value` as a file. No rule, text or output changes, and no project has to migrate. Restart Claude Code sessions after updating: a session keeps the script it read when it started.

Issue [#106](https://github.com/WimSuenens/agent-plugins/issues/106). Before this, awk read such a name as a variable assignment, so the script read nothing, or waited on stdin. Each script now has one helper, `awk_operand`, that returns a relative path as `./<path>` and leaves an absolute path and `-` unchanged. It guards every awk file operand: in `post-text.sh` the draft of `render` and the input of `elide` and `split`; in `board.sh` the file of `table_get`, the `factory.md` and tracker doc reads of `finish`, and the scratch copy of the tracker doc. `-v` values are not file operands and are untouched. Exit codes and output are as before. This is the fix `a3-check.sh` got in 2.3.0, and it closes the known limitation of the 2.3.0 entry.

**Tests.** New `tests/factory/test_awk_operand_guard.sh` runs each path twice, with a plain name and with a file literally named `x=1`, and compares exit code and output. It failed on 10 checks before the fix and passes after. The version pins move from 2.3.0 to 2.3.1 and the fingerprint pin in `tests/factory/test_lean_rules.sh` reads this entry.

**Unverified.** Nothing ran in a live factory session. `post-text.sh` is the scan gate; its `scan` command is unchanged, and the security review of the branch is in the pull request.

Fingerprints for this release, from `scripts/fingerprint.sh` on 2026-11-10: standard `99f1c24c685fc0cfd5fb9b9134596ed2b031bfe2b4f7b40844beb9d389be1930`, tooling `bdb54576a6e0a6e88fd2910d59c7cf874a9132937b42ac9c0d6d7e23d255f992`. The standard fingerprint is the same as for 2.3.0: scripts are in the tooling fingerprint. Any later change under `plugins/factory/` in this release is a forgotten bump.

## factory 2.3.0 (#94)

Release: `2.3.0`, lean extensions to the A3 and the hansei record. This is a **minor** release: it adds lines and one script and removes no rule, so no project has to migrate. A3 v1 comments, hansei v3 to v5 records, and 2.2.0 ledgers and overrides stay valid. New runs post an **A3 v2** (`<!-- factory:a3 v2 -->`). Restart Claude Code sessions after updating: a session keeps the factory skill text it read when it started.

Slice [#94](https://github.com/WimSuenens/agent-plugins/issues/94), map [#93](https://github.com/WimSuenens/agent-plugins/issues/93). Requirement [94-lean-extensions](docs/requirements/94-lean-extensions.md). Contracts [94-a3-v2](contracts/94-a3-v2.md), [94-hansei-lean](contracts/94-hansei-lean.md) and [94-release](contracts/94-release.md); the contract index is [docs/factory/reference.md](docs/factory/reference.md). No ADR: each change is text that a later edit reverts.

**What changed for the person who runs the factory:**

- **#87 waste tags.** An optional `waste:` tag, one of the eight TIMWOODS names (transport, inventory, motion, waiting, overproduction, over-processing, defects, skills), on an andon comment (a last line), on a ledger Waits row (in `What`) and Tasks row (in `Notes`), and on a `## Findings` row (a sixth column). The A3's `waste` line counts the tagged entries per type and says how many were untagged. The tagging guide is in `references/hansei.md`, section 1. Untagged stays valid everywhere.
- **#88 flow efficiency and the per-stage view.** Two sub-lines under measure 1 of the hansei record, derived at close from the ledger's Tasks and Waits tables: `flow efficiency` (agent working time as a whole percent of total lead time) and `per stage` (working and waiting minutes for each stage). The record stays at v5. Nothing is stored, and the baseline and the A3 measure table do not read the sub-lines.
- **#89 the target.** An experiment may state an optional `target:` line, written with the override and never edited. The A3's `target` line reads `reached`, `not reached` or `none (<reason>)`, and the settle question shows the target beside before and after.
- **#90 the targeted walk.** One walk per run, at the stage or role the problem points at, before the A3's chain is written. The A3's `gemba (targeted)` line holds its result, and the chain cites it. A difference is evidence for the chain; it raises no andon.
- **The A3 check.** `scripts/a3-check.sh` checks an A3 before it is posted. It applies the lines of v2 or v1 and names any line that is missing, blank, out of order or outside its grammar. A reader that meets a version it does not know skips the comment and says so.

**Tests.** The pinned 2.2.0 version rows move to 2.3.0. New offline checks cover AC-1 to AC-17: the `a3-check.sh` fixtures in `tests/factory/test_a3_check.sh`, replays of the count, minute and percent rules, and text pins in `tests/factory/test_lean_rules.sh`. The three checks that waited for this entry, the runbook note and the docs (AC-17 and AC-19) pass now. `bash tests/run.sh` prints `ALL PASSED`.

**Known limitations at release.**

- Security's low finding 1 (the file operand of `a3-check.sh` passed to awk) is fixed in this release. The fix came after security's pass and security has not re-reviewed it.
- The same awk file-operand pattern is in `scripts/post-text.sh` and `scripts/board.sh`, unchanged here because no slice path lists them. It needs a follow-up issue.
- `a3-check.sh` is a format gate, not a secret scan. The *Scan before posting* step stays the gate.
- A 2.2.0 install reads a v2 A3 as a version it does not know: it skips the comment and says so. That is the 2.2.0 text; no install was run to see it.

**Unverified.** Nothing ran in a live factory session. What only real use shows: whether the waste tags are applied consistently by the lead across a real run, whether the targeted walk finds anything, and whether the waste Pareto changes which improvement the person picks. The install and update path was not run, because the machine stays on its frozen install.

Fingerprints for this release, from `scripts/fingerprint.sh` on 2026-11-10: standard `99f1c24c685fc0cfd5fb9b9134596ed2b031bfe2b4f7b40844beb9d389be1930`, tooling `d1147172c1056068edc50a8a7b44bc45d16215e98229d585c83309aba48ac070`. Any later change under `plugins/factory/` in this release is a forgotten bump.

## factory 2.2.0 (triage batch: #86 #84 #85 #71 #70 #69 #68 #59 #43 #41)

Release: `2.2.0`, fixes and small rules from the open-issue triage. This is a **minor** release (it changes the run skill and agent files). No migration is needed. Restart Claude Code sessions after updating.

- **#86** The path check of QA, security and the lead ignores the item's own review and requirement files.
- **#84** *Add to board*: "Content already exists" means "already on the board"; look the card up, do not retry.
- **#85** README: `/factory:run` is user-typed only (`disable-model-invocation`); a session that cannot type it reads `SKILL.md` from the plugin root.
- **#71** Kind 6(b): the FREEZE token is the install's last path segment, a sha or a semver; a line with no token reads `not captured`.
- **#70** The gemba walk builds its view from the sampled row's time window when a transcript is shared by several rows.
- **#69** `board.sh` creates a view first and sets its filter with a second call (`B-vupdate`); a refused update tells the person to set the filter by hand. The update call was checked only against the fake `gh`, not a live Project.
- **#68** Developer and architect Done lists, and the lead's rework feedback, require a search for every other statement of a changed rule.
- **#59** The test command is an input for QA and docs-writer, on its own line in the brief; the lead supplies QA's "how to run" when there is no developer stage.
- **#43** Documentation runs before the Acceptance demo when a Human-only criterion names a document the docs-writer delivers.
- **#41** Step 4 has a rule for a destination with no one-way doors: cut one slice to the Done-when; never dissolve before a first slice ships.

**Tests.** Three slice-73 checks that required byte-equal baseline lines were relaxed to prefix checks (the lines were extended on purpose). New offline checks for #71, #70 and #69. `rel-*` and `ac44-check-bump-exit-0` rows of slice 73 and 64 describe the 2.0.0 to 2.1.0 delta and were already failing on `main`.

**Unverified.** Nothing ran in a live factory session. #87, #88, #89 and #90 (lean additions to the A3 and hansei) are not part of this release.

## factory 2.1.0 (#73)

Release: `2.1.0`, test ownership and the TDD loop. This is a **minor** release: it adds rules to the factory's instructions and removes none. No project has to migrate. `factory-state` stays at 2, and `/factory:run` runs as before. Restart Claude Code sessions after updating: a session keeps the factory skill text it read when it started, so a session opened before the update runs the old text.

Slice [#73](https://github.com/WimSuenens/agent-plugins/issues/73), map [#72](https://github.com/WimSuenens/agent-plugins/issues/72). Requirement [73-test-ownership-and-tdd-loop](docs/requirements/73-test-ownership-and-tdd-loop.md). Decision: [#42, "Agreed direction"](https://github.com/WimSuenens/agent-plugins/issues/42). No ADR was needed: each change is text that a later edit reverts. Contracts: [73-ownership-and-tdd-loop](contracts/73-ownership-and-tdd-loop.md), [73-optional-code-review](contracts/73-optional-code-review.md) and [73-release](contracts/73-release.md). The contract index is [docs/factory/reference.md](docs/factory/reference.md).

**What changed for the person who runs the factory:**

- **Who owns the tests.** `tests/` is QA's. The developer never creates, edits or deletes a file there. A developer who meets a test or a contract it doubts writes a question to the lead, names the test, and keeps building. It does not change the test.
- **The TDD loop.** The architect's contracts define the expected behaviour. QA writes the next targeted test before that behaviour is built, and the test fails for the expected reason. The developer runs the targeted test until it is green. When a test or a contract is unclear, the lead sends the test to QA and the contract to the architect. QA still gives the independent pass or block verdict, and the security review stays mandatory.
- **Test scope.** Executable behaviour and important safety invariants are automated. Whether an agent follows an instruction is checked with realistic scenarios and human review. Exact prose is asserted only where a machine-readable format or a safety rule needs it.
- **Optional code review.** After the contracts and before the build, the lead decides whether to run a code review. Three risk triggers decide it: shared protocols or approval and state rules, broad changes across two or more plugins, and significant refactors. The decision is one line in the lead state. A slice with no trigger is not reviewed. The review never replaces QA or the security review, and its findings do not block a merge on their own. The lead also checks every slice's diff for unexpected breadth or scope creep.
- **The developer's Done list.** The developer is done only when the applicable tests have run and exit 0: the targeted test when the Tests stage ran, and the repo's own test and lint commands. The developer does not write the acceptance suite.
- **A new ledger stage, `Tests`.** QA's test preparation is its own role task, in its own stage, before Build.

**The gates are not weakened.** The QA and security gates stand as before. The fenced section *Never overridable locally* of the protocol is unchanged. The optional code review adds a check; it removes none.

**Files.** The standard text changed: the protocol (a new `## Tests` section, outside the fenced section), the run skill, `references/hansei.md` (the stage list), the developer, QA and architect agent files, the setup skill and its `factory.md` template. No script and no hook changed, and no other agent changed.

**Pilot.** This release's first use is the pilot named on #42. It compares test-to-green time and QA and developer rework rounds with #64, built on 1.3.0. The lead records the pilot's numbers in the hansei record; this entry does not state them.

**No acceptance demo gated this slice.** Offline checks, scenario cards and reviews cover the text. What they cannot show is listed under *Unverified* below.

### Unverified

Nothing in this release ran in a live factory session. The following is unverified:

1. **The new text in a live session.** The Tests stage and the code-review decision are text the lead follows. No live lead has yet followed them.
2. **The three risk triggers.** A real lead has not yet judged a slice with them. A script or checklist for the triggers is deferred until a pilot run shows the lead misjudges one.
3. **The loop itself.** The first run that uses the loop is this item's own pilot. Its outcome is not known when this entry is written.
4. **The Human-only scenarios.** QA played the scenario cards once, as one reader, reading only the named files. A second reader, the lead or a person, has not yet played them.
5. **A path-check command (QA finding F1, medium, open).** The changed-paths command in the QA agent file does not ignore the item's own review files, so it lists them as off-list. The acceptance suite ignores them; the command's wording does not yet. The architect owns the wording.
6. **The release check needs its base commit (security, informational).** The release test reads the baseline commit `4086c9c`. Where that commit is missing, the test skips itself, and a shallow clone passes without a check.

## factory 2.0.0 (#64)

Release: `2.0.0`, the board as run state. **This is a major release.** The project's GitHub Project board now holds the status of every card, each role's work on an item is a sub-issue of its slice, and several slices can run at the same time. A project on 1.x must run `/factory:setup-factory-skill` (its migration step) before `/factory:run` accepts it. The migration shows the status mapping and the item count and waits for a yes; `/factory:run` never applies it, and `/factory:run` refuses a project that has not migrated. Undoing ADR 0014 or ADR 0015 after this release is a 3.0.0 release.

Slice [#64](https://github.com/WimSuenens/agent-plugins/issues/64), map [#50](https://github.com/WimSuenens/agent-plugins/issues/50). Requirement [64-board-as-run-state](docs/requirements/64-board-as-run-state.md). Decisions: [ADR 0014](docs/adr/0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md), [ADR 0015](docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md) and [ADR 0016](docs/adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md); no new ADR. Contracts: [64-release](contracts/64-release.md), [64-board-status](contracts/64-board-status.md), [64-role-tasks](contracts/64-role-tasks.md), [64-ledger-and-fields](contracts/64-ledger-and-fields.md), [64-gh-calls](contracts/64-gh-calls.md), [64-board-script](contracts/64-board-script.md) and [64-parallel-slices](contracts/64-parallel-slices.md). The contract index is [docs/factory/reference.md](docs/factory/reference.md); the steps and checks are in [docs/factory/release-runbook.md](docs/factory/release-runbook.md), section *Release 2.0.0*.

wayfinding (unversioned): this release changes two wayfinding files, `plugins/wayfinding/skills/wayfinder/SKILL.md` (a *Slices in flight* step in the resurvey) and `plugins/wayfinding/skills/beachhead/SKILL.md` (one line). The wayfinding plugin keeps no `version`: ADR 0012 versions the factory only.

**No acceptance demo gated this slice.** What offline checks cannot show is listed under *Unverified* below. Real use settles that list: each finding goes to this repo as a feedback issue (the *Factory feedback* template, label `plugin:factory`).

**This item ran on the 1.3.0 mechanism.** It ran on the frozen install, factory 1.3.0, so its briefs and feedback were files, its lead state held a stage log, and it had no sub-issues and no migration. **No new-series baseline was written for 2.0.0**: the `2.0` series starts with the next run.

**Installs are frozen.** Merging and tagging 2.0.0 changes nothing on a machine that holds the frozen install, which stays on factory 1.3.0 until the freeze ends. The tag `factory-v2.0.0` is made by hand on the merge commit, as for 1.1.0 to 1.3.0. Once a machine updates (`claude plugin marketplace update wimsuenens`), this release reaches the projects on it.

**Restart your Claude Code sessions after updating.** A session keeps the factory skill text it read when it started. A session that started before the update runs the old text and does not read the board.

### Added

- **The board as status.** The project's board holds the status of every card: the map, each child ticket, each role task and each frontier ticket. `Factory status` has six values: `Backlog`, `Ready`, `Running`, `Waiting on you`, `Blocked` and `Done`. Two single-select fields are added: `Kind` (`map`, `slice`, `role task`, `frontier ticket`) and `Role` (set only on a role task). Five text fields hold the numbers: `Tokens`, `Minutes`, `Hours`, `Rework rounds` and `Person touches`.
- **Two views.** `Needs you` lists the cards that wait on the person. `History` lists the closed slices and role tasks, newest first. The filter tokens are `factory-status:"Waiting on you"` and `is:closed kind:slice,"role task"`. The script cannot create either view with its filter, so in 2.0.0 both are built by hand from the instructions it prints (see *Unverified*, item 2).
- **A waiting card says what to do.** Before a card goes to `Waiting on you`, the lead posts a needs-you comment: its cause, the ask, the options, and what happens after the answer.
- **Role tasks as sub-issues.** Each spawn of a role on an item is one sub-issue of its slice. The brief is its body and the result is its closing comment; a result longer than one comment is split into parts. Findings go back to a role as a new rework sub-issue, and earlier role tasks stay closed and unedited.
- **The ledger.** The lead's working record of an item is one comment on the slice ticket, holding the Tasks, Waits and Person's touches tables. It replaces the tables the 1.x lead state held.
- **Parallel slices.** Slices run at the same time, up to `parallel-limit` (default `2`), when their path lists do not overlap. Each contract names its paths in a `Paths:` block; a slice's list is the union of its contracts' blocks. A path that overlaps another slice's list or its `shared:` entry keeps the slice waiting.
- **The `factory-state` line.** Line 1 of `docs/agents/factory.md` reads `factory-state: 2`. `/factory:run` refuses a project without it.
- **Four scripts.** `board.sh` (setup, the three-phase migration, the views, `finish`), `paths.sh` (path lists and the overlap rule), `factory-config.sh` (the `factory-state` and `parallel-limit` lines) and `post-text.sh` (the scan of text before it is posted, and the rendering, elision and splitting of long comments).
- **The migration.** `/factory:setup-factory-skill` migrates a 1.x project. It writes a snapshot of every item and field value under the machine's state folder, outside the repository, before any change. It then adds the new options, re-sets the items, and drops the old options only when no item holds one.

### Changed

- **Status moves to the board.** The lead state no longer holds a status. The 1.x values `Designed`, `In progress`, `In review` and `Ready to deploy` are replaced by the six values above. The migration maps Designed to Ready, In progress and In review to Running, and Ready to deploy to Waiting on you; Backlog, Ready and Done are unchanged. **In progress and In review both become Running, so the old distinction survives only in the snapshot.**
- **Removed from the standard.** The `## Stage log`, `## Waits` and `## Person's touches` sections of the lead state (their data is in the ledger and the sub-issues); the lead state's `Status:` line; the brief and feedback files `NN-brief-<role>.md` and `NN-feedback-<role>.md`; and the one-item-at-a-time rule, which the limit replaces.
- **The hansei record stays at schema v5.** Its header key `stage-log cross-check` keeps its 1.x name and checks the Tasks table of the ledger. The seven measures keep their keys, order and grammar; their sources now read the ledger and the sub-issues. A frontier round has no ledger, so its role tasks read `not captured (frontier round keeps no ledger)` in `Tokens` and `Minutes`.
- **Readers re-pointed.** Every reader of a 1.x table now reads the ledger or the sub-issues. The gemba sample counts the ledger's Tasks table in place of the stage log; the walk, its line, the baseline and the A3 keep their 1.3.0 grammar.
- **Files.** Standard work under `plugins/factory/`: `skills/run/SKILL.md`, `references/protocol.md`, `references/hansei.md`, the seven `agents/*.md` and the setup skill. Tooling: the four scripts above. `plugins/factory/.claude-plugin/plugin.json` is at `2.0.0`.
- **Bump.** `scripts/check-bump.sh` is unchanged. It passes `1.3.0 -> 2.0.0` (`pass: minor bump needed, 1.3.0 -> 2.0.0`). The script's word "minor" is a floor; the major level is the architect's decision, because no path pattern can tell a breaking change.
- **Wayfinding.** The run text says that where an installed older wayfinding text describes slices running one at a time, the run's rule governs.

### Unverified

Offline checks, replays and reviews cover the text of this release. **In a live session, none was exercised.** On a live Project nothing was written. The migration was tried once on a scratch Project on 2026-11-08, on the real GitHub API; the scratch Project was deleted afterwards, and the outcome is under item 2 and in the runbook. The following is named here as unverified:

1. **Limits and result size under real load.** The usage-limit gate (`N = 1` after a limit is hit), the cut of a long result, and the limits the tracker sets.
2. **Anything needing a live Project.** Found in the scratch try: `createProjectV2View` takes no `filter` on create. So the single create call always fails, and `board.sh apply` always ends with exit 10 and prints the hand-build instructions for both views (`Needs you`: table layout, filter `factory-status:"Waiting on you"`; `History`: table layout, filter `is:closed kind:slice,"role task"`). The fallback works. A create-then-update path (`updateProjectV2View` with the filter) was checked by hand and the filter reads back; it is a candidate for a later release and is **not** in 2.0.0. Still unproven: that the views filter correctly in the UI with the `factory-status:` token (only the stored text was read back), and the fields shown and their order. A real restore from the snapshot is not rehearsed.
3. **Whether the board alone lets the person tell what to do next.** The needs-you comment and its card, in the first real run.
4. **Parallel running.** Path lists, the off-list catch, merge conflicts and the resurvey pause.
5. **Hansei numbers across a real run**, including `Tokens` per role task and the frontier-round fields that read `not captured`.
6. **Migrating a project other than agent-plugins.**
7. **A live role following the brief check.** The role-side check of a brief's author and marker, and of the path list, is an instruction to the role: its text is pinned and its logic replayed on fixtures.
8. **jq 1.6 and mawk.** Not tried. The suite runs on jq 1.8.1 and bash 3.2.57 (the macOS shell); the QA verdict also records bash 5.
9. **Accepted limits (security review).** The scan finds home paths and the listed token shapes, but not instruction-like text or an unlisted secret. Anyone with write access to the repository can edit a sub-issue body; the lead's own-login filter narrows this and does not remove it.

**Verified once on a scratch Project (2026-11-08):** `updateProjectV2Field` keeps the option ids through the migration, and the shape of `gh project item-list` that `board.sh` reads matches the one it expects. These are no longer on the unverified list.

**Migration try, 2026-11-08 (scratch Project, deleted afterwards).** `board.sh plan` read the board: seven options, 8 items to change and 4 staying. `apply --yes` moved the 8 items by the mapping and left the 4; every `Priority` value was identical before and after; the four old options were dropped last; the `Kind` and `Role` fields were created; the snapshot was written outside the repository with mode 600. `finish --views-confirmed` refused while a view was missing, and wrote `factory-state: 2`, the new option ids and the 2.0.0 operations section into scratch copies of the two docs; a second run gave the same result, and `plan` then read `already migrated`. A failed try would have been an andon, not a line here; it did not fail.

## factory 1.3.0 (#60)

Release: `1.3.0`, the gemba sample. At each item's close the Lead walks one stage of the item, chosen by a counted rule. It reads what that agent actually did, in its transcript or, where no transcript can be read, in its commits and result file, and compares it with the brief and with the stage-log row. The hansei record then carries one line, `gemba`, that says which stage was walked, what the walk found, and whether it changes anything. A finding is a question about the process, and it goes to a 5 Whys; it is never a verdict on a person, a role or a model. A walk that could not be done reads `not captured (<reason>)`, never `found nothing` and never `0`. The version lives in `plugins/factory/.claude-plugin/plugin.json` only. Tag: `factory-v1.3.0`, created by hand by the Lead on the merge commit at merge. This item ran on the frozen install `9147301f75c3`, whose text has neither the walk nor a tag step, so the tag is made by hand, as for 1.1.0 and 1.2.0.

Slice [#60](https://github.com/WimSuenens/agent-plugins/issues/60), map [#34](https://github.com/WimSuenens/agent-plugins/issues/34). Requirement [60-gemba-sample](docs/requirements/60-gemba-sample.md). Decisions: [ADR 0011](docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [ADR 0012](docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) and [ADR 0013](docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md), unchanged; no new ADR. Contracts: [60-gemba-sample](contracts/60-gemba-sample.md), [60-gemba-walk](contracts/60-gemba-walk.md), [60-gemba-line](contracts/60-gemba-line.md) and [60-standard-changes](contracts/60-standard-changes.md). The hansei record is at schema v5, and v3 and v4 records are still read. The contract index is [docs/factory/reference.md](docs/factory/reference.md). The release steps and checks are in [docs/factory/release-runbook.md](docs/factory/release-runbook.md), section *Release 1.3.0*.

**No acceptance demo gated this slice.** The map decided that it is verified by best practice, not by a demo ([#60](https://github.com/WimSuenens/agent-plugins/issues/60), *Deliberately faked*). What offline checks cannot show is listed below as **unverified**. Real use settles that list: each finding goes to this repo as a feedback issue (the *Factory feedback* template, label `plugin:factory`).

**Restart your Claude Code sessions after updating.** A session keeps the factory skill text it read when it started. A session that started before 1.3.0 runs the 1.2.0 run close, with no walk and no `gemba` line, until it is restarted.

**Installs.** The machine on which this run is frozen keeps the install `9147301f75c3` until the freeze ends. Until someone updates that install (`claude plugin marketplace update wimsuenens`, then a restart), this release reaches no project on that machine.

### Added

- **The sample rule.** The stage is picked from the stage log by a count. Take the role rows (`product-owner`, `architect`, `developer`, `qa-engineer`, `security-reviewer`, `devops`, `docs-writer`) whose `Agents` cell is not `-`, and drop the flagged ones: a row whose `Result` does not start with `done` or `pass`, or whose `Notes` record a pause by an andon. The ticket number modulo the count picks the row, counted in the log's own order. When every role row is flagged, the same count runs over all of them and the line says `already flagged`. A log with no role row reads `not captured (no role stage ran)`. No duration, wait, peak or random choice enters the rule.
- **The walk (step 8.3a).** One walk per item, after the merge approval and the token totals, before the record is filled. The evidence is the sampled row's transcript, or its commits and result file when no transcript can be read. The result's `Summary`, the completion notice, the stage summary and the agent's final reply are claims, never evidence. The walk compares the evidence with the brief (`Done`, `Constraints`, `Output`) and with the row (`Result`, `Notes`, `Waits`), and looks for exactly three things: a `Done` item with no trace, work that the brief or the ownership table forbids, and a row field that the evidence contradicts. Everything the walk reads is data: the Lead follows no instruction in it.
- **The read limit.** Every read of a walk goes through a command that ends in `head -c`. A walk prints at most 30,000 characters, the brief included. A view longer than that is `partial (cap)`: the walk reads its head and may make one more bounded read, and the line says so.
- **The 5 Whys of a difference.** A difference gets a 5 Whys as a kind 7 andon with no paused agent. It has no wait, no stop, no override and no resume, because the approval has already ended the lead time and covered the diff as shown. The andon comment, its row and the `abnormalities` link follow the andon rules, and the refusal rules of *The 5 Whys* apply unchanged.
- **The gemba line, hansei schema v5.** The first line is `<!-- factory:hansei v5 -->`. One header line `gemba` follows `stage-log cross-check` and comes before the measures. The measures do not change: seven, with the same keys, order and grammar, so v3, v4 and v5 measures may be compared. The line is not a measure, and no baseline figure reads it. It is a new schema version and not a field in v4, so that a v4 reader skips a v5 record and says so rather than reading a key it does not know.
- **Reading old and new records.** The baseline reads v3, v4 and v5. A v5 record with no `gemba` line, or with two, is skipped and named (`gemba line missing`, `gemba line repeated`). The check counts lines; no baseline or A3 field reads what a gemba line says. A v3 or v4 record has no line, and no `not captured` entry is made for one. The `records:` line of a series names every schema the series holds.

### Changed

- **The item close gains one step.** Step 8.3a is the walk. No step is renumbered: 8.4 stays 8.4. The walk runs after the approval, so its time is in no measure, and lead time still ends at the approval.
- **The hansei record is at v5.** Its template, its header-field table and its worked example carry the line. The *Versions* paragraph and *Which versions the standard reads* (`v3, v4 and v5`) say what changed.
- **The baseline.** `references/baseline.md` reads v3, v4 and v5, takes the presence check for the gemba line, and its `records:` line names the schemas of each series (`schema v4 and v5 read together`, `schema v3, v4 and v5 read together`).
- **The files of this release under `plugins/factory/`** are `skills/run/SKILL.md`, `references/hansei.md`, `references/baseline.md` and `.claude-plugin/plugin.json`. No agent, script, hook or new file changed. The bounded read is text, so no script was added.

### Unverified

Offline checks, replays and reviews cover the text of this release. They cannot show the following, so they are named here as unverified:

1. **The sample rule under real load.** Whether the stages it picks teach the Lead anything, judged by the share of walks that find a `difference` against those that find `nothing`, over items.
2. **The walk's cost in a long item.** Whether the walk stays within its cap, and whether its cost in the Lead's context is worth the line, with a large transcript.
3. **A real transcript read in a project's own checkout.** The bounded read has been run on transcripts of this machine and on generated ones. A project's own checkout has not been read, and the fallback to commits and result file is tested offline only.
4. **How often a walk finds a difference.** Not measured yet. The line is the only record.
5. **The 5 Whys of a real gemba finding.** Whether a real chain ends in a process item without the Lead's correction.
6. **A fresh person or agent applying the rule's text.** Two programmatic readers agree on the fixtures. No person and no language-model reader has applied the text.
7. **A live close at step 8.3a.** The order of the steps, the kind 7 andon after the approval, its `Abnormalities` row and the lead-state commit were read from the text and replayed on arithmetic. No live close has run them.
8. **The guessed numbers.** The 30,000-character cap, the 300- and 200-character cuts of the view and the 1,500-character cut of the final reply are guesses. Feedback will tune them.
9. **The first baseline that holds mixed v4 and v5 records.** Neither the `records:` line of such a series nor a real series 1.3 has been read.
10. **The Lead obeying the data rule and the gate paragraph** against a hostile transcript (one whose tool results or final reply tell the Lead to do something else), in a live session.
11. **The jq filter beyond one local transcript.** The view has been run on one transcript of this machine and on generated transcripts.
12. **SIGPIPE behaviour.** Whether `head -c` closing the pipe ends a `jq` read cleanly was not run.

### Known limits

- **The extra read's pattern (security N2, low, accepted for this release).** The one extra read is a `grep -n` over the view, and its pattern can come from a `Done` item of the brief. A pattern that begins with `-` would be read as an option, and a regular expression can be slow. The read stays under `head -c`, and the line still reads `partial (cap)`.
- **The walk cannot stop the merge.** It runs after the approval. A difference about a gating stage (QA or security did not run, or a verdict was not what its result said) is told to the person before the merge, and the merge question is asked again. Any other difference goes into the record and its 5 Whys.
- **This item has no gemba line.** #60 ran on the frozen install `9147301f75c3`, which has no walk. Its close writes no `gemba` line and creates no `Factory baseline` issue. The first item run on 1.3.0 is the first walk.
- **The 29,900-character budget.** A walk reads at most 29,900 characters of evidence and brief together, so that its printed total stays under 30,000. The rest of a long view is not read, and the line says `partial (cap)`. With two transcripts in one row the budget is shared and the first takes it first (QA observation): a second agent may then go unread, and the line says only `partial (cap)`.
- **The rule is text.** The walk is the Lead following the text of `hansei.md` section 6 and step 8.3a. No script runs it, and the suite checks the text and replays the rule on fixtures, not in a live session.
- **Carried from 1.2.0.** The limits listed under 1.2.0 stand: the experiment's settle, the paused-agent check, and the shared identity of the Lead.
- **Post-merge checks, by the Lead.** The tag `factory-v1.3.0` must point at the merge commit on `main`, and this repo must hold no `Factory baseline` issue from this item's work. The release runbook lists the commands.

Verdicts: QA round 3, pass, with the ten criteria covered by offline tests or named above ([reviews/qa-60.md](reviews/qa-60.md)); security round 3, pass with N2 open ([reviews/security-60.md](reviews/security-60.md)).

## factory 1.2.0 (#57)

Release: `1.2.0`, the per-run A3 and the Factory baseline. Each project gets one `Factory baseline` issue that says what normal looks like for the factory release it runs, and each run ends with one A3: one problem, the 5 Whys behind it, at most one countermeasure tried as a local override, its before and after against that baseline, and what is still uncertain. The run's close is one step 9, in one order. The version lives in `plugins/factory/.claude-plugin/plugin.json` only. Tag: `factory-v1.2.0`, created by hand by the Lead on the merge commit at merge. This run is frozen on install `9147301f75c3`, whose text has no tag step, as for 1.0.0 and 1.1.0.

Slice [#57](https://github.com/WimSuenens/agent-plugins/issues/57), map [#34](https://github.com/WimSuenens/agent-plugins/issues/34). Requirement [57-per-run-a3-and-baseline](docs/requirements/57-per-run-a3-and-baseline.md). Decisions: [ADR 0011](docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [ADR 0012](docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) and [ADR 0013](docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md), unchanged; no new ADR. Contracts: [57-baseline](contracts/57-baseline.md), [57-a3](contracts/57-a3.md), [57-records-and-overrides](contracts/57-records-and-overrides.md), [57-run-close](contracts/57-run-close.md) and [57-standard-changes](contracts/57-standard-changes.md). The hansei record is at schema v4, and v3 records are still read. The contract index is [docs/factory/reference.md](docs/factory/reference.md).

**Restart your Claude Code sessions after updating.** A session keeps the factory skill text it read when it started. A session that started before 1.2.0 still runs the 1.1.0 run close until it is restarted: the baseline and the A3 steps appear only in sessions started after the update.

**Installs.** The machine on which this run is frozen keeps the install `9147301f75c3` until the freeze ends. Until someone updates that install (`claude plugin marketplace update wimsuenens`, then a restart), this release reaches no project on that machine.

### Added

- **The Factory baseline.** One issue per project, in the project's own tracker, titled exactly `Factory baseline`, authored by the Lead's own `gh` user, whose body starts with `<!-- factory:baseline v1 -->`. The Lead finds it at run start and at each item start, by title, author and marker in any state. It creates the issue when none exists, and pins it when the tracker allows; a failed pin never leads to a second issue. A failed lookup changes nothing. An exact-title issue without the marker is left alone and the person is asked. Its body has a block for the current series (the release the session runs), history for each earlier series, labelled with the date it was replaced, a calibration list with no figures, the skipped and excluded records by name, and notes for dropped overrides. Nothing is stored: every figure is recomputed from the records the issue names.
- **Figures that never show `0`.** Each figure is the median of the items that captured it, shown with `k of n`. A value that no item captured reads `not captured (<reason>)`. A `n/a (did not run)` is counted beside it, never as zero. There is no mean and no sum of captured values. Lead time is read in its parts, and the section says that the medians of the parts need not add up.
- **Series and sections.** Records are grouped by the release's `X.Y`, read from the `plugin:` line of a `series: release` record. A patch or a tooling-only change starts no new series. A difference in `standard` under one `X.Y` is excluded and named; the forgotten bump is an andon of kind 6. Calibration records (`series: calibration (pre-baseline)`) enter no series and no figure. An item with an override applied partway through is counted in no section.
- **The per-run A3.** One comment on the run's map issue, its first line `<!-- factory:a3 v1 -->`, with a fixed set of field lines in one order: `run`, `series and release`, `problem`, `evidence`, the `5 whys` block, `process item to change`, `countermeasure`, `measure targeted`, `before`, `after`, `change`, `items counted`, `still uncertain`, `other problems seen`, `other overrides`, `standard changes proposed`, `baseline` and `answer`. The problem is the process item that the most items' andons name; with no andon, the measure furthest above its reference in the baseline. It is posted once, at run close. A run that closed no item writes none. A run the person stops after an item has closed gets one, marked `run stopped`.
- **One experiment per run.** The run's countermeasure is an override that names one measure from a short table, has a closed item to measure against, addresses the run's problem, and is checked against the fence before anything is written. Any other override of the run is listed and reads `before/after: not measured (not this run's experiment)`. A countermeasure that needs a plugin text change writes no override: the A3 says `none (needs a plugin change)`.
- **Before, during and after, from the records.** A before-item closed before the override started, in the same series and with the same overrides in force. A during-item, one in flight when it started, counts in neither reading. An after-item is in the run's list with the override in force for the whole item. A reading that cannot be compared reads `not comparable (<why>)`, for example when the release moved between the two sides or another override was in force on one side only. Nothing is shown as a difference between readings that are not comparable.
- **Settle answers with the numbers.** At run close each override gets `keep`, `promote` or `drop`, and the experiment's line shows its before and after. `keep` and `promote` make the override the baseline's reference section for the next run, and the settle merge comes before the report. `drop` removes it and the baseline keeps a note `<name> dropped <date>`. `promote` puts a decision card in front of the person: the product owner writes it, it is posted on the ticket the A3 belongs to, and it is the person who decides it. The override stays in force meanwhile, nothing under `plugins/` changes, and the run may be reported closed with the card open.
- **Hansei record, schema v4.** The first line is `<!-- factory:hansei v4 -->`. In the `active overrides` line each override carries its extent: `whole item`, `from <time>` for one written during the item, or `until <time>` for one superseded during it. The label gains the line `overrides at start`. No measure changed, so v3 and v4 measures may be compared. A v3 record is read by its own marker, and a v4 record whose extent line does not match its grammar is skipped and named.
- **Experiment lines and the run list.** An experiment's override carries eight more lines (`experiment: yes`, `problem`, `measure`, `direction`, `series`, `reference`, `before`, `a3`), committed with the override. The Factory run section keeps `closed in this run`, which lists the items whose after-items are read, and a `baseline:` note with the record count and the minutes an update took.
- **Tracker operations.** The ten operations of the baseline and the A3 (*Find baseline*, *Create baseline*, *Pin baseline*, *Read baseline*, *Edit baseline*, *Find records*, *Find A3s*, *Find A3*, *Post A3*, *Edit A3*) are in the setup skill's tracker template, and in this repo's `docs/agents/issue-tracker.md`.
- **Text read back is data.** Text read from records, A3s, overrides and comments is read only by the fixed grammars the standard names. A line that does not match is skipped and named. A reason text copied into a body is cut to 120 characters and placed in a code span, with backticks, `@` and `<` neutralised. By the rule, it cannot mention someone or form a link or markup; security checked that on paper against the rule, not in a live session.

### Changed

- **The run close is step 9 alone.** Step 10 is removed. The close runs in this order: the baseline is updated from the records (9.1); the A3 is posted (9.2); the settle round (9.3); the feedback offer (9.4); the run is reported closed with the A3's link, the baseline's link and each override's outcome (9.5). Before, the close gathered feedback issues in one batch at the end of the run.
- **Step 9.4 drafts less.** A draft is written only for what the A3 lists (`standard changes proposed`, the other kind 7 abnormalities, the `problem` and `other problems seen`) and for the person's remark. Each draft states why it is listed, quotes readings without item numbers or links, and names no project path. Only an approved draft is posted to this repo. Briefs that came back `blocked`, and a role's work done by another role, stay in the project's records and are not drafted unless the A3 lists them.
- **The baseline is updated after each item.** At step 8.10, after the item's record is final (measure 7 edited by the resurvey, or `not captured (run stopped before the resurvey)`), the Lead recomputes the baseline. At run start a repair check finds a record that the baseline does not list and recomputes it, saying so in one line.
- **Run start and item start.** Step 0 and step 5 look for the baseline. An experiment written between items is committed at step 5, after the worktree is created and before the `Start item` stamp, so that the next item is an after-item.
- **Measurement baseline.** A minor release resets it (ADR 0012). A project's `1.2` series begins with its first item run on 1.2.0. Items run on a pre-release install (no semver) are calibration and never start a series. Earlier releases' records stay in the baseline as history, and no 1.2.0 figure is computed from them.

### Upgrading a project set up before 1.2.0

A project whose `## Factory operations` section has no *Find baseline* bullet predates 1.2.0. Its Lead uses the template's bullets for the baseline and the A3 and tells the person once. Replacing that section with the one in `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` (what `/factory:setup-factory-skill` step 6 does) brings the project up to date. The Lead never edits the project's tracker doc itself. At its first run on 1.2.0 the Lead creates the project's `Factory baseline` issue if there is none, and says so in one line.

### Acceptance demo

The acceptance demo ran in a scratch project, with the item's plugin loaded by `claude --plugin-dir` from the item's worktree, and the install left frozen. The person typed every seed. The outcomes, as recorded on the slice ticket:

- The baseline issue appeared at run start, with the marker on its first line, the current 1.2 block reading `not captured`, and the older release kept as history: pass.
- The run close posted one A3 with one problem, no experiment, and `answer: none (no override to settle)`: pass.
- One issue reached this repo, approved by hand, with no project data: pass. The A3, the baseline and the andon comments stayed in the scratch project.
- The plugin worktree stayed clean through the demo: first half of AC-30 pass.

Not exercised, as the demo's stops ended in `none (needs a plugin change)` and no override existed to measure or settle: the before and after readings of an experiment, the `keep`, `promote` and `drop` answers on a real override, and the second half of AC-30.

### Known limitations at release

From the verdicts on #57 (QA [reviews/qa-57.md](reviews/qa-57.md), round 3 pass; security [reviews/security-57.md](reviews/security-57.md), round 3 pass with two info items) and from the acceptance demo above.

- **Not yet exercised in a session: the experiment and its settle.** No live session has written an experiment, read its before and after, or answered `keep`, `promote` or `drop` on a real override. The text of step 8.10, step 9.3 and the settle round is checked from its wording and from fixtures. The first run with a real countermeasure is the check.
- **Not yet exercised in a session: a paused agent keeps its context.** The demo's pause hit an agent that had already handed back, and then one that had checked nothing before the person cancelled it. The check of #49 that a resumed agent states its earlier note and runs the shell again is still open.
- **A cancelled agent was refused by the harness, not by the standard.** When the person cancelled an agent from the task list, the Lead tried to resume it. The harness refused, and the Lead had already spawned a replacement that it stopped and then asked the person about. The standard did not prevent the attempt. The refusal and the replacement are the behaviour the standard asks for after the attempt.
- **The Lead's identity is shared with the person.** The baseline, the records and the A3 are found by the Lead's own `gh` user. Where that is the person's account, a comment or issue they write with the marker, or with the title `Factory baseline`, is read as the factory's (the shared-login limit of 1.1.0). A failed `gh api user` lookup reads as "none found" and could create a second baseline (security I1, info). If a project ends up with two, close the newer by hand.
- **A reason text can run past 120 characters.** The text is cut before the characters `@` and `<` are expanded in it, so a cut text can be a few characters longer (security I2, info, cosmetic).
- **The stopped-run path is not recorded as checked.** The demo's close followed the person's stop and posted its A3, but the demo outcome does not record the A3's `run:` line reading `run stopped`.
- **Escaped defects** (measure 4) still read `not captured`.
- **No script was added.** The question whether a change under `hooks/` or `scripts/` resets the baseline is still open on the map. The settled rule is that a tooling-only patch does not reset it (ADR 0012). The tooling fingerprint did not move in this release.
- **The suite failed once.** In one early full run during QA's round 3, a check on an accented file name in `test_andon_kind3_kind4.sh` failed. It passed in fifteen solo runs and in the later full runs, including the one this release was checked with (1436 passed, 0 skipped). The cause is not found (QA observation R3-O3).
- **Run close and install are checked from text.** The item close (step 8) and the run close (step 9) were not run in a live session except as the demo recorded above. The install, its update and the rollback were not run: the machine is frozen.
- **Post-merge checks, by the Lead.** The tag `factory-v1.2.0` must point at the merge commit on `main`, and this repo must hold no `Factory baseline` issue from this item's work. The release runbook lists the commands.
- **Carried from 1.1.0.** These stand: one git identity on the item branch (security S1 of #49), a long path in an andon's `seen` line (N1), the AC-8 wording of the andon contract (QA O1), the Lead's own readings of kind 2 and of the fence questions, and the install that was not exercised.
- **Carried from 1.0.0.** These stand: fingerprints move with any edit, the path rule covers message files only, the merge style keeps the history of `work/`, worktree location, the setup's labels, unreadable transcripts, and step 6.1 of the item close is not chained (security I6).

## factory 1.1.0 (#49)

Release: `1.1.0`, the andon: stop the line on an abnormality, with a local countermeasure written as an override in the project's own `docs/agents/factory.md`. The version lives in `plugins/factory/.claude-plugin/plugin.json` only. Tag: `factory-v1.1.0`, created by hand by the Lead on the merge commit at merge. This run is frozen on install `9147301f75c3`, whose text has no tag step, as for 1.0.0.

Slice [#49](https://github.com/WimSuenens/agent-plugins/issues/49), map [#34](https://github.com/WimSuenens/agent-plugins/issues/34). Requirement [49-andon](docs/requirements/49-andon.md). Decisions: [ADR 0011](docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md) (the fence and the expiry, which this release implements), [ADR 0012](docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) (releases and the baseline) and [ADR 0013](docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) (merge style and the path rule), unchanged; no new ADR. Contracts: [49-abnormality-list](contracts/49-abnormality-list.md), [49-andon-process](contracts/49-andon-process.md), [49-overrides](contracts/49-overrides.md), [49-records](contracts/49-records.md) and [49-standard-changes](contracts/49-standard-changes.md). The hansei record is at schema v3.

**Restart your Claude Code sessions after updating.** A session keeps the factory skill text it read when it started. A session that started before 1.1.0 still runs the 1.0.0 run skill until it is restarted. After an install, an update or a change to `plugins/factory/`, start a new session before running an item.

### Added

- **The andon.** Seven abnormality kinds, one list read by every role and the Lead: 1 `blocked-input`, 2 `same-finding-twice`, 3 `role-outside-role`, 4 `slow-stage`, 5 `fence-crossing`, 6 `version-drift`, 7 `other` (a free-form kind for an event that fits none of kinds 1 to 6; its andon says why no listed kind fits). A role raises one with an `Abnormality:` line in its result, directly after `Status:`. The Lead reads it when the role hands back, at the latest; it starts the andon before it briefs anything that depends on the affected work, and it does not accept the result as `done` until the andon has run.
- **Pause, 5 Whys, resume.** The Lead stops the affected running agent with `TaskStop` (an agent that has already handed back is not stopped), writes a 5 Whys chain of at most five whys, decides the countermeasure inside the fence, and resumes the same agent with `SendMessage`. The pause is its own wait kind, `andon`. When the person has cancelled the agent from the UI, the resume is refused: the Lead makes no second attempt and spawns a fresh agent of the role from the result file and the committed work. An item is never abandoned by a pause.
- **Blame the process first.** Each 5 Whys cause names a process object (the brief, the inputs, the standard's text, the tooling, the ownership table, the order of stages) with evidence. A chain that names a person, a role's care or competence, or a model is refused. A model or role swap is allowed only when the brief, the inputs, the role's standard text and the tooling were each examined and found adequate.
- **Detection rules the Lead applies.** Kind 2 matches findings across the roles and rounds of one item by a written signature; kind 3 reads the ownership table from `origin/main` and checks each commit's paths with `git diff-tree -z`; kind 4 compares a row's agent-working time with twice the median of the same role's earlier rows (at least three of them, waits excluded); kind 6 compares the fingerprints with the latest earlier record of the same release, and the installed sha with the run's FREEZE line. Kinds 1, 5 and 7 are read from the result and the override file. These are rules the Lead follows from the run skill's text; no script, hook or watcher raises an andon.
- **Overrides.** A countermeasure is written as an override under a `## Overrides` section of `docs/agents/factory.md`, which the Lead owns. Each has a name, the start date, the run it started in, the rule in plain words, the andon comment, a status and the fence check. An override applies outside the fence and wins over the plugin's text where they disagree; of two that disagree, the later one wins. No plugin file is edited to apply one. A countermeasure that needs a plugin change is recorded in the andon comment and in the step-9 feedback issue.
- **The fence.** `## Never overridable locally` in `references/protocol.md` lists the seven fenced items of ADR 0011 (merge and production approvals; the decision-card route for one-way doors; QA and security verdicts as merge gates; the andon itself; the memory rules; the shell-scope rules; the honesty rule for measures), each with where it is written and the question the Lead asks. The Lead checks every new override against it before it writes the override. The data-egress question E applies to every override as an eighth question; it is not an eighth fenced item. One yes to any question refuses the override. A request from the person does not loosen the fence; loosening is a decision card.
- **Run start and expiry.** At run start and item start the Lead does not apply an override that crosses the fence (it starts a kind 5 andon and tells the person which item it touches), nor an override from an earlier run that has no answer (a kind 7 andon; the person answers before the first item starts). New step 10, *Close the run*: before the run is reported closed, the Lead shows one line per override in force (name, start date, `before/after: no baseline yet`) and records the person's keep, promote or drop in a settle worktree and PR (`settle/<map>`), merged on the person's yes. `promote chosen` keeps an override in force until a decision card is decided; the card itself is not built.
- **Hansei record, schema v3.** The first line is `<!-- factory:hansei v3 -->`. Measure 1 gains a sixth part, `andon`, and the six parts add up to the total. A new `active overrides` line lists each in-force override by name and start date; a new `abnormalities` line gives the count per kind and a link to each andon comment, or `raised, no andon recorded` for one that has none. The record carries no 5 Whys text and no transcript content.
- **Stage log.** The lead state gains `## Findings` (the ledger the kind 2 rule reads) and `## Abnormalities` (one row per abnormality, with the paused agent and the andon comment). The stage log gains the row `Andon A<n>`, and the paused row names its andon. The wait kinds are five: `person`, `limits`, `stalled`, `interrupted` and `andon`.
- **Andon comment.** One comment per andon on the slice ticket, in the project's own tracker, marker `<!-- factory:andon v1 -->`, posted once after the resume and never edited. The text is the Lead's paraphrase: no copied tool output, comment text or transcript, no secrets, no absolute paths.
- **Ownership row.** `` | `docs/agents/factory.md` section `## Overrides` | lead | `` is written by `/factory:setup-factory-skill` for new projects, and is in this repo's `docs/agents/factory.md`. The word `section` is what makes the kind 3 check skip the row.

### Changed

- **Result template.** The `Abnormality:` line is optional; an absent line reads `none`, so results from earlier releases stay valid. A `blocked` result whose `Missing` input is not in the role's **Inputs needed** is kind 1.
- **Run skill.** Run-start checks at step 0, item-start checks at step 5 (kinds 5 and 6; each in-force override's rule is shown in the stage summary), per-result checks at step 6, a new `## Andon` section after `## Interruptions`, step 9 also lists each kind 7 abnormality and each plugin change an andon proposed, and step 10 is new. The existing step numbers do not move.
- **Hansei template.** Schema v3 replaces v2 in `references/hansei.md`; a v2 record is still read by its own marker. Measure 1 of a v2 record and of a v3 record are not compared for an item that had an andon.
- **Measurement baseline.** A minor release resets the baseline (ADR 0012, point 3). Records from 1.0.0 stay as the history of that standard and are not compared with 1.1.0 records.
- **The word "override".** `## Role models` rows in `docs/agents/factory.md` still override a role's model, as before. The new `## Overrides` section is a different thing: a local countermeasure.

### Upgrading a project set up before 1.1.0

A project whose `docs/agents/factory.md` has no `## Overrides` row predates 1.1.0. Its Lead adds the row, and the section with its first override, and tells the person once in the stage summary. Nothing else changes in that project's files.

### Known limitations at release

From the verdicts on #49 (QA [reviews/qa-49.md](reviews/qa-49.md), security [reviews/security-49.md](reviews/security-49.md)). The item itself is calibration (pre-baseline) on the frozen install. No model has run the new standard yet, and the suite runs no Lead session.

- **Human-only checks are open.** AC-7, AC-9, AC-10, AC-11, AC-14, AC-20, AC-25 and AC-28 are judged by the person in a real session that loads the new standard with `claude --plugin-dir`. Two live checks are added: that a live Lead paraphrases each in-force override into its briefs and its andon comment, and that the FREEZE check's `gh api graphql` read of the map body's last editor returns a value on a real map (otherwise the Lead writes `not captured`).
- **The Lead's judgments are checked from the text.** The kind 2 "same condition" call, the substitution test on each 5 Whys cause and the fence questions are the Lead's reading of the text. The kind 2 rule replayed on #39's findings flags all five of its abnormalities and none of eight control pairs; QA filled the signatures from the texts alone.
- **One git identity on the item branch (security S1, residual, low).** All commits of `item/49` carry one identity, so the author test of rule 5.6 cannot separate the roles. A commit with a forged `#<id> lead:` subject passes the subject test. The Lead says so in the stage summary and shows each in-force override's rule to the person before the first brief. An override that passes the fence and is harmful is shown, not stopped.
- **A long path in `seen` (security N1, low).** A path in an andon's `seen` line that is long, or reads as a sentence, can be pasted into the comment. Fix when that line is next touched: give such a path as its sha and "path escaped" only.
- **Shared GitHub login (security N2, low).** The FREEZE check compares logins. When the person and the Lead share one account, an edit by the person counts as the Lead's.
- **AC-8 wording (QA O1).** The paused agent's last `Next:` line is saved in the item's committed andon draft file. The agent id and the times are in the `## Abnormalities` table and the `Andon A<n>` row; the `Next:` line is not copied into the table.
- **Close steps not run in a session.** Step 8 (the close, with the AC-18 check left open from 1.0.0) and step 10 (the close of the run) are checked from their text, not in a live session.
- **Install not exercised.** Install and update were not run on the frozen machine for 1.1.0, as for 1.0.0; the install path is the one 1.0.0 documents.
- **Carried from 1.0.0.** Limitations of 1.0.0 that no verdict on #49 closes stay open, as listed under 1.0.0: escaped defects read `not captured`; fingerprints move with any edit; the path rule covers message files only; the merge style keeps the history of `work/`; worktree location; the setup's labels; unreadable transcripts; the close step's 6.1 is not chained (security I6).

## factory 1.0.0 (#39)

Release: `1.0.0`, the first semver for the factory. Tag: `factory-v1.0.0`, created by the Lead on the merge commit at merge (the release date is the merge date). The version lives in `plugins/factory/.claude-plugin/plugin.json` only; the factory's entry in `.claude-plugin/marketplace.json` has none.

Slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39), map [#34](https://github.com/WimSuenens/agent-plugins/issues/34). Decisions: [ADR 0011](docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md) (local countermeasures, the wide fence), [ADR 0012](docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) (releases, fingerprint, calibration) and [ADR 0013](docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) (merge style and the path rule). The hansei record is at schema v2. Contracts: [39-hansei-record](contracts/39-hansei-record.md), [39-stage-log](contracts/39-stage-log.md), [39-plugin-scripts](contracts/39-plugin-scripts.md) and [39-standard-changes](contracts/39-standard-changes.md).

**Restart your Claude Code sessions after updating.** A session keeps the factory skill text it read when it started, even when the plugin is loaded with `--plugin-dir`. A session that started before the update kept the pre-1.0.0 run skill until it was restarted. After an install, an update or a change to `plugins/factory/`, start a new session before running an item.

### Added

- **Hansei record, schema v2.** At the person's merge approval the Lead posts one comment on the slice ticket, in the project's own tracker. Its first line is the marker `<!-- factory:hansei v2 -->`. It carries the release, the two fingerprints, the dependency versions as context, the active overrides (`none` for now), a stage-log cross-check, and seven measures in a fixed order:
  1. **lead time**, split into five parts that add up to the total: agent working, waiting for the person, waiting on limits, stalled, and interrupted;
  2. **first-pass yield** per stage (QA, security, acceptance demo); a first pass with findings below minor reads `pass first time (<n> low)`;
  3. **rework**: the feedback briefs each role received, and the two-way decisions overturned;
  4. **escaped defects**: `not captured` in this release;
  5. **tokens** per role, the Lead first;
  6. **the person's touches**;
  7. **doors**: confirmed or contradicted per Under test line, filled by editing the same comment after the resurvey.

  Schema: [contracts/39-hansei-record.md](contracts/39-hansei-record.md). A schema v1 record (the acceptance demo's, from a pre-release build) is not comparable with a v2 record: their measures 1 and 2 mean different things.
- **Four wait kinds.** The stage log's `## Waits` table records every stretch in which an agent or the Lead sat still for a reason other than its own work, as one of four kinds: `person` (the item waits on the person's answer), `limits` (a usage or session limit), `stalled` (no progress while the session stayed up, such as the stream watchdog's `no progress for 600s`), and `interrupted` (the connection or the machine went away, including a machine sleep and an API server error). Each wait names the agent it stopped in an `Agent` column. Overlapping held waits count once, to the first kind in measure 1's order. Schema: [contracts/39-stage-log.md](contracts/39-stage-log.md) §3.
- **Truncated transcripts read `not captured`.** A role's transcript cut by a stall or an interruption lost the request in flight, so its spend is short by an unknown amount. Its spend then reads `not captured (transcript truncated by <kind>)`, never a number. The Lead finds the cut from the logged wait, or from `token-spend.sh --require-end` when no wait was logged.
- **`token-spend.sh --require-end`** (exit 6). With this option the script checks that each transcript ends on a final reply: no `[Request interrupted` entry, and no unanswered tool call at the end. A cut transcript exits 6 and names its file by basename on stderr. The Lead passes it for every role transcript at close, never for its own session. Schema: [contracts/39-plugin-scripts.md](contracts/39-plugin-scripts.md) §3.
- **Done, then stopped.** An agent that stalls or fails after writing a complete `Status: done` result is not resumed, when its commits are on the item branch and its paths are clean. The Lead checks the Done list, accepts the result and logs the wait with its kind. Otherwise the agent is resumed as an ordinary interruption. Schema: [contracts/39-stage-log.md](contracts/39-stage-log.md) §3.
- **Close in two commits.** The Lead commits the lead state (`#<id> lead: close`), then removes `work/<id>/` with `git rm -r` and commits again (`#<id> lead: remove work/`), so the removal never needs `-f`. The record is posted before both commits. Schema: [contracts/39-hansei-record.md](contracts/39-hansei-record.md) §6.
- **Hansei record, honesty rule.** A value that could not be captured reads `not captured (<reason>)`. It is never `0`, never blank, and never dropped. `n/a (did not run)` is allowed only for a stage or role that did not run, in measures 2 and 5.
- **Stage log.** The Lead keeps four sections in `work/<id>/00-lead-state.md` while an item runs: `## Label` (written once at item start), `## Stage log` (one row per stage, UTC times from `date -u`), `## Waits`, and `## Person's touches`. Schema: [contracts/39-stage-log.md](contracts/39-stage-log.md).
- **Stage-log cross-check.** Before posting, the Lead compares each row with the role's commit times on the item branch and with the stage-summary comment times. The largest gap goes into the record.
- **Two fingerprints.** `standard` (sha256 over `skills/run/SKILL.md`, `references/*.md`, `agents/*.md`) and `tooling` (sha256 over `hooks/` and `scripts/`). A change to one of them under the same release means a bump was forgotten. Schema: [contracts/39-plugin-scripts.md](contracts/39-plugin-scripts.md) §1.
- **Four scripts** under `plugins/factory/scripts/`, all bash 3.2 compatible:
  - `fingerprint.sh <plugin root>`: prints the release and both fingerprints. It exits 2 when a file cannot be read, when the version is empty or not a semver, and when the root is not a factory root.
  - `check-bump.sh [<base-ref>]`: the bump check, run from the branch's worktree (default base `origin/main`). It exits 0 when the bump covers the change, 1 when it does not, and 2 when the repository, the base ref or the base version cannot be used. A changed file whose name contains a newline counts as standard work.
  - `token-spend.sh [--since T] [--until T] [--require-end] [--] <transcript.jsonl>...`: sums token spend and reports the peak context from transcripts. It needs `jq`.
  - `cut-offs.sh [--since T] [--until T] [--sleep-log <file> | --sleep-log -] [--] <transcript.jsonl>...`: prints one line per gap in which an agent or the Lead made no progress, with its kind (`limits`, `stalled` or `interrupted`) and its start and end. The Lead takes a wait's start from this output, not from the file's last entry. The `--sleep-log` input is the output of the `pmset` filter in `references/hansei.md`. It needs `jq`.
- **Tracker operations** in the GitHub tracker patch: *Find hansei*, *Post hansei* and *Edit hansei*. They act only in the project's own tracker and never name `--repo`.
- **Release tag** in *Merge PR*: after a merge that changed the version, the Lead tags `factory-v<version>` on the merge commit, when the version is a strict semver and the tag does not exist yet.

### Changed

- **Bump rule.** Every change under `plugins/factory/` needs a version bump in `plugin.json`, checked before a PR opens, before a frontier-round PR opens, and again before a merge:
  - **Minor** or more for standard work (`skills/run/SKILL.md`, `references/*.md`, `agents/*.md`).
  - **Patch** or more for every other path under `plugins/factory/`, including `hooks/`, `scripts/`, `skills/setup-factory-skill/` and the plugin's own `plugin.json`.
  - **Major** when message formats or the protocol break. The check never requires a major; the architect calls it and the developer bumps it when told.
  - The baseline resets on a major or minor release only. A tooling-only patch does not reset it.
- **The Lead's refusal.** When the check fails with exit 1, the Lead does not open or merge the PR. It sends the developer a feedback brief quoting the refusal and logs a `refused` row. Exit 2 goes to the person. Changes outside `plugins/factory/` pass without a bump.
- **Setup skill step 6 writes the new tracker section** into a project's `docs/agents/issue-tracker.md`, replacing the `## Factory operations` section.
- **Merge style and the path rule (ADR 0013).** The merge style is decided: `*Merge PR*` keeps `gh pr merge <branch> --merge`, with its reason (`--merge`, never squash or rebase: the role commits are the evidence the hansei record is re-checked against). Every item's role commits, `work/<id>/` included, stay in main's history, and that is expected. `protocol.md` (*Messages*) now says how paths in a message file are written: relative to the worktree (`plugins/factory/agents/developer.md`), relative to the repo's parent for another worktree (`../wt/<id>`), or with the home directory as `~` (`~/.claude/plugins/cache/...`). An absolute path under the home directory is not written, because `work/` is merged with every commit. The security checklist (*Steps*, step 1) reads an absolute home path in a `work/` commit as a low finding, and `work/` in history as expected. The rule covers `work/<id>/` and `work/frontier-<id>/`; see *Known limitations*.
- **Installs follow versions, not pushes.** The factory now carries a `version`, so an install of it changes only when that string changes (the README's note on `version` describes the cache behaviour; ADR 0012 gives the reason). Pushes that do not bump the version do not reach other projects.

### Upgrading a project set up before 1.0.0

A project whose `## Factory operations` section has no *Post hansei* bullet predates 1.0.0. The Lead then uses the plugin's copy of the section for the item, and tells the person once. To bring the project up to date, replace that section with the one in `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md`, which is what `/factory:setup-factory-skill` step 6 does. The Lead never edits the project's tracker doc itself.

### Acceptance demo

The acceptance demo ran in a scratch project, with the item's plugin loaded by `claude --plugin-dir`. Every human-only criterion passed except AC-17, which failed: measure 1 counted stalls and machine sleep as agent work, and a stalled transcript's truncated spend was shown as measured. AC-17 was fixed in schema v2 (feedback issues #44 to #47). QA checked the fix by replaying the demo's own transcripts through the scripts, and accepted AC-17 on that replay, without a demo re-run. The close step's live-session check is listed under *Known limitations*.

### Known limitations at release

From the verdicts on #39 (QA [reviews/qa-39.md](reviews/qa-39.md), security [reviews/security-39.md](reviews/security-39.md)) and from the acceptance demo:

- **Escaped defects** (measure 4) read `not captured` in schema v2. Tracing them back to an item is deferred.
- **Calibration, not baseline.** Items run on the frozen install `9147301f75c3` are recorded as `calibration (pre-baseline)`. Their numbers show what capture costs and are never used as a before. The baseline opens with the first item run on 1.0.0.
- **Fingerprints move with any edit** to the files they cover. A record made before a change keeps the old values, so compare fingerprints only between records that carry them.
- **Path rule covers message files only.** The rule in `protocol.md` applies to `work/<id>/` and `work/frontier-<id>/`. Other committed files (`reviews/`, `contracts/`, `docs/`) are not covered, and the security checklist only scans `work/` (its `git log -S` runs on `work/`). #39's own QA review carried one home path in `reviews/`, which QA removed before the merge (security L13). Widening the rule to every committed file is deferred to a later item.
- **Merge style is decided, and its cost stays.** `--merge` keeps every role commit, with the `work/<id>/` files, in the history of `main` (ADR 0013). Item #39's own history holds one absolute home path, in its QA brief, and one quotation of it in the architect's options; both are accepted and not rewritten. Changing the style later is a one-line template change from the next item, but it does not rewrite main.
- **Worktree location.** Two projects that share one parent folder can collide in `../wt/`. The location is left as it is for now.
- **Setup labels.** The acceptance demo found that the setup did not create every label the stages use: after setup only `wayfinder:slice` existed, and the others were created by hand.
- **Unreadable transcripts.** When a role's transcript cannot be read, its spend reads `not captured`, and a stall or interruption whose start is not in the transcript is marked `~` in the stage log.
- **Close step 6.1 is not chained (security I6, informational, deferred).** The close's guard and step 6.2 run as one shell call that stops at the first failure. Step 6.1 (the commits and the `git add`s) is given as prose commands with no `|| exit 1` after each. A failed `git add` could let the chain go on, and a message file never committed would then be removed by `git clean`. Nothing outside the item's worktree is touched. Widening the chain is deferred ([reviews/security-39.md](reviews/security-39.md)).
- **The close's live-session check is open (AC-18).** The close was checked from its text and from scratch runs of its verbatim commands. The acceptance demo ran on an earlier close text (the close was rewritten in QA's round 5). Whether a live session runs it without a permission prompt, and commits only the `NN-*.md` message files under `work/<id>/`, is still for the person to check.
