# Options: architect — frontier-53 (#53, #54, #55 for map #50)

Settled by the person on 2026-11-07 and not offered again: one slice, released as 2.0.0; the run keeps the old state mechanism until it closes; migration is a `setup-factory-skill` step with Designed→Ready, In progress and In review→Running, Ready to deploy→Waiting on you; no acceptance demo.

Everything below that is marked "estimate" is my reckoning in working days for one developer plus review, not a measurement. After 2.0.0 ships, undoing A or B changes where briefs, results and status live, so the undo is itself a 3.0.0 release; undoing C is not (see C).

## Door A (#53): where a role task's brief and result live

Today (ADR 0001): brief, result, feedback and question are files in `work/<id>/`, committed on the item branch, and they stay in main's history (ADR 0013). The lead reads only Status and Summary.

### A1. Sub-issue per role task (the map's leaning)
The brief is the sub-issue body. The result is the closing comment (Status and Summary on top, the rest in `<details>`). Rework is a new sub-issue. Only the lead writes to the tracker. A role still writes its result as a draft file in `work/`, and the lead posts it, so a role cut off mid-way keeps its `Progress` where a resumed agent finds it. Questions to the lead and the lead's memory stay in `work/`.

- Gain: the person can open any role task from the board and read what it was told and what it answered, without a clone. Role-task numbers (tokens, minutes) get a card to sit on. Rework is visible as cards, not as a feedback file number.
- Cost: the record moves from git to the tracker. Briefs stop being in main's history; QA cannot re-read a brief from a commit. Comments and bodies can be edited or deleted by the owner, where commits cannot. The hansei cross-check (ADR 0013) reads role commit times; it keeps working on the drafts' commits, and sub-issue created and closed times become a second source. Each role task is a public issue the moment it is created, so the home-path and secret rules of ADR 0013 now also apply to issue text, and an edited comment keeps its edit history.
- Limits (#51): 100 sub-issues per parent, 8 levels, 80 content writes per minute. A slice has 4 to 8 role tasks plus rework, which is far inside all three. The one real cap is 65,536 characters per comment, not on a docs page: the lead keeps Status and Summary on top, links logs and diffs instead of pasting them, and splits an oversize result into a second comment.
- Undo cost, estimate: back to files (A3) is 4 to 5 days (protocol message templates, run skill steps for briefing and reading results, hansei record sources, the QA and security briefs, tests) plus a 3.0.0 release. The sub-issues already created stay as history and are closed, not deleted. To A2 it is about 3 days.

### A2. Comments on the slice ticket, no sub-issues
Brief and result are marker comments on the slice ticket (`<!-- factory:brief role=developer -->`). One card per slice on the board.

- Gain: far fewer issues (a slice's 8 role tasks do not become 8 issues or 8 notification streams), no 100-per-parent question, simpler to build.
- Cost: no card per role task, so the board cannot show which role is running, and the Destination's role-task fields (tokens, minutes) and the progress bar lose their place. Rework is a comment, so "rework rounds" must be counted from comments. A slice ticket with 20 marker comments is hard for a person to read. The 65,536 cap is per comment, so it is the same.
- Undo cost, estimate: to A1 about 3 days (the posting moves from comments to issues); to A3 about 3 days.

### A3. Keep files (ADR 0001 stays), the lead only mirrors a summary
No change to roles. The lead keeps the stage summary comment it already posts.

- Gain: nothing to build or migrate; the git record stays whole.
- Cost: fails the Destination's bullet on role tasks; the person cannot read a role task without opening a branch. Role-task hansei fields have no card.
- Undo cost, estimate: to A1 about 4 to 5 days, the same work as the reverse of A1.

### Leaning: A1
It is the only option that gives the board a card per role task, which B and the hansei fields want. Its main cost, a mutable record, I would answer by keeping the drafts committed in `work/` (so the git evidence of ADR 0013 stays) and by stating in the ADR that the tracker comment is the record the person reads and the commit is the record that cannot be edited. This partly replaces ADR 0001 (briefs and results) and keeps its reasons (no direct messaging, files survive interruptions) for questions, drafts and the lead's memory.

### Mechanism for A1 (technical)
- Lead creates the sub-issue: `gh issue create --title "<role>: <task>" --body-file <brief>`, then links it with GraphQL `addSubIssue(issueId, subIssueId)` (`gh api graphql`); it passes the sub-issue number to the role in the spawn prompt. Parent is the slice ticket for items.
- Frontier rounds: role tasks hang under the frontier ticket (for example #53), not under the map. Depth is map > ticket > role task = 3, and the map's 100-child watch-item from #51 never fills.
- Role reads its brief with `gh issue view <n> --json body --jq .body` (architect and product-owner may read the tracker, protocol *Shell*). It writes `work/<id>/NN-result-<role>.md` as today and commits it.
- Lead posts the result: `gh issue comment <n> --body-file <result>` using the same `mktemp` pattern as *Post hansei* in `issue-tracker.md`, then closes the sub-issue. One marker first line, `<!-- factory:result v1 -->`, lets the lead find it again on a resume (as *Find hansei* does), so a resumed lead never posts a second one.
- Rework: a new sub-issue titled `rework <n>: ...` with the finding as body, added to the board as `Blocked` until its dependency is met, then `Ready`.
- Protocol changes: *Messages* keeps Result, Question; Brief and Feedback become "the sub-issue body". Paths rule unchanged and extended to issue text.

## Door B (#54): the board as the only status a person reads

Today (ADR 0002): status lives in the tracker, seven values (Backlog, Ready, Designed, In progress, In review, Ready to deploy, Done) on `Factory status`; the stage and waits live in `00-lead-state.md`.

### B1. One list of six, plus Kind and Role (the map's leaning)
`Factory status`: Backlog / Ready / Running / Waiting on you / Blocked / Done. `Kind` (map, slice, role task, frontier ticket) and `Role` as extra single-select fields. The stage is "which role sub-issue is Running", not a status. The lead state keeps only the lead's memory.

- Gain: one question answers "what do I do now": the "Needs you" view is `status:"Waiting on you"`. A slice that waits on a decision keeps showing its place because the running role task is still a card.
- Cost: the stage is only readable through A1's sub-issues. Migration is many-to-one (In progress and In review both become Running), so the old distinction on a card in flight is lost; Done and Backlog items are untouched. Every project's `docs/agents/factory.md` table of option ids changes.
- Undo cost, estimate: back to seven values is 2 to 3 days of plugin work plus a re-run of a migration in reverse (about half a day), and the many-to-one loss can be restored only from the snapshot taken at migration. Needs a 3.0.0 release.

### B2. The same six plus a `Stage` field
`Factory status` as in B1 (six values) and a second single-select `Stage` with the old stages (Design, Build, Review, Deploy, ...) set by the lead on slice cards.

- Gain: the person sees "Running / In review" on a slice card without opening sub-issues. Works whether or not A1 is chosen. Migration keeps the old distinction: In progress and In review go into `Stage`.
- Cost: two fields to keep in step, and the lead writes both at every stage change (one more write per stage; well inside the 80-per-minute cap). Two places that can disagree; the stage duplicates what the running sub-issue already says under A1.
- Undo cost, estimate: to B1 about 1 day (drop the field, drop the writes). To B3 about 2 days.

### B3. Keep the seven values, add Blocked and Waiting on you (nine in all)
No mapping, no migration step.

- Gain: no migration, no breaking change for projects already on 1.3.x.
- Cost: a card waiting on the person loses its stage (a slice cannot be "In review" and "Waiting on you" at once), which is the exact signal the person reads. Fails the Destination's six values and the status table the person already approved.
- Undo cost, estimate: to B1 about 3 days, including the migration this option avoids now.

### Leaning: B1 if A1 is chosen, B2 if A is overturned
B1 relies on A1 for the stage; B2 does not. Counting the settled mapping (the person has already accepted the many-to-one loss), B1 matches what they approved.

### Mechanism for B1 (technical) and the 2.0.0 migration
- The map and all children go on the board with `gh project item-add`; `Kind` and `Role` are made with `gh project field-create ... --data-type SINGLE_SELECT`; colours need GraphQL `createProjectV2Field` (#52). The "Needs you" view is `createProjectV2View` with filter `status:"Waiting on you"`; untested, so the migration step creates it and the person checks it once by hand. The Insights chart and the progress bar are by hand (#52).
- Migration in three phases that never rely on the undocumented effect of dropping an in-use option (#52 flags it): (1) snapshot `gh project item-list <n> --owner <o> --format json` to a scratch file outside the repo, never committed; then `updateProjectV2Field` adds Running, Waiting on you and Blocked while sending every old option with its existing id, so no value clears. (2) `gh project item-edit` re-sets each affected item per the settled table (Designed→Ready, In progress and In review→Running, Ready to deploy→Waiting on you). (3) Only when no item holds Designed, In progress, In review or Ready to deploy, drop those four options, which now clear nothing. The step prints the table and the item count and applies nothing until the person confirms; run first on a scratch Project, where a failure is an andon (settled).
- The step then rewrites the id table in `docs/agents/factory.md` from `field-list`. A new first line `factory-state: 2` in that file lets `/factory:run` in 2.0.0 stop with "run setup-factory-skill" on an unmigrated project instead of writing a status that does not exist.
- The lead state loses status, Stage log, Waits and Person's touches (settled with the hansei fields); it keeps Running agents, Shared resources and the interrupted role's `Progress` pointer. The "Factory run" section of the map body stays as the run's resume pointer and shrinks to step, branch and FREEZE line (a two-way choice I made; see result).

## Door C (#55): parallel slices

Today (ADR 0007): "Parallel slices. Rejected for now. A slice cut before the previous resurvey is cut on stale knowledge." ADR 0006 is already superseded by 0007, so the amendment targets 0007 and the wayfinding text (beachhead, resurvey).

### C1. Slices run in parallel when their contracts' path lists do not overlap (the map's leaning)
The architect's contracts carry a `Paths:` list (files or directory prefixes the slice may touch, every role's paths included). Two slices overlap when one path is equal to, or a prefix of, a path in the other. The lead starts a second slice only if its list does not overlap a running slice's, up to the limit in `docs/agents/factory.md` (default 2). A path outside the list is a QA or security finding. After each merge the resurvey checks the running slices against what the merge taught and marks questioned ones Waiting on you.

- Gain: the person's waiting time falls when two independent slices exist. Cheap to run: one list per slice, one comparison.
- Cost, and what the map's text does not yet say:
  1. The list exists only after the architect stage, so the overlap check cannot happen at the cut. A slice is cut, its architect runs, and only then does the lead know whether it may run alongside. If it overlaps it waits (Ready). That architect work is not lost, but the slice was cut on the knowledge of its moment, which is the objection in ADR 0007. The amendment answers it with the resurvey check above, and says so.
  2. Some paths are touched by every slice: the plugin's `version` and `CHANGELOG.md`, `CONTEXT.md`, and the next free ADR number in `docs/adr/` (two architects both pick 0014). They are declared "shared paths" in the contract format and always count as overlapping for edits; the lead assigns the ADR number when it starts the slice, and applies the version bump and changelog line at merge, after rebasing.
  3. Ports and test environments are shared; settled as deferred until two slices run at once.
  4. A wrong list is caught late (at QA), by which time two branches may have diverged. The cost is a merge conflict resolved by the later slice, not data loss.
  5. This run cannot exercise any of it (settled): it ships unverified.
- Undo cost, estimate: setting the limit to 1 restores one-at-a-time behaviour at once, with no code change, so the operational undo is minutes. Removing the `Paths:` field from contracts, the resurvey text and the setting is about 2 days and a minor release. Path lists left in older contracts are harmless. This means C is closer to a two-way door than A or B; I would still put it on the card because the person asked for it, ADR 0007 states the opposite, and the wayfinding plugin's text changes.

### C2. File-level locks, enforced while the work runs
The lead records which paths each running role holds (in the lead's memory, or as a label on the sub-issue) and a hook refuses a write outside the role's own slice or onto a path another slice holds.

- Gain: catches an off-list write at the moment it happens, not at QA; no separate list to get wrong.
- Cost: a registry both worktrees can see (outside git, so in the tracker or a shared scratch folder), a hook in the plugin, and a way for a role to wait or fail on a lock. More mechanism than the problem has shown so far, and ADR 0010 gives roles a full shell, so a hook is a guard and not a boundary. Locks held by an interrupted role must be released by hand.
- Undo cost, estimate: 5 to 8 days to build; removing it again about 2 days.

### C3. No parallelism: keep ADR 0007 as written
Remove the Destination's last bullet and the limit setting. Board, sub-issues and migration are unaffected.

- Gain: no new risk; every resurvey still shapes the next cut.
- Cost: waiting time stays; with a human approval at every merge, a second ready slice idles.
- Undo cost, estimate: to C1 about 3 days (the amendment, the `Paths:` field, the resurvey step, the setting).

### Leaning: C1
It buys the most for the least mechanism and has the cheapest retreat (limit 1). I would make the shared-path rule and the late list (points 1 and 2) part of the ADR, because they are what a first parallel run will hit.

### Mechanism for C1 (technical)
- `contracts/<slice>-paths.md` (or a `## Paths` section in the slice's first contract): one path per line, directory prefixes end in `/`, plus a `shared:` line naming the always-overlapping paths.
- Overlap test: after normalising, two lists overlap when any path of one equals or is a directory prefix of a path of the other, or both name a `shared:` path. The lead runs it once per start, as shell on the two lists.
- Limit: a line `parallel-limit: 2` in `docs/agents/factory.md` (the lead reads it; roles do not).
- Resurvey (wayfinding `Resurvey`, step 2 and "what happens next"): after the merge, for each running slice, compare the finding with its assumptions; a questioned slice gets `Waiting on you` on its card and a note on the map, and its running role tasks finish their current step but start no more.
- Findings: QA and security checklists gain "changed files all inside the slice's `Paths:`", checked with `git diff --name-only main...item/<id>`.

## Dependencies between the doors

- A and C do not depend on each other. C needs no sub-issues; A needs no parallelism.
- B1 depends on A1: "the stage is the running role sub-issue" holds only if there are role sub-issues. If A is overturned to A2 or A3, B1 must become B2 (add a `Stage` field) or the person loses the stage. The role-task fields (tokens, minutes) and the progress bar also lose their card, so the Destination text changes.
- C depends on B for two of its values: the resurvey pause is `Waiting on you` and a path conflict holds a slice as `Blocked`. If B is overturned to B3 (seven values plus Blocked and Waiting on you) C still works. If B is overturned to keep only the old seven, C loses its pause signal and must record the pause in the lead's memory, which the person then cannot see.
- An overturn of C changes nothing in A or B; only the Destination's last bullet and the setting go.
- An overturn of B after release is the most expensive (every project migrated; a reverse migration). An overturn of A is next (briefs and results move back). C is cheapest (limit 1).
- Because the whole map is one slice, the three go out together as 2.0.0, and an overturn after it is a 3.0.0 for A or B and a minor for C.
- Order for the card: answer A first, then B (which reads A's answer), then C (which reads B's).
