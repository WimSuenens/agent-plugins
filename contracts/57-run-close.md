# Contract 57 — The run close: update, A3, settle, feedback, report

Slice [#57](https://github.com/WimSuenens/agent-plugins/issues/57) · Requirement [57-per-run-a3-and-baseline](../docs/requirements/57-per-run-a3-and-baseline.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) · Builds on [49-overrides](49-overrides.md) §7, §8 · Companions: [57-baseline](57-baseline.md), [57-a3](57-a3.md), [57-records-and-overrides](57-records-and-overrides.md), [57-standard-changes](57-standard-changes.md)

Serves AC-6, AC-7 (the order), AC-22 to AC-25. Where each action sits in `skills/run/SKILL.md` and what it says is fixed here; the wording is the developer's.

## 1. Where the actions sit in `skills/run/SKILL.md`

The run close is written **once**, as **step 9**. Step 10 is removed: its text becomes 9.3 and 9.5. Step 9 keeps its number, because the requirement, the ADRs and the other contracts cite "step 9's issue" for the only instruction that names `WimSuenens/agent-plugins`; that instruction is now 9.4.

| Step | Change |
|---|---|
| 0, 5 | the baseline check of [57-baseline](57-baseline.md) §2.1 and the repair check of §8.2 join the run-start checks (`## Andon`, *Run start*); step 5.3 writes `overrides at start` in `## Label` ([57-records-and-overrides](57-records-and-overrides.md) §2) |
| 6 (override written) | the experiment decision of [57-a3](57-a3.md) §5 joins the andon procedure's step 4 and the between-items moment |
| 8.4 | also append the item to `closed in this run` in the map's Factory run section ([57-records-and-overrides](57-records-and-overrides.md) §7) |
| **8.10 (new)** | **Update the baseline**: after 8.9 (*Edit hansei*), recompute ([57-baseline](57-baseline.md) §8.1), append the `baseline:` note; then, before the next item starts, decide whether the run's experiment is written now ([57-a3](57-a3.md) §5) |
| 8.11 | the former 8.10, *Advance*; "the map dissolves → step 9" |
| **9 (rewritten)** | **Close the run**, §2 below. Replaces the old step 9 (feedback) and the old step 10 (settle) |
| `## Andon` | *Run identity*: "step 8.10 to step 9" becomes "step 8.11 to step 9"; *Settle round*: "At step 10" becomes "At step 9.3", the line text changes (§4), "When the person stops the run before step 10 nothing is written" is replaced by §3; the phrase `before/after: no baseline yet` is deleted |
| *Reading list* | `references/baseline.md` is read at step 0, 8.10 and 9; `references/a3.md` at 9 and whenever an override is written |

`references/hansei.md` §5 (*Close, in order*) gains a last line: `10. Update the baseline (references/baseline.md), then the experiment decision.`

## 2. Step 9 — Close the run

Entered when the map dissolves (8.11) or when the person stops the run. In this order, and **no other batch step gathers findings at the end of the run**:

0. **Entry.** When the person stopped the run, go to §3. When the map dissolved, carry on.
1. **Update the current section from the records.** The recomputation of [57-baseline](57-baseline.md) §8.1. When the page is unchanged, say `baseline unchanged`.
2. **Write the experiment's before/after reading and post the A3.** [57-a3](57-a3.md): the problem (§4), the readings (§6, §7), the lines (§2). When the run closed no item (the `closed in this run` line is absent or empty), say `0 items closed: nothing to measure`, post nothing, and go on to 9.3 (the overrides still need their answers).
3. **The settle round** ([49-overrides](49-overrides.md) §8.2, with §4 below): the lines carry the A3's before and after.
4. **The feedback offer** (§6): what the A3 lists and the person approves, as issues for `WimSuenens/agent-plugins`.
5. **Report the run closed**, with the A3's link, the baseline's link and the outcome of each override (and the link of each decision card, §5). **No instruction reports the run closed before 9.3 has an answer, applied and merged, for every override of the run.**

**Done when** every override of the run has an answer applied and merged, or the run has none; the A3 is posted (or the run closed no item); the person has approved, edited or declined every draft; and the run is reported closed.

## 3. A run the person stops (AC-22)

When the person stops the run, the Lead asks **once**: `Close the run now? That posts the A3 and settles the overrides.` The question is not a default: silence, a timeout or an assumption is no yes.

- **Yes:** run 9.1 to 9.5, with the A3's `run:` line reading `run stopped`. A closed item counts; an item in flight does not (its worktree stays, resumable with `/factory:run #<slice>`, and the report says so).
- **No:** write nothing. A later run start finds the unanswered overrides and settles them ([49-overrides](49-overrides.md) §7.2), with the line of §4 below.

## 4. The settle round (AC-6, AC-23)

### 4.1 The lines

For each override the round asks about (an `active` or `kept … for #<map>` one of the run; at run start, an unanswered one of an earlier run `#<M>`; superseded ones are removed and named; `promote chosen` ones are named in the summary and not asked), show **one line**:

- **The experiment:** `<name> — started <date> — before <reading> / after <reading> — keep, promote or drop?` where `<reading>` is the A3's `before` and `after` text **verbatim**, `<value> (<k> of <n>; items #<a>, #<b>; factory <semver>)`. When the A3's `change` starts with `not comparable` or `not captured`, it follows the readings: `<name> — started <date> — before <reading> / after <reading> — not comparable (<why>) — keep, promote or drop?` (or `not captured (<reason>)`).
- **Any other override:** `<name> — started <date> — before/after: not measured (not this run's experiment) — keep, promote or drop?`
- **An override of an earlier run `#<M>`** takes its readings from the A3 on `#<M>` when that A3 names it as the experiment (*Find A3* on `#<M>`); with none: `before/after: not measured (no A3 for run #<M>)`.

The line never shows a figure the A3 does not (AC-23). The text `before/after: no baseline yet` is nowhere in the standard.

### 4.2 The sequence

1. Show the lines; ask `keep`, `promote` or `drop` for each. Silence, a timeout or a default is no answer (F1).
2. On each answer, **Edit A3** now: that override's `answer` entry becomes `<keep|promote|drop> <date>` (`date -u +%F`), the A3's last line showing the answer and its date. For an earlier run's A3 the same edit goes on `#<M>`.
3. For each `promote`, the card of §5 is briefed and posted (it needs no merge).
4. Create the settle worktree and apply the answers as 49 says: `git worktree add ../wt/settle-<map> -b settle/<map>` from an up-to-date main; `keep` sets `status: kept <date> for next run`, `drop` removes the entry (and any `## Role models` row it added), `promote` sets `status: promote chosen <date>`; superseded entries are removed. **The experiment's `a3:` line gets the A3's URL in the same commit** (§5 of [57-records-and-overrides](57-records-and-overrides.md)) when its answer is `keep` or `promote`.
5. One commit `#<map> lead: settle overrides` (after the commits of §5, when a card was briefed). Run the *Open PR* bump check (`git fetch origin main`, then `check-bump.sh`), open one PR and ask **merge and clean up?** as in step 8.1; on the yes, merge and clean up (*Merge PR*). No default, no timeout.
6. **After the merge, recompute the baseline** ([57-baseline](57-baseline.md) §6, which reads main): the reference section moves for `keep` and `promote`; the dropped section moves to history with its note.
7. The answers are in the A3 already (step 2). The A3's last line shows each answer and its date.

When the person stops the run before 9.3, §3 applies.

### 4.3 Worked example (AC-6, AC-23)

Run `#3`. Overrides `qa-brief-names-runner` (the experiment) and `ownership-each-stage` (written by an andon, not the experiment), both `active`. Lines shown:

```
qa-brief-names-runner — started 2026-11-09 — before 1 (2 of 2; items #5, #6; factory 1.2.0) / after 0 (2 of 2; items #7, #8; factory 1.2.0) — keep, promote or drop?
ownership-each-stage — started 2026-11-09 — before/after: not measured (not this run's experiment) — keep, promote or drop?
```

The person types `promote` and `drop`. The A3's last line becomes `- answer: qa-brief-names-runner (experiment): promote 2026-11-12; ownership-each-stage: drop 2026-11-12`. The settle commit sets `status: promote chosen 2026-11-12` on the first, removes the second, and writes the A3 URL into the first's `a3:` line. After the merge the baseline: reference section keyed `qa-brief-names-runner` (the items run since), the former reference labelled `history: before qa-brief-names-runner (promote chosen 2026-11-12)`, and `## Notes`: `ownership-each-stage dropped 2026-11-12 (A3 <url>)`.

## 5. `promote` puts a decision card in front of the person (AC-24)

A `promote` answer is a **one-way door** (the change goes to every project: yokoten, ADR 0011) and takes the existing route of step 7; this contract adds only where it runs at the run close.

1. `X`'s status becomes `promote chosen <date>` in the settle commit and `X` **stays in force**.
2. **Place.** The settle worktree is a third place for role messages besides an item and a frontier round: messages in `work/settle-<map>/`, named `NN-<type>-<role>.md`, commits starting `#<map>`; `references/protocol.md`, *Your place*, gains that one bullet. The files follow the path rule (no absolute home path) and are removed before the settle commit's PR with the same two-commit sequence as step 8.6 (`#<map> lead: close`, `#<map> lead: remove work/`), in the settle worktree, guard first.
3. **The brief to the product-owner** (step 7.2): Goal — a decision card for the yokoten of override `X`; Inputs — the override's name and rule, the A3's URL, the A3's `before`, `after` and `change` lines, `references/decision-card.md`, the decision-maker level in `docs/agents/factory.md`; Constraints — the card offers two or three options (for example: change the plugin text in a minor release; keep it local to this project; drop it), carries the recommendation and each option's undo cost, and holds no project data beyond the A3's numbers. At `technical` the architect gives the options first (step 7.1).
4. **Post** the card on the map issue `#<map>` (*Decision card*, step 7.3) and put it to the person in chat in the same words.
5. Nothing is written under `plugins/` and nothing is sent to `WimSuenens/agent-plugins` until the person decides the card; the choice is then recorded as step 7.5 says, and the change itself is a later item.
6. **The run may be reported closed with the card open** (the card is not an override's answer). The report lists the card's link.
7. **No route promotes without a card**: no automatic promotion, no `promote` by silence or default, no promotion that a later run start applies on its own (F1, F2).

## 6. Step 9.4 — the feedback offer shrinks (AC-25)

The old step 9 gathered everything that went wrong with the factory; that list moves into the project's records (hansei, andon comments) and the A3's lists. Step 9.4 reads:

1. **Ask the person** what felt clumsy, before drafting (as step 9 does now).
2. **Draft a factory issue only for what the A3 lists, plus the person's remark.** The sources are exactly: the A3's `standard changes proposed` entries (plugin changes an andon proposed, and `other` (kind 7) abnormalities), the A3's `problem` and `other problems seen`, and the person's remark. Each draft states the reason it is listed (`listed because: standard change proposed | other abnormality A<k> | the A3's problem | other problem seen | the person's remark`). Things the A3 does not list — three briefs that came back `blocked` for an input the protocol should have named, a role that did another's work — stay in the project's hansei and andon records and are **not** drafted, unless they are the A3's problem or one of its other problems seen.
3. **Each draft holds** the problem in factory terms, the exact standard change, the before and after figures from the A3 against the baseline with the item count and the release, and a neutral kind of work (the `kind of work` clause of `still uncertain`). It holds no code, no project names, no business content and no raw hansei records.
4. **Show the drafts; the person approves, edits or declines each.** Only an approved draft is posted: `gh issue create --repo WimSuenens/agent-plugins --label plugin:factory --title "<title>" --body "<body>"`. **This is the only instruction in the standard that names `--repo WimSuenens/agent-plugins`**; the baseline, the A3 and every measure stay in the project's tracker (AC-9).
5. A promoted override's plugin change is **not** drafted here until its card is decided.

**Done when** the person has approved, edited or declined every draft. A fixture run with a kind 7 abnormality, an andon whose countermeasure was `none: needs a plugin change`, three blocked briefs, a role that did another's work and a remark that a step felt clumsy yields drafts for the first, the second and the remark only (AC-25).

## 7. Acceptance criteria → this contract

| AC | Where |
|---|---|
| AC-6 | §4.2 (step 6), [57-baseline](57-baseline.md) §6 |
| AC-7 (order of the update) | §1 (8.10), §2 (9.1) |
| AC-22 | §1, §2, §3 |
| AC-23 | §4 |
| AC-24 | §5 |
| AC-25 | §6 |
| AC-29 (the settle line in the demo) | §4.1 |
| AC-30, AC-31 | human-only: §5 (nothing under `plugins/`), §6 (only an approved issue leaves the project) |
