---
name: setup-factory-skill
description: Wire a repo for the factory plugin — runs the wayfinding setup if needed, writes docs/agents/factory.md and its AGENTS.md pointer, adds the factory operations to the tracker doc, and prepares or migrates the GitHub Project board. Run once per repo; run again to migrate a 1.x project to 2.0.0 or to add the flow table a 2.x project needs from 3.0.0.
disable-model-invocation: true
---

# Setup the factory

`/factory:run` and the seven role agents read two repo files: `docs/agents/factory.md` (decision-maker, role model overrides, path ownership, worktree location (`.claude/worktrees`), the optional run budget, tracker ids) and the `## Factory operations` section of `docs/agents/issue-tracker.md`. This skill writes both, once. `/factory:run` accepts a project only when line 1 of `docs/agents/factory.md` is `factory-state: 2` and the flow table is there (step 9a); a 1.x project gets that line from this skill's migration, written last. A re-run of the whole skill on a migrated project reports `already migrated` and changes nothing, except that it appends the flow table and the `ci:` line when they are missing.

## Process

### 1. Check configuration state

Look for `docs/agents/issue-tracker.md` with a `## Wayfinding operations` section that mentions the `slice` type, and an `## Agent skills` block in `AGENTS.md` or `CLAUDE.md`.

If either is missing, invoke `/wayfinding:setup-wayfinding-skill` first and let it run to completion. Factory items are wayfinder slices, so the wayfinding conventions come first.

**Done when** the tracker doc carries the slice conventions and the `## Agent skills` block exists.

### 2. Check the tracker

Read the first heading of `docs/agents/issue-tracker.md`. The factory supports `# Issue tracker: GitHub` only. For any other tracker, stop and tell the user plainly: the factory needs GitHub for now, and Azure DevOps and others wait on a real project to design against. Point them at `https://github.com/WimSuenens/agent-plugins/issues` to ask for theirs.

**Done when** the tracker is GitHub, or the user has been told why setup stops.

### 3. Ask the decision-maker level

Ask the user one question: who decides one-way doors in this repo, and could they follow a technical explanation?

- **non-technical** (default): owns the product and budget, has not read the code.
- **technical**: can weigh an architecture trade-off.

**Done when** the user has answered.

### 4. Ask about role models

Each role runs on the default model in its agent file:

| Role | Default |
|---|---|
| product-owner, architect, qa-engineer, security-reviewer | `inherit` (the lead's model) |
| developer, devops, integrator | `sonnet` |
| docs-writer | `haiku` |

When an existing `docs/agents/factory.md` has a `## Role models` table, show its overrides and ask whether to keep or change them; keep is the default. Otherwise show the defaults and ask one question: override any of them for this repo? On yes, ask per role, offering `haiku`, `sonnet`, `opus`, or `fable` with the default preselected. Only these four work: the lead passes the override as the spawn's `model`, which takes no pinned id and no `inherit`.

**Done when** the user has kept the overrides, declined, or picked a model for every role they want overridden.

### 5. Write `docs/agents/factory.md`

- **A repo with no `docs/agents/factory.md`**: copy [assets/factory.md](./assets/factory.md) to `docs/agents/factory.md` (it starts with `factory-state: 2`). Then fit it to the repo:
  - Set `decision-maker:` to the answer from step 3.
  - When step 4 produced overrides, replace the `None` line under `## Role models` with a `| Role | Model |` table, one row per overridden role, and keep the paragraph that explains the format.
  - Point `src/` and `tests/` in the ownership table at where this repo keeps its code and tests. Look at the directory layout and the test command in the repo's own config; use one row per directory when there are several. Unit tests that sit beside the code stay under the developer's row; only the acceptance suite goes under `tests/`.
  - Keep the row `` | `docs/agents/factory.md` section `## Overrides` | lead | `` exactly as written, and do not create the `## Overrides` section: the lead adds it with the first override. The word `section` after the path is what lets the role-outside-role check skip the row.
  - Keep the other ownership rows as written unless the repo already uses a different home for that material (an existing `adr/` folder, a `docs/decisions/`, a runbook folder); then point the row there.
- **A repo whose `docs/agents/factory.md` is a 1.x file** (no `factory-state:` line): **do not replace it**. Its decision-maker, role models, ownership rows and overrides stay as they are. `board.sh finish` (step 7) adds the new Tracker rows, the `## Run budget` section (`run-budget: none`), drops a `## Parallel slices` section left by 2.0.0 to 2.5.x (its `parallel-limit` line is ignored from 2.6.0) and, last, the `factory-state: 2` line.

**Done when** every path in the ownership table names a directory this repo has, or one the factory will create.

### 6. Patch the tracker doc

`board.sh finish` (step 7) replaces the `## Factory operations` section of `docs/agents/issue-tracker.md` with the section of [references/issue-tracker-github.factory.md](./references/issue-tracker-github.factory.md), and leaves every other section untouched. Nothing to do by hand here.

**Done when** exactly one `## Factory operations` section exists, after step 7's `finish`.

### 7. Prepare the Project board

The factory tracks status in a GitHub Project: a single-select `Factory status` field with six options, the `Kind` (map, slice, role task, frontier ticket, idea) and `Role` fields, five text fields for the numbers, and two views. `${CLAUDE_PLUGIN_ROOT}/scripts/board.sh` makes every call; it asks no question, so every question below is yours, and the answer reaches the script as a flag. Run `gh auth status`; when the token lacks the `project` scope, ask the user to run `gh auth refresh -s project` and wait.

1. List the owner's projects: `gh project list --owner <owner> --format json` (it also gives each project's id). Ask the user to pick one or to create a new one (`gh project create --owner <owner> --title "<repo> factory"`), then link it to the repo: `gh project link <number> --owner <owner> --repo <owner>/<repo>`.
2. **Plan.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" plan --owner <owner> --project <number> --project-id <id>`. It reads the board and prints the status mapping, the item counts and the snapshot file it would write; it changes nothing. On `already migrated`, say so, skip the rest of this step (the board is done) and go on to step 8: nothing on the board changes.
3. **Show the lines to the person and ask one question: apply this?** The mapping the script prints is:

   | Old value | Becomes |
   |---|---|
   | Designed | Ready |
   | In progress | Running |
   | In review | Running |
   | Ready to deploy | Waiting on you |
   | Backlog, Ready, Done | unchanged |
   | no value | left as it is |

   **In progress and In review both become Running. The old distinction is restorable only from the snapshot, never from the board.** Only a clear yes (the word `yes`) leads to step 4. `no`, silence, a timeout or anything else ends the step: make no call, and do not ask again unprompted.
