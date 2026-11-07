## Decision: Three linked choices for the 2.0.0 release: where a role's task is recorded (A), how the board shows status (B), and whether two slices may run at once (C)

**Why now:** All three are built together as one slice and released as 2.0.0. Until you answer, the architect cannot write the contracts (the written agreements that say what each part must do), so nothing in map #50 can start. The answers also depend on each other, so please answer in the order A, B, C.

**Already settled by you on 2026-11-07, not offered again:** the whole map is one slice released as 2.0.0; the running factory keeps the old state mechanism until this run closes; migration of existing projects is a step in `setup-factory-skill`, with Designed becoming Ready, In progress and In review becoming Running, and Ready to deploy becoming Waiting on you; no acceptance demo.

**What an undo costs once 2.0.0 is out:** undoing A or B changes where briefs, results and status live, so reversing either is itself a 3.0.0 release (a new major version that breaks projects again). Undoing C is only a minor release. All day figures below are the architect's estimates for one developer plus review, not measurements.

**How the three depend on each other:**
- B1 depends on A1. B1 shows the stage of a slice as "which role task is Running", which only exists if each role task is its own card (A1). If A is overturned, B takes its alternative B2.
- C depends on B. C pauses a questioned slice as Waiting on you and holds a path conflict as Blocked; both values come from B. If B is overturned to B3, C still works (B3 also has both values). If B were reduced to the old seven values, C would lose its pause signal and the person could no longer see it.
- A and C are independent. Overturning C changes nothing in A or B. Overturning A forces B2 and takes the role-task fields (tokens, minutes) and the progress bar off the board. Overturning B after release is the most expensive: every migrated project needs a reverse migration.

---

## Decision A (#53): Where does a role's brief and result live?

Today the brief (what a role is told) and the result (what it answers) are files in a `work/` folder, committed on the item's branch and kept in main's history (ADR 0001, ADR 0013).

### Option A1: One sub-issue per role task
- **For users:** From the board you open any role task and read what it was told and what it answered, without a clone of the repo. Rework shows up as its own card. Role-task numbers (tokens, minutes) get a card to sit on.
- **Cost and time:** The record moves from git to the tracker. Briefs are no longer in main's history. Issue text can be edited or deleted by its owner, where commits cannot, and each role task is public the moment it is created, so the no-secrets and no-home-path rules now cover issue text too. Build time is not estimated by the architect; undo cost below is the nearest measure.
- **Undoing it later:** Back to files (A3): 4 to 5 days (about one week) plus a 3.0.0 release. To A2: about 3 days. The sub-issues already created stay as closed history.
- *Technical:* The lead creates the sub-issue (`gh issue create --body-file`) and links it with GraphQL `addSubIssue`; the role reads its brief with `gh issue view <n>`. A role still writes its result as a committed draft in `work/<id>/`, and the lead posts it as the closing comment (Status and Summary on top, the rest in `<details>`) under a marker line `<!-- factory:result v1 -->`, so a resumed lead never posts twice. Questions and the lead's memory stay in `work/`. Rework is a new sub-issue. In frontier rounds, role tasks hang under the frontier ticket, not the map. Limits (#51): 100 sub-issues per parent, 8 levels, 80 writes per minute, 65,536 characters per comment; a slice with 4 to 8 role tasks stays far inside. This partly replaces ADR 0001 and keeps its reasons for questions, drafts and the lead's memory.

### Option A2: Marker comments on the slice ticket, no sub-issues
- **For users:** One card per slice, far fewer issues and notifications. But the board cannot show which role is running, and a ticket with 20 marker comments is hard to read.
- **Cost and time:** Simpler to build than A1. The role-task fields and the progress bar from the Destination lose their place. "Rework rounds" must be counted from comments.
- **Undoing it later:** To A1 about 3 days; to A3 about 3 days. Either needs a 3.0.0 release.
- *Technical:* Brief and result are comments starting `<!-- factory:brief role=developer -->` and so on. The 65,536-character cap applies per comment, as in A1.

