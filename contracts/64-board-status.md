# Contract 64 — The board as status: fields, the six values, the events that set them, the needs-you comment

Slice [#64](https://github.com/WimSuenens/agent-plugins/issues/64) · Requirement [64-board-as-run-state](../docs/requirements/64-board-as-run-state.md) · ADR [0015](../docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md) (amends [0002](../docs/adr/0002-one-branch-and-worktree-per-item.md)) · Calls: [64-gh-calls](64-gh-calls.md) · Fields and views: [64-ledger-and-fields](64-ledger-and-fields.md) §5, §6 · Migration: [64-board-script](64-board-script.md)

Serves AC-1 to AC-8. Role-task cards: [64-role-tasks](64-role-tasks.md).

## Paths

Paths:
- plugins/factory/skills/run/SKILL.md
- plugins/factory/skills/setup-factory-skill/
- tests/factory/
shared: none

## 1. The fields

| Field | Type | Options, in this order |
|---|---|---|
| `Factory status` | single select | `Backlog`, `Ready`, `Running`, `Waiting on you`, `Blocked`, `Done` |
| `Kind` | single select | `map`, `slice`, `role task`, `frontier ticket` |
| `Role` | single select | `product-owner`, `architect`, `developer`, `qa-engineer`, `security-reviewer`, `devops`, `docs-writer` |
| `Tokens`, `Minutes`, `Hours`, `Rework rounds`, `Person touches` | text | [64-ledger-and-fields](64-ledger-and-fields.md) §5 |

- **Exactly these options and no others** (AC-1, AC-2). A seventh `Factory status` option, or an old value, is a defect. The built-in `Status` field is not used.
- **`Role` is set only on a `role task` card** and is empty on every other (Decision 1 of the requirement). A blank `Role` is not a measure, so the honesty rule does not apply to it.
- **`Kind` mapping.** The map issue: `map`. A child ticket of the map labelled `wayfinder:slice`: `slice`. A child of any other `wayfinder:*` type (`research`, `prototype`, `grilling`, `task`): `frontier ticket`. A role-task sub-issue: `role task`.

## 2. The Tracker section of `docs/agents/factory.md` (the 2.0.0 template)

`assets/factory.md` becomes (changed lines only; the rest is the 1.3.0 template):

```
factory-state: 2

# Factory
…
## Decision-maker
…
## Role models
…
## Ownership
…
## Worktrees
…
## Parallel slices

parallel-limit: 2

How many slices may run at the same time, when their path lists do not overlap. `1` means one at a time.

## Tracker

Factory operations are in `docs/agents/issue-tracker.md`, under `## Factory operations`. The board view groups by `Factory status`; the project's built-in `Status` field is not used by the factory.

Resolved ids for the GitHub Project:

| Key | Value |
|---|---|
| owner | |
| project number | |
| project id | |
| field id (`Factory status`) | |
| field id (`Kind`) | |
| field id (`Role`) | |
| field id (`Tokens`) | |
| field id (`Minutes`) | |
| field id (`Hours`) | |
| field id (`Rework rounds`) | |
| field id (`Person touches`) | |

| Status | Option id |
|---|---|
| Backlog | |
| Ready | |
| Running | |
| Waiting on you | |
| Blocked | |
| Done | |

| Kind | Option id |
|---|---|
| map | |
| slice | |
| role task | |
| frontier ticket | |

| Role | Option id |
|---|---|
| product-owner | |
| … (seven rows) | |
```

- `factory-state: 2` is line 1, then a blank line, then `# Factory`. The line formats of `factory-state:` and `parallel-limit:` are [64-parallel-slices](64-parallel-slices.md) §3 and [64-board-script](64-board-script.md) §2.
- **One row per option with its id, and no row for an old value** (AC-1). Table headers are exactly `| Status | Option id |`, `| Kind | Option id |`, `| Role | Option id |`; a reader finds a row by the first cell.
- The lead reads ids from these tables; a missing cell stops the run and names the cell (as a bad role model does).

## 3. Which event sets which status (AC-4)

Every transition is tied to an event the lead can observe **without `work/` or a branch**. Precedence when several hold for one card: `Waiting on you` over `Blocked` over `Running` (the status shows what the person must act on first).

### Role task

| Event | Status |
|---|---|
| the lead creates it and spawns the role | `Running` |
| its result is `working` (cut off) | stays `Running`, sub-issue open |
| its closing comment is posted and the issue closed, result `done`, `pass`, `findings`, `needs-decision`, `approved`, … | `Done` |
| its result is `blocked`, comment posted and issue closed | `Blocked` |
| the lead stops its agent for an andon | `Blocked` |
| the andon ends and the agent is resumed | `Running` |
| the lead creates the next task that supplies what a `blocked` task lacked | the blocked task becomes `Done` |

### Slice (and frontier ticket, with "round" in place of "item")

| Event | Status |
|---|---|
| the slice is cut and may start (step 4) | `Ready` |
| the gate of [64-parallel-slices](64-parallel-slices.md) §4 fails (limit reached, or a path overlap) | stays `Ready`; the lead says why in the session |
| the first role task of the item is spawned | `Running`. The **stage** is "which role task is `Running`"; no field holds it |
| the lead asks the person for anything (a decision card, the merge approval, a task request, the delivery approval, a resurvey pause, a missing project permission) | `Waiting on you`, with the comment of §4 |
| the lead reads the person's answer | `Running` (or the status the answer's next event gives) |
| a role task of the item ends `blocked`, or a task waits on a missing input | `Blocked` until the lead spawns the next task, then `Running` |
| the lead stops work on the slice for an andon | `Blocked` until the andon is resumed or the lead carries on, then back to what it was |
| the slice's PR is merged | `Done` |

