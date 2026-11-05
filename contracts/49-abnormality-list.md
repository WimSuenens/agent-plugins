# Contract 49 — The abnormality list, the `Abnormality:` line and the detection rules

Slice [#49](https://github.com/WimSuenens/agent-plugins/issues/49) · Requirement [49-andon](../docs/requirements/49-andon.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) · Companions: [49-andon-process](49-andon-process.md) (what happens after a rule fires), [49-overrides](49-overrides.md), [49-records](49-records.md), [49-standard-changes](49-standard-changes.md)

Serves AC-1 to AC-7. This contract fixes the written rules **before any code**. Wording in the plugin is the developer's; what each rule says, and what each input and output is, is fixed here. QA replays the rules of §4 (kind 2), §5 (kind 3) and §6 (kind 4) from the text alone; the architect does not run the replay.

## 1. Where the list sits

`plugins/factory/references/protocol.md` gets a new section `## Andon`, after `## Doors`, read by every role and the Lead. It holds, in this order: the list (§2), the `Abnormality:` line (§3), and the raising rules for roles and the Lead ([49-andon-process](49-andon-process.md) §1). The list is a fenced item ([49-overrides](49-overrides.md) §6): no override may add, drop, narrow or redefine a kind, or touch the right of any role to raise one.

## 2. The list

Seven kinds. Each has a number, a name (used on the `Abnormality:` line and in records), and the observation that proves it. A role or the Lead raises a kind only with its observation in hand (the `where to look` of §3).

| # | Name | Observation that proves it | Who normally sees it |
|---|---|---|---|
| 1 | `blocked-input` | a result with `Status: blocked` whose `Missing` lists an input that is not in that role's `## Inputs needed` (§3 of this contract, *Kind 1*) | Lead, at each result |
| 2 | `same-finding-twice` | two findings in one item that §4 matches | Lead, at each result or verdict that lists findings |
| 3 | `role-outside-role` | a commit whose subject names role R and that changes a path the ownership table gives to another role (§5) | Lead, at each role stage and before the PR |
| 4 | `slow-stage` | a stage-log row whose agent-working time is more than twice the median of the same role's earlier rows (§6) | Lead, when it closes each row |
| 5 | `fence-crossing` | an override in `docs/agents/factory.md` that touches a fenced item ([49-overrides](49-overrides.md) §6) | Lead, at run start and item start; any role that reads the file |
| 6 | `version-drift` | (a) the standard or tooling fingerprint of the running plugin differs from the one recorded for the same release; (b) the installed sha differs from the run's FREEZE line, when the map has one (§7) | Lead, at item start |
| 7 | `other` | an event that fits no kind 1–6 and still ought to stop the line | any role or the Lead |

Kind 7 exists because #39 logged two abnormalities that fit no kind 1–6: the demo prep check that named the wrong input, and contract and code that drifted apart under parallel fixes. The standard tells the Lead to list each `other` abnormality in the step-9 factory feedback issue as a candidate for the list ([49-standard-changes](49-standard-changes.md) §3, step 9).

*Kind 1, the comparison.* Read `agents/<role>.md`, section `## Inputs needed`. An entry of `Missing` is **listed** when it is one of those bullets or a named part of one ("the contracts" lists `contracts/39-stage-log.md`). Every unlisted entry makes the result kind 1; the `seen` text names the entry. Two blocked cases are by design and never kind 1: the port case of the protocol's *Processes and ports* (a fixed port is taken), and a blocked result that lists only entries which are listed (the brief did not supply them; that is the ordinary *Missing input* route).

## 3. The `Abnormality:` line

The protocol's result template gets a new line directly after `Status:`, so the Lead sees it before `Progress`:

```
Status: working | done | blocked | needs-decision
Abnormality: none | <kind number or name> — <what was seen> — <where to look>
```

- Optional. An absent line reads as `none`; older results stay valid. A role with nothing to report may write `none`.
- One abnormality per line; several abnormalities are several lines, in order seen.
- The separator is exactly space, em dash, space (` — `), so a reader splits a line into three parts. `what was seen` therefore holds no ` — `.
- `<kind>`: the number 1–7 or the name from §2 (`3` and `role-outside-role` are the same).
- `where to look`: a worktree-relative path with line, a commit sha, or a tracker comment URL. Never an absolute home path (protocol path rule).
- A result with a line other than `none` is **not `done` for the Lead**, even when its Done list is met, until the andon has run ([49-andon-process](49-andon-process.md) §1).

Worked example, from #39's second kind-7 case, as a fixture result:

```
# Result: qa-engineer — 39
Status: blocked
Abnormality: other — the demo prep check named the wrong input (the plugin base dir, not the loaded text) — reviews/qa-39.md, section "Human-only criteria"
Progress:
  Done: ...
  Next: ...
```

The Lead, following the standard, starts an andon for it; its comment says `fit: no listed kind: the event is a check that tested the wrong object, not a blocked input, a repeat, a role outside its role, a slow row, a fence crossing or a version change`.

## 4. Kind 2, "same finding twice"

### 4.1 What is compared

- **A finding** is one entry of a role's `Findings`/verdict block, of a QA or security verdict, or one failed criterion of the acceptance demo's outcome. Not compared: entries whose severity is `info`, `informational` or `note`, notes to the lead, and the Lead's own feedback briefs (they copy findings and would match their source).
- The Lead keeps every finding it reads in the lead state's `## Findings` ledger ([49-records](49-records.md) §3), one row per finding, **as it reads the result**: `Role | Round | Id | Severity | Text`. The ledger holds exactly what the fixtures of AC-3 hold.
  - `Role`: `qa-engineer`, `security-reviewer`, `devops`, `docs-writer`, `developer`, or `demo` (the person's acceptance demo).
  - `Round`: 1 for a stage's first run, 2 for `(round 2)`, and so on, as in the stage log. A demo repeat counts rounds the same way.
  - `Id`: the id the finding carries in its file (`F2`, `L4`); a finding without one gets `<stage letter><n>`.
  - `Text`: the finding's one-line title as written; not the Lead's paraphrase.
- **Which pairs.** A new finding is compared with every earlier row of the ledger, except rows of the same `(Role, Round)`: one role listing two findings in one block has already separated them.

### 4.2 The signature

For each finding, from its one-line `Text` alone, the Lead writes five slots. A slot the text does not give reads `-`.

| Slot | Content |
|---|---|
| `object` | the file (basename with no directories) the finding is about; where it names none, the section heading it names; else `-` |
| `trigger` | the input, state or event under which it goes wrong, as a short noun phrase |
| `guard` | the one check or rule that, written once, would have prevented the finding. At most 15 words, naming no file |
| `criterion` | the acceptance criterion id the finding says is violated (`AC-17`), else `-` |
| `field` | the most specific record field or measure part it names (`measure 1 stalled`, `Waits.Agent`), else `-` |

### 4.3 The match

Two findings A and B (from different `(Role, Round)`) are the **same type** when either clause holds:

- **M1, same missing guard.** `guard(A)` and `guard(B)` pass the **one-fix test** (the same sentence, or two sentences that name the same check on the same kind of input; one fix written once would close both), **and** `object(A) = object(B)` (same file) **or** `trigger(A)` and `trigger(B)` name the same condition.
- **M2, a criterion that failed again.** `criterion(A) = criterion(B)`, both not `-`, **and** `field(A) = field(B)`, both not `-`, **and** `Round(A) ≠ Round(B)` (the same stage raising it in a later round; a different stage counts as well).

When a slot cannot be filled from the text and the clause hangs on it, the pair is **not flagged**; the Lead writes `unclear` in the pair's line of the lead state's notes. (A miss shows up in the replay and is fixed in the rule; a guess would show up as a false andon.)

Same file with a different `guard` is a different type, and so is the same `guard` on a different `object` with a different `trigger`.

A residual (a finding about a defect that an earlier fix round claimed to close) matches by the same clauses and is flagged like any repeat.

### 4.4 What the Lead writes

On a match, before it routes the new finding to the developer as feedback, the Lead starts an andon of kind 2. The row in the Abnormalities table and the andon comment's `seen` line read:

```
same-finding-twice: <role> r<round> <id> = <role> r<round> <id>: <the guard sentence>
```

The reason names both findings and the guard sentence. A new finding that matches several earlier ones is one abnormality; the line names all ids.

### 4.5 The replay QA runs (AC-3)

QA (or the developer; never the architect) takes the findings of #39 from its tracker comments and `reviews/qa-39.md`/`reviews/security-39.md` (earlier rounds: `git show` of their commits), and builds fixtures: per finding, `role | round | id | severity | text`, nothing else. Before the replay QA writes down at least five **control pairs** from #39's other findings, each with the reason it is a different type (same file, other cause, and so on). QA must not pick as a control a pair that is itself a repeat by §4.3 (for example L1 and its residual L1a). Then QA fills the signatures from the texts alone and applies §4.3 to every pair. The table in QA's verdict:

| Pair | Clause | Reason line (what the Lead would write) | Expected |
|---|---|---|---|

with the five #39 pairs expected **flagged**, the control pairs expected **not flagged**. The rule is contradicted if it misses a pair of #39's five or flags a control. Extra flags of genuine repeats outside the controls are listed in the table and are not a failure.

Worked example (the wording of each text is illustrative; QA uses the real titles):

| Pair | Signatures | Result |
|---|---|---|
| QA F2 (round 1) = security L4 (round 1) | object `fingerprint.sh` both; guard "stop with an error when a file cannot be read" both | M1: flagged, `qa-engineer r1 F2 = security-reviewer r1 L4: stop with an error when a file cannot be read` |
| QA F6 (round 2) = security L6 (round 1) | object `issue-tracker-github.factory.md` both; guard "write scratch output to a private mktemp file" both | M1: flagged |
| security L12 (final) repeats L7 (round 1) | object differs (`cut-offs.sh`, `token-spend.sh`); trigger "a file name starting with `-`" both; guard "put `--` or `./` before a user-supplied name" both | M1: flagged |
| QA F4 (round 5) = security L11 (round 5) | object `run/SKILL.md` and `hansei.md` close step; guard "run the guard and the commands in one shell call" both; trigger "variable lost between shell calls" both | M1: flagged |
| AC-17 stall accounting, demo (round 1) and v2 re-check (round 4) | criterion `AC-17` both; field `measure 1 stalled` both; rounds differ | M2: flagged |
| Control: security L1 (quoted paths escape the bump classification) and L4 (unreadable file yields a fingerprint) | both are in `plugins/factory/scripts/`; guard differs ("treat a file name literally" against "stop on a read error") | not flagged: same directory, other cause |

## 5. Kind 3, "role outside its role"

### 5.1 Input

- The commits of the branch: `git log --no-merges --format=%H%x09%s "$(git merge-base origin/main HEAD)"..HEAD` in the item (or frontier) worktree. A role is read from the subject by the pattern `^#[0-9]+ ([a-z-]+): `.
- The ownership table in `docs/agents/factory.md`, rows `| <Path cell> | <Owner> |`.

### 5.2 Reading the table

- From each Path cell take the backticked tokens that look like paths: they contain `/` or `.`, do not start with `#` or a space, and are **not followed by the word `section`**. A token followed by `section` (as in `` `docs/agents/factory.md` section `## Overrides` ``) names part of a file and is skipped: whole-file ownership is all this rule can see. Rows with no such token (`pipeline, infra, deploy scripts, runbooks`) cannot be checked by path and are skipped.
- Match a path P to a token T:
  - T ends in `/`: P equals T without the slash, or starts with T;
  - T contains `*`: shell-style match where `*` stands for any characters including `/`;
  - otherwise: P equals T.
- The **owner of P** is the Owner of the row with the **longest matching token**; `docs/requirements/` beats `docs/`, which is why the table writes `docs/` as "(rest)". A path that no token matches is unowned.

### 5.3 The rule

For every commit with a role R in the **seven roles** (`product-owner`, `architect`, `developer`, `qa-engineer`, `security-reviewer`, `devops`, `docs-writer`): list its changed paths with `git diff-tree --no-commit-id --name-only -r --no-renames <sha>` (a rename or move lists both its old and new path; deleted files count). For each path P that has an owner O with `O ≠ R`, the commit is flagged: `role-outside-role: <sha7> <R> changed <P> (owner <O>)`.

Never flagged: the commits whose role is `lead`, any other role name, or no role pattern; paths under `work/` (not in the table: unowned), and unowned paths in general; section rows. Merge commits are not read.

### 5.4 When the Lead applies it

At the end of each role stage, to the commits since the previous check (the stage row's commits); and once more over the whole branch before `Open PR` and at the merge approval. A hit is one abnormality per commit.

### 5.5 Worked example (AC-4)

A scratch repo with the table of this repository (`plugins/` developer; `tests/`, `reviews/qa-*` qa-engineer; `docs/requirements/` product-owner; `contracts/`, `docs/adr/` architect; `docs/` and `README.md` docs-writer), and four commits on `item/7`:

| Sha | Subject | Paths | Result |
|---|---|---|---|
| a1 | `#7 developer: build` | `plugins/factory/x.sh` | owner developer: not flagged |
| b2 | `#7 developer: add fixture` | `tests/fixtures/y.md` | owner qa-engineer ≠ developer: **flagged** `b2 developer changed tests/fixtures/y.md (owner qa-engineer)` |
| c3 | `#7 qa-engineer: verdict` | `tests/t.sh`, `reviews/qa-7.md` | `reviews/qa-*` matches `reviews/qa-7.md`; both qa-engineer: not flagged |
| d4 | `#7 lead: remove work/` | `work/7/00-lead-state.md` (deleted) | role `lead`: not read |

Exactly the second commit is flagged.

## 6. Kind 4, "slow stage" (the 2× test)

### 6.1 Input

The lead state's `## Stage log` and `## Waits` ([49-records](49-records.md)). The rule runs when the Lead closes a row whose `Role` is one of the seven roles. Lead and person rows are never tested.

### 6.2 The rule

1. **Agent-working time of a row** = `Duration` minus the union of the intervals of its waits: the entries named in the row's `Waits` column that have `Held item: yes` and kind `person`, `limits`, `stalled`, `interrupted` or `andon`, each cut to the row's [Start, End]. Overlaps count once. Whole minutes, as in the log.
2. **Earlier rows**: rows of the same `Role` with a smaller `#`, feedback rounds included (`Build (round 2)` is a row), the current row excluded. Their agent-working times are computed the same way.
3. If there are **fewer than 3** earlier rows: not tested. The row's `Notes` read `no baseline: fewer than 3 earlier rows`.
4. Otherwise let `m` be the **median** of the earlier rows' agent-working times (the mean of the two middle values for an even count, which may end in .5). The row is **flagged** when its agent-working time is **strictly greater than 2 × m**, computed exactly, without rounding. The `Notes` then read `slow: <own> against median <m> of <n> earlier rows`.
5. A flagged row is one abnormality of kind 4; the andon starts after the row is closed (the agent has handed back, so no `TaskStop`; [49-andon-process](49-andon-process.md) §2).
6. A project baseline, when a later slice builds one, changes step 2's input. This contract does not fix that.

### 6.3 Worked example (AC-5)

Developer rows 1–3 (earlier) have agent-working times 30m, 40m, 50m: median 40m, limit 80m.

| Case | Row | Result |
|---|---|---|
| exactly 2.0× | 80m agent working | not flagged (80 is not greater than 80) |
| 2.1× | 84m | flagged: `slow: 84m against median 40m of 3 earlier rows` |
| explained by a wait | `Duration` 3h30m (210m, 5.25× the median on the clock) with W2 (`limits`, held, 3h00m) in its `Waits`: 30m working | not flagged: the wait explains the duration |
| two earlier rows | the third developer row | not tested; Notes `no baseline: fewer than 3 earlier rows` |
| first row of a role | the QA's first row | same note |

## 7. Kind 6, "version drift"

- **(a) Fingerprint drift.** At item start (step 5), after `fingerprint.sh`, the Lead finds the most recent **earlier hansei record in the project** (any schema, by `plugin: factory <semver>`) with the same `<semver>` as the running release. It compares `standard` and `tooling`. A difference is kind 6, `seen`: `standard moved under 1.1.0: <old 12 hex> -> <new 12 hex> (record on #<n>)`. With no earlier record for the release there is nothing to compare: the `Start item` row's `Notes` read `drift: no earlier record for <semver>`. A match reads `drift: same as #<n>`. The release is a calibration install without a semver: not tested, Notes `drift: pre-release install`.
- **(b) Freeze.** The Lead reads the map's Factory run section for a line holding `FREEZE:`. When there is one, it takes the first backticked 12-hex token on that line as the frozen sha, and compares it with the last path segment of the `Plugin root:` line. A difference is kind 6, `seen`: `installed <segment>, FREEZE line <sha>`. With no `FREEZE:` line the project has no freeze and the check is skipped (not an abnormality).

Both are checked at every item start and, for (b), at the start of a resumed run.

## 8. Acceptance criteria → this contract

| AC | Where |
|---|---|
| AC-1 | §2, §3 |
| AC-2 | §2 (kind 7), §3 worked example; step-9 listing in [49-standard-changes](49-standard-changes.md) §3 |
| AC-3 | §4 |
| AC-4 | §5 |
| AC-5 | §6 |
| AC-6 | §3 (not `done`), [49-andon-process](49-andon-process.md) §1 |
| AC-7 | §2 kinds 1 and 3 are the seeded abnormalities; replayable on seeded input, human-only part per [49-standard-changes](49-standard-changes.md) §6 |