### Option A3: Keep files, the lead only mirrors a summary
- **For users:** Nothing changes. A person still cannot read a role task without opening a branch.
- **Cost and time:** Nothing to build or migrate. Fails the Destination's bullet on role tasks; role-task numbers have no card.
- **Undoing it later:** To A1 about 4 to 5 days (about one week), the same work as the reverse of A1.
- *Technical:* ADR 0001 stays; the lead keeps the stage summary comment it already posts.

**Recommendation:** A1, because it is the only option that lets you open a role task from the board and see exactly what it was told and what it answered, which is what you asked for. The architect leans the same way. The editable-record risk is answered by keeping committed drafts in `work/`, so the unalterable git copy still exists next to the tracker copy.
**If we're wrong:** We go back to files or comments: about 3 to 5 days of work plus a 3.0.0 release, and projects have to be moved again. The role tasks already created stay readable as closed history.

Decision A: ______ (A1 / A2 / A3)

---

## Decision B (#54): How does the board show status?

Today status has seven values (Backlog, Ready, Designed, In progress, In review, Ready to deploy, Done), and the stage and waits live in a lead-only state file (ADR 0002).

### Option B1: Six values plus two extra fields, Kind and Role (depends on A1)
- **For users:** One question answers "what do I do now": the "Needs you" view lists everything that is Waiting on you. A slice waiting on a decision still shows where it stands, because its running role task is a card.
- **Cost and time:** The stage can only be read through A1's role-task cards. Migration is many-to-one: In progress and In review both become Running, so the old distinction on a card in flight is lost (you accepted this). Every project's `docs/agents/factory.md` table of option ids changes.
- **Undoing it later:** Back to seven values: 2 to 3 days of plugin work plus a reverse migration of about half a day, and a 3.0.0 release. The lost In progress / In review distinction can be restored only from the snapshot taken at migration.
- *Technical:* `Factory status` becomes Backlog / Ready / Running / Waiting on you / Blocked / Done; `Kind` (map, slice, role task, frontier ticket) and `Role` are single-select fields. Migration runs in three phases and never relies on the undocumented effect of dropping an in-use option (#52): (1) snapshot items to a scratch file outside the repo, then `updateProjectV2Field` adds the three new options while sending every old option with its id; (2) `gh project item-edit` re-sets each affected item per your table; (3) only when no item holds an old option, drop the four old ones. The step prints the table and item count and changes nothing until you confirm. A first line `factory-state: 2` in `docs/agents/factory.md` makes `/factory:run` stop with "run setup-factory-skill" on an unmigrated project. The "Needs you" view is made with `createProjectV2View`, untested, so the person checks it once by hand.

### Option B2: The same six values plus a Stage field (the fallback if A is overturned)
- **For users:** A slice card shows both "Running" and its stage (Design, Build, Review, Deploy) without opening anything. Works with or without A1; migration keeps the old In progress / In review distinction in Stage.
- **Cost and time:** Two fields to keep in step; the lead writes both at every stage change. Two places that can disagree, and under A1 the stage duplicates what the running sub-issue already says.
- **Undoing it later:** To B1 about 1 day (drop the field and the writes); to B3 about 2 days. Either needs a 3.0.0 release once shipped.
- *Technical:* One extra write per stage change, well inside the 80-per-minute cap.

### Option B3: Keep the seven values and add Blocked and Waiting on you (nine in all)
- **For users:** No migration, nothing breaks for projects on 1.3.x. But a card waiting on you loses its stage: a slice cannot be In review and Waiting on you at once, and that is exactly the signal you read. It does not match the six-value status table you approved.
- **Cost and time:** Cheapest now; no mapping step.
- **Undoing it later:** To B1 about 3 days, including the migration this option avoids now, and a 3.0.0 release.
- *Technical:* No `updateProjectV2Field` migration beyond adding two options.

**Recommendation:** B1 if you chose A1, because it is the six-value board you already approved and it keeps the "Needs you" view as the single place to look. If you chose A2 or A3 in Decision A, choose B2, because without role-task cards the stage would otherwise disappear. This matches the architect's leaning.
**If we're wrong:** Going back is 1 to 3 days of plugin work, a reverse migration, and a 3.0.0 release. This is the most expensive of the three to undo once projects have migrated, because every migrated project has to be moved again.

Decision B: ______ (B1 / B2 / B3)

---

## Decision C (#55): May two slices run at the same time?

Today ADR 0007 says parallel slices are "rejected for now": a slice cut before the previous resurvey (the check after each merge of what we learned) is cut on stale knowledge.

**Why this is still a card although it is cheap to undo:** setting the limit to 1 in `docs/agents/factory.md` restores one-at-a-time at once, with no code change. But you asked for parallelism, ADR 0007 says the opposite, and the wayfinding plugin's text changes. Removing the feature altogether (the `Paths:` field, resurvey text and setting) is about 2 days and a minor release. This run cannot exercise parallel running, so it ships unverified (settled).

### Option C1: Parallel when the slices' path lists do not overlap (depends on B)
- **For users:** Less waiting for you when two independent slices exist. If a merge teaches something that questions a running slice, its card moves to Waiting on you and its roles finish their current step and start no more.
- **Cost and time:** One path list per slice and one comparison. Three honest limits: (1) the list exists only after the architect stage, so a slice is cut before the lead knows whether it may run alongside; if it overlaps it waits as Ready. This is ADR 0007's objection, answered by the resurvey check above; (2) some paths every slice touches (plugin version, `CHANGELOG.md`, `CONTEXT.md`, the next ADR number) are treated as always overlapping, so the lead assigns the ADR number at slice start and applies the version bump and changelog line at merge; (3) a wrong list is caught late, at QA, and costs a merge conflict for the later slice, not lost data.
- **Undoing it later:** Minutes (limit 1); fully removing it about 2 days and a minor release. Old path lists are harmless.
- *Technical:* `contracts/<slice>-paths.md` or a `## Paths` section: one path per line, directory prefixes end in `/`, plus a `shared:` line. Overlap: equal path or directory prefix, or both name a shared path. Limit: `parallel-limit: 2` in `docs/agents/factory.md`. QA and security check `git diff --name-only main...item/<id>` against the list. Resurvey: after the merge each running slice is compared with the finding.

### Option C2: File-level locks enforced while the work runs
- **For users:** An off-list write is stopped the moment it happens, not found at QA.
- **Cost and time:** 5 to 8 days to build (a registry both worktrees can see, a plugin hook, a wait-or-fail rule); locks held by an interrupted role are released by hand. ADR 0010 gives roles a full shell, so a hook is a guard, not a boundary.
- **Undoing it later:** About 2 days to remove, and a minor release.
- *Technical:* Registry in the tracker or a shared scratch folder, outside git.

### Option C3: No parallelism, keep ADR 0007 as written
- **For users:** Every resurvey still shapes the next cut. A second ready slice waits, though, because every merge needs your approval.
- **Cost and time:** Nothing to build; removes the Destination's last bullet and the limit setting.
- **Undoing it later:** To C1 about 3 days (amendment, `Paths:` field, resurvey step, setting) and a minor release.
- *Technical:* Board, sub-issues and migration are unaffected.

**Recommendation:** C1, with the limit set to 1 when 2.0.0 ships and raised to 2 by you once you have a second independent slice. The architect leans C1 with a default of 2; I differ only on the default, because this run cannot test parallel running, so it should not switch on before it has been seen to work. This setting is a two-way door and you can overrule it.
**If we're wrong:** Set the limit to 1 and it is one-at-a-time again within minutes. Removing the feature entirely is about 2 days.

Decision C: ______ (C1 / C2 / C3)

---

**Want to dig deeper?** Reply with a number, and say which decision (A, B or C):
1. **Ask me** — I explain with an example or comparison until it is clear.
2. **Look it up** — `/research` writes a sourced report on the options.
3. **Show me** — `/prototype` builds a throwaway version you can look at or click through.
4. **Question me** — `/grilling` asks you questions until your own answer is clear.