A frontier ticket follows the same table: `Backlog` while it waits on the frontier, `Running` while the lead or a role works it, `Waiting on you` on its decision card or task request, `Done` when its resolution comment is posted and the ticket closed.

### Map

| Event | Status |
|---|---|
| the lead creates or adopts the map (step 2) | `Running` |
| the lead asks the person something at run level (keep, promote or drop; an A3 draft; a freeze question) | `Waiting on you`, with the comment of §4; `Running` again on the answer |
| the run is reported closed (step 9) | `Done` |

### Child tickets of the map

A child ticket that exists and is neither cut nor worked: `Backlog`.

### The narrated run (the worked example for AC-4)

QA derives the status of the slice and of every role task by §3 alone after each step and compares the sequence with this one (fixture `board-run.md`). `S` is the slice, `Tn` the role tasks in creation order.

| Step | Event | S | Role tasks after the step |
|---|---|---|---|
| 1 | slice cut | Ready | |
| 2 | gate passes; product-owner spawned | Running | T1 Running |
| 3 | requirement `done` (comment, close) | Running | T1 Done |
| 4 | architect spawned | Running | T2 Running |
| 5 | architect result `needs-decision`; card posted (needs-you comment first) | Waiting on you | T2 Done |
| 6 | the person answers | Running | |
| 7 | architect spawned again | Running | T3 Running |
| 8 | `done` | Running | T3 Done |
| 9 | developer spawned, `done` | Running | T4 Done |
| 10 | QA `findings`; the lead creates rework 1 (developer) | Running | T5 Done, T6 Running |
| 11 | rework `done`; QA again `pass` | Running | T6 Done, T7 Done |
| 12 | the lead asks `merge and clean up?` (needs-you comment first) | Waiting on you | |
| 13 | the person says yes; the lead merges | Done | |

The sequence needs no file of `work/` and no branch name: every row's event is a tracker or session event.

## 4. A card that waits on the person says what to do (AC-5)

When a card goes to `Waiting on you`, the lead first posts **one comment** on that card's issue (the slice, the frontier ticket or the map; a role task never waits on the person), then sets the status. The comment is the person's instruction; the status alone is not.

```
<!-- factory:needs-you v1 -->
Asked: 2026-11-07T12:41Z
Cause: decision card
Ask: Which export format should the report use, CSV or JSON?
Options: A CSV. B JSON. (full card: https://github.com/example/shop/issues/12#issuecomment-111)
After you answer: the architect writes the decision down and the build starts.
```

