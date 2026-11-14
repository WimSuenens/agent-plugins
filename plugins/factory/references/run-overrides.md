# Run skill: overrides and the settle round

Read this when a countermeasure is an override, at run start and item start when overrides exist, when the run's first worktree is created, and at the settle round of step 9.3. It is part of the run skill; the text below moved out of `skills/run/SKILL.md` unchanged, and the pointer in the router for any heading says which file holds it. Here `${CLAUDE_PLUGIN_ROOT}` is not substituted (only the router is): read it as the path on the `Plugin root:` line of `skills/run/SKILL.md`, and write that path in every shell command.

### Overrides

Check the fence before you write: for each of the eight questions of the protocol's *Never overridable locally* (F1 to F7 and the data-egress question E), ask it of the override's effect, not its wording. One yes refuses; where you cannot answer "no" with confidence, do not write: record the doubt, tell the person, and carry on with `none`. A refusal writes nothing to `docs/agents/factory.md`; the comment's `fence check` reads `refused YYYY-MM-DD: touches <fenced item>`, with the reason in the chain's last line. A request from the person to cross the fence is refused and the item named; loosening is a decision card.

Write an accepted override in the worktree that raised the andon, under `## Overrides` in `docs/agents/factory.md` (create the section on first use; for a project set up before the row existed, also add the ownership row `` | `docs/agents/factory.md` section `## Overrides` | lead | `` and tell the person in the stage summary). Commit with `git -C "<worktree>" commit`, subject `#<id> lead: override <name>`. Format:

```
## Overrides

### <name>

- started: YYYY-MM-DD
- run: #<map>
- rule: <the rule in plain words; may continue on indented lines>
- andon: <URL of the andon comment | pending | none (experiment)>
- status: <status>
- fence check: pass YYYY-MM-DD (touches none of the seven)
```

The run's experiment (`references/a3.md`, section 5) carries eight more lines after `fence check` (a ninth, `target`, when it states one), written at the moment the override is written and never edited except `a3` (`target` is never edited):

```
- experiment: yes
- problem: <the problem's process item to change, in one line>
- measure: <number field, from the table in references/a3.md section 5>
- direction: <down | up>
- target: <number, optional>
- series: <M.N>
- reference: <none | name; name …>
- before: <value> (<k> of <n>; items #<a>, #<b>; factory <semver>)
- a3: <pending | the A3 comment's URL>
```

`series` is the series of the session, `reference` the key of the baseline's reference section when the override was written (`none` when empty), `before` the reading over the before-items; it is never `not captured`. `a3` is `pending` until the A3 is posted; the settle commit replaces it with the comment's URL while the entry exists. An override without `experiment: yes` is not the run's experiment. The rule that a `pending` andon link left after the item carried on is a defect applies to `pending` only, never to `none (experiment)`. An override that crosses the fence is refused before any of these lines is written.

`<name>` is `[a-z0-9]+(-[a-z0-9]+)*`, unique in the file. `started` is `date -u +%F`. Write `andon: pending` first (the override must exist before the resume; an experiment written between items has `andon: none (experiment)` and needs no second commit), and replace it with the comment URL in a second commit, `#<id> lead: override <name> andon link`, right after you post the comment. Entries stay in the order written; the section holds nothing else. An override without `pass` is never applied. Status must match:

```
^(active|promote chosen [0-9]{4}-[0-9]{2}-[0-9]{2}|kept [0-9]{4}-[0-9]{2}-[0-9]{2} for (next run|#[0-9]+)|superseded [0-9]{4}-[0-9]{2}-[0-9]{2} by [a-z0-9-]+)$
```

`active` applies in its run and is asked about at that run's close; `kept … for next run` applies in the next run and is bound at that run's first worktree; `kept … for #<map>` is the same, bound; `promote chosen` stays in force until its decision card is decided; `superseded` is not applied. An override is in force when its status is `active`, kept bound to the current run (or `for next run`), or `promote chosen`, and it is not a crossing.

Two overrides whose rules cannot both be followed in one brief or stage: the later `started` wins, the one lower in the file when equal. Set the loser to `superseded <date> by <winner>` in the commit that writes the winner, and name it in the winner's comment (`supersedes:`). Superseded entries are removed at that run's close and named in the close summary. An override whose rule is a `## Role models` row adds that row; dropping the override removes it.

A countermeasure whose only form is a change of plugin text writes no override: the comment holds the 5 Whys and the proposed change, the item continues, and the proposal goes into the A3's `standard changes proposed` line and, if the person approves a draft, into step 9.4's issue. Never edit `plugins/` to apply a countermeasure.

### Run identity

A run is one cycle over a map, identified by the map's issue number `#<map>`: from its start (step 0) to its close (step 9). The map outlives the run; a later cycle on the same map is a new run. The current run is the map named by `/factory:run #<map>`, the map of the slice named by `/factory:run #<slice>`, or on a new idea the map created at step 2; until step 2 a new idea has no current run.

At the first worktree the run creates (a frontier round or an item), rewrite each `kept … for next run` to `kept … for #<map>` in that worktree, in a commit `#<id> lead: bind kept overrides to #<map>`.

