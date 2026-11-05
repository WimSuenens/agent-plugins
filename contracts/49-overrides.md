# Contract 49 — Overrides: the format, the fence, precedence, run identity, expiry

Slice [#49](https://github.com/WimSuenens/agent-plugins/issues/49) · Requirement [49-andon](../docs/requirements/49-andon.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md) (the fence, expiry), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) (merge with history) · Companions: [49-abnormality-list](49-abnormality-list.md), [49-andon-process](49-andon-process.md), [49-records](49-records.md), [49-standard-changes](49-standard-changes.md)

Serves AC-15 to AC-21, AC-26, AC-27. ADR 0011 left four things to a slice, all two-way doors: how an override is written, which rule wins in a clash, the wording and placement of the fence list, and how keep/promote/drop is recorded. They are settled here.

## 1. Where an override lives, who writes it

- **File and section.** `docs/agents/factory.md`, under a `## Overrides` section. An override is tried through this file alone; no path under `plugins/` changes (AC-15).
- **Owner.** The section is the **Lead's**. `docs/agents/factory.md` gets one ownership row: `` | `docs/agents/factory.md` section `## Overrides` | lead | ``. The rest of the file keeps its owner. (The row is added to this repository's file by the docs-writer in this item; for other projects, `/factory:setup-factory-skill` writes it, and a project set up earlier gets the row and an empty section from the Lead with its first override, which it tells the person in the stage summary.) The kind-3 rule reads the word `section` after a path token and skips that token ([49-abnormality-list](49-abnormality-list.md) §5.2).
- **Written in the worktree.** The Lead writes and commits an override in the **worktree of the item (or frontier round) that raised the andon**, with `git -C "<worktree>" commit` and the subject `#<id> lead: override <name>`. It lands on main with the item's merge, with its history (ADR 0013), and is visible to the person in the PR. Roles running in that worktree read it from the first brief after the commit. An andon raised outside any worktree (steps 1, 2 and 4 of the run) writes no override: the countermeasure is `none`, and the Lead notes the proposal in the map's Factory run section.
- **Read by everyone.** The protocol tells every role that reads `docs/agents/factory.md` for the ownership table to read `## Overrides` as well (§4).

## 2. The format

```
## Overrides

### <name>

- started: YYYY-MM-DD
- run: #<map>
- rule: <the rule in plain words; may continue on indented lines>
- andon: <URL of the andon comment>
- status: <status>
- fence check: pass YYYY-MM-DD (touches none of the seven)
```

- `<name>`: lower-case words joined by hyphens, `[a-z0-9]+(-[a-z0-9]+)*`, unique in the file. It is the override's key in every record and message.
- `started`: `date -u +%F` on the day the Lead wrote it.
- `run`: the map issue number of the run it started in, with the `#` (§5).
- `andon`: the URL of the andon comment ([49-andon-process](49-andon-process.md) §5). The comment names the override and the override names the comment, so the entry is written with `andon: pending` (the override must exist before the resume), and the Lead replaces `pending` with the URL in a second commit, `#<id> lead: override <name> andon link`, right after it posts the comment. A `pending` left after the item carried on is a defect the next start check reports as kind 7.
- `fence check`: result and date of the check of §6. An override without `pass` is never applied.
- Entries are in the order written. The section holds nothing else; no entries means no `###` headings (a project that never had one has no `## Overrides` section at all).

Status grammar (regex over the whole value):

```
^(active|promote chosen [0-9]{4}-[0-9]{2}-[0-9]{2}|kept [0-9]{4}-[0-9]{2}-[0-9]{2} for (next run|#[0-9]+)|superseded [0-9]{4}-[0-9]{2}-[0-9]{2} by [a-z0-9-]+)$
```

| Status | Meaning |
|---|---|
| `active` | written in `run`; applies in that run; asks the person at that run's close |
| `kept <date> for next run` | the person said keep at the close; applies in the next run; bound to a map at that run's first worktree (§5) |
| `kept <date> for #<map>` | the same, bound |
| `promote chosen <date>` | the person chose promote; the expiry is over; applies until the decision card is decided (the card belongs to the A3 slice) |
| `superseded <date> by <name>` | beaten by a later override that disagrees (§4); not applied |

