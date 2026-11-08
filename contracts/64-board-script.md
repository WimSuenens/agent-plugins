# Contract 64 — The board script: setup, the three-phase migration, the views, and the line that makes `/factory:run` accept a project

Slice [#64](https://github.com/WimSuenens/agent-plugins/issues/64) · Requirement [64-board-as-run-state](../docs/requirements/64-board-as-run-state.md) · ADR [0015](../docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md) · Calls: [64-gh-calls](64-gh-calls.md) · Fields and views: [64-ledger-and-fields](64-ledger-and-fields.md) §5, §6 · Template: [64-board-status](64-board-status.md) §2 · The `factory-state` check: [64-parallel-slices](64-parallel-slices.md) §3

Serves AC-6, AC-20, AC-21 (setup), AC-34 to AC-43. ADR 0015 is built to, not reopened: the table, the three phases, the snapshot outside the repo, the yes before any change, `factory-state: 2`.

## Paths

Paths:
- plugins/factory/scripts/board.sh
- plugins/factory/skills/setup-factory-skill/
- plugins/factory/skills/run/SKILL.md
- tests/factory/
shared: none

## 1. Why a script

AC-35 to AC-41 are about **order of calls and what a call carries** (every existing option sent with its id, a re-read after each phase, a write that is last). A text step cannot be run against a fake `gh`; a script can. `setup-factory-skill/SKILL.md` stays the text the person reads and the place the questions are asked; the script does the calls. The script asks no question: it never reads the terminal. Every "ask the person" is the skill's, and the answer arrives as a flag.

## 2. Interface

`bash` 3.2, `jq` 1.6 or later, `gh`. It calls `gh` only through the operations of [64-gh-calls](64-gh-calls.md), and `git rev-parse --show-toplevel` once. No other network, no home path in any output (a path is printed by its last two components, `…/factory/board-<owner>-<n>/`).

```
board.sh plan   [--owner <O>] [--project <N>] [--project-id <P>] [--state-dir <D>]
board.sh apply  [--owner <O>] [--project <N>] [--project-id <P>] [--state-dir <D>] --yes [--views-confirmed]
board.sh finish [--owner <O>] [--project <N>] [--project-id <P>] --views-confirmed
                [--factory-md <file>] [--tracker-md <file>] [--ops-template <file>]
```

- **Project input.** `--owner` and `--project` win. Without them the script reads `owner` and `project number` from the Tracker table of `--factory-md` (default `docs/agents/factory.md`). If neither gives both: exit 2, `board: say which project (--owner, --project)`. **No project number, id or owner of this repository's Project is written in the script, its tests or its text** (AC-42); a test greps for them.
- **Project id.** `B-views` and `B-set` need the project's node id `<P>`; no read answer of `B-fields` or `B-items` carries it, and no new `gh` operation is added. `--project-id <P>` gives it. Without the flag the script reads the `project id` row of the Tracker table of `--factory-md`, **only when** that table's `owner` and `project number` equal the project in use (a row for another project is ignored). The setup skill passes the flag, with the id it reads from `gh project list --owner <O> --format json`. `plan` works without an id: it skips the `B-views` read, prints `views: not read (no project id)`, and so reports the state from the options and items alone. `apply` and `finish` without an id exit 2 with `board: project id unknown` before any call.
- **`--state-dir`.** Default `${XDG_STATE_HOME:-$HOME/.local/state}/factory/board-<owner>-<project>/`. It is created `0700`; files are written `0600` (a snapshot holds the titles of the project's items). It must be **outside** the repository working tree (`git rev-parse --show-toplevel` of the current directory, when there is one) and outside any `work/` folder: otherwise exit 2, `board: state dir is inside the repository`. Its path is printed to the person and never saved in a repo file.

| Exit | Meaning |
|---|---|
| 0 | done, or `already migrated` (no mutation) |
| 2 | usage, project not given, project id unknown (`apply`, `finish`), state dir inside the repo, `gh` or `jq` missing, `--yes` missing for `apply` |
| 3 | a read call failed |
| 5 | a **verification difference**: an item's field value differs from the snapshot beyond the expected status change. Stderr names the item and the field; no later phase runs |
| 6 | phase 3 refused: an item still holds an old value after phase 2 re-set it (a `B-set` did not take). Stderr names the item |
| 7 | a mutation call failed (stderr: the call's op id and `gh`'s message) |
| 10 | the views need the person's confirmation (printed what to check); nothing is wrong |

## 3. `plan` (AC-37, AC-43)

Read-only: only `B-fields`, `B-options`, `B-items`, `B-views`. It prints these lines, in this order, before anything else happens, and **makes no mutation call and writes nothing**:

```
board: project <O>/<N>
state: <fresh | seven-option board | migration in progress | migrated>
map: Designed -> Ready (<n> items)
map: In progress -> Running (<n> items)
map: In review -> Running (<n> items)
map: Ready to deploy -> Waiting on you (<n> items)
map: Backlog -> Backlog (unchanged, <n> items)
map: Ready -> Ready (unchanged, <n> items)
map: Done -> Done (unchanged, <n> items)
map: no Factory status -> left as it is (<n> items: #<number>, …)
count: change <c>, stay <s>
note: In progress and In review both become Running. The old distinction is restorable only from the snapshot, never from the board.
snapshot: <state dir tail>/snapshot-1.json (written by apply, before the first change)
```

For **Board-v1** (12 items over all seven values, one extra `Priority` value, one item without `Factory status`) the counts are the fixture's; the sum of `change` and `stay` and `left as it is` is 12. `state: migrated` prints `already migrated` and nothing else (AC-40). `state: fresh` (no `Factory status` field) prints `board: fresh project: nothing to migrate; apply creates the fields` instead of the map lines.

The skill shows these lines to the person and asks one question: **apply this?** Only a clear yes (the word `yes`) leads to `apply --yes`. `no`, silence, a timeout or anything else ends the step: no call is made (AC-37). The skill does not ask again unprompted.

## 4. `apply` (AC-35, AC-36, AC-38, AC-39, AC-40)

Without `--yes`: exit 2, `board: apply needs --yes`, **no mutation**.

**State is read from the board, never from a progress file.** `apply` decides what to do from `B-fields`, `B-options`, `B-items`:

| Board state | Phases |
|---|---|
| no `Factory status` field | create it with the six options (`B-fcreate`), then §5. No snapshot (nothing to lose) |
| the three new options missing | 1, 2, 3, then §5 |
| new options present, an item holds an old value | 2, 3, then §5 |
| no item holds an old value, old options still present | 3, then §5 |
| six options, nothing old, fields and views present | `already migrated`, exit 0, **no mutation, no snapshot** |

### Before the first mutation: the snapshot (AC-36)

Written when a migration has anything to do (not for `already migrated`, not for a fresh project): `snapshot-<k>.json` in the state dir, `k` one above the highest present (the first is `snapshot-1.json`, **the original**). A re-run that finds the board part-way writes `snapshot-2.json` (and so on) with `"note":"taken before re-run, <state>"`, **never overwrites an earlier file**, and prints `original snapshot: snapshot-1.json`.

```
{ "taken": "2026-11-08T09:00:00Z", "note": "original",
  "project": {"owner": "…", "number": 0, "id": "…"},
  "field": {"id": "…", "name": "Factory status"},
  "options": [{"id": "…", "name": "Designed", "color": "…", "description": "…"}],
  "items": [ {"id": "PVTI_…", "number": 12, "title": "…",
              "status": {"id": "…", "name": "Designed"},
              "fields": {"priority": "high", "estimate": 3}} ] }
```

`status` is `null` for an item without a value. `fields` holds **every other field value** of the item as `B-items` returns it (key lower-case as returned). `git status` is unchanged by the step. The script prints `snapshot: <tail of path>` and nothing from inside the file.

### The phases

1. **Add.** One `B-foptions` call whose `singleSelectOptions` is the **full list**: every existing option **with its id, name, colour and description** (read by `B-options`), then `Running`, `Waiting on you`, `Blocked` without ids. At no point is the list overwritten without the old ids (AC-35). Then **verify** (below).
2. **Re-set.** For each item whose current value is an old option: one `B-set` to the new option by the table (`Designed` to `Ready`, `In progress` and `In review` to `Running`, `Ready to deploy` to `Waiting on you`). Items on `Backlog`, `Ready`, `Done` and items with no value receive **no** call (AC-38). Then **verify**.
3. **Drop.** Re-read the items. Phase 2 has already re-set every old item itself, so an item still on an old option here means **a `B-set` did not take** (the call reported success and the re-read shows the old value, or a person set an old option in between); it does not mean the board started with an old item, which phase 2 handles. If any item holds an old option id: exit 6, name the item, **drop nothing**, report not done. Otherwise one `B-foptions` call whose list is the six final options in order, each **with its id** (the old `Backlog`, `Ready`, `Done` and the three new ones). Then **verify**.

### Verify (AC-38)

After each phase, `B-items` again and compare, for **every item in the snapshot**, **every field value** (not `Factory status` alone) with the snapshot, allowing exactly the status change the table gives for that item at that point. A difference: exit 5, `board: item #<n>: field "<name>" changed (snapshot: <a>, now: <b>)`, no later phase. This is what catches a replaced option list that silently cleared a `Priority` value (the fake in the test does exactly that after phase 1). Items added after the snapshot are ignored and counted (`note: <k> items added since the snapshot`).

### Idempotence and interruption (AC-40)

Because state is read from the board, a run interrupted after phase 1, after phase 2, or after phase 3 but before `finish`, and then run again, ends at the **same board and the same files** as an uninterrupted run (the Board-mid variants of the requirement). A run on a migrated board makes no mutation call, creates no second field or view, writes no second snapshot, and prints `already migrated`.

## 5. Fields (AC-2, AC-20) and the end of `apply`

After the phases (or for a fresh project), `apply` lists the fields (`B-fields`) and creates each missing one with `B-fcreate`, never one twice:

| Field | Create as |
|---|---|
| `Kind` | single select: `map`, `slice`, `role task`, `frontier ticket` |
| `Role` | single select: the seven role names in the order of [64-board-status](64-board-status.md) §1 |
| `Tokens`, `Minutes`, `Hours`, `Rework rounds`, `Person touches` | text |

Then the views (§6). `apply` exits 10 when it requested a view, or failed to create one, in this run; it exits 0 when both views were already there.

## 6. Views and the manual fallback (AC-6, AC-21)

For each of `Needs you` and `History` ([64-ledger-and-fields](64-ledger-and-fields.md) §6): look for it by name in `B-views`; **if present, make no second** (and no call). If absent, request it with `B-vcreate` (`name`, `layout` TABLE, `filter`).

- **(a) the call succeeds:** print `view: Needs you: requested; open it once and confirm it shows the filter factory-status:"Waiting on you"` (and the same for `History`).
- **(b) the call is refused or fails:** print `view: Needs you: NOT created. Build it by hand: name "Needs you", table layout, filter factory-status:"Waiting on you"` and, for `History`, name, layout, filter `is:closed kind:slice,"role task"`, the fields to show and the order (`closed`, newest first).

In both cases `apply` exits **10**, and the skill asks the person to confirm that the view exists and filters. Only then does it run `apply --yes --views-confirmed` (which re-reads `B-views`, makes no call for a view that is there, and exits 0) and `finish --views-confirmed`. A view found in `B-views` at the start of a run gets no call and no question from `apply`; `finish` still requires `--views-confirmed`, so the person's confirmation is asked once whatever the path. **Neither case reports `done` for a view the person has not confirmed.** A view that cannot be confirmed leaves the step open; `factory-state: 2` is not written.

## 7. `finish` (AC-41)

Preconditions, checked from the board and printed on failure: six options in order and no item on an old value; the seven fields of §5 present; both views present; `--views-confirmed`. Otherwise exit 2 or 6 and **nothing is written**.

It then writes, **in this order**, each file by writing a scratch file beside it and renaming (never a half-written file):

1. **`--factory-md`** (default `docs/agents/factory.md`):
   - the Tracker table `Key | Value` gets (or updates) the rows `field id (`Kind`)`, `Role`, `Tokens`, `Minutes`, `Hours`, `Rework rounds`, `Person touches` and keeps `owner`, `project number`, `project id`, `field id (`Factory status`)`;
   - `| Status | Option id |` becomes the six rows with their ids and **no row for an old value**; `| Kind | Option id |` and `| Role | Option id |` are added or refreshed;
   - the section `## Parallel slices` with `parallel-limit: 2` is **added when no `parallel-limit:` line exists**; an existing value is **kept**;
   - **every other line is unchanged**, `## Overrides` and the ownership table included (a test diffs the file before and after and allows exactly these hunks).
2. **`--tracker-md`** (default `docs/agents/issue-tracker.md`): the `## Factory operations` section is **replaced** by the 2.0.0 section of `--ops-template` (default: `references/issue-tracker-github.factory.md` beside the plugin's skill): exactly one such section remains, every other section untouched (the existing rule of setup step 6).
3. **Last act:** line 1 of `--factory-md` becomes `factory-state: 2`, then one blank line before the existing first line. If line 1 already held a `factory-state:` line it is replaced. **Only after steps 1 and 2 succeeded.**

On a failure at any earlier point the line is **not** written, so `/factory:run` still refuses ([64-parallel-slices](64-parallel-slices.md) §3). The three writes are each idempotent: running `finish` again changes nothing.

## 8. What the skill text says (`setup-factory-skill/SKILL.md`)

Step 7 (*Prepare the Project board*) becomes the sequence: pick the project; `board.sh plan`; show the person the lines; ask **apply this?**; on a clear yes `board.sh apply --yes`; on exit 10 ask for the confirmation of both views; `apply --yes --views-confirmed`; `board.sh finish --views-confirmed`. Step 5 copies the template for a fresh repo (with `factory-state: 2` in it); for a repo whose `docs/agents/factory.md` is a 1.x file (no `factory-state` line) the skill **does not replace the file**: it leaves it to `finish`. Step 6 (patch the tracker doc) is done by `finish`. A re-run of the whole skill on a migrated project reports `already migrated` and changes nothing.

The skill also holds, under a heading `Version 1.x records`, the 1.3.0 worked stage-log example ([64-ledger-and-fields](64-ledger-and-fields.md) §8 item 3), and the restore procedure:

**Restoring the old distinction (AC-43).** The snapshot is the only place the difference between In progress and In review survives; the board cannot give it back. To restore: (1) add the four old option names back to `Factory status` (they get new ids), keeping every present option's id; (2) for each item in the snapshot, set its recorded old option with `item-edit`; (3) when every item is set, drop what the old workflow did not have. The standard says so next to the table of `plan`, and nowhere promises a restore from the board. A real restore is not rehearsed (**Unverified** 2).

## 9. What QA can check offline

Fixtures: **Board-v1**, **Board-v2**, **Board-mid** (after phase 1; and Board-mid-stuck: after phase 2 where one `B-set` did not take, the fake ignoring it, so one item is still old), fresh project, and the fake `gh` of [64-gh-calls](64-gh-calls.md) §3. Each check reads the call log.

| Check | AC | How |
|---|---|---|
| order and ids | 35 | `apply --yes` on Board-v1: `B-foptions` (10 options, the 7 old with ids) before any `B-set`; all `B-set` before the second `B-foptions` (6 options with ids); no call replaces the list without old ids |
| snapshot outside the repo, never overwritten | 36 | `--state-dir` inside the repo exits 2; the file holds every item and every field value; `git status` unchanged; a re-run on Board-mid writes `snapshot-2.json` and keeps `snapshot-1.json` byte for byte |
| table and counts, no change before yes | 37 | `plan` output lines for Board-v1; `plan` and `apply` without `--yes` leave no mutation in the log; the skill text asks and treats silence as no |
| exact mapping, nothing else touched | 38 | the final board equals Board-v2; Backlog, Ready and Done items got no `B-set`; the no-status item and the `Priority` value are as before. The fault fake that clears `Priority` after phase 1: exit 5 naming the item and the field, no phase 2 call |
| phase 3 only when nothing is old | 39 | Two cases. (a) Board-v1 with one old item: phase 2 re-sets it, phase 3 drops, exit 0 (the build does this; exit 6 does not occur). (b) Board-mid-stuck, a `B-set` that does not take: exit 6, no second `B-foptions`, the item named; after the fixture is updated the next run drops and exits 0 |
| idempotent | 40 | Board-v2: `already migrated`, zero mutation, no second snapshot; the three interruption variants end at the same board and file contents as one clean run |
| files and the last line | 41 | after a clean run `finish` leaves the diff of §7 and nothing else; with a forced failure in step 2 line 1 is not written and `factory-config.sh state` exits 3 |
| no live project | 42 | grep of `plugins/`, `tests/factory/` and this contract's fixtures for the real number, id and owner of this repo's Project: none; with `gh` removed from `PATH` the tests fail with a clear message |
| restore text | 43 | text check of the skill: the restore procedure, and the many-to-one sentence beside the table |
| project id | 6, 35 | `plan` without a flag and with a `--factory-md` fixture lacking the row: exit 0, no `B-views` in the log, the line `views: not read (no project id)`; `apply --yes` and `finish` in that case: exit 2, `board: project id unknown`, empty call log; with `--project-id` or a matching row, `B-views` carries it and every `B-set` has `--project-id` equal to it; a fixture row for another owner or project number is ignored (exit 2 as without) |
| views | 6, 21 | `B-vcreate` accepted: the printed line asks for confirmation, exit 10; refused: the manual instructions, exit 10; a second run with the view in `B-views` makes no `B-vcreate` |
