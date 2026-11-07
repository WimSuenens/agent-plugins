# Contract 64 — Release 2.0.0: version, files, wayfinding, changelog, decisions, and the map of every criterion

Slice [#64](https://github.com/WimSuenens/agent-plugins/issues/64) · Requirement [64-board-as-run-state](../docs/requirements/64-board-as-run-state.md) · ADRs [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md), [0014](../docs/adr/0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md), [0015](../docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md), [0016](../docs/adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md) · Parts: [64-gh-calls](64-gh-calls.md), [64-board-status](64-board-status.md), [64-role-tasks](64-role-tasks.md), [64-ledger-and-fields](64-ledger-and-fields.md), [64-parallel-slices](64-parallel-slices.md), [64-board-script](64-board-script.md)

Serves AC-44 to AC-46, and holds the answers to the requirement's open questions, the architect's decisions, and the criterion map.

## Paths

Paths:
- plugins/factory/.claude-plugin/plugin.json
- CHANGELOG.md
- README.md
- docs/factory/
- CONTEXT.md
- contracts/
- reviews/qa-64.md
- reviews/security-64.md
- tests/
shared: plugins/factory/.claude-plugin/plugin.json, CHANGELOG.md, CONTEXT.md

**The union** of the `## Paths` blocks of the seven `contracts/64-*.md` files is the item's list. Besides this block, the developer's paths are in the parts: `plugins/factory/skills/run/SKILL.md`, `references/protocol.md`, `references/hansei.md`, `references/baseline.md`, `references/a3.md`, `references/decision-card.md`, `agents/`, `skills/setup-factory-skill/`, `scripts/{board,paths,factory-config,post-text}.sh`, and `plugins/wayfinding/skills/{wayfinder,beachhead}/SKILL.md`. Reviewers pass `--ignore work/64/` to the check ([64-parallel-slices](64-parallel-slices.md) §6). This slice is frozen on the 1.3.0 install, so the version file and the changelog are edited **in the branch** and named on its `shared:` line; a slice run on 2.0.0 leaves them to the lead at merge.

## 1. Version and the bump check (AC-44)

- `plugins/factory/.claude-plugin/plugin.json` gets `"version": "2.0.0"` (the developer). **Major**: tracker contents and the project's state change, and a 1.x project is refused until it migrates (the person settled this; requirement Decision 9).
- **`scripts/check-bump.sh` does not change.** Reading it: a diff that touches `skills/run/SKILL.md` or a `references/*.md` ranks `minor`; the check passes when the new version is above the old in major, or equal major and higher minor. `1.3.0 -> 2.0.0` has a higher major, so it passes and prints `pass: minor bump needed, 1.3.0 -> 2.0.0`. The script's word "minor" is a floor, not a ceiling; a major bump is a human decision (ADR 0012) and no path pattern can tell a breaking change. QA adds the case `1.3.0 -> 2.0.0` to `tests/factory/test_check_bump.sh` and the refusal of `1.3.0 -> 1.3.0`. No script change is in scope.
- **Fingerprints.** `standard` moves (`SKILL.md`, `references/*.md`, `agents/*.md`) and `tooling` moves (four new files under `scripts/`). QA quotes both new values in its verdict (`fingerprint.sh plugins/factory`).
- **Tag.** `factory-v2.0.0` on the merge commit **[post-merge]**. This item runs on the frozen install `1.3.0`, whose text has the tag step; the lead tags as that step says, by hand if the install's text does not. The item's own close uses the **1.3.0 mechanism**: briefs and feedback as files, a stage log in the lead state, no sub-issues, no migration, no `parallel-limit`, no `factory-state` check; **no new-series baseline** is written. The changelog says so (§5). The 2.0.0 series starts with the next run.

## 2. What changes, file by file

| File | Kind | Change | Contract |
|---|---|---|---|
| `plugins/factory/.claude-plugin/plugin.json` | other | `"version": "2.0.0"` | here §1 |
| `plugins/factory/skills/run/SKILL.md` | standard work | the `factory-state` check first in step 0; one-at-a-time rule replaced by the limit; board as status, role tasks, ledger, fields at 8.4a, gate and pause, readers re-pointed, Interruptions and Andon steps | all |
| `plugins/factory/references/protocol.md` | standard work | *Messages*, *Citations*, *Andon* row 4's noun; *Shell* untouched | [64-role-tasks](64-role-tasks.md) §11, [64-ledger-and-fields](64-ledger-and-fields.md) §4 |
| `plugins/factory/references/hansei.md` | standard work | sections 1, 2, 4, 5 and the gemba brief paragraph; section 3's marker stays v5 | [64-ledger-and-fields](64-ledger-and-fields.md) §8 |
| `plugins/factory/references/baseline.md`, `a3.md`, `decision-card.md` | standard work | only where the search of [64-ledger-and-fields](64-ledger-and-fields.md) §7 step 5 finds a reader; otherwise none | |
| `plugins/factory/agents/*.md` (seven) | standard work | where the brief is read from; the result file's name; the architect's Done line; QA and security's diff step | [64-role-tasks](64-role-tasks.md) §11, [64-parallel-slices](64-parallel-slices.md) §6, §10 |
| `plugins/factory/skills/setup-factory-skill/SKILL.md`, `assets/factory.md`, `references/issue-tracker-github.factory.md` | other | step 7 sequence, template, operations list, the `Version 1.x records` heading, the restore text | [64-board-script](64-board-script.md) §8, [64-board-status](64-board-status.md) §2, [64-gh-calls](64-gh-calls.md) |
| `plugins/factory/scripts/board.sh`, `paths.sh`, `factory-config.sh`, `post-text.sh` | tooling, new | as the parts say | the four parts |
| `plugins/wayfinding/skills/wayfinder/SKILL.md`, `beachhead/SKILL.md` | other | the Resurvey step *Slices in flight*; one line in beachhead | [64-parallel-slices](64-parallel-slices.md) §8 |
| `CONTEXT.md` | glossary (architect, done here) | **Ledger**, **Parallel limit**, **History view**, **Board**; **Stage log** marked as the 1.x term | |
| `CHANGELOG.md`, `README.md`, `docs/factory/reference.md`, `docs/factory/release-runbook.md` | docs-writer | §5 | |
| `reviews/qa-64.md`, `reviews/security-64.md`, `tests/` | QA, security | §8 | |

**Not changed by the build:** `scripts/check-bump.sh`, `cut-offs.sh`, `token-spend.sh`, `fingerprint.sh`, `guard-memory.sh`, `hooks/`; the live Project; **this repository's `docs/agents/factory.md` and `docs/agents/issue-tracker.md`** (they migrate through the step after the run closes, so the build does not edit them: AC-41 owns that edit); `docs/requirements/`; `docs/adr/` (no new ADR, §6); the files of #41, #42, #43 and #59.

## 3. Fence

Nothing in the fence moves; the slice moves **where** things are recorded. The checks QA makes against `main`: the *Never overridable locally* section and the *Shell* section of `references/protocol.md` are word for word unchanged; the andon table has seven rows with the same names; the honesty rule's text in `hansei.md` *Value grammar* is unchanged. The memory rules are untouched. The ledger and the fields obey F7: no blank, no guess, no `0` for unknown ([64-ledger-and-fields](64-ledger-and-fields.md) §5).

## 4. The wayfinding plugin (open question 5)

**`plugins/wayfinding/` is not given a version.** ADR 0012 versions only the factory; giving wayfinding a `version` would change how it installs (with a version set, an install changes only when that string changes), which is a decision about wayfinding's release that this item has no mandate to take. Instead: (a) the 2.0.0 changelog entry lists the two wayfinding files it changed under a line "wayfinding (unversioned)"; (b) the run text carries the pause sentence and a **precedence sentence**: where an installed older wayfinding text says anything about running slices one at a time, the run's rule governs; (c) `claude plugin validate` expectations are unchanged (the four no-version warnings remain intentional). Cost to undo: a version string and a CHANGELOG heading, under a day. Risk accepted: `"dependencies": ["wayfinding"]` cannot pin a wayfinding state, so a machine with an older wayfinding gets the run's rule through (b).

## 5. The changelog entry and the docs (AC-46)

The docs-writer's 2.0.0 entry, in this order:

1. First lines: **major release**; a 1.x project must run `/factory:setup-factory-skill` (the migration) before `/factory:run` accepts it; the migration shows the table and the item count and waits for a yes; **undoing ADR 0014 or ADR 0015 after this release is a 3.0.0 release**.
2. What is new: the board as status (six values, `Kind`, `Role`, two views), role tasks as sub-issues, the ledger and the five fields, parallel slices with `parallel-limit` (default 2), the `factory-state` check.
3. **Removed from the standard:** the `## Stage log`, `## Waits` and `## Person's touches` sections of the lead state (their data lives in the ledger and the sub-issues), the old `Factory status` values (Designed, In progress, In review, Ready to deploy), the files `NN-brief-<role>.md` and `NN-feedback-<role>.md`, the lead state's `Status:` line, and "Items run one at a time".
4. **Unverified**, under that heading, every item of the requirement's list by name (1 limits and result size; 2 anything needing a live Project; 3 whether the person can tell what to do next from the board; 4 parallel running; 5 hansei numbers across a real run; 6 migration of a project other than agent-plugins), plus the architect's three additions: the `Needs you` filter token (`factory-status:"Waiting on you"`, [64-ledger-and-fields](64-ledger-and-fields.md) §6), the GitHub shape of `gh project item-list` that `board.sh` reads (the lower-case field keys and option names of [64-gh-calls](64-gh-calls.md) §2), and the frontier-round role-task fields (`not captured`). It says **none was exercised**.
5. The sentence: this item ran on the frozen 1.3.0 install; the migration was tried once on a scratch Project by the lead, with the outcome written after that try (**a failed try is an andon, not a changelog line**).
6. `wayfinding (unversioned)`: the two files changed (§4).
7. The README and `docs/factory/` pages describe the board, role tasks, the setting and the migration in their own words and contradict nothing above. `docs/factory/reference.md` gets an entry per `64-*` contract. `docs/factory/release-runbook.md` gets *Release 2.0.0*: the scratch-Project try by the lead, the tag by hand, and the sentence on what the person does after the run closes: **run the migration on the live Project, then confirm the two views.**

## 6. Decisions (architect, two-way doors; chosen / rejected / cost to undo)

No one-way door was found. The three of this map are decided (ADRs 0014 to 0016) and are built to; **no new ADR is written** (nothing here is hard to reverse, surprising and a real trade-off all at once). Each decision below was checked against the three-part test; none passes it.

1. **Sub-issues are found, created and linked through the REST endpoints** (`GET`/`POST …/sub_issues`, [64-gh-calls](64-gh-calls.md)), with a numeric database id. Rejected: the GraphQL `addSubIssue` mutation (it needs node ids, and `{owner}`/`{repo}` do not expand in GraphQL variables the way they do in a REST path). ADR 0014 says "links it with `addSubIssue`"; the REST call is the same operation. Undo: two call forms, an hour.
2. **Four scripts: `paths.sh`, `factory-config.sh`, `post-text.sh`, `board.sh`.** Rejected: all text (the overlap table, the config lines, the size split and the migration order then cannot be run by a test; QA would test its own copy of the rule). ADR 0016's "no new tooling" is about lock registries and hooks; a two-list comparison is the "one comparison" it names. If the lead reads it otherwise it can be overturned by a feedback brief: the tests then drive reference code in `tests/` and the scripts go. Undo: a day plus the tests' reference code.
3. **The ledger is one comment on the slice ticket** holding the Tasks, Waits and Touches tables. Rejected: waits and touches as one comment each (a dozen comments per item; no single table to read); a comment per role task (the readers then need N reads); the lead state (the sections must leave it); the sub-issue timeline (not exposed). ADR 0015 point 4 says status, stage log, waits and touches "move to the board and the sub-issues"; the ledger is on the slice, the parent of the sub-issues, and out of the lead state, which is the point of the sentence. Undo: a day (rewrite the table's home).
4. **The five fields are text.** Rejected: Number (blank for `not captured`, fence F7), Number plus a note field, a sentinel. Undo: half a day (new fields and a copy).
5. **The hansei record stays at schema v5.** The header key `stage-log cross-check` keeps its 1.x name; the measures keep keys, order and grammar. Rejected: v6 (a reader and a test-pin change with no new information). Undo: a v6 record, a day.
6. **After a usage-limit hit the start gate behaves as `N = 1`** until the slices in flight have closed. Rejected: no change (two slices would go on spending against a limit just hit, which the existing rule already forbids for roles). Undo: one sentence.
7. **`plugins/wayfinding/` stays unversioned** (§4). Rejected: a version for it. Undo: under a day.
8. **`check-bump.sh` is unchanged** (§1). Rejected: a `major` level (no path pattern can say breaking). Undo: n/a.
9. **The `Needs you` filter is `factory-status:"Waiting on you"`**, not the requirement's literal `status:"Waiting on you"` ([64-ledger-and-fields](64-ledger-and-fields.md) §6). The literal names the unused built-in field. Unproven until the scratch try. Undo: the fallback prints the filter; one string.
10. **`work/` holds five kinds of draft plus the lead state** (result, question, decision card, andon, lead state), and the `Citations` rule covers decision cards and needs-you comments, not briefs and closing comments ([64-role-tasks](64-role-tasks.md) §9, §11). Rejected: the requirement's AC-17 read as three kinds (the card and andon drafts would lose their home) and the wide `Citations` reading (the brief's `Output` line must name the draft). Undo: one rule.
11. **The Tasks table lists role tasks only and numbers them from 1** ([64-ledger-and-fields](64-ledger-and-fields.md) §2). Rejected: keeping lead and person rows (nothing reads them). The gemba line's `row <#>` therefore differs from 1.3.0's for the same stage; replays compare by stage and role. Undo: add rows back, an hour.
12. **The snapshot lives under `${XDG_STATE_HOME:-$HOME/.local/state}/factory/board-<owner>-<project>/`**. Rejected: a temp directory (cleaned in days; the snapshot is the only record of the old distinction); a path inside the repo (forbidden). Undo: a flag default.
13. **The `Paths:` block is a `## Paths` section directly after the contract's title block**, one per contract file, the slice's list the union of `contracts/<id>-*.md` ([64-parallel-slices](64-parallel-slices.md) §1). Rejected: one block in a separate index file (it drifts from the contracts). Undo: a script argument.
14. **`parallel-limit: <N>`** in `## Parallel slices`, `N` a positive integer; **`factory-state: 2`** is line 1 ([64-parallel-slices](64-parallel-slices.md) §3). Rejected: a line inside the Tracker section; a JSON header. Undo: under a day (ADR 0015 already fixes `factory-state: 2` as a first line).
15. **The list is compared when the architect's result is read, before any other role's brief** ([64-parallel-slices](64-parallel-slices.md) §5), and again if a contract of an in-flight slice changes. Rejected: only at QA; at slice cut (no list yet). Undo: one rule.
16. **Reviewers diff with `git diff --name-only origin/main...item/<id>`** after a fetch, and ignore `work/<id>/`. Rejected: local `main` (may be stale and show main's own commits); `main...` literal. Undo: one sentence.
17. **The result file's `NN` is assigned by the lead in the brief's `Output` line.** Rejected: the role counting (two roles briefed together would collide in order). Undo: one rule.
18. **Frontier-round role tasks get `not captured (frontier round keeps no ledger)` in `Tokens` and `Minutes`.** Rejected: leaving them blank (F7); computing from agent ids the round does not keep. Undo: when a frontier round gets a record (Deferred in the map).
19. **A comment is capped at 60,000 bytes by the helper** (below 65,536 characters in every encoding). Rejected: counting characters in `bash` 3.2 (locale-dependent). Undo: a constant.
20. **`Hours` is lead time in hours to two decimals** (`187m` is `3.12`), a text value. Rejected: `<dur>` text under a field named `Hours`. Undo: a rule.
21. **A role task created but not linked is found by `T-recent`** (the lead's 100 newest issues) when the parent's sub-issues do not hold the marker. Rejected: a search query (index latency); the lead state alone (may be lost). Undo: one operation.
22. **A cut-off or unlinked state is never lost to a lead restart:** the open person wait is the needs-you comment's `Asked:` line; other open waits are found again by the close scan. Rejected: an open-wait row in the ledger (a PATCH at every stop). Undo: one rule.

## 7. The requirement's open questions, answered

| Open question | Answer |
|---|---|
| Stage-log readers (AC-25, AC-26) | all re-pointed with no loss: [64-ledger-and-fields](64-ledger-and-fields.md) §4; replay plan §7 there. No question to the lead |
| Field type for `not captured` (AC-22) | text, [64-ledger-and-fields](64-ledger-and-fields.md) §5; meets F7. No question to the lead |
| Where touches and waits are recorded | the ledger comment; the open person wait in the needs-you comment |
| `Paths:` place; AC-30 check point; `parallel-limit` format; script or text | [64-parallel-slices](64-parallel-slices.md) §1, §5, §3; text and a script |
| Whether wayfinding is bumped | no, §4 |
| `check-bump.sh` and a major bump | passes unchanged, §1 |
| Tracker operations the fake `gh` must answer | [64-gh-calls](64-gh-calls.md) |
| Docs-writer: README and runbook | §5 |
| Lead: the scratch Project try | not a build task; the contracts give it `board.sh plan`, `apply --yes`, `finish` and the restore text; a failure is an andon |

## 8. What QA writes in `tests/`

All offline, in the style of `tests/factory/` (`lib.sh`; text checks read the file, replay checks run the extracted command or the script). `gh` is always the fake of [64-gh-calls](64-gh-calls.md) §3, placed first on `PATH`; no test reaches the network.

| Suite (new file) | Covers | Fixtures |
|---|---|---|
| `tests/factory/fake-gh/gh` and `lib` helpers | the fake and its log | |
| `test_board_status.sh` | AC-1 to AC-8 | `board-run.md` (the narrated run of [64-board-status](64-board-status.md) §3), template files |
| `test_role_tasks.sh` | AC-9 to AC-19 | **Big result**, **Home-path result**, resume fixtures, limit fakes |
| `test_ledger_fields.sh` | AC-20 to AC-26 | **W12, C49, L57** in old and new form (`fixtures/board/replay/`), the expected values QA writes first |
| `test_parallel.sh` | AC-27 to AC-34 | list pairs, `parallel-limit` and `factory-state` cases, throwaway git repo for `check` |
| `test_board_script.sh` | AC-6, AC-21, AC-35 to AC-43 | **Board-v1**, **Board-v2**, **Board-mid** variants, fresh project, the `Priority`-clearing fake |
| `test_release64.sh` | AC-44 to AC-46 | `plugin.json`, `check-bump.sh` cases, diff paths against the union of the `Paths:` blocks, home-path and secret search over the diff |

**Pins that move.** Existing suites pin text this item rewrites: `test_standard_text.sh`, `test_gemba.sh` (the sample rule's source line and the *Which brief* paragraph), `test_andon_*.sh` (kind 4's noun, the `Andon A<n>` row), `test_baseline_a3.sh` and `test_baseline_replay.sh` (only if the search finds a reader there). QA updates each and lists the changed pins with the reason in its verdict.

**QA's verdict quotes:** the two fingerprints; the check-bump line; the three replay tables; the search results of [64-ledger-and-fields](64-ledger-and-fields.md) §7 step 5; and the count of `unknown` ops in the fake's log (zero).

## 9. Every acceptance criterion, and where it is met

| AC | Contract |
|---|---|
| 1 to 8 | [64-board-status](64-board-status.md); 3 also [64-gh-calls](64-gh-calls.md); 6 also [64-board-script](64-board-script.md) §6 |
| 9 to 19 | [64-role-tasks](64-role-tasks.md); calls in [64-gh-calls](64-gh-calls.md) |
| 20, 21 | [64-ledger-and-fields](64-ledger-and-fields.md) §5, §6; creation in [64-board-script](64-board-script.md) §5, §6 |
| 22, 23 | [64-ledger-and-fields](64-ledger-and-fields.md) §5, §7 |
| 24 | [64-ledger-and-fields](64-ledger-and-fields.md) §3, §8 |
| 25, 26 | [64-ledger-and-fields](64-ledger-and-fields.md) §4, §7 |
| 27 to 33 | [64-parallel-slices](64-parallel-slices.md) |
| 34 | [64-parallel-slices](64-parallel-slices.md) §3; written by [64-board-script](64-board-script.md) §7 |
| 35 to 43 | [64-board-script](64-board-script.md) |
| 44 to 46 | here §1, §2, §5 |

Every criterion maps to a contract; no ADR is new.

## 10. Proposals to other owners (not written here)

- **Docs-writer:** §5. `docs/agents/factory.md` and `docs/agents/issue-tracker.md` of this repository are **not** edited by the build; they migrate through the step after the run closes.
- **Product-owner:** requirement AC-6 and ADR 0015 point 3 write the filter `status:"Waiting on you"`; decision 9 changes the token to `factory-status:"Waiting on you"`. Amend the requirement's text if the lead agrees; AC-17's "three kinds" is read as five drafts (decision 10).
- **Lead:** the scratch-Project try needs `gh auth refresh -s project` and a scratch Project the lead creates; it records the outcome after the try.
