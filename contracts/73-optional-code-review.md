# Contract 73 — Optional code review: the lead's decision, the three risk triggers, and the diff-breadth check

Slice [#73](https://github.com/WimSuenens/agent-plugins/issues/73) · Requirement [73-test-ownership-and-tdd-loop](../docs/requirements/73-test-ownership-and-tdd-loop.md) · Decision: [#42, "Agreed direction"](https://github.com/WimSuenens/agent-plugins/issues/42) · Parts: [73-ownership-and-tdd-loop](73-ownership-and-tdd-loop.md), [73-release](73-release.md)

Serves AC-4 and AC-7 (the run skill's gate lines). Only `plugins/factory/skills/run/SKILL.md` changes here. The fence F3 is untouched: the review adds a check, it never removes or narrows one.

## Paths

Paths:
- plugins/factory/skills/run/SKILL.md
shared: none

## 1. Insertion points in `skills/run/SKILL.md`

| What | Where | Why there |
|---|---|---|
| a one-line pointer | directly under the stage table of `## 6. Run the stages`, before `The **stage** of a slice is the role task …`: *Between the Contracts and ADRs row and the Tests row the lead takes the code-review decision (*Optional code review*); it is a decision, not a role task, and gives the slice no status.* | the table is where a reader looks for the order; this sits between the contracts stage and the build stage |
| the sentence that triggers it | in stage-loop item 4, the `done` bullet, after the existing sentence ending `(*Parallel slices*).` (word for word): `Then take the code-review decision (*Optional code review*), then brief QA for the Tests stage.` | the decision follows the architect's `done` and the path comparison, so the Paths list is known |
| a new subsection `### Optional code review` | directly before `### Environment and shared resources` | it follows the same pattern: a lead decision taken when the architect's stage is done |
| the diff-breadth check | one paragraph, the line starting `Open the PR (*Open PR*) when the developer is done`: add before it a paragraph starting `When the developer is done, and before *Open PR*, check the diff for breadth.` | the diff exists then; QA and security have not yet run |

## 2. `### Optional code review`: what it says

1. **When.** When the architect's stage is done, after the path comparison, before the Tests brief (so before Build), decide from the contracts and their `Paths:` blocks whether to run a code review. The review is **optional**: a slice with no trigger is not reviewed.
2. **The three risk triggers, named exactly as below** (AC-4). Each is decided from the contracts alone; no other input is needed:

| Trigger | Fires when |
|---|---|
| **shared protocols or approval/state rules** | a contract's `Paths:` lists text that every role or the lead reads as a rule (the protocol, the run skill's approval, status, andon or gate steps, the `factory.md` template), and the contract changes what is allowed, who approves, or what state an item is in |
| **broad cross-plugin changes** | the `Paths:` lists files under two or more `plugins/<name>/` directories (the shared files `CHANGELOG.md`, `README.md` and the version file do not count) |
| **significant refactors** | a contract moves, renames or splits files, or changes the shape of a seam without changing behaviour |

3. **Record it.** Write one line in the lead state, `code review: yes — trigger: <name>` or `code review: no — trigger: no trigger`, and the same line in the architect stage's stage summary. (The lead state is the lead's file; the summary is scanned before posting like any other.)
4. **When it runs.** The review runs on the diff once the developer is done, beside QA and security, with `/code-review`. It covers standards, spec and scope. It does **not** repeat QA's execution of the tests and does **not** repeat the security scan. Duplicate findings are combined: a finding that QA or security also made is kept once, under the verdict that owns it, and the reviewer's copy is dropped.
5. **What its findings do.** The non-duplicate findings go to the developer in the same rework task as QA's and security's findings (*Role tasks*, rework); the loop repeats until both verdicts are `pass`. The review has no verdict. It cannot replace the QA or the security stage, cannot make either verdict optional or non-binding, and its absence never blocks a merge.

## 3. The diff-breadth check (after the diff exists)

Not optional: every slice, after the developer's `done` and before *Open PR*. The lead lists `git diff --stat origin/main...item/<id>` in the item worktree and compares it with the contracts: every changed file is on the `Paths:` list (QA's off-list check repeats this later and is not replaced), and the size of the change fits the behaviour the contracts name. A change in an area no contract names, a rewrite of a file the contracts only touch in one section, or a diff clearly larger than the contracts imply is **unexpected breadth or scope creep**: create a rework task (`Source: lead`) naming the files, and run the check again when the developer is done. Otherwise say `breadth: as expected` in the stage summary. The check reads the diff only; it runs no test and no scan.

## 4. Worked example (AC-4)

The three scenario cards QA writes, with the answer a reader reaches from the run skill alone:

| Slice (from its contracts) | Trigger | Decision line |
|---|---|---|
| reword two sentences in `plugins/factory/agents/devops.md` only | none: one plugin, no shared rule, no move | `code review: no — trigger: no trigger` |
| change the protocol's approval rule for merges (`plugins/factory/references/protocol.md`, run skill step 8.1) | shared protocols or approval/state rules | `code review: yes — trigger: shared protocols or approval/state rules` |
| move `plugins/design/shared/` files into `plugins/toolkit/` and update both plugins' references | broad cross-plugin changes (also significant refactors) | `code review: yes — trigger: broad cross-plugin changes` |

After the build of the second slice the lead lists the diff stat, finds three files, all on the `Paths:` list, one section each, and writes `breadth: as expected`. The review (when it ran) found "the new sentence repeats line 12" (standards) and "no test covers the second rule" (QA found the same): the lead keeps the second under QA's verdict and sends the first to the developer inside the combined rework task.

## 5. Word for word, and the criterion map

- Unchanged and pinned (AC-7): `QA and security findings go to the developer as a **rework task** (*Role tasks*, rework); repeat until both verdicts are `pass`.`; `both verdicts are `pass`` in the `Done when`; the paragraph `**QA and security check the diff against the list.**`; the `Open PR` bump-check steps 1 to 4; `After the **architect's** `done`, make the path comparison before any other brief (*Parallel slices*).`
- Not made optional, ever: the QA verdict, the security review, the check-bump gate. No sentence of the new text may say `optional` about those.

| AC | Where |
|---|---|
| AC-4 | §1 the insertion points, §2 triggers and record, §3 breadth check, §4 scenario cards |
| AC-7 (run skill lines) | §5 |