An override is from an earlier run when its status is `active` with `run: #<M>`, or `kept … for #<M>`, and `M` is not the current run. `kept … for next run` and `promote chosen` are never from an earlier run.

### Run start

At step 0 and again at step 5, read `docs/agents/factory.md` and sort every override:

1. **Crossing the fence** (the questions asked of its rule, whoever wrote it): not applied; start a kind 5 andon naming the override and tell the person which fenced item it touches. Do not remove it; the person decides.
2. **From an earlier run** with no answer: not applied; start a kind 7 andon (no listed kind names it), show the person the settle line for it, and ask **keep, promote or drop** before the first item starts. Apply the answer in a settle round before the item's worktree is created.
3. Otherwise it is in force.

### Settle round

At step 9.3, and on the run-start answer above, when the run has at least one `active` or `kept … for #<map>` override (superseded ones too, for removal). `promote chosen` ones are named in the summary and not asked again.

1. **The lines.** For each override show one line and ask `keep`, `promote` or `drop`. Silence, a timeout or a default is no answer (F1).
   - The experiment: `<name> — started <date> — before <reading> / target <target> / after <reading> — keep, promote or drop?`, where `<reading>` is the A3's `before` and `after` text **verbatim** (`<value> (<k> of <n>; items #<a>, #<b>; factory <semver>)`) and `<target>` is the number of the override's own `target:` line followed by ` (reached)` or ` (not reached)` when the A3's `target` line says so, and the word `none` when the override has no `target:` line (`target none`). When the A3's `change` starts with `not comparable` or `not captured`, it follows the readings: `… — not comparable (<why>) — keep, promote or drop?` (or `not captured (<reason>)`).
   - Any other override: `<name> — started <date> — before/after: not measured (not this run's experiment) — keep, promote or drop?`
   - An override of an earlier run `#<M>` takes its readings from the A3 on `#<M>` when that A3 names it as the experiment (*Find A3* on `#<M>`); with none: `before/after: not measured (no A3 for run #<M>)`.

   The line never shows a figure the A3 does not, except the target, which is the override's own line. An override of an earlier run whose A3 is v1 (or whose override has no `target:` line) shows `target none`.
2. **On each answer, *Edit A3* now**: that override's `answer` entry becomes `<keep|promote|drop> <date>` (`date -u +%F`). For an earlier run's A3 the same edit goes on `#<M>`.
3. **For each `promote`, a decision card** (below) is briefed and posted; it needs no merge.
4. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/worktree.sh" add settle <map>` from `origin/main`, `<map>` the map of the run being settled. Apply the answers in `docs/agents/factory.md` there: `keep` sets `status: kept <date> for next run` (`date -u +%F`); `drop` removes the entry (and any `## Role models` row it added); `promote` sets `status: promote chosen <date>`; superseded entries are removed and named in the summary. **The experiment's `a3:` line gets the A3's URL in the same commit** when its answer is `keep` or `promote`.
5. One commit `#<map> lead: settle overrides` (after the commits of a promote card). Run the *Open PR* release check (`git fetch origin main`, then `release-hook.sh check` in the settle worktree, as in step 6), open one PR, and ask **merge and clean up?** as in step 8.1; on the yes merge and clean up (*Merge PR*). No default, no timeout.
6. **After the merge, recompute the baseline** (`references/baseline.md`, section 6 reads main): the reference section moves for `keep` and `promote`; the dropped section moves to history with its note.
7. Report the run closed with the outcome of each override (step 9.5).

When the person stops the run before step 9.3 and does not say yes to the question of step 9.0, nothing is written; the run-start check finds the unanswered ones.

**`promote` is a one-way door** (the change goes to every project) and takes the route of step 7:

- `promote chosen <date>` is written in the settle commit and the override **stays in force**.
- The settle worktree is a third place for role messages besides an item and a frontier round: messages in `work/settle-<map>/`, commits starting `#<map>`. They follow the path rule, and are removed before the settle commit's PR with the two-commit sequence of step 8.6 (`#<map> lead: close`, `#<map> lead: remove work/`), in the settle worktree, guard first.
- Brief the product-owner (step 7.2): Goal, a decision card for the yokoten of the override; Inputs, the override's name and rule, the A3's URL, the A3's `before`, `after` and `change` lines, `references/decision-card.md`, the decision-maker level; Constraints, two or three options (for example: change the plugin text in a minor release; keep it local to this project; drop it), the recommendation and each option's undo cost, and no project data beyond the A3's numbers. At `technical` the architect gives the options first (step 7.1).
- Post the card on the map issue `#<map>` (*Decision card*), scanned first (*Scan before posting* with `--needs-you`) and put it to the person in chat in the same words.
- Nothing is written under `plugins/` and nothing is sent to `WimSuenens/agent-plugins` until the person decides the card; the choice is then recorded as step 7.5 says, and the change itself is a later item.
- The run may be reported closed with the card open; the report lists the card's link. No route promotes without a card: no automatic promotion, no `promote` by silence or default, no promotion that a later run start applies on its own.