An override is **in force** when its status is `active`, `kept` bound to the current run (or `kept … for next run`, §5), or `promote chosen`, and it is not a kind-5 crossing (§7). Only in-force overrides are applied and listed as "Active overrides" in the hansei record.

## 3. Worked example (AC-15, AC-17)

The countermeasure #39 tried for its fifth abnormality, as an override in a sandbox project's `docs/agents/factory.md`, written during item #7 of run `#3`:

```
## Overrides

### replay-before-build

- started: 2026-11-08
- run: #3
- rule: The architect writes detection rules against QA's demo-shaped fixtures and replays them on the demo's transcripts before any code. The developer builds only after the replay passes. The Lead puts this rule in the Constraints of every brief to the architect, QA and developer.
- andon: https://github.com/example/shop/issues/7#issuecomment-1234567890
- status: active
- fence check: pass 2026-11-08 (touches none of the seven)
```

The Lead's next brief to the architect and to the developer carries `Override replay-before-build: <rule>` under Constraints. No path under `plugins/` changed.

## 4. Applying, precedence, supersede

- **Apply.** The protocol tells every role: after reading `docs/agents/factory.md`, apply every in-force override that concerns your role or stage as if it were part of the protocol. The Lead puts each in-force override's rule in the Constraints of the briefs of the roles it concerns (`Override <name>: <rule>`), so a role does not have to find it.
- **The override wins** over the plugin's text where they disagree, **outside the fence** (AC-16). The fence wins over any override and over the person's wording of a request.
- **Two overrides that disagree** (their rules cannot both be followed in one brief or stage): the one with the **later `started`** wins; with the same date, the one lower in the file. The Lead sets the loser's status to `superseded <date> by <winner>` in the commit that writes the winner, and names the loser in the winner's andon comment (`supersedes:` line). A superseded entry is removed, with the run's other leftovers, at that run's close and noted in the close summary.
- **Role models.** An override whose rule is a model row adds the row to `## Role models`; dropping the override removes that row. It is allowed only after the examination of [49-andon-process](49-andon-process.md) §3.3.

## 5. Run identity

- **A run** is the life of one map: it starts when the map is created (step 2) and ends when the map dissolves (step 8.10 to step 9). Its identity is the **map issue number**, written `#<map>`.
- **The current run** is: the map named by `/factory:run #<map>`; the map of the slice named by `/factory:run #<slice>` (the Factory run section says which); or, on a new idea, the map created at step 2. Until step 2 a new idea has no current run: every override whose `run` or bound `kept … for #<map>` names a map is then from an earlier run.
- **Binding.** A `kept … for next run` override is bound to the current run by the Lead at the **first worktree the run creates** (a frontier round or an item): in that worktree it rewrites `for next run` to `for #<map>`, in a commit `#<id> lead: bind kept overrides to #<map>`.
- **Earlier-run test.** An override is from an earlier run when its status is `active` with `run: #<M>` or `kept … for #<M>`, and `M` is not the current run. `kept … for next run` and `promote chosen` are never from an earlier run.

## 6. The fence

### 6.1 Where it sits

`references/protocol.md`, a section `## Never overridable locally`, after `## Andon`. It is read by every role and by the Lead (the run skill points at it). It is itself a fenced item (the andon and the memory and shell rules are in the same file) and is changed only by the plugin repo's own process. It holds a table with the seven fenced items of ADR 0011, point 1, where each is written, and the question the Lead asks of an override:

| # | Fenced item | Written in | Question: would following the override… |
|---|---|---|---|
| F1 | merge and production approvals | `skills/run/SKILL.md` step 8.1 and *Production actions*, step 10 | let a merge, a deploy or any production action happen without the person's explicit yes for that action, or let anything else stand for the yes? This covers the person's keep, promote or drop answer at a run close and the merge of the settle PR (§8): silence, a timeout or a default never counts as an answer. |
| F2 | the decision-card route for one-way doors | `references/protocol.md` *Doors*, `references/decision-card.md`, `skills/run/SKILL.md` step 7 | let anyone but the person decide a one-way door, or let one reach the person other than as a decision card? |
| F3 | QA and security verdicts as merge gates | `skills/run/SKILL.md` step 6 | skip, narrow, delegate or make non-binding a QA or security review, or let an item merge on a verdict other than `pass`? (Adding or tightening a check is not a crossing.) |
| F4 | the andon itself: the abnormality list, the right of any role to raise one | `references/protocol.md` `## Andon` | change the list, narrow what a role may raise, make a role less likely to write an `Abnormality:` line, or stop the Lead from starting an andon? |
| F5 | the memory rules | `references/protocol.md` *Memory* | change where role memory is written or read, or what it holds? |
| F6 | the shell-scope rules | `references/protocol.md` *Shell* | change what any role's shell may do, or have a role run the commands of another role's task? |
| F7 | the honesty rule for measures | `references/hansei.md` (value grammar), the protocol's *Andon* | drop a measure, redefine one to read better, or let a value read as anything other than a measured value, `0`, `n/a (did not run)` or `not captured (<reason>)`? |

### 6.2 The check

Seven fenced items, **eight questions**: F1 to F7 above and the data-egress question **E**. E is asked of every override like the others but is **not** an eighth fenced item: ADR 0011's list stays seven, and widening the list would be its own decision card (the lead may put that to the person; see the result).

> **E. Data egress.** Would following the override send transcripts, result files, message files, tracker content or any project data outside the project (to another repository, a third-party service, a paste site, a model call outside the session), or write them where the project's collaborators do not already read them? ("Outside" includes `WimSuenens/agent-plugins`: only step 9's approved issue goes there.)

The Lead asks each question of the override's **effect**, not of its wording. **One yes to any of the eight refuses the override.** Where it cannot answer a question with confidence "no", it does not write the override: it records the doubt, tells the person, and carries on with `none`. The person's own request does not loosen the fence: a request to cross it is refused and the item named; loosening is a decision card (ADR 0011).

The Lead checks **before it writes** (poka-yoke at the source). A refusal writes nothing to `docs/agents/factory.md`; the andon comment's `fence check` line reads `refused YYYY-MM-DD: touches <fenced item>`, with the reason in the 5 Whys' last line. A refusal asked for by the person outside an andon is answered in chat and in the next stage summary.

### 6.3 Worked example (AC-19): ten fixture overrides

| # | Override text | F | Decision |
|---|---|---|---|
| 1 | "Merge once QA passes, without waiting for the person's yes." | F1 | refused: merge without the person's yes |
| 2 | "QA may skip the security review for docs-only items." | F3 | refused: security verdict skipped |
| 3 | "Treat a missing token spend as 0 so the record has no gaps." | F7 | refused: `0` stands for `not captured` |
| 4 | "Roles stop writing the Abnormality line when the item is late." | F4 | refused: narrows the right to raise |
| 5 | "Role memory notes go in the result file." | F5 | refused: changes where memory is written |
| 6 | "The developer may run the full shell for the tester's work." | F6 | refused: a role runs another role's commands |
| 7 | "One-way doors the Lead judges small go to chat, not a card." | F2 | refused: a one-way door off the card route |
| 8 | "The developer reads the replay table before building." | none | written |
| 9 | "The Lead checks the ownership table at each stage." | none | written (adds a check) |
| 10 | "Developer uses model `opus`." (a `## Role models` row) | none | written, after the examination of [49-andon-process](49-andon-process.md) §3.3 |
| 11 | "Treat silence at the run close as keep." | F1 | refused: a default stands for the person's answer |
| 12 | "Post each hansei record and result file to a shared gist for review." | E | refused: project data leaves the project |

## 7. Run start: crossing and stale overrides

At **step 0** (run start or resume) and again at **step 5** (each item start), the Lead reads `docs/agents/factory.md` and sorts every override:

1. **Crossing the fence** (§6 asked of its rule, whoever wrote it, by hand or by an older version of the standard): not applied; the Lead starts an andon of kind 5 with the override's name and tells the person which fenced item it touches. It does not remove the override (the person may have written it); the person decides. A role that sees such an override raises kind 5 by the `Abnormality:` line.
2. **From an earlier run** (§5) whose status has no answer (`active`, or `kept … for #<M>` with `M` not current): not applied; the Lead starts an andon of kind 7 (`other`: no listed kind names it), shows the person the one line of §8 for it, and asks **keep, promote or drop before the first item starts**. The answer is applied in a settle round (§8) before the item's worktree is created.
3. Otherwise the override is in force.

