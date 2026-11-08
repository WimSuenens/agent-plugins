# 73 — Test ownership and the TDD loop in the factory's instructions

Slice: [#73](https://github.com/WimSuenens/agent-plugins/issues/73) · Map: [#72](https://github.com/WimSuenens/agent-plugins/issues/72) · Decision: [#42, "Agreed direction"](https://github.com/WimSuenens/agent-plugins/issues/42) (locked, not reopened) · Builds on: [64-board-as-run-state](64-board-as-run-state.md) (role tasks, the kind-3 path rule)

## User outcome

The person who runs the factory reads the protocol, the developer, QA and architect agent files, the run skill and the `factory.md` template. Each file that concerns a point states it the same way, and no file contradicts another. The five points:

1. **Ownership.** `tests/` is QA-owned. The developer never edits a file in it.
2. **TDD loop.** Architect contracts define the seams and expected behaviour. QA prepares the next scenario test before its behaviour slice. The developer implements and runs that targeted test until green. A test or contract that is unclear goes back to QA or the lead; the developer does not change the test. QA keeps the independent pass/block verdict; the security review stays mandatory.
3. **Test scope.** Executable behaviour and important safety invariants are automated. Instruction-following is assessed with realistic scenarios and human review, not broad exact-prose assertions. Exact text is asserted only where a machine-readable format or a safety rule needs it.
4. **Optional code review.** The lead decides after the contracts and before the build, from documented risk triggers, whether to run a code review. After the diff exists, the lead checks it for unexpected breadth or scope creep. A review that runs covers standards, spec and scope; it does not repeat QA's execution or the security scan, and duplicate findings are combined.
5. **Developer Done list.** It requires running the applicable tests. It never says the developer writes the acceptance suite.

#42's "Standard change" is answered in the `factory.md` template and in the developer's agent file (see AC-6).

## Terms used here

- **The five points**: the list above. **The files**: `plugins/factory/references/protocol.md`, `plugins/factory/agents/developer.md`, `qa-engineer.md`, `architect.md`, `plugins/factory/skills/run/SKILL.md`, and `plugins/factory/skills/setup-factory-skill/assets/factory.md`.
- **Baseline**: the plugin text at commit `4086c9c` (the run's FREEZE, 2.0.0). "Today" in the criteria means the baseline.
- **Machine-checkable**: a script test in `tests/` can decide it from the files. **Scenario**: a stated situation a reviewer plays against the text, with the answer a reader should reach; the reviewer is a person or an agent reading only the named files. **Human review**: the verdict is a person's reading, listed in QA's Human-only criteria.
- **Risk trigger**: a condition in the run skill that, when it holds for a slice, makes the lead run the code review (see AC-4).

## Validation data

- **Baseline files**: `git show 4086c9c:<path>` for each of the files, used by AC-7. No tracker call.
- **Scenario cards** QA writes in `tests/` for AC-2, AC-4 and AC-5 (each: the text given, the situation, the expected answer). They are written from the criteria below, not from the finished text.
- **1.3.0 reference numbers** for the pilot (QA 3 passes, developer 2 feedback briefs) are recorded by the lead in the hansei record. No criterion tests them.

## Acceptance criteria

Each ends with what contradicts it. "The text" means the files above.

### AC-1 `tests/` stays QA-owned and the developer never edits it *(Done when 1; Under test: whose test to change)*
Given the files,
when they are read,
then (machine-checkable):
- the ownership table in the `factory.md` template has `` `tests/` `` on the `qa-engineer` row and on no other row;
- the developer's agent file says in one sentence that the developer does not create, edit or delete files under `tests/`;
- the QA agent file says QA owns `tests/` and prepares the tests the developer runs;
- the protocol states the same rule where it states ownership.

And given the scenario "a targeted test fails because its expected value looks wrong to the developer", when a reviewer reads only the developer's agent file and the protocol, then the answer is "send the question to QA or the lead; do not edit the test".
It is contradicted if a file lets the developer edit `tests/`, or the reviewer answers otherwise or cannot answer.

### AC-2 The TDD loop is stated in order and agrees across files *(Done when 2; Under test: whose test to change)*
Given the five files that mention the loop (protocol, developer, QA, architect, run skill),
when they are read,
then (machine-checkable) each states the loop steps it owns, using these terms: contracts define seams and behaviour (architect, run skill); QA prepares the next scenario test before its behaviour slice (QA, run skill); the developer implements and runs the targeted test until green (developer); an unclear test or contract returns to QA or the lead (developer, protocol).
And given the scenario "the contract names a seam but the scenario test asserts a different return value", when a reviewer reads the files, then the answer is that the developer stops and asks QA or the lead, and does not change the test or the contract.
And the run skill's stage table and brief rules put QA's test preparation before the Build stage for each behaviour slice, and the developer's brief names the test to run.
It is contradicted if a file says the developer writes the test first in `tests/`, if the order differs between two files, or the reviewer cannot tell who acts next.

### AC-3 Test scope is stated, and QA is not pushed into prose assertions *(Done when 3; Under test: test scope)*
Given the QA agent file, the protocol and the run skill,
when they are read,
then (machine-checkable) the QA agent file and the protocol each state the three parts: executable behaviour and important safety invariants are automated; instruction-following is assessed by realistic scenarios with human review; exact-text assertions are limited to machine-readable formats and safety rules.
And the QA agent file's Done list no longer reads as "one test per acceptance criterion" for a criterion that is instruction-following; such a criterion maps to a scenario or to the Human-only criteria list, and QA's verdict still lists it.
And given the scenario "an acceptance criterion says the lead must tell the person X before Y", when a reviewer reads the QA agent file, then the answer is a scenario plus human review, not a grep for a sentence.
It is contradicted if QA can reach a verdict only by adding a broad exact-prose assertion, or if a criterion has no test, scenario or Human-only entry.

### AC-4 Optional code review is decided from documented triggers *(Done when 4; Under test: optional code review)*
Given the run skill,
when it is read,
then (machine-checkable) it has a step between the contracts stage and the build stage in which the lead decides whether to run a code review, and it lists these risk triggers by name: shared protocols or approval/state rules; broad cross-plugin changes; significant refactors.
And after the diff exists, a step tells the lead to check it for unexpected breadth or scope creep.
And the text says a review that runs covers standards, spec and scope, not QA's execution or the security scan, and that duplicate findings are combined.
And the text says the decision and the trigger that fired (or `no trigger`) are written in the lead state or the stage summary.
And given three scenario cards (a slice changing only one plugin's agent wording; a slice editing a protocol approval rule; a slice moving files across two plugins), when a reviewer reads only the run skill, then the answers are: no review, review, review, each naming the trigger.
It is contradicted if the lead cannot decide from the listed triggers alone, or if the review is made mandatory, or if it replaces QA or security.

### AC-5 The developer's Done list requires running tests and never implies authorship of the acceptance suite *(Done when 5)*
Given the developer's agent file,
when its Done list and Steps are read,
then (machine-checkable) the Done list has a line requiring that the applicable tests were run (the targeted test for each slice, then the repo's test and lint commands) and that they exit 0.
And neither the Done list nor the Steps contains a line that makes the developer write, own or derive the acceptance tests (the baseline line "Every acceptance criterion of the item has a passing test" is replaced; the step "test first with `/tdd`" is reworded so the developer's test-first work is running QA's prepared test).
And the Done list still requires the result to list changed files and open questions.
It is contradicted if the developer can meet its Done list only by writing in `tests/`.

### AC-6 #42's "Standard change" is answered in two named places *(Done when 6)*
Given the `factory.md` template and the developer's agent file,
when they are read,
then both state where the developer's own tests live: tests the developer needs for its own steps (such as unit tests beside the code) are developer-owned and sit in the developer's own path (the `src/` row of the template), are not the acceptance suite, and QA is free to read, run and ignore them; the acceptance suite is `tests/`.
And the protocol does not say the developer may create tests under `tests/` during Build.
And given the scenario "the slice's deliverable is a test harness", when a reviewer reads the two files, then the answer is that QA writes the harness and its first cases in `tests/`, the developer builds what the harness runs, and the lead makes no ad-hoc ownership decision.
It is contradicted if either file is silent on where the developer's tests live, or the two disagree.

### AC-7 The QA and security gates are not weakened *(Not)*
Given the baseline and the files,
when each is compared,
then (machine-checkable) every line of these exists in the new text, word for word where it states a rule: the QA agent file's Authority line ("Owns the release verdict. A block stands until a re-run passes."), its Human-only criteria line, its changed-paths check line and its "Every defect has a reproduction" line; the security-reviewer agent file unchanged; the run skill's rework rule ("repeat until both verdicts are `pass`"), the Done-when "both verdicts are `pass`", and the sentence that QA and security check the diff against the path list; the protocol's F3 row.
And the QA agent file's "Every acceptance criterion maps to a test" line may be reworded only to add scenarios and the Human-only list (AC-3), not to drop a criterion.
It is contradicted if any listed line is missing or softened, or the security review becomes optional anywhere.

### AC-8 The fenced items and the lead's rules are untouched *(Not; Done when 6)*
Given the protocol,
when the *Never overridable locally* section (F1 to F7 and question E) is compared with the baseline,
then it is byte-identical. And the protocol's other changes are limited to the ownership/test text of AC-1 to AC-3.
It is contradicted if any fenced line differs.

### AC-9 No file contradicts another *(Under test: whose test to change)*
Given the files,
when a reviewer reads them as the lead, developer, QA and architect in turn, using the scenario cards of AC-1, AC-2 and AC-6,
then each role reaches the same answer to "whose test do I change" from its own file, and no file keeps the baseline wording "test first with `/tdd`" or "has a passing test" in a way that gives the developer the suite.
It is contradicted if two files give different answers, or a role must ask to find out.

## Out of scope

Everything the frame lists as **Deliberately faked**:
- Running the new text live in a session. It cannot be tested offline beyond the script tests, so it ships **unverified** and is named in the changelog.
- A script or checklist for the risk triggers (deferred on the map; prose only here; trigger: the lead misjudges a trigger in a pilot run).

Also out of scope: the pilot numbers (test-to-green time, QA and developer rework rounds against 1.3.0), which the lead records in the hansei record; issues 41, 43, 59, 66, 68, 69, 70, 71; the Acceptance demo; any change to the fenced items; reducing scenario coverage.

This repository's own `docs/agents/factory.md` and `docs/factory/reference.md`: no point requires a change. The ownership table already gives `tests/` to qa-engineer and `plugins/` to the developer (the developer's own-test path in this repo is inside `plugins/`). `docs/factory/reference.md` is docs-writer's and may restate the five points if the docs-writer judges it should; nothing here depends on it.

## Human-only

AC-1, AC-2, AC-4, AC-6 and AC-9 each have a scenario part that a reviewer plays against the text; QA lists those scenarios in the Human-only criteria of its verdict. Shipped unverified: instruction-following in a live run.