4. **Apply.** Run `board.sh apply --owner <owner> --project <number> --project-id <id> --yes`. It writes a snapshot of every item and field value outside the repository first (the script prints the file's tail; tell the person where it is and that it is the only record of the old distinction), then adds the three new options with every old option's id kept, re-sets the items, re-reads, and only then drops the old options. It reads the state from the board, so a run interrupted anywhere is simply run again. Exit 5 (a field value changed) or 6 (an item still holds an old value) stops the migration: put the message to the person and do not go on.
5. **Views.** `apply` exits 10 when it requested a view (`Needs you`, `History`) or could not create one. Ask the person to open the views and confirm that each exists and filters as printed (`Needs you`: `factory-status:"Waiting on you"`; `History`: `is:closed kind:slice,"role task"`, closed newest first). Where the script says a view was NOT created, give the person its manual instructions. Neither case counts as done for a view the person has not confirmed; a view that cannot be confirmed leaves the step open and `factory-state: 2` unwritten.
6. On the confirmation, run `board.sh apply ... --yes --views-confirmed` (it makes no call for a view that is there and exits 0), then `board.sh finish --owner <owner> --project <number> --project-id <id> --views-confirmed`. `finish` fills the Tracker tables of `docs/agents/factory.md`, adds `## Run budget` with `run-budget: none` when no such line exists (an existing value is kept), removes an old `## Parallel slices` section with its `parallel-limit` line, replaces the `## Factory operations` section of the tracker doc, and as its last act writes `factory-state: 2` on line 1.
7. Ask the user: "Open the project's board view, and set *Column by* to **Factory status**." Wait until they confirm.
8. **The `idea` kind.** A new board gets the `Kind` options `map`, `slice`, `role task`, `frontier ticket` and `idea`. A board made before 2.5.0 has no `idea` option: ask the person to open the project's settings, add the option `idea` to the `Kind` field by hand, and then run `board.sh finish ... --views-confirmed` again so that the `Kind` table of `docs/agents/factory.md` gets its id. Until then ideas are triaged from the tracker and stay off the board; nothing else waits on it.

**Done when** `board.sh finish` exited 0, every cell in the Tracker tables holds a value, both views are confirmed and the user has confirmed the board groups by `Factory status`.

**Restoring the old distinction** (the board cannot give it back). The snapshot is the only place the difference between In progress and In review survives. To restore: (1) add the four old option names back to `Factory status` (they get new ids), keeping every present option's id; (2) for each item in the snapshot, set its recorded old option with `gh project item-edit`; (3) when every item is set, drop what the old workflow did not have. A real restore is not rehearsed.

### 8. Put worktrees in the project's agent folder

Item and frontier-round worktrees live in `.claude/worktrees`, inside the project, so they need no permission outside it. Make that true for this repo:

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" ignore`. It adds `/.claude/worktrees/` to `.gitignore` and says `added`, or says `already present` and changes nothing; running it twice is safe. Commit a changed `.gitignore` on main.
2. Make the repo's own test, lint and search commands skip `.claude/worktrees` (a runner's ignore or exclude setting; `grep -rn --exclude-dir=worktrees`; `git grep` already skips ignored folders). If a command scans the whole tree, change it here, or tell the person which one and why.
3. Set the `## Worktrees` section of `docs/agents/factory.md` to `.claude/worktrees/<id>` and `.claude/worktrees/frontier-<map>` (the template has them). A repo whose section still says `../wt/<id>` gets the new text.
4. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" legacy`. Exit 0 and no output: nothing to migrate. Exit 10 lists each worktree at the old location (`../wt/<name>`) with its branch. Offer the person one choice per worktree: **move or finish**. *Move* is `git worktree move <old path> <main checkout>/.claude/worktrees/<name>` (git updates its links; do it only when the worktree has no running agent and no uncommitted work); *finish* leaves it where it is, and the lead completes that item there. Make no move without a yes.

**Done when** `worktree.sh ignore` has run, the search, lint and test commands exclude `.claude/worktrees`, `docs/agents/factory.md` names the new location, and every worktree `legacy` listed was moved, or the person chose to finish it where it is.

### 8a. Keep item folders out of trunk

Item folders in `work/` are removed by the last commit on each item branch. Nothing to ignore; confirm no `work/` rule in `.gitignore` hides them, since roles commit their messages.

**Done when** `git check-ignore work/x` prints nothing.

### 8b. Offer the idea inbox

The inbox is a local, gitignored folder where the person drops a file (a note, a link, a pasted passage) to be filed as an idea at the next run start; the folder is a drop zone and the tracker holds the ideas (`skills/run/SKILL.md`, *Idea intake*). Ask the person whether to create the inbox folder and its ignore rule. Only a clear yes (the word `yes`) leads to `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" init`: it creates `.claude/factory-inbox/`, adds `/.claude/factory-inbox/` to `.gitignore` (commit a changed `.gitignore` on main) and prints `created`, or `already present` and changes nothing the second time. On anything but a clear yes, run nothing and create nothing; do not ask again unprompted. Ideas filed with `/factory:idea` or as a tracker issue with the label `idea` need neither the folder nor this step.

**Done when** the person has answered, and the folder and its ignore rule exist only if the answer was yes.

### 8c. Create the role files and migrate role memory

