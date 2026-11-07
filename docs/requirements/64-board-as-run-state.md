# 64 — The board holds the factory run's state (release 2.0.0)

Slice: [#64](https://github.com/WimSuenens/agent-plugins/issues/64) · Map: [#50](https://github.com/WimSuenens/agent-plugins/issues/50) · ADRs: [0014](../adr/0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md), [0015](../adr/0015-factory-status-has-six-values-plus-kind-and-role.md), [0016](../adr/0016-slices-run-in-parallel-when-their-path-lists-do-not-overlap.md) · Also binding: [0001](../adr/0001-factory-roles-talk-through-files.md), [0002](../adr/0002-one-branch-and-worktree-per-item.md), [0007](../adr/0007-factory-owns-destination-and-slicing.md), [0012](../adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) · Builds on: [39-hansei-record](39-hansei-record.md), [49-andon](49-andon.md), [57-per-run-a3-and-baseline](57-per-run-a3-and-baseline.md), [60-gemba-sample](60-gemba-sample.md)

## User outcome

The person who runs the factory opens the GitHub Project and reads the run live. The board shows the map, the slice and one card per role task. Every card has one `Factory status` (Backlog, Ready, Running, Waiting on you, Blocked, Done), a `Kind` and a `Role`. A "Needs you" view lists what waits for the person. The person opens a role task from the board and reads what the role was told (the sub-issue body) and what it answered (the closing comment), with no clone and no branch. The slice's hansei numbers sit in Project fields and a History view shows them across closed slices. The lead's `work/` folder holds only drafts, questions and the lead's own memory, and no status.

Two slices may run at the same time when the path lists in their contracts do not overlap; the limit is a setting that defaults to 2. A project on 1.x is brought up by one migration step in `setup-factory-skill`, which shows the person what it will change and applies it only after a yes, and which `/factory:run` insists on before it does anything else.

This is the whole Destination of map #50, built as one slice and released as 2.0.0 with one merge approval. What cannot be tested offline ships as **unverified** and is named in the changelog.

## Terms used here

- **Board**: the GitHub Project of the repo (`docs/agents/factory.md`, *Tracker*). **Card**: an item on it.
- **Role task**: one spawn of one role on one item. Its **sub-issue** is the card; its **brief** is the sub-issue's body; its **result** is the closing comment (ADR 0014).
- **Draft result**: the committed file `work/<id>/NN-result-<role>.md` a role writes; the lead copies it to the comment (ADR 0014, point 4).
- **Fake `gh`**: a script placed first on `PATH` in a test that logs every call with its arguments and answers from a fixture. No test in this slice calls the real tracker.
- **Mutation call**: a `gh` call that creates, edits, closes, links or deletes something (`issue create|edit|comment|close`, `project item-add|item-edit|field-create|item-create`, `api` with `--method` other than GET, `api graphql` with a `mutation`). A read call is any other.
- **Honesty rule** (`references/hansei.md`, *Value grammar*): a value is a measured value, `0` when truly zero, `n/a (did not run)` or `not captured (<reason>)`; never a guess, never blank, never dropped.
- **Path list**: the `Paths:` and `shared:` lines of a contract (ADR 0016).
- **Old values**: Designed, In progress, In review, Ready to deploy.
- **Human-only**: a criterion only a person can judge or only a live Project can show; no script checks it. **Unverified**: a criterion this release cannot exercise; it is named in the changelog.

## Validation data

Nothing from a live Project is used. Fixtures QA writes in `tests/` (the architect's contracts name the exact calls):

| Name | What it is |
|---|---|
| **Fake `gh`** | records calls and answers from fixture files: field lists, item lists with field values, issue comments, sub-issue lists. A switch makes a named call fail with a limit message. |
| **Board-v1** | a Project fixture in 1.x shape: seven options, 12 items spread over all seven values, one item with a value in an extra field (`Priority`), one item with no `Factory status`. |
| **Board-v2** | the same fixture after a correct migration. |
| **Board-mid** | Board-v1 after phase 1 only, and after phase 2 with one item still on an old value. |
| **Big result** | a draft result of 150,000 characters; **Home-path result**, a draft result with an absolute home path in its body. |
| **W12, C49, L57** | the stage logs of requirement 60 (`references/hansei.md` section 4, [#49 comment](https://github.com/WimSuenens/agent-plugins/issues/49#issuecomment-6691671841), [#57 comment](https://github.com/WimSuenens/agent-plugins/issues/57#issuecomment-6700562237)). Used as role-task fixtures to check that readers of the old stage log still give the same answers (AC-26). |

Facts found while writing this: the real Project (number 9) is never touched by the build. The only evidence of the migration on a real board is the lead's one try on a scratch Project after the build, which is **Unverified** here (list below).

## Acceptance criteria

Each criterion ends with what contradicts it. "The standard" means the text of `plugins/factory/` (skills, references, agents); "the lead" is the person or agent following that text.

### A. The board as status (ADR 0015)

**AC-1 `Factory status` has exactly six values.** *(Under test: One `Factory status`)*
Given a project set up by 2.0.0 (fresh, or migrated),
when its `Factory status` field is read,
then its options are, in this order, `Backlog`, `Ready`, `Running`, `Waiting on you`, `Blocked`, `Done`, no others, and the option-id table in `docs/agents/factory.md` has one row per option with its id and no row for an old value.
And the standard's tracker operations (`references/issue-tracker-github.factory.md` and the copy in `docs/agents/issue-tracker.md`) name only these six values.
It is contradicted if an old value or a seventh option remains, or the table and the field disagree.

**AC-2 `Kind` and `Role` are single-select fields with fixed options.** *(Under test: One `Factory status`)*
Given a project set up by 2.0.0,
when its fields are read,
then `Kind` has the options `map`, `slice`, `role task`, `frontier ticket`; `Role` has the seven role names (`product-owner`, `architect`, `developer`, `qa-engineer`, `security-reviewer`, `devops`, `docs-writer`); both ids are in the Tracker table of `docs/agents/factory.md`.
And a card has a `Role` only when its `Kind` is `role task`; every other card leaves `Role` empty (a blank `Role` is not a measure, so the honesty rule does not apply to it).
It is contradicted if a card of another kind carries a `Role`, or a role task has none.

**AC-3 Every card is on the board with its three fields, set by the lead through `gh`.** *(Under test: One `Factory status`; Done when line 1)*
Given a fake `gh` and the lead following the standard for (a) a run start (the map, its children), (b) cutting a slice, (c) opening a frontier ticket's work, (d) creating a role task,
when the calls are read,
then each of the map, each child ticket of the map, the slice and each role task is added to the board (`item-add`) and gets `Factory status` and `Kind` set (and `Role` for a role task), and each call is one the standard names in its operations list.
It is contradicted if a card of these four kinds is created without being on the board, or without a `Factory status`.

**AC-4 Each status is set by a named event, so the board needs no other source.** *(Under test: reading only the board)*
Given the standard,
when its status rules are read,
then every transition is tied to an observable event, and the rules say at least this:
- `Backlog`: a ticket exists and is not yet sliced or cut.
- `Ready`: the ticket is cut and may start, or it waits for a path overlap (AC-29).
- `Running`: a role task of the item has been spawned and has not returned a result, and for the slice and the frontier ticket: from the first such spawn until it waits, blocks or is done. The stage is the role task that is `Running`; no field holds it.
- `Waiting on you`: whenever the lead asks the person for something: a decision card (step 7), the merge approval, a task request, the delivery approval, a resurvey pause (AC-31), a missing project permission.
- `Blocked`: a role task whose result `Status` is `blocked`, a role task or slice stopped by an andon, or a role task waiting on a missing input.
- `Done`: the role task's result is posted and the sub-issue closed; the slice's PR is merged.
And given a fixture run narrated step by step (start, requirement, a decision card, answer, build, QA findings, rework, pass, merge approval, merge),
when the status of the slice and of every role task is derived by the rules after each step,
then the sequence matches the fixture's expected sequence, and no step needs `work/` or a branch to be derived.
It is contradicted if a transition needs information that is only in `work/`, or two events map to a status in conflicting ways.

**AC-5 A card that is `Waiting on you` says what the person must do.** *(Under test: the person, reading only the board, can tell what to do next)*
Given the lead sets a card to `Waiting on you`,
when the standard's calls are read,
then the same step posts one comment on that card, in plain words, that begins with a fixed marker and holds: what is asked (one sentence), the options or the link to the decision card when it is a decision, and what happens when the person answers; the comment is posted before or in the same step as the status change and never after.
And given a fake `gh` run of each cause listed in AC-4,
when the comment is read,
then each reads as an instruction a person can act on without opening `work/` or a branch (QA checks the comment contains no path under `work/` and no branch name).
It is contradicted if the card can reach `Waiting on you` with no comment, or the comment points the person to `work/`.
*Human-only addition:* the person reads the board once during the first real run and states whether the next step was clear (settles in feedback; **Unverified** item 3).

**AC-6 The "Needs you" view is created by the migration or setup step, with a manual fallback.** *(Under test: the view cannot be created or filled by script)*
Given the setup step runs against a fake `gh` that (a) accepts the view-creation mutation, (b) refuses it,
when the step completes,
then in (a) a view named `Needs you` with the filter `status:"Waiting on you"` is requested and the step then asks the person to open it once and confirm it shows the filter; in (b) the step does not report success for the view, prints exactly what the person must click (name, filter), asks for confirmation, and continues only after it; neither case leaves the step reporting `done` for the view unconfirmed.
And re-running the step with the view already present (fixture field list shows it) makes no second view.
It is contradicted if the step reports the view as created when the call failed, or creates a duplicate.
*Human-only:* that the view really appears and filters on a live Project (**Unverified** item 2).

**AC-7 No card carries an old value; no text outside the migration names one.** *(Under test: One `Factory status`)*
Given the 2.0.0 standard,
when `plugins/`, `docs/agents/factory.md`'s template and the tracker templates are searched for `Designed`, `In progress`, `In review` and `Ready to deploy`,
then each hit is inside the migration step (table and snapshot text) or the changelog, and nowhere else.
It is contradicted by any other hit.

**AC-8 The map and its children are on the board; the map's "Factory run" section stays as the resume pointer.** *(ADR 0014, "Decided inside")*
Given a run on 2.0.0,
when the lead starts, resumes and closes it,
then the map is a card of `Kind` `map` and every child ticket of the map is a card (`slice`, or `frontier ticket` for the other ticket types); the map's `## Factory run` section is kept, holds step, branch(es), the FREEZE line and the open andon pointers and no status word of the six values, and is the only run-state text in the map body.
It is contradicted if the section carries a status the board also carries, or a child ticket is missing from the board.

### B. Role tasks as sub-issues (ADR 0014)

**AC-9 One sub-issue per role task, body = brief, linked under the right parent.** *(Under test: Role sub-issues hold the message record)*
Given a fake `gh` and a brief for a role,
when the lead creates the role task,
then it makes exactly one issue whose body is the brief (the brief template of `references/protocol.md`, unchanged in fields), links it with `addSubIssue` to the slice ticket (item) or to the frontier ticket (frontier round, never the map), puts it on the board with `Kind` `role task` and its `Role`, and the spawn prompt names the issue number and says the role reads the brief from it.
And the issue carries a first-line marker `<!-- factory:task <role> <n> -->` (n counts the role's tasks in this item, rework included), and its title names the role and the item.
It is contradicted if the brief is a file in `work/` and not the body, or the parent is the map for a frontier role task.

**AC-10 Creating a role task twice is impossible.** *(Under test: the lead can find a role task again after a resume)*
Given the lead is resumed after creating a role task but before spawning it (a fixture where the sub-issue already exists under the parent with that marker),
when the lead follows the standard,
then it finds the existing sub-issue by its marker (a read call) and does not create a second; with no match it creates one.
It is contradicted if the fixture ends with two sub-issues for the same marker.

**AC-11 The result is the closing comment, in a fixed shape, followed by the close.** *(Under test: Role sub-issues hold the message record)*
Given a draft result,
when the lead posts it,
then the comment's first line is `<!-- factory:result v1 -->`; then `Status:`, `Abnormality:` and `Summary:` (at most 10 lines) are visible, and `Progress`, `Artifacts`, `Decisions`, `Open questions`, `Missing` and `Decision card` are inside one `<details>` element; the sub-issue is closed after the comment and not before; the card's `Factory status` becomes `Done`, or `Blocked` / `Waiting on you` per AC-4.
And the comment's text equals the draft's text field for field (no field is added, dropped or reworded).
It is contradicted if Status or Summary is inside `<details>`, or the issue is closed with no comment.

**AC-12 A resumed lead finds the posted result and does not post it twice.** *(Under test: the lead cannot find a role task's comment again after a resume)*
Given fixtures (a) a sub-issue with the marker comment and still open, (b) closed with the comment, (c) open with no comment,
when the lead resumes,
then (a) closes the issue and posts nothing; (b) does nothing; (c) posts once; none ends with two marker comments.
And the find is by the first-line marker among the lead's own comments, not by position or time.
It is contradicted if any fixture ends with two comments.

**AC-13 A result longer than one comment is split, with Status and Summary first.** *(Under test: a real result exceeds what one comment holds)*
Given **Big result** (150,000 characters) and a normal result,
when the lead posts them,
then the normal result is one comment; the big one is a first comment (marker line, Status, Summary, as much of the rest as fits) and further comments that each carry a continuation marker naming the first, with no comment longer than 65,536 characters; logs and diffs are linked, not pasted (a fixture with an inline 100,000-character diff is posted as a link and the file path in the commit); and the resume find of AC-12 finds the first comment and all continuations and does not repost.
And the number of results that needed a split is visible to the lead at close (a count in the lead's close checks), so "more than rarely" can be judged.
It is contradicted if any posted comment exceeds 65,536 characters, if Status and Summary are not in the first, or if a split result is reposted on resume.
*Unverified:* how often real results need a split (item 1).

**AC-14 A cut-off role loses no `Progress`.** *(Under test: a cut-off role loses its Progress)*
Given a role cut off while `Status: working` (fixture: a draft result committed with `Progress` filled, no comment posted),
when the lead resumes it,
then the resumed agent is told to read its `Progress` from the committed draft in `work/<id>/`, not from the sub-issue; the sub-issue stays open and the card stays `Running`; no result comment is posted for a `working` draft.
And the draft result file is still written, committed and named by the protocol (`NN-result-<role>.md`), and where the comment and the draft differ, the draft's commit decides (the standard says so in one line).
It is contradicted if the standard asks the role to keep `Progress` only in the tracker, or posts a `working` draft as the closing comment.

**AC-15 Rework is a new sub-issue; feedback is its body.** *(ADR 0014, point 3)*
Given QA findings (a feedback brief),
when the lead sends them to the developer,
then the lead creates a sub-issue under the same slice titled `rework <n>: …` (n counts rework sub-issues of the slice from 1), its body the finding list and the re-verify line in the feedback template; the earlier role-task sub-issue stays closed and unedited; the new card gets `Kind` `role task`, `Role` the role that fixes, status per AC-4.
And the slice's `Rework rounds` field (AC-22) equals the number of `rework` sub-issues.
It is contradicted if a finding is written into an earlier closed sub-issue or into a file instead of the new one.

**AC-16 Only the lead writes to the tracker; roles' shells are unchanged.** *(Fenced F6; ADR 0014, point 4)*
Given the 2.0.0 standard,
when the protocol's *Shell* section, every agent file and every brief template are read,
then the *Shell* section is word for word the 1.3.0 text; no agent file or brief template tells a role to run `gh issue create|edit|comment|close` or a `gh project` or `gh api` write; the architect and product-owner may still read the tracker (`gh issue view`).
It is contradicted by one role instruction to write to the tracker, or any change to the fenced text of the protocol.

**AC-17 Questions and the lead's memory stay files; the other message files go.** *(Done when line 3)*
Given the 2.0.0 protocol,
when its *Messages* section is read,
then it names these `work/` files and no others: the committed draft result of each role, the question (role → lead), and the lead's state (`00-lead-state.md`); the brief and the feedback are defined as sub-issue text; the rule `NN-<type>-<role>.md` keeps its numbering for the files that remain; the `Citations` rule (no `work/` path in anything that lands on main) holds and now also covers issue text.
And given a fixture of a role question,
when the lead answers,
then the answer goes into the role's next sub-issue body (or the rework body) and never into a file the role did not write.
It is contradicted if a brief or feedback is still written as a file, or a question is posted to the tracker by a role.

**AC-18 Text posted to the tracker obeys the home-path and secret rules.** *(ADR 0013 applied to issue text; ADR 0014, point 6)*
Given **Home-path result** (an absolute path under a user's home directory, and a fixture token string, in its body),
when the lead prepares the comment or the brief,
then the standard has the lead scan the text first with a named command and, on a hit, post nothing, tell the person which line, and keep the card `Running`; a clean text is posted.
And the scan covers briefs, closing comments, rework bodies and every comment of AC-5.
It is contradicted if the fixture is posted.

**AC-19 A tracker limit stops the creation, loudly and without duplicates.** *(Under test: GitHub limits reached before the item closes)*
Given a fake `gh` that answers (a) a content-creation call with a secondary rate-limit error and `Retry-After`, (b) `addSubIssue` with a "too many sub-issues" or nesting error,
when the lead creates a role task,
then in (a) it waits the stated time once and retries once, then stops with a message naming the limit and the call; in (b) it stops at once; in both it leaves no half-linked issue unannounced (the issue created but not linked is named to the person), asks the person (card `Waiting on you`), and on resume the marker find of AC-10 prevents a second issue.
And the standard names the three limits it was designed for (100 sub-issues per parent, 8 levels, 80 content-creating requests per minute; [#51 findings](https://github.com/WimSuenens/agent-plugins/issues/51#issuecomment-6671497843)) and says a run counts its content-creating calls per minute only by reacting to the error, not by pre-counting.
It is contradicted if the lead retries without bound, or reports success after a failed link.
*Unverified:* whether a real slice or frontier round ever reaches a limit (item 1).

### C. Hansei numbers in Project fields, and the sections that leave

**AC-20 The fields exist, with fixed names, and are made by the setup step.** *(Under test: Hansei numbers in fields)*
Given a project set up or migrated by 2.0.0,
when its fields are read,
then the slice fields `Tokens`, `Hours`, `Rework rounds`, `Person touches` and the role-task fields `Tokens`, `Minutes` exist (the same `Tokens` field may serve both kinds), their ids are in the Tracker table of `docs/agents/factory.md`, and a re-run of the step creates none twice.
It is contradicted if a number of the Destination has no field, or a re-run duplicates one.

**AC-21 The History view exists, with the same fallback as AC-6.** *(Under test: Hansei numbers in fields)*
Given the setup step against a fake `gh` that accepts, then refuses, the view-creation call,
when it completes,
then a view named `History` is requested (a table of closed slices and closed role tasks with the six fields above, newest first) or the person is told exactly what to build and asked to confirm, as in AC-6; no `done` is reported unconfirmed.
*Human-only:* that the view shows the closed items' numbers on a live Project (**Unverified** item 2).

**AC-22 At the close of a role task and of the slice, the lead fills the fields; none is blank.** *(Under test: a number cannot be captured per slice or role task)*
Given a fixture item with role tasks whose sub-issues have created and closed times, token totals (`token-spend.sh` output), two rework sub-issues and three recorded person touches,
when the lead closes a role task and then the slice,
then each role task gets `Tokens` and `Minutes` (minutes between the sub-issue's created and closed times, less the waits the standard names); the slice gets `Tokens` (total of its role tasks), `Hours` (lead time as `references/hansei.md` defines it, ending at the merge approval), `Rework rounds` (AC-15) and `Person touches` (count of the person's touches, defined in the standard).
And for each value that was not measured the field holds a value the honesty rule allows (`not captured (<reason>)` or `n/a (did not run)` in a place the History view shows), never an empty cell, never `0` in place of unknown; the field type that can hold that is the architect's choice (open question).
It is contradicted if any of the six fields is empty after the close, or `0` is written for a number that was not measured.

**AC-23 The fields read the same as the sections they replace.** *(Under test: reads differently from the stage log it replaces)*
Given the stage logs **W12**, **C49** and **L57** re-expressed as the sub-issue and touch fixtures they would have been under 2.0.0 (QA writes both forms and states, before the replay, the expected values),
when the lead fills the fields by the new rules,
then `Hours`, `Person touches` and `Minutes` equal what the 1.3.0 rules give from the stage log, wait table and touch table (measure definitions in `references/hansei.md` unchanged in meaning), except where a field is explicitly `not captured`; any difference is listed by QA with its cause and is a finding unless the standard states the new definition in one place.
It is contradicted if a replayed value differs without the standard saying why.

**AC-24 The three sections leave the lead state, and so does the status line.** *(Destination, "work/ holds only drafts, questions and the lead's memory")*
Given the 2.0.0 standard and the lead-state template,
when `## Stage log`, `## Waits`, `## Person's touches` and a `Status:` line of the lead state are searched in `plugins/`,
then none is defined, started or written as part of the lead state, and the template of `00-lead-state.md` holds: board item id, next step, open questions, freeze line, `## Running agents`, shared resources, the interrupted role's `Progress` pointer, `## Label`, `## Findings` and `## Abnormalities` (these last three stay unless the architect shows they must move; open question).
And `references/hansei.md` section 1 and 4 (the six sections and the worked stage-log example) are rewritten for the sections that remain, and the 1.3.0 worked examples are either deleted or moved under a heading that says they describe version 1.x records.
It is contradicted if the lead is told to keep a stage log, or `Status` remains in the lead-state template.

**AC-25 Nothing in the standard still reads a section that has left.** *(Under test: the numbers needed for the History view)*
Given the 2.0.0 standard,
when every sentence that names the stage log, waits or touches is listed (known readers: the slow-stage test (andon kind 4), the close scan for cut-offs, the stage-log cross-check, the hansei measures and the baseline, the gemba sample rule, the interruption procedure, the `Held item` rule),
then each reader names its new source (a role-task sub-issue's times, a field, a comment, the lead's state) or is removed with the reason in the changelog, and the search for `stage log` finds only the list of 1.x text inside the migration and the worked examples of AC-24.
And the lists differ from 1.3.0 only where stated: `references/protocol.md`'s andon table keeps seven kinds and the same observation text for each unless the new source changes it (fenced F4: no kind is dropped and no role loses the right to raise one).
It is contradicted if a reader still points to a section that is no longer defined, or an andon kind is dropped.

**AC-26 The gemba sample rule and the slow-stage test still give the same answers on the old fixtures.** *(Under test: reads differently)*
Given **W12**, **C49** and **L57** as role-task fixtures (AC-23),
when the gemba rule (`references/hansei.md` section 6; picks W12 row 2, C49 row 8) and the kind 4 test (median of earlier rows of the same role, flagged above twice the median) are run on the new source,
then the picks and flags are identical to the 1.3.0 results QA recorded on the old logs, or QA lists each difference with the standard's stated reason.
It is contradicted by an unexplained difference.

### D. Parallel slices (ADR 0016)

**AC-27 A contract carries `Paths:` and a `shared:` line.** *(Under test: parallel slices on non-overlapping path lists)*
Given the 2.0.0 architect agent and contract guidance,
when they are read,
then a contract must carry a `Paths:` block (one path per line; a directory prefix ends in `/`; every role's paths included: `plugins/` for the developer, `tests/` for QA, `docs/` for the docs-writer, and so on) and a `shared:` line (the shared paths this slice names, or `shared: none`); a contract with no `Paths:` block fails the architect's Done list.
It is contradicted if the architect's Done list can be met with no list.

**AC-28 The overlap rule gives fixed answers on a table of pairs.** *(Under test: parallel slices on non-overlapping path lists)*
Given these pairs of path lists (QA adds more),
when the lead applies the rule (overlap if a path is equal to, or a directory prefix of, a path in the other list, or both name a shared path),
then the answer is:
| List 1 | List 2 | Overlap |
|---|---|---|
| `plugins/factory/skills/run/SKILL.md` | `plugins/factory/skills/run/SKILL.md` | yes (equal) |
| `plugins/factory/` | `plugins/factory/agents/qa-engineer.md` | yes (prefix) |
| `plugins/factory/agents/qa-engineer.md` | `plugins/factory/` | yes (prefix, other order) |
| `plugins/factory/` | `plugins/factory-x/a.md` | no (a name that starts the same is not a prefix) |
| `docs/requirements/70-a.md` | `docs/requirements/71-b.md` | no |
| `plugins/design/` | `plugins/wayfinding/` | no |
| `shared: CHANGELOG.md`, `a/` | `shared: CHANGELOG.md`, `b/` | yes (both shared) |
| `shared: CHANGELOG.md`, `a/` | `shared: none`, `b/` | no (only one names it) |
| `shared: none`, `a/` | `shared: none`, `a/x.md` | yes (prefix) |
and the standard lists the shared paths that always count as shared: the plugin version file, `CHANGELOG.md`, `CONTEXT.md` and the next ADR number.
It is contradicted by any row, or if the rule is stated in a form that cannot yield these answers.

**AC-29 Starting a second slice is gated by the limit, the list and the status.** *(Under test: parallel slices)*
Given `docs/agents/factory.md` with `parallel-limit: N` and a set of slices in flight (slices that have an item branch and are `Running`, `Waiting on you` or `Blocked`),
when the lead considers starting the next ready slice,
then it starts it only if (a) the number in flight is below N, (b) the new slice's list exists and (AC-28) does not overlap the list of any slice in flight; otherwise the slice stays `Ready` and the lead says why (limit, or the overlapping slice's number).
And fixtures: N = 1 with one in flight → no second slice; N = 2 with one in flight and no overlap → starts; N = 2 with two in flight → waits; N = 2 with an overlap → waits; the setting absent → behaves as 2; the setting `0`, `-1`, `two` or empty → the lead stops and names the line to fix (as for a bad role model value), and starts nothing.
And the setting is written in the template of `docs/agents/factory.md` with the default 2 and one sentence explaining that 1 means one at a time.
It is contradicted by any fixture answer, or if the setting is read from anywhere else.

**AC-30 A slice that has no list yet is not built; it may be required and designed.** *(ADR 0016, point 4)*
Given a second slice cut while one is running,
when the lead runs its stages,
then only the product-owner and architect stages may start before the list exists; no developer, QA or security role is spawned for it until its list exists and passed AC-29; a slice whose list overlaps stays `Ready` with the requirement and contract kept.
It is contradicted if a build role is spawned for a slice whose list was never compared. (A decision of this requirement; the architect may change the point of the check, see Decisions 3.)

**AC-31 After each merge the resurvey checks the slices in flight and pauses the questioned ones.** *(Under test: the resurvey pause is missed)*
Given two slices in flight, A and B, and A's merge,
when the lead runs the close and resurvey,
then the resurvey (the wayfinding plugin's text, as changed by this release) compares B's requirement, contract and path list with what A's merge taught (the Under test results, any new decision, any changed path); for each question that touches B, B becomes `Waiting on you` with the comment of AC-5, its running roles finish the step in hand, and the lead starts no further role for B until the person answers; for no question, B stays `Running` and the lead says it checked.
And given fixtures (a) a merge whose decision contradicts B's frame, (b) a merge that touches a path in B's list (which AC-29 should have prevented), (c) a merge that touches nothing of B,
then (a) and (b) pause B; (c) does not.
And the pause is written in the run text for both the item and the wayfinding resurvey, with the same words, and the factory does not copy the wayfinding text but calls it.
It is contradicted if a questioned slice keeps getting new roles, or an unquestioned one is paused.
*Unverified until two slices run side by side (item 4).*

**AC-32 QA and security check the diff against the list.** *(Under test: an off-list path is touched)*
Given a QA or security brief for item `<id>` and a fixture branch diff,
when the reviewer follows the standard,
then it runs `git diff --name-only main...item/<id>`, compares each path with the contract's `Paths:` list, and a path outside the list is a finding with the path named, severity at least `medium`; a diff within the list gives none. The QA and security agent files and the review templates carry this step.
And a path that only the lead changes at merge (version, changelog line, ADR number as assigned) is not part of `main...item/<id>` when the review runs, and the standard says so.
It is contradicted if an off-list path passes review.

**AC-33 The run text no longer says slices run one at a time.** *(ADR 0016 amends ADR 0007)*
Given `skills/run/SKILL.md`, `docs/agents/factory.md`'s template and the wayfinding plugin's `beachhead` and resurvey text,
when they are searched for "one at a time" and "Items run one at a time",
then none states that rule except as the meaning of `parallel-limit: 1`; the lead assigns the ADR number at slice start (the next free number, recorded in the slice's lead state) and applies the version bump and the changelog line at merge, after rebasing on `main`; `0007`'s closing rule is cited as amended.
And the map's `## Factory run` section lists every item in flight.
It is contradicted if two sources give two rules.

### E. Migration of a 1.x project (ADR 0015)

**AC-34 `factory-state: 2` makes `/factory:run` refuse an unmigrated project.** *(Under test: delivery and version — accepts but cannot read)*
Given `docs/agents/factory.md` (a) with `factory-state: 2` as its first line, (b) without the line (a 1.x project), (c) with another value (`1`, `3`, empty),
when `/factory:run` starts,
then (a) proceeds; (b) and (c) stop before any tracker or git write with a message that says "run setup-factory-skill" and names the line found; the check comes first, before the resume or start decision of step 0 and before any call to the board.
And a project set up fresh by 2.0.0 gets the line from the template, and the migration writes it as the last act (AC-41).
It is contradicted if (b) or (c) starts a run, or the check comes after a mutation call.

**AC-35 The migration step is three phases in a fixed order.** *(Under test: the three-phase migration)*
Given the step's text,
when it is read and then run against **Board-v1** in a fake `gh`,
then the calls come in this order: (1) read all items and their field values, write the snapshot, then add the new options (`Running`, `Waiting on you`, `Blocked`) with every existing option sent with its existing id; (2) re-set each affected item by the table; (3) only then drop the four old options.
And at no point is the option list overwritten without the old ids.
It is contradicted by any call out of that order, or a single call that replaces the list and drops an in-use option.

**AC-36 The snapshot is outside the repo and is never committed or overwritten.** *(ADR 0015, point 5)*
Given the step runs,
when the snapshot is written,
then its path is outside the repo's working tree and outside `work/` (checked by comparing it with `git rev-parse --show-toplevel`), `git status` is unchanged by the step, it holds for every item the item id, the issue number, the title, `Factory status` (option id and name) and every other field value of the item, and it is not written under the home directory in any file the step edits (the path is printed to the person, never saved in the repo).
And given a re-run after phase 1 or 2 (**Board-mid**),
when the step runs again,
then it keeps the first snapshot, makes a second one only under a new name, and says which snapshot is the original.
It is contradicted if the snapshot is inside the repo, or a re-run overwrites the original.

**AC-37 The step prints the table and the item count and applies nothing before a yes.** *(Under test: delivery; fenced F1 spirit)*
Given **Board-v1**,
when the step starts,
then it prints, before any mutation call: the mapping table (Designed → Ready; In progress and In review → Running; Ready to deploy → Waiting on you; Backlog, Ready, Done unchanged) and, per old value, the number of items that will change (for Board-v1: the counts of its fixture) and the number that stay; then it asks.
And given the answer (a) `no`, (b) no answer or a timeout, (c) anything but a clear yes,
when the step ends,
then the fake `gh` log holds no mutation call; given a clear yes, phase 1 starts.
It is contradicted by any mutation call before the yes, or if silence counts as a yes.

**AC-38 The mapping is exact and touches only what it must.** *(Under test: the migration clears a value on an item)*
Given **Board-v1**,
when the migration has run,
then every item that was Designed is Ready, In progress or In review is Running, Ready to deploy is Waiting on you; Backlog, Ready and Done items receive no `item-edit` call; the item with no `Factory status` is left as it is and reported by number; the item with a `Priority` value still holds it.
And after each phase the step re-reads every item and compares every field value (all fields, not only `Factory status`) with the snapshot; a difference other than the expected status change stops the step with a message naming the item and the field, and no later phase runs.
And given a fake `gh` that silently clears one item's `Priority` when the options are replaced,
then the step stops after phase 1 with that finding.
It is contradicted if any value but the intended status is changed or lost without the step stopping.

**AC-39 Phase 3 runs only when no item holds an old value.** *(ADR 0015, point 5)*
Given **Board-mid** (phase 2 done for all but one item),
when the step runs phase 3,
then it drops no option, names the item still on an old value, and ends without `done`; once that item is re-set (fixture updated), the next run drops the four options and reports `done`.
It is contradicted if an option is dropped while an item holds it.

**AC-40 The migration is idempotent.** *(Under test: the migration cannot be applied twice safely)*
Given **Board-v2** (a migrated board),
when the step runs again and the person answers yes,
then it makes no mutation call, creates no second field or view, writes no second snapshot, and reports "already migrated".
And given a run interrupted after phase 1, after phase 2, and after phase 3 but before the final write (**Board-mid** variants),
when the step is run again,
then each ends at the same final board as an uninterrupted run, with the same final file contents.
It is contradicted by one extra mutation call on a migrated board, or any end state that differs.

**AC-41 The step brings the rest of the project up to date and writes `factory-state: 2` last.** *(Under test: accepts but cannot read)*
Given **Board-v1** and a 1.x `docs/agents/factory.md` and `docs/agents/issue-tracker.md`,
when the step succeeds,
then: the new fields and views of AC-1, 2, 6, 20, 21 exist; the option-id table in `docs/agents/factory.md` holds the six new ids and the new field ids and no old row; the `## Factory operations` section of `docs/agents/issue-tracker.md` is replaced by the 2.0.0 template's (the existing step 6 rule: exactly one such section); the `parallel-limit: 2` line is added when absent and an existing value is kept; every other line of both files, including `## Overrides`, is unchanged; then `factory-state: 2` is written as the first line, and only after everything else succeeded.
And given a failure at any earlier point,
then the line is not written, so `/factory:run` still refuses (AC-34).
It is contradicted if the line is present while a field, id or table is missing, or `## Overrides` changes.

**AC-42 The step takes the project number as input and has no live Project baked in.** *(Settled: the build never touches the live Project)*
Given the step's text and any script or test it adds,
when they are searched for the real project number, id and owner of this repo's Project,
then there is none; the step asks for or reads the project from `docs/agents/factory.md` and works the same on a scratch Project; every test in `tests/` for this slice runs against the fake `gh`, and a test run with `gh` removed from `PATH` fails with a clear message and does not reach the network.
It is contradicted if the build or a test calls the real tracker.

**AC-43 The migration's snapshot restores the old distinction.** *(ADR 0015, "Consequences")*
Given a snapshot of **Board-v1** and a migrated **Board-v2**,
when the step's restore path (or its documented manual procedure) is followed,
then the standard says how an item's old value is read from the snapshot and set back; the step names that the many-to-one step (In progress and In review to Running) is restorable only from the snapshot, and prints this next to the table in AC-37.
It is contradicted if the text promises that the old distinction can be restored from the board itself.
*Human-only:* a real restore is not rehearsed (**Unverified** item 2).

### F. Release 2.0.0

**AC-44 Version 2.0.0, tag, and the bump check.** *(Under test: delivery and version; ADR 0012)*
Given branch `item/64`,
when the diff against `main` is read,
then `plugins/factory/.claude-plugin/plugin.json` has `version` `2.0.0` (a major bump: tracker contents and the project's state change), `scripts/check-bump.sh` passes for it (if the script's `level` cannot yield a major suggestion, the script change is in Scope), and the new `standard` and `tooling` fingerprints are quoted in QA's verdict.
And **[post-merge]**, given the PR is merged, the tag `factory-v2.0.0` exists and points at the merge commit on `main`; this item runs on the frozen install `1.3.0`, so its own close keeps the old mechanism (no sub-issues, no migration, no `parallel-limit`), carries no new-series baseline, and the lead tags by hand.
It is contradicted if the bump check fails, or the changelog says the item ran on 2.0.0.

**AC-45 Only named paths change; no home paths; no project data.** *(ADRs 0012, 0013)*
Given branch `item/64`,
when every changed path is listed,
then each is in the Scope section below, or the architect's contract lists it; no file the diff adds or changes holds an absolute path that starts at a user's home directory (any platform), a token, or project data from a project other than this repository's own issues; and no committed file holds the migration's snapshot.
It is contradicted by a path outside the list, or one hit of the search.

**AC-46 The changelog entry for 2.0.0 names the breaking change, the migration and the unverified list.** *(Settled: no demo; name what cannot be tested)*
Given `CHANGELOG.md`,
when the 2.0.0 entry is read,
then it says in the first lines: this is a major release; a 1.x project must run `/factory:setup-factory-skill` (the migration step) before `/factory:run` accepts it; the migration shows a table and waits for a yes; undoing ADR 0014 or 0015 after this release is a 3.0.0 release; it lists, under the heading **Unverified**, every item of the list below by name and says none was exercised; it says this item ran on the frozen 1.3.0 install and the migration was tried once on a scratch Project by the lead, with the outcome written after that try (a failed try is an andon, not a changelog line); it lists what was removed from the standard (the three sections, the old status values, the files `NN-brief-*` and `NN-feedback-*`).
And the README and `docs/factory/` pages describe the board, role tasks, the setting and the migration in their own words, and no page says anything the AC above contradicts.
It is contradicted if any unverified item is presented as verified.

## Unverified

Offline tests cannot show these. The 2.0.0 changelog names them and real use settles them by feedback issues (the map's *Verification* decision).

1. **Limits and result size under real load.** Whether a real slice or frontier round reaches the sub-issue, nesting or request-rate limit, and how often a real result needs a split comment (AC-13, AC-19).
2. **Anything that needs a live Project.** That the `Needs you` and `History` views really appear and filter, that field creation by `gh` really works, that the migration really leaves every value on a real board, and the restore path (AC-6, AC-21, AC-38, AC-43). The lead tries the migration once on a scratch Project after the build; a failure there is an andon.
3. **Whether the person, reading only the board, can tell what to do next** (AC-5, AC-4); and whether the six fields and views read well with many sub-issues (the map's *Not yet specified*).
4. **Parallel running.** Two slices in flight at once: whether a path list is right, whether QA catches an off-list path, whether a merge conflict happens, whether the resurvey pause is missed (AC-28 to AC-33 are tested on fixtures only; the first real pair is the test).
5. **Hansei numbers across a real run.** Whether tokens and minutes per role task are captured as the standard says in a live run, and whether the History view answers a look-back question (AC-22, AC-23).
6. **The migration of a project other than agent-plugins.** The step is tried on one scratch Project; other projects do it when they update.

## Under test → criteria

| #64 Under test line | Criteria that would show it confirmed or contradicted |
|---|---|
| Role sub-issues hold the message record (ADR 0014): result exceeds a comment; a cut-off role loses its Progress; the lead cannot find a comment after a resume | AC-9, AC-10, AC-11 (shape); AC-13 (size, split); AC-14 (Progress kept in the draft); AC-12 and AC-10 (find again after a resume). Real frequency of splits: **Unverified** 1 |
| GitHub limits for role sub-issues and full-result comments | AC-19 (limit errors handled), AC-9 (depth map > slice > role task, frontier under the frontier ticket), AC-13 (65,536 cap). Reaching a limit in real use: **Unverified** 1 |
| What the lead can set and show on the Project through gh | AC-3, AC-6, AC-20, AC-21 (fields and views created, with fallback), AC-35 to AC-41 (migration, no value cleared). Live behaviour: **Unverified** 2 |
| One `Factory status` for every card (ADR 0015): the person, reading only the board, cannot tell what to do next, or must open `work/` or a branch | AC-1, AC-2, AC-4 (events), AC-5 (the card says what to do, no `work/` path), AC-7, AC-8. The judgement itself is **Human-only** / **Unverified** 3 |
| Hansei numbers in fields: a number cannot be captured per slice or role task, or reads differently from the stage log it replaces | AC-20, AC-22 (captured, honest), AC-23 (same values on W12, C49, L57), AC-24, AC-25, AC-26 (no reader of the old sections is lost). Real run: **Unverified** 5 |
| Parallel slices on non-overlapping path lists (ADR 0016): off-list path, merge conflict, resurvey pause missed | AC-27, AC-28, AC-29, AC-30, AC-31 (pause), AC-32 (off-list finding), AC-33. A merge conflict and the first pair in flight: **Unverified** 4 |
| Delivery and version: the migration cannot be applied twice safely, or leaves a project that `/factory:run` accepts but cannot read | AC-34 (refusal), AC-40 (idempotent), AC-41 (`factory-state: 2` written last), AC-44, AC-45, AC-46. A real project: **Unverified** 6 |

## Scope

Paths this slice is expected to change, grouped by who edits them. The architect's contracts decide the exact list and its `Paths:` block; a path not here and not in a contract is a finding (AC-45).

**Developer (`plugins/`)**
- `plugins/factory/skills/run/SKILL.md`: the board as status (AC-1 to 8), role-task creation, result posting and rework (AC-9 to 19), parallel start, limit and resurvey (AC-29 to 33), lead-state sections removed and readers re-pointed (AC-24 to 26), the `factory-state` check (AC-34), `Items run one at a time` (AC-33).
- `plugins/factory/references/protocol.md` (and the copy the setup skill reads, if one exists): *Messages* (AC-17), *Citations* (AC-17, AC-18), *Doors* and *Andon* wording only where a reader of the removed sections changes (AC-25); *Shell* is not edited.
- `plugins/factory/references/hansei.md`, `baseline.md`, `a3.md`: sections 1 and 4, the close order, readers of the stage log (AC-22 to 26). `references/decision-card.md` only where it cites a file path for a card.
- `plugins/factory/agents/*.md` (seven): where the brief or result is read or written, and the new path-list step (AC-9, 14, 16, 17, 27, 32).
- `plugins/factory/skills/setup-factory-skill/SKILL.md`, `assets/factory.md` (the template with `factory-state: 2` and `parallel-limit`), `references/issue-tracker-github.factory.md` (the operations list): the board setup, the migration, the views (AC-1, 2, 6, 20, 21, 34 to 43).
- `plugins/factory/scripts/` : scripts the architect adds (for example a migration helper, a result-split helper), `check-bump.sh` if it cannot take a major bump, `cut-offs.sh` and `token-spend.sh` only if their input changes with the stage log (AC-22, 25).
- `plugins/factory/.claude-plugin/plugin.json`: version (AC-44).
- `plugins/wayfinding/skills/` (the `beachhead` and resurvey text that the factory calls): the parallel rule and the pause (AC-31, 33). Whether the wayfinding plugin is bumped is an open question.

**Architect (`contracts/`, `docs/adr/`, `CONTEXT.md`)**: contracts for each part with `Paths:` blocks; ADR status lines when the run closes; glossary terms (Role task, Kind, Needs you, Path list, Parallel limit, History view); any new ADR the two-way decisions below do not cover.

**QA (`tests/`, `reviews/qa-*`)**: fixtures (fake `gh`, Board-v1, Board-v2, Board-mid, Big result, Home-path result, W12 / C49 / L57 as role tasks), scripts and text checks for AC-1 to AC-46, the verdict.

**Docs-writer (`docs/` rest, `README.md`, `CHANGELOG.md`)**: the 2.0.0 entry (AC-46), `docs/factory/reference.md`, `docs/factory/release-runbook.md` (new section *Release 2.0.0*, including the scratch-Project try by the lead and the tag by hand), `docs/agents/factory.md`'s non-lead parts only if the architect names them (this repo's own file migrates through the step, after the run closes), `docs/agents/issue-tracker.md` as the setup step's patch note describes.

**Not changed by the build**: the live Project, the live `docs/agents/factory.md` option ids of this repo, and the files of items #41, #42, #43 and #59.

## Out of scope

From the frame's **Deliberately faked** and the map:
- Everything that needs the live Project: running the migration on it (the person does it after the run closes), the real views, real field creation (**Unverified**).
- Shared resources (ports, test environments) across parallel slices (Deferred; trigger: two slices in flight at once).
- Raising the limit above 2 (Deferred; trigger: two parallel slices run without a pause or conflict).
- Where an andon shows on the board; notifications for `Waiting on you`; whether the History view becomes #34's hoshin view; the exact way tokens and minutes are measured per role task (Deferred in the map; the roles decide the last as a two-way decision and AC-22 asks only that a value or an honest `not captured` be there).
- Roles messaging each other directly (agent teams); removing `work/` entirely; a dashboard outside GitHub Projects.
- #41, #42, #43, #59 (overlaps are noted on those issues).
- A project-specific `Stage` field (ADR 0015's rejected B2) and nine statuses (B3).
- File-level locks (ADR 0016's C2).
- Changing the fence (protocol *Never overridable locally*) or any fenced item: merge and production approvals, the decision-card route, QA and security as merge gates, the andon, memory, shell scope, the honesty rule for measures. The slice moves where they are recorded, not what they say.
- An acceptance demo, and a baseline for 2.0.0 (the 2.0.0 series starts with the next run).
- Rewriting history of earlier items' `work/` files in main; they stay as they are.

## Decisions

Two-way doors decided here (chosen / rejected / cost to undo). No one-way door was found; the three one-way doors of this map are decided (ADR 0014, 0015, 0016).

1. **`Role` is set only on role-task cards.** Rejected: also on slices (the owner role of the current step; it would duplicate the Running role task, which ADR 0015 rejected as B2). Undo: one rule.
2. **A `Waiting on you` card always gets a comment that says what to do (AC-5).** Rejected: the status alone (it fails the Under test line about reading only the board). Undo: one rule.
3. **A second slice may be required and designed before its list exists, but no build role starts until the list was compared (AC-30).** Rejected: no stage at all before the comparison (it would waste the time the person gains from parallel running, since the list comes only after the architect stage); building first and checking at QA (it would defeat the list). Undo: one rule. The architect may move the point of the check inside the item.
4. **"In flight" for the limit means a slice with an item branch that is `Running`, `Waiting on you` or `Blocked`.** Rejected: only `Running` (a slice waiting on the person still holds its paths and its worktree). Undo: one rule.
5. **The marker `<!-- factory:task <role> <n> -->` on a role task's first line, to find it again after a resume.** Rejected: finding by title (editable, ambiguous across rework). Undo: one rule.
6. **A tracker limit error gets one retry after the stated wait, then a stop and a `Waiting on you` card (AC-19).** Rejected: unbounded retry; pre-counting requests (the limit is per minute and per account, not seen from the run). Undo: one rule.
7. **The migration keeps the first snapshot and writes later ones under a new name.** Rejected: one snapshot overwritten on re-run (a mid-state snapshot would hide the old distinction). Undo: one rule.
8. **`Findings`, `Abnormalities` and `Label` stay in the lead state**, since the brief names only three sections to leave. Rejected: moving them too. Undo: one rule; the architect may show a reason to move them.
9. **Major version for the bump (2.0.0)**, as the person settled. No alternative was open.
10. **Every criterion that needs a live Project is marked Human-only or Unverified and has an offline twin on the fake `gh`.** Rejected: criteria checked against the real Project (the person settled that the build never touches it).

## Open questions

- **Architect: the stage log's readers (AC-25, AC-26).** The stage log is not only a record: the slow-stage andon (kind 4), the cut-off scan, the gemba sample rule (requirement 60, which picks a row of the log), the `Held item` and wait arithmetic, and four of the seven hansei measures read it. Moving the sections out of the lead state in the same change means each reader needs a new source (role-task sub-issue times, fields, comments). The architect decides each source; if one cannot be replaced without losing a measure, the lead must hear it before the build (a question, not a silent drop).
- **Architect: the field type for a number that may be `not captured` (AC-22).** A Number field cannot hold `not captured (<reason>)`, and the honesty rule (fenced F7) forbids a blank. Options are a text field, a paired text field for the reason, or a convention in the History view; the choice is the architect's. If no option meets F7, this is a question to the lead.
- **Architect: where "person touches" and waits are recorded now (AC-22).** The slice field `Person touches` and the waits that kind 4 subtracts have no home once their sections leave. Candidates: a counter in the lead's state, comments on the slice, the timeline of the card.
- **Architect: the `Paths:` block's place in the contract and the check point of AC-30**; the setting's exact name and line format in `docs/agents/factory.md` (`parallel-limit: N`), and whether the start rule is text only or a helper script (ADR 0016: no new tooling).
- **Architect: whether `wayfinding` is bumped.** The beachhead and resurvey text lives in `plugins/wayfinding/`, which has no entry in `CHANGELOG.md` yet (ADR 0012 versions only the factory). The factory requires its text; confirm whether a change there needs its own note.
- **Architect: how `check-bump.sh` classifies a major bump (AC-44)**, and whether the script changes.
- **Architect and QA: the list of tracker operations the fake `gh` must answer** (AC-3, AC-9 to AC-12, AC-35 to AC-41); QA writes the fixtures from the architect's contracts.
- **Docs-writer: the README and the runbook text** (AC-46), including the sentence on what the person does after the run closes: run the migration on the live Project, then confirm the two views.
- **Lead: the scratch Project try** after the build: who creates the scratch Project, and what is recorded if it fails (an andon, per the person's decision on #50). Not a build task.
