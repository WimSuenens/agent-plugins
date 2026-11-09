# Contract 73 — Test ownership, the TDD loop, test scope and the developer's Done list: what each file says

Slice [#73](https://github.com/WimSuenens/agent-plugins/issues/73) · Requirement [73-test-ownership-and-tdd-loop](../docs/requirements/73-test-ownership-and-tdd-loop.md) · Decision: [#42, "Agreed direction"](https://github.com/WimSuenens/agent-plugins/issues/42) (locked, built to, not reopened) · Parts: [73-optional-code-review](73-optional-code-review.md), [73-release](73-release.md) · Builds on [64-role-tasks](64-role-tasks.md) (role tasks, the kind-3 path rule)

Serves AC-1, AC-2, AC-3, AC-5, AC-6, AC-7 (QA gate lines), AC-8 and AC-9. The seams here are **text sections**, not code. For each file this contract names the section, the statement (its meaning; the developer writes the prose), and the lines that stay word for word. No ADR: every change is markdown a later edit reverts (see [73-release](73-release.md) §3).

## Paths

Paths:
- plugins/factory/references/protocol.md
- plugins/factory/agents/developer.md
- plugins/factory/agents/qa-engineer.md
- plugins/factory/agents/architect.md
- plugins/factory/skills/run/SKILL.md
- plugins/factory/skills/setup-factory-skill/assets/factory.md
- plugins/factory/skills/setup-factory-skill/SKILL.md
- plugins/factory/references/hansei.md
shared: none

## 1. The terms every file uses

One vocabulary, so a script test and a reviewer can tell the files agree (AC-2, AC-9). Each file uses the words below where it states its step; it does not need all of them.

| Term | Meaning |
|---|---|
| **acceptance suite** | everything under `tests/`; owned by qa-engineer |
| **targeted test** | the test or tests QA prepared for the slice, named in the developer's brief |
| **own tests** | tests the developer needs for its own steps, such as unit tests beside the code; developer-owned; not the acceptance suite |
| **scenario** | a stated situation with the answer a reader should reach; assessed by a person or an agent reading the named files |
| **Human-only criteria** | the list in QA's verdict (already defined in the QA agent file) |

The loop, in order, with who acts (every file states only the steps it owns):

1. **Architect**: contracts define the seams and the expected behaviour, in terms QA can test without reading code.
2. **QA**: prepares the next scenario test (the targeted test) before its behaviour slice, in `tests/`; the test fails for the expected reason.
3. **Developer**: implements and runs the targeted test until green.
4. **Unclear test or contract**: the developer does not change the test or the contract; it writes a question, the test goes back to QA, the contract to the architect, through the lead.
5. **QA**: verification, with the independent pass or block verdict. **Security**: review, still mandatory.

## 2. `plugins/factory/references/protocol.md`

**Section:** a new section `## Tests`, directly after `## Ownership` and before `## Shell`. Nothing else in the file changes (AC-8). The text of `## Never overridable locally` (F1 to F7 and question E) stays byte-identical, and so does every other existing line.

**Statements:**

- **Ownership (AC-1).** `tests/` belongs to qa-engineer. The developer never creates, edits or deletes a file under `tests/`. A commit that does is a kind-3 hit (the path rule already covers it; the section may say so in one clause).
- **Own tests (AC-6).** The developer's own tests live in the developer's own path, beside the code; they are not the acceptance suite. The protocol does not say the developer may create tests under `tests/` during Build.
- **The loop (AC-2).** The steps of §1, short. The developer's half is: run the targeted test until green; an unclear test or contract is a question to the lead (a *Question*, role → lead) that names the test or contract; the lead sends it to QA or the architect; the developer does not change the test.
- **Verdicts.** QA keeps the independent pass or block verdict. The security review stays mandatory. (One sentence; the F3 row is not touched.)
- **Test scope (AC-3).** Three parts, in this order: executable behaviour and important safety invariants are automated; instruction-following is assessed with realistic scenarios and human review, not broad exact-prose assertions; exact text is asserted only where a machine-readable format or a safety rule needs it.

**Word for word:** every existing line, the F3 row above all (AC-7, AC-8).

## 3. `plugins/factory/agents/developer.md`

| Section | Change |
|---|---|
| `## Inputs needed` | add: the targeted test QA prepared, named in the brief |
| `## Steps` | step 3 `Widen slice by slice, test first with /tdd.` is replaced (AC-5, AC-9). New steps, in order: (1) read the requirement and its contracts; (2) run the targeted test and see it fail for the expected reason; (3) build the tracer bullet against it; (4) widen slice by slice, running the targeted test until green; the developer's own tests for its steps, written with `/tdd`, sit beside the code; (5) run the repo's own test and lint commands; (6) finish the result (changed files, how to run, open questions). The words `test first with` do not remain |
| new paragraph under `## Steps`, after the contract-friction line | the **one sentence**: *You do not create, edit or delete files under `tests/`; QA owns them.* Then: a targeted test whose expected value looks wrong, or a contract that disagrees with the test, goes to the lead as a question naming the test; keep building on the agreed contract meanwhile; never change the test. Then the own-tests rule (below) |
| `## Done` | see below |

**Own tests (AC-6, the answer to #42's "Standard change").** Tests the developer needs for its own steps are developer-owned and sit in the developer's own path (the `src/` row of the `factory.md` template, `plugins/` in this repo). They are not the acceptance suite. QA may read, run and ignore them. The acceptance suite is `tests/`. When the slice's deliverable is a test harness, QA writes the harness and its first cases in `tests/`, the developer builds what the harness runs, and the lead makes no ad-hoc ownership decision.

**`## Done`, replacing the three lines of the baseline:**

- The applicable tests were run: the targeted test for each slice, then the repo's test and lint commands, and they exit 0.
- The result lists changed files and open questions.

The baseline line `Every acceptance criterion of the item has a passing test.` is deleted. Neither the Done list nor the Steps may make the developer write, own or derive the acceptance tests. `skills: mattpocock-skills:tdd` stays in the front matter: `/tdd` still guides the developer's own tests.

## 4. `plugins/factory/agents/qa-engineer.md`

| Section | Change |
|---|---|
| line under the title block | `Tests come from the requirement; read the implementation only to locate the cause of a failure.` stays; add after it: QA owns `tests/` and prepares the tests the developer runs |
| `## Inputs needed` | add: the architect's contracts (read before the build). The developer's result is an input of the verification only |
| `## Steps` | two phases. **Test preparation** (before the Build stage, one task per behaviour slice): from the criteria and the contracts, write the next scenario test in `tests/`; it fails for the expected reason; name the targeted test (command and expected failure) in the result so the lead puts it in the developer's brief; an unclear contract is a question to the lead. **Verification**: the three existing steps, with step 1 reworded (below) |
| step 1 | `Derive at least one test per acceptance criterion.` becomes: for each acceptance criterion derive one of: an automated test (executable behaviour, safety invariants), a realistic scenario assessed by human review (instruction-following), or an entry in the Human-only criteria list |
| new subsection or paragraph, **test scope** | the three parts of §2 (automated; scenarios and human review; exact text only for machine-readable formats and safety rules). QA never needs a broad exact-prose assertion to reach a verdict |
| `## Done` | line 1 only is reworded: `Every acceptance criterion maps to a test, a scenario, or the Human-only criteria list, and the verdict lists each.` |

**Word for word (AC-7):**

- the step line `Write `reviews/qa-<id>.md` with the verdict: pass or block, and a **Human-only criteria** list: each acceptance criterion only a person can judge in a real client, with what they should look for, or `none`.`
- `Owns the release verdict. A block stands until a re-run passes.`
- `Every defect has a reproduction.`
- `The verdict is recorded, with its Human-only criteria list.`
- the changed-paths line, whole (it carries the `git -c core.quotePath=false diff --no-renames --name-only` form that `test_round2_64.sh` pins)
- `Each defect carries reproduction steps, expected result, actual result, and severity.`

A criterion with no test, no scenario and no Human-only entry is a defect of the verdict; so is a verdict that exists only because QA added an exact-prose assertion.

## 5. `plugins/factory/agents/architect.md`

| Section | Change |
|---|---|
| `## Output`, the `contracts/` bullet | add: each contract names the **seams** (the public interface, or for a text slice the section of a file) and the **expected behaviour** in observable terms, so QA can write the test from the contract alone |
| same bullet, the `Paths:` sentence | add: the developer's own tests that the slice will add beside the code are listed too (a file, or the developer's directory ending in `/`); they are not under `tests/` |
| `## Done` | add one line: `Every contract names its seams and expected behaviour, so QA can prepare the test from it.` |

**Word for word:** every existing line that `test_parallel.sh` pins (the `Paths:` block and `shared:` line Done item, `## Paths`, `every role's paths`), the Authority lines, and the Done lines `Every acceptance criterion maps to a contract or an ADR.`, `Every contract carries a worked example.` and `Every ADR records the rejected alternatives.`

## 6. `plugins/factory/skills/run/SKILL.md` (the loop part; the review part is [73-optional-code-review](73-optional-code-review.md))

- **Stage table** (`## 6. Run the stages`): one new row directly after `| Contracts and ADRs | architect |`: `| Tests, for each behaviour slice, before the build | qa-engineer |`. The row `| Build, tracer bullet first | developer |` stays exactly as written (`test_parallel.sh` finds it by its prefix and orders it before the comparison text). The ledger `Stage` value of the new task is `Tests` (title `Tests: qa-engineer on #<id>`); `Verification` stays `QA`, so the pilot's "QA passes" count is unchanged.
- **Stage loop, item 1** (brief rules): add at its end: the developer's **Inputs** name the targeted test QA prepared (read from the Tests result); the Tests task's **Inputs** name the contracts and the criteria. No tracker content is copied in.
- **Stage loop, item 4, the `done` bullet**: after the existing sentence `After the **architect's** `done`, make the path comparison before any other brief (*Parallel slices*).` (word for word) add: then take the code-review decision ([73-optional-code-review](73-optional-code-review.md)), then brief QA for the Tests stage.
- **Tests stage rules** (a short paragraph after the table): QA's Tests task runs after the architect's `done`, the path comparison and the code-review decision, and before the Build brief; the Build brief is never written before the Tests result names the targeted test. The stage is skipped only when the contracts define no behaviour to test; the stage summary says so. Tests QA prepared may stay red until the developer's Done. A developer question about a test is routed to QA (a rework or clarification task for QA, `Source: lead`), about a contract to the architect; the lead answers neither by editing `tests/` or a contract.
- **Word for word (AC-7):** item 5 `QA and security findings go to the developer as a **rework task** (*Role tasks*, rework); repeat until both verdicts are `pass`.`; the `Done when` sentence `both verdicts are `pass``; the sentence that QA and security check the diff against the path list; and every pinned line named in [73-release](73-release.md) §2.

## 7. `plugins/factory/skills/setup-factory-skill/assets/factory.md` and its `SKILL.md`

**Template, `## Ownership`:** the table keeps its rows unchanged (`` `tests/`, `reviews/qa-*` `` stays on the `qa-engineer` row and on no other row; AC-1). Directly after the table add a paragraph `Tests.` with the statements of §3 *Own tests*: `tests/` is the acceptance suite, QA owns it and the developer never edits it; the developer's own tests (unit tests beside the code) are developer-owned, sit in the `src/` row's path, are not the acceptance suite, and QA may read, run and ignore them; where a repo keeps unit tests in a directory of its own, give that directory a row owned by the developer, never a path under the `tests/` row; when the deliverable is a test harness, QA writes it and its first cases in `tests/`. The paragraph holds none of the words `Designed`, `In progress`, `In review`, `Ready to deploy` (`test_board_status.sh` greps the template for them). It contains no backticked token in a table cell, so the kind-3 reader (which reads only the table) is unaffected.

**Setup `SKILL.md`, step 5:** in the bullet `Point `src/` and `tests/` in the ownership table …` add one sentence: unit tests that sit beside the code stay under the developer's row; only the acceptance suite goes under `tests/`. No line `test_*.sh` pins is changed.

## 8. `plugins/factory/references/hansei.md`

One edit: the `Stage` row of the ledger columns (line with `one of: `Requirement`, `Contracts and ADRs`, `Environment`, `Build`, `QA`, …`) gains `Tests` after `Contracts and ADRs`. Nothing else in hansei changes. The lead's ledger is the only reader.

## 9. Worked example (AC-1, AC-2, AC-6, AC-9)

A slice's contract names a seam `parse(line) -> {key, value}` and says an empty line returns `{}`. QA's Tests task writes `tests/unit/test_parse.sh` with a case "empty line gives `{}`" that fails because `parse` does not exist, and its result says `Targeted test: bash tests/unit/test_parse.sh (fails: parse missing)`. The lead puts that line in the developer's Inputs. The developer runs it, sees the failure, builds `parse`, and runs it until green. Beside the code it adds `src/parse_helpers_test.sh` for a private helper (its own test, developer-owned; listed in the contract's `Paths:` through `src/`).