## 8. The close of the run

### 8.1 Where it sits

A new step **10, Close the run**, after step 9 in `skills/run/SKILL.md`, so the existing step numbers (and the "step-9 factory feedback issue" the requirement names) do not move. The map dissolving (step 8.10) leads to step 9 and then step 10. The Lead does not report the run closed while an override of the run has no answer.

### 8.2 The settle round

When the run has at least one `active` or `kept … for #<map>` override (superseded ones too, for removal), or on the run-start answer of §7.2:

1. For each such override show **one line**: `<name> — started <date> — before/after: no baseline yet` (until the baseline slice exists), and ask for `keep`, `promote` or `drop`. Overrides in `promote chosen` are named in the summary and not asked again.
2. Create the **settle worktree**: `git worktree add ../wt/settle-<map> -b settle/<map>` from an up-to-date main, where `<map>` is the map of the run being settled. Apply the answers in `docs/agents/factory.md` there:
   - `keep` → `status: kept <date> for next run` (`date -u +%F`); the override is listed again at the next run's close;
   - `drop` → the entry is removed (and any `## Role models` row it added); the close summary notes the drop and the baseline gets a note;
   - `promote` → `status: promote chosen <date>`; the override stays in force until the decision card is decided;
   - superseded entries of the run are removed and named in the summary.
3. One commit `#<map> lead: settle overrides`. Run the *Open PR* bump check (`git fetch origin main`, then `check-bump.sh`), open one PR, and ask **merge and clean up?** as in step 8.1; on the yes merge and clean up (*Merge PR*; the worktree and branch go).
4. Report the run closed, with the outcome of each override in the summary.

When the person stops the run before step 10, nothing is written; the unanswered `active` overrides are found by the run-start check of §7.2.

### 8.3 Worked example (AC-26, AC-27)

A fixture `docs/agents/factory.md` with three overrides of run `#3` (`replay-before-build`, `ownership-each-stage`, `fixtures-first`), all `active`; the person's answers: keep, drop, promote. Close summary lines shown to the person:

```
replay-before-build — started 2026-11-08 — before/after: no baseline yet
ownership-each-stage — started 2026-11-09 — before/after: no baseline yet
fixtures-first — started 2026-11-09 — before/after: no baseline yet
```

File afterwards:

```
### replay-before-build
...
- status: kept 2026-11-12 for next run
...
### fixtures-first
...
- status: promote chosen 2026-11-12
```

`ownership-each-stage` no longer appears. Run #3 stopped before its close instead: at the next run's start (`/factory:run` on a new idea, no current run), the three entries are `active` with `run: #3`, so they are from an earlier run with no answer; the Lead applies none, starts an andon of kind 7, shows the three lines, and asks for the answers before the first item starts.

## 9. Visibility of long-lived overrides (S3)

Every stage summary the Lead posts lists the overrides in force that are marked `promote chosen`, by name and date, in one line (`promote chosen, still in force: <name> (<date>); …`, or nothing when there are none), because that status ends the expiry and keeps the override in force until a card is decided. The Lead also shows the **rule text** of every in-force override at item start ([49-abnormality-list](49-abnormality-list.md) §5.6).

## 10. Acceptance criteria → this contract

| AC | Where |
|---|---|
| AC-15 | §1, §3, §4 (apply), [49-andon-process](49-andon-process.md) §4 (plugin-change-only countermeasure) |
| AC-16 | §4 |
| AC-17 | §2, §3 |
| AC-18 | §6.1, §6.2 |
| AC-19 | §6.3 (fixtures 1 to 10 are the AC-19 set; 11 and 12 are added by the security review) |
| AC-20 | §6.2 (the person's request is refused; the demo records the wording, human-only) |
| AC-21 | §7.1 |
| AC-26 | §8, §9 |
| AC-27 | §8.3, §7.2 |