Each role keeps its project rules and knowledge in the project: `docs/agents/roles/<role>.md` and `docs/agents/skills/<role>/`, under version control (protocol, *Role knowledge*). Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/role-knowledge.sh" init`; it creates a role file and a skills folder for each of the eight roles, and prints `created <n> role files` or `already present`. Commit them on main.

Older versions kept role memory in user scope (`~/.claude/agent-memory/`). User scope is shared by every project the person runs the factory in, so its notes are not all about this project. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/role-knowledge.sh" migrate`: it only lists the candidate notes (`candidate <dir>/<file> (<first line>)`) and writes nothing. Show the person the list and ask which notes belong to this project; default to none. Copy only those with `migrate --select <dir>/<file>[,...]` (repeatable); it puts them in that role's file under `## Migrated memory`, once. Use `--all` only when the person says every note belongs to this project. Show what was copied, and ask whether to remove the user-scope copies of the migrated notes. Only a clear yes (the word `yes`) leads to the same command with `--remove-source` added; it removes only migrated notes, never an unselected one. On anything else leave them. Tell the person to move any remaining personal preferences by hand and nothing else. Commit the role files.

**Done when** the eight role files exist, the notes the person selected are migrated, and the person has answered the removal question.

### 8d. Ask about the Obeya

The Obeya is an opt-in, read-only browser view of the project (`/factory:obeya`). It is on only when `docs/agents/factory.md` has the line `obeya: on`, so a repo set up before it existed has no way to learn that the choice is there. Run this step on every run, also on a repo reported `already migrated`.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/obeya-optin.sh" status`. It prints `on`, `off` or `unanswered`.
2. **`on` or `off` and the repo already existed**: the person answered before. Say what the line is and change nothing; do not ask again.
3. **`unanswered`**: ask one question: "Enable the Obeya? It is a read-only browser view of this project that runs in a container on loopback. yes or no, default no." Only the word `yes` or the word `no` is an answer; no answer, no write. On silence, a timeout or anything else, run nothing and do not ask again unprompted.
4. **`off` in a `docs/agents/factory.md` that step 5 copied from the template in this run**: the template's line is not an answer. Ask the same question.
5. Write the answer: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/obeya-optin.sh" set on` (yes) or `set off` (no). Add `--replace` only in case 4, to overwrite the template's `obeya: off`. The script adds the `## Obeya` section when it is missing and reports `already answered: <v>` and changes nothing when the line is there. Commit a changed `docs/agents/factory.md` on main.

**Done when** the person has answered yes or no and `status` prints `on` or `off`, or the person gave no answer and the file is as it was.

### 9. Add the pointer

In the `## Agent skills` block, add this subsection after the last existing `###` subsection, unless a `### Factory` subsection is already there:

```markdown
### Factory

Slices are built by the factory's role agents. See `docs/agents/factory.md`.
```

**Done when** exactly one `### Factory` subsection exists in the block.

### 9a. Scan the project and write the flow table

The lead sizes work with a points table, and a project without one cannot run (`factory-config.sh state` exits 6 and says `run setup-factory-skill`). Run this step on every run, also on a repo reported `already migrated`: a 2.x project gets the table here, appended as its own section.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-table.sh" scan`. It reads the project and prints findings, one per line, and changes nothing: the project type (markdown/LLM plugin, static site, code app), its test command, whether a workflow runs that command on pull requests (the `ci:` line: `ci: workflow <file> runs ... on pull requests`, or `ci: none (<reason>)`), the protected-area candidates, deploy or pipeline config, contracts or interfaces others use, and visual output. These are candidates: correct any the project's own files show to be wrong.
2. Show the person the table the findings give: the eight triggers with their points and what each adds (an open one-way door 3, an unresolved research question 3, more than 3 expected slices 2, a protected area 3, a contract or interface 2, new logic in a code project 2, a visual result 1, deploy or pipeline config 3), the bands (Light 0 to 2, Normal 3 to 6, Heavy 7 or more), the starting test depth of the project type (proof-only for a markdown/LLM plugin or a static site, targeted for a code app), each row's reason from the scan with the status `provisional`, the floor (never removed by the table), and the `ci:` line with its reason. Ask one question: confirm this table? Only a clear yes (the word `yes`) leads to step 3; anything else writes nothing, and the project stays without a table. This is the only question of this step. The setup does not offer a test workflow: a project with `ci: none` declares it and the merge gate accepts a recorded local run in place of a check.
3. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-table.sh" write`. It appends the section `## Flow table` and the section `## CI` to `docs/agents/factory.md` and changes no other line (so a re-run on a 2.x project appends the section and touches nothing else); a section already there is left as it is, so a second run prints `already present` and changes nothing. Commit the changed file on main.