Halfway the developer sees that the test expects `{}` for a line of spaces, while the contract says only "empty line". The developer does **not** edit `tests/unit/test_parse.sh` and does not edit the contract. It writes a *Question* to the lead: "test_parse.sh line 14 expects `{}` for a spaces-only line; the contract defines only the empty line; which holds?" The lead routes it to the architect (contract) and QA (test). Both answers arrive as a rework task; the developer builds to the answer. At Done the result lists the changed files, the open questions, and `targeted test: pass; repo test and lint commands: exit 0`.

Scenario answers a reviewer reaches from the files alone: "a targeted test fails because its expected value looks wrong": ask QA or the lead, do not edit the test (developer file and protocol). "The contract names a seam but the scenario test asserts a different return value": the developer stops and asks; neither the test nor the contract is changed (developer file and protocol). "The slice's deliverable is a test harness": QA writes the harness and its first cases in `tests/`; the developer builds what it runs; no ad-hoc ownership decision (developer file and template).

## 10. Criterion map

| AC | Where |
|---|---|
| AC-1 | §2 ownership, §3 sentence, §4 first line, §7 table; example scenario 1 |
| AC-2 | §1 loop, §2 loop, §3, §4, §5, §6 stage table and Tests rules; scenario 2 |
| AC-3 | §2 test scope, §4 test scope and Done line 1 |
| AC-5 | §3 `## Done` and `## Steps` |
| AC-6 | §3 own tests, §7 template paragraph; scenario 3 |
| AC-7 | the "word for word" lists of §2, §4, §6 |
| AC-8 | §2 (only `## Tests` is added) |
| AC-9 | §1 vocabulary, §3 removal of `test first with`, §10 of [73-release](73-release.md) (QA's cross-file scenario cards) |
| AC-4 | [73-optional-code-review](73-optional-code-review.md) |