- **First line** exactly `<!-- factory:needs-you v1 -->`. The lines after it are `Asked:`, `Cause:`, `Ask:`, `Options:`, `After you answer:`, in this order, each once, each on one line. Plain words; no mechanism beyond what the decision-maker level of `docs/agents/factory.md` allows.
- `Asked:` is the lead's `date -u +%FT%TZ` stamp, cut to the minute. It is the **start of the person's wait** ([64-ledger-and-fields](64-ledger-and-fields.md) §2), recorded exactly, so a resumed lead can tell an open person wait from a closed one: the newest needs-you comment with no `Answered:` line and a card still `Waiting on you`.
- `Cause:` is one of `decision card`, `merge approval`, `task request`, `delivery approval`, `resurvey pause`, `missing permission`, `tracker limit`, `run decision`. `Options:` is the options, or `see <URL>` to the decision card comment, or `yes or no` for an approval.
- **No path under `work/`, no branch name** (`item/<n>`, `frontier/<n>`). `post-text.sh scan --needs-you` ([64-role-tasks](64-role-tasks.md) §9) rejects both and also the home-path and secret patterns; a rejected text is not posted, the card stays `Running`, the person is told which line.
- **Order.** The comment is posted before the status change or in the same step, never after (a card cannot be seen `Waiting on you` with no comment). Re-asking is a new comment, not an edit.
- **Answered.** When the lead reads the answer it adds one line to the newest needs-you comment with `T-edit-comment`: `Answered: <UTC>`. The wait row is then written to the ledger (`Start` = `Asked`, `End` = `Answered`).

## 5. The map and its children are on the board (AC-3, AC-8)

- At **run start** the lead adds the map (`Kind` map) and every child ticket of the map (`Kind` slice or frontier ticket) to the board with `B-add`, then sets `Factory status` and `Kind` (`B-set`). A child ticket cut later is added in the same step that cuts it. A role task is added by [64-role-tasks](64-role-tasks.md) §3.
- On a **resumed run** the lead reads the board (`B-items`) and adds any card that is missing; it never adds one twice (`B-add` returns the existing item).
- The map's `## Factory run` section stays at the top of the map body. It holds the step, the branch(es), the `FREEZE:` line, the pointers (`hansei: …`, `closed in this run`, `baseline:`), the open andon lines, and one new line, `in flight: #<id> (item/<id>), …` (or `in flight: none`), which replaces "current item". **It holds no status word**: none of `Backlog`, `Ready`, `Running`, `Waiting on you`, `Blocked`, `Done` appears as a status in it (a test searches the section's template for the six status words as whole words and finds none). The board is the only place a status lives.

## 6. No old value outside the migration (AC-7)

The four old values (`Designed`, `In progress`, `In review`, `Ready to deploy`) appear in `plugins/`, in the `assets/factory.md` template and in `references/issue-tracker-github.factory.md` only in: `scripts/board.sh` (its mapping table and snapshot text), `skills/setup-factory-skill/SKILL.md` (the migration step's table and prose) and nowhere else. `CHANGELOG.md` and `docs/adr/` (history) are not searched. The test is a `grep -rn` of the four strings over `plugins/` with those two files removed; zero hits.

## 7. What QA can check offline

| Check | AC | How |
|---|---|---|
| the six options and the three option tables | 1, 2 | read `assets/factory.md`; run `board.sh apply` on a fresh-project fake (no `Factory status` field) and read the `B-fcreate`/`B-foptions` bodies |
| every transition is tied to an event; precedence | 4 | text check of §3 in `SKILL.md`; the narrated run as a table-driven replay |
| the calls for run start, slice cut, frontier ticket, role task | 3 | follow the standard step by step with the fake `gh` ([64-gh-calls](64-gh-calls.md) §3); every logged call has an `op` other than `unknown`, and each of the four card kinds has `B-add` then `B-set` for `Factory status` and `Kind` |
| needs-you comment before the status, shape, no `work/` or branch | 5 | for each `Cause`: the fake log shows `T-comment` before `B-set`; the body matches the shape; `post-text.sh scan --needs-you` exits 0 on it and 1 on a body naming `work/12/` or `item/12` |
| the map's Factory run section has no status word | 8 | search the section template |
| no old value | 7 | §6 |
