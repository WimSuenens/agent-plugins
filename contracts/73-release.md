# Contract 73 — Release 2.1.0: version, changelog, the tests that pin changed wording, the answers to the requirement's open questions, and the map of every criterion

Slice [#73](https://github.com/WimSuenens/agent-plugins/issues/73) · Requirement [73-test-ownership-and-tdd-loop](../docs/requirements/73-test-ownership-and-tdd-loop.md) · Decision: [#42, "Agreed direction"](https://github.com/WimSuenens/agent-plugins/issues/42) · Parts: [73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md), [73-optional-code-review](73-optional-code-review.md) · Release rules: [64-release](64-release.md), [ADR 0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md)

Serves AC-7, AC-8 and AC-9 (with the other two contracts), and holds the architect's answers to the requirement's open questions and the criterion map.

## Paths

Paths:
- plugins/factory/.claude-plugin/plugin.json
- CHANGELOG.md
- README.md
- docs/factory/reference.md
- docs/requirements/73-test-ownership-and-tdd-loop.md
- tests/factory/
- contracts/73-ownership-and-tdd-loop.md
- contracts/73-optional-code-review.md
- contracts/73-release.md
shared: plugins/factory/.claude-plugin/plugin.json, CHANGELOG.md

## 1. Version and shared files

- `plugins/factory/.claude-plugin/plugin.json` `version`: `2.0.0` becomes `2.1.0`. `check-bump.sh` wants a bump above main's `2.0.0` because agents, the protocol, the run skill and a template change; the change adds rules and removes none, so it is a minor release, not a major (no project has to migrate: `factory-state: 2` stays). The marketplace file carries no version.
- `CHANGELOG.md`: a `## factory 2.1.0 (#73)` entry above the 2.0.0 entry, in its form (release line, slice and map links, contracts, what changed per file). It says in words: **the new instruction text ships unverified**; it cannot be run live offline beyond the script tests, so instruction-following is shown only by the scenario cards and human review (the frame's *Deliberately faked*). It names the pilot comparison (test-to-green time; QA and developer rework rounds against #64 on 1.3.0; recorded by the lead in the hansei record). It names `Tests` as the new ledger stage. It states that no ADR was needed and that the risk triggers are prose, with the trigger for a script: the lead misjudges a trigger in a pilot run. `docs/factory/release-runbook.md` is not changed.
- `README.md`: the factory's release table gains a 2.1.0 row in its form. docs-writer's.
- `docs/factory/reference.md`: the contract index gains the three `73-*` contracts (it states "Twenty-five contracts"; the count and the 73 entries are updated). docs-writer's.
- `docs/requirements/73-test-ownership-and-tdd-loop.md` is the product-owner's and is listed only because the brief names it; this slice does not change it.
- `docs/agents/factory.md` (this repo's) and the other plugins: **not changed** (the requirement says no point requires it; this repo's developer own tests sit in `plugins/`).

## 2. Existing script tests that pin wording or values this build changes

The developer does not edit `tests/` (this slice's own rule). QA updates these before the Build brief and decides, per row, whether to update or retire the check with a named skip.

| Test file | Check(s) | Why it changes | Action |
|---|---|---|---|
| `test_standard_text.sh` | `ac1-plugin-version`, `ac1-version-own-line` (lines 20 to 21) | pin `2.0.0` and the line `"version": "2.0.0",` | update to `2.1.0` |
| `test_andon_text.sh` | `ac29-version-is-minor-above-1.1.0` (line 421) | pins `2.0.0` | update to `2.1.0` |
| `test_gemba.sh` | `t13-plugin-json-2.0.0` (line 552) | pins `2.0.0` | update to `2.1.0` (rename the check) |
| `test_fingerprint.sh` | the cache path `…/factory/2.0.0`, `ac2-install-path-release`, `ac2-plugin-dir-release`, `ac2-real-plugin-json` (lines 29 to 36) and the `sed` of `2.0.0` to `2.0.1` (line 95) | pin the release text of the real plugin | update to `2.1.0` and `2.1.1` |
| `test_release64.sh` | `ac44-plugin-json-version-2.0.0`, `ac44-main-version-1.3.0`, `ac44-check-bump-line`, `ac44-new-release-line`, `ac45-off-list-paths-are-only-the-earlier-roles-files` | slice-64 deltas against a main that has since moved to 2.0.0; the off-list comparison runs against 64's contracts | retire as the other slice-64 deltas were (a skip naming slice 73), or re-point at 73's contracts; the 2.0.0 changelog checks stay |
| `test_standard_text.sh` | `ac11-acceptance-demo-stage` (line 59) | pins the hansei `Stage` list in `references/hansei.md` | add `Tests` after `Contracts and ADRs` |
| `test_parallel.sh` | `ac30-text-order-table-then-comparison` (line 233), `ac30-step-6-comparison-after-architect-done`, `ac27-*` (architect lines) | pin the `| Build, tracer bullet first |` row's place before the comparison text, the architect sentence, and the architect's Paths lines | **no change expected**; they must still pass (they are the guard that the build keeps those lines) |
| `test_round2_64.sh` | `r2-two-option-form-in-*` (line 77 to 79) | pins `git -c core.quotePath=false diff --no-renames --name-only` in the QA file and the run skill | **no change expected**; the QA changed-paths line stays word for word |
| `test_board_status.sh` | `ac7-template-has-no-old-value` (line 52) | greps the template for `Designed`, `In progress`, `In review`, `Ready to deploy` | **no change expected**; the template's new paragraph avoids those words |
| `test_andon_text.sh` | `agent-reads-protocol-*` (line 405), `ac17-setup-row` (line 192) | pin the first line of each agent and the lead's template row | **no change expected** |
| `test_fingerprint.sh`, `test_baseline_a3.sh`, `test_andon_kind3_kind4.sh` | fingerprint-moves and role-outside-role fixtures | fingerprints are computed, fixtures use their own ownership table | **no change expected**; QA runs the whole suite and reports any other red |

QA adds new checks and scenario cards in `tests/factory/` (a new `test_ownership_tdd.sh` for the machine-checkable parts of AC-1 to AC-9 and the scenario cards in a directory of cards beside it). The names are QA's. `tests/run.sh` picks up any `tests/factory/test_*.sh` file, so no runner change is needed. The shell-script rules of the repo's tests apply (bash 3.2, data-only cases).

AC-7 and AC-8 are mostly byte comparisons against the baseline (`git show 4086c9c:<path>`): QA writes them as "these lines exist unchanged" and "the *Never overridable locally* section is identical", not as a copy of the prose.

## 3. ADR: none, and why I agree with the requirement

No ADR. The test for a one-way door has three parts (hard to reverse, surprising without context, a real trade-off). Every change here is markdown inside the plugin, reverted by a later edit at the price of one release; the roles' behaviour in a live session is the only cost of being wrong, and the pilot measures exactly that. The decision's source is the person's own comment on #42, which this contract cites; it is linked from the contracts, not restated in an ADR. The one place that comes close, QA's new `Tests` stage, adds one word to a ledger list that has changed before without an ADR (2.0.0 did it). **Disagreement: none.**

## 4. Answers to the requirement's open questions

**The developer's own-test path fits the Paths blocks (the question the brief named).** Yes, with one rule written into the architect file ([73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md) §5): a contract's `Paths:` lists the developer's own test files too, or the directory that holds them (`src/` or, here, `plugins/`, ending in `/`). Reasons, checked in the scripts:

- `paths.sh` treats a listed directory as a prefix of every path under it, so a developer test beside the code is on the list when its directory is. A test file the list names neither by file nor by directory is `off-list:` and QA records a finding of at least `medium`; the architect rule prevents that finding.
- The kind-3 reader gives a path to the row with the longest matching token. A developer unit test under the `src/` row's path is owned by the developer and is not flagged; the same file under `tests/` is flagged `role-outside-role` (owner qa-engineer). So the ownership table and the Paths block agree, and the protocol needs no new exception.
- If a repo keeps unit tests in a directory of their own outside `tests/`, its table gets a developer-owned row for that directory (template paragraph, [73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md) §7). A developer row under `tests/` is not allowed: `tests/` stays on the `qa-engineer` row and on no other (AC-1), and the longest-token rule would otherwise hand the nested path to the developer. A repo that nests its unit tests under `tests/` moves them; the template says so.

**#42's "Standard change":** answered in the `factory.md` template (the `Tests.` paragraph) and in the developer's agent file (own tests, harness case), AC-6.

**Where the QA test-preparation task is recorded:** a role task of the slice, ledger `Stage` `Tests`; the pilot's "QA passes" counts `QA` rows only, so the count compares with #64.

## 5. Two-way decisions taken in these contracts

| Decision | Chosen | Rejected | Cost to undo |
|---|---|---|---|
| where the five points sit | a new `## Tests` section in the protocol, a `Tests.` paragraph in the template, edits in each agent file | folding them into `## Ownership`; one new reference file | one edit to the files; the references would need a pointer in each agent |
| the code-review decision | a lead decision with no role task and no status, recorded as a line in the lead state and the stage summary | a stage-table row with a role task; a new role | a later edit; no ledger or board change |
| QA test preparation | its own role task and ledger stage `Tests`, before Build | counting it as a `QA` row; having the architect write the tests | one word in `hansei.md` and the stage table row |
| `/tdd` | stays in the developer's front matter, for its own tests | removing it | one front-matter line |
| risk triggers | prose in the run skill, decided from the contracts' `Paths:` and wording | a script or checklist | deferred on the map; trigger: the lead misjudges a trigger in a pilot run |
| the diff-breadth check | every slice, a rework task `Source: lead` on a hit | only after a review ran | one paragraph |

## 6. Deferred, with the trigger

- A script or checklist for the risk triggers: when the lead misjudges a trigger in a pilot run (the map's deferred line; recorded on the slice's resurvey).
- `docs/factory/reference.md` restating the five points beyond the contract index: docs-writer's judgement; nothing here depends on it.

## 7. Criterion map

| AC | Contract | Section |
|---|---|---|
| AC-1 | [73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md) | §2, §3, §4, §7 |
| AC-2 | [73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md) | §1, §2 to §6 |
| AC-3 | [73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md) | §2, §4 |
| AC-4 | [73-optional-code-review](73-optional-code-review.md) | §1 to §4 |
| AC-5 | [73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md) | §3 |
| AC-6 | [73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md) | §3, §7; this file §4 |
| AC-7 | all three | the "word for word" lists; this file §2 (the guards) |
| AC-8 | [73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md) | §2 (only `## Tests` is added); this file §2 |
| AC-9 | all three | §1 vocabulary; QA's scenario cards of AC-1, AC-2 and AC-6 played against all six files |

## 8. Worked example (the release check)

After the build, in the item worktree: `git fetch origin main`, then `bash plugins/factory/scripts/check-bump.sh` prints `pass: minor bump needed, 2.0.0 -> 2.1.0` and exits 0. `bash plugins/factory/scripts/fingerprint.sh plugins/factory` prints `release: 2.1.0`, and both fingerprints differ from main's. `git diff --stat origin/main...item/73` lists only the paths of the three contracts plus `work/73/` and `contracts/73-*.md` (ignored by QA's check) and the earlier roles' `docs/requirements/` file. `bash tests/run.sh` prints `ALL PASSED` with the slice-64 retirements named as skips.