**Done when** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/factory-config.sh" state` exits 0, and the person has confirmed the table or has been told that the project stays without one.

### 10. Report completion

Tell the user setup is done and name the next step:

- No wayfinder map yet → `/factory:run` with the idea; the lead charts a map with `/wayfinding:wayfinder` first.
- A framed slice ticket exists → `/factory:run #<n>`.

Mention that improvements to the factory itself go to `https://github.com/WimSuenens/agent-plugins/issues` with the `plugin:factory` label, and that `/factory:run` offers to draft one at the end of every item.

## Version 1.x records

The worked example of the stage log that factory 1.3.0 wrote into the lead state, kept so that a record or a log written by a 1.x run can still be read after the migration.

The lead state of item #12 at approval, new sections only.

```
## Label

- plugin root: ~/.claude/plugins/cache/wimsuenens/factory/1.3.0
- release: 1.3.0
- standard: 9a1c5e7b3d2f40869a7c1e5b3d9f2a4c6e8b0d1f3a5c7e9b2d4f6a8c0e1b3d5f
- tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652
- overrides at start: none
- wayfinding: 5a136f2eaa0a (skill base dir)
- mattpocock-skills: 1.3.1 (plugin list)
- lead sessions: 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c

## Stage log

| # | Stage | Role | Agents | Start (UTC) | End (UTC) | Duration | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Start item | lead | - | 2026-11-04T11:40Z | 2026-11-04T11:43Z | 3m | - | - | done | label computed; drift: same as #9; author test: ok; freeze: none |
| 2 | Requirement | product-owner | a1c9e2 | 2026-11-04T11:43Z | 2026-11-04T11:58Z | 15m | - | 53942 | done | 9 ACs, 2 decisions |
| 3 | Contracts and ADRs | architect | b7d031 | 2026-11-04T11:58Z | 2026-11-04T12:55Z | 57m | W1 | 81277 | done | 1 card |
| 4 | Build | developer | c44a10 | 2026-11-04T12:55Z | 2026-11-04T14:46Z | 1h51m | W2, W3 | 138578 | done | resumed after a limit and after a sleep |
| 5 | Open PR | lead | - | 2026-11-04T14:47Z | 2026-11-04T14:48Z | 1m | - | - | done | bump check passed (no factory paths) |
| 6 | QA | qa-engineer | d21f77 | 2026-11-04T14:48Z | 2026-11-04T15:10Z | 22m | W6 | 70114 | findings | 1 finding |
| 7 | Security | security-reviewer | a41f09 | 2026-11-04T14:48Z | 2026-11-04T15:02Z | 14m | - | 48820 | pass | 2 low |
| 8 | Andon A1 | lead | c44a10 | 2026-11-04T15:11Z | 2026-11-04T15:23Z | 12m | W7 | - | done | kind 2 same-finding-twice; override replay-before-build |
| 9 | Build (round 2) | developer | c44a10 | 2026-11-04T15:23Z | 2026-11-04T15:30Z | 7m | W7 | 141210 | done | QA finding fixed; paused by A1 |
| 10 | QA (round 2) | qa-engineer | d21f77 | 2026-11-04T15:31Z | 2026-11-04T15:40Z | 9m | - | 74480 | pass | |
| 11 | Documentation | docs-writer | e90b55 | 2026-11-04T15:41Z | 2026-11-04T16:00Z | 19m | W4 | not captured (failure notice carried no token count) | done | done, then stalled; Done list checked, not resumed |
| 12 | Andon A2 | lead | - | 2026-11-04T16:01Z | 2026-11-04T16:09Z | 8m | W8 | - | done | kind 3 role-outside-role; override none |
| 13 | Merge approval | person | - | 2026-11-04T16:09Z | 2026-11-04T16:21Z | 12m | W5 | - | approved | bump re-check passed (no factory paths) |

## Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-04T12:02Z | 2026-11-04T12:41Z | yes | decision card on #12: export format |
| W2 | limits | c44a10 | 2026-11-04T13:05Z | 2026-11-04T13:20Z | yes | developer failed: session limit, resumed at reset |
| W3 | interrupted | c44a10 | 2026-11-04T13:52Z | 2026-11-04T14:10Z | yes | developer failed: server_error at 14:09Z; sleep 13:53Z–14:08Z; start from cut-offs.sh; resumed |
| W4 | stalled | e90b55 | 2026-11-04T15:49Z | 2026-11-04T16:00Z | yes | docs-writer failed: no progress for 600s, after its done result; start from cut-offs.sh; accepted, not resumed |
| W5 | person | - | 2026-11-04T16:09Z | 2026-11-04T16:21Z | yes | merge and clean up? |
| W6 | stalled | d21f77 | 2026-11-04T15:03Z | 2026-11-04T15:07Z | yes | found at close: cut-mid-stream; QA recovered by itself, no notice |
| W7 | andon | c44a10 | 2026-11-04T15:11Z | 2026-11-04T15:23Z | yes | no stop A1 kind 2: same-finding-twice |
| W8 | andon | lead | 2026-11-04T16:01Z | 2026-11-04T16:09Z | yes | no stop A2 kind 3: role-outside-role |

## Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-04T12:41Z | decision card | chose B on the export-format card |
| 2026-11-04T13:40Z | overturn | overturned the architect's CSV delimiter decision |
| 2026-11-04T16:21Z | approval | merge and clean up: yes |

## Findings

| Role | Round | Id | Severity | Text |
|---|---|---|---|---|
| qa-engineer | 1 | F2 | major | the export writes its scratch file to a shared path |
| security-reviewer | 1 | L2 | low | the scratch file is created under a predictable path |

## Abnormalities

| Id | Raised (UTC) | Kind | Raised by | Paused agent | Resumed (UTC) | Andon comment | Override |
|---|---|---|---|---|---|---|---|
| A1 | 2026-11-04T15:11Z | 2 same-finding-twice | lead | developer c44a10 (handed back) | 2026-11-04T15:23Z | https://github.com/example/shop/issues/12#issuecomment-111 | replay-before-build |
| A2 | 2026-11-04T16:01Z | 3 role-outside-role | lead | - | 2026-11-04T16:09Z | https://github.com/example/shop/issues/12#issuecomment-222 | none |
```

From this log: total 11:40Z → 16:21Z = 4h41m; held person waits W1 + W5 = 39m + 12m = 51m; held limit wait W2 = 15m; held stalls W4 + W6 = 11m + 4m = 15m; held interruption W3 = 18m; held andon waits W7 + W8 = 12m + 8m = 20m; no two held waits overlap; agent working 4h41m − 51m − 15m − 15m − 18m − 20m = 2h42m. W6 is held because the security review, the only other agent in that stretch, ended at 15:02Z. W3, W4 and W6 also mark the developer's, the docs-writer's and the QA's transcripts as truncated, so the record reads their spend as `not captured`; W7 and W8 begin `no stop` and truncate nothing. No Delivery row: the item had nothing to deliver, and devops reads `n/a (did not run)` in the record.

W6 is the close scan's work: QA's transcript held one `cut-off mid-stream` marker, QA recovered and handed back normally, and no notice came. `cut-offs.sh` printed `agent-d21f77.jsonl\tstalled\t2026-11-04T15:03:12Z\t2026-11-04T15:07:40Z\tcut-mid-stream`, with no logged wait for `d21f77` overlapping it, so the lead added W6. Had an andon wait of `d21f77` covered that interval, the line would have been that wait and nothing would have been added.
