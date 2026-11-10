# 94 — Lean extensions to the A3 and hansei loop

Slice: [#94](https://github.com/WimSuenens/agent-plugins/issues/94) · Map: [#93](https://github.com/WimSuenens/agent-plugins/issues/93) · Sources: [#87](https://github.com/WimSuenens/agent-plugins/issues/87) (waste), [#88](https://github.com/WimSuenens/agent-plugins/issues/88) (flow efficiency), [#89](https://github.com/WimSuenens/agent-plugins/issues/89) (target), [#90](https://github.com/WimSuenens/agent-plugins/issues/90) (targeted gemba) · Builds on: [39-hansei-record](39-hansei-record.md), [57-per-run-a3-and-baseline](57-per-run-a3-and-baseline.md), [60-gemba-sample](60-gemba-sample.md)

## User outcome

The person who runs the factory, and the lead, read each run's A3 and each item's hansei record and can see four things they cannot see today:

1. **Which kind of waste** the run lost most to (waiting, defects, handoffs and so on), as a count per waste type on the A3.
2. **How much of an item was value-adding work**, as one percentage on the hansei record, and **where along the stages the waiting sat**.
3. **Whether the experiment reached the bar it was written against**, not only whether the figure moved.
4. **That the stage where the problem showed was looked at** before the cause analysis was written, or why it was not.

A run closes with an **A3 v2** that always carries the lines `waste`, `target` and `gemba (targeted)`; a line with nothing to say reads `none (<reason>)`. The hansei record of an item gains a derived `flow efficiency` line and a per-stage working/waiting line, computed from the ledger at close, never stored. An A3 v1 posted by an older run is still read, and the A3 check knows both versions.

This serves the map's Destination (the improvement loop of the factory gets four lean extensions) and all four of its Done-when lines.

## Terms used here

- **A3 v1 / v2**: the A3 comment whose first line is the marker `<!-- factory:a3 v<N> -->`. v1 has the fixed lines of `references/a3.md` section 2 as of factory 2.2.0. v2 is v1 plus the three new lines.
- **Waste type**: one of the eight TIMWOODS names of #87: transport, inventory, motion, waiting, overproduction, over-processing, defects, skills.
- **Tagged / untagged**: an andon comment, a `## Findings` row or a Waits row is tagged when it carries a `waste:` value; untagged reads `-` and stays valid.
- **Flow efficiency**: agent working time divided by total lead time of the item (measure 1), as a whole percentage.
- **Per-stage view**: for each stage of the item, the agent working minutes and the waiting minutes that held the item at or before that stage.
- **Derived**: computed at close from the Tasks and Waits tables of the ledger. Not stored as a field anywhere else, so no stored field and no schema version is added.
- **Honesty rule**: a value is a measured value, `0` when truly zero, `n/a (did not run)`, or `not captured (<reason>)`; never a guess, never blank (fenced item F7).

## Acceptance criteria

All criteria are checked by QA against the branch, offline (the plugin files and fixtures QA writes in `tests/`), by reading the standard step by step and applying it to fixtures, and by the existing shell tests for the A3 check. Exact line grammars (the waste tagging grammar, the Pareto line, the per-stage line, the v2 marker) are the architect's contract, fixed before the build; the criteria below hold for any grammar that satisfies them. There is no human-only criterion.

### A. A3 v2 always has the three lines (Done-when 1)

**AC-1 A v2 A3 cannot be posted without `waste`, `target` or `gemba (targeted)`.** *(Under test: Done-when 1)*
Given the A3 template and the check before *Post A3*,
when an A3 whose first line is the v2 marker is checked and one of the lines `waste`, `target`, `gemba (targeted)` is missing, blank, or out of the fixed order,
then the check refuses it and names the missing line.
And given three fixtures, each missing exactly one of the three lines,
then all three are refused, each naming its own line.

**AC-2 An empty line reads `none (<reason>)`.** *(Under test: Done-when 1)*
Given a run with no tagged entry, an experiment without a target, and no problem pointing at a stage or role,
when the A3 is written,
then its `waste` line reads `none (<reason>)`, its `target` line reads `none (<reason>)`, and its `gemba (targeted)` line reads `none (<reason>)`, each with a non-empty reason in the allowed-reasons table.
And given an A3 fixture where one of these lines is `none` with no parentheses, or `none ()`, or a bare blank,
then the check refuses it.

**AC-3 The waste line is a count per waste type over the run's tagged entries.**
Given a run whose items hold tagged entries (for example three waiting waits, one defects finding, one untagged andon),
when the A3 is written,
then the `waste` line lists each waste type that has at least one tagged entry with its count, most frequent first (a tie in the fixed TIMWOODS order), untagged entries are not counted as any type and are not an error, and the line states how many entries were untagged or says `none` for that count. An entry tagged with a word that is not one of the eight is skipped and named, as `references/a3.md` section 1 says for a line outside its grammar, and is not counted.
And the A3's problem rule (section 4) gives the same problem as before on the same run: tagging does not change which problem is chosen.

**AC-4 A tag is optional on andons, findings and waits.**
Given an andon comment, a `## Findings` row and a Waits row with no `waste:` value,
when the standard is applied,
then each is valid, reads `-` where a value would be, and every existing fixture and record of factory 2.2.0 still passes unchanged.
And given the same three carrying `waste: waiting`,
then they are valid and counted by AC-3.

**AC-5 The tagging guide is in the hansei reference.**
Given `references/hansei.md`,
when a reader looks for how to tag,
then it names the eight waste types with what each means in the factory (the table of #87), so two readers tag the same wait the same way.

### B. Flow efficiency and the per-stage view (Done-when 2)

**AC-6 The record shows `flow efficiency` derived from measure 1.** *(Under test: Done-when 2)*
Given a ledger with a total of 404m and an agent working time of 52m (the item #73 figures),
when the hansei record is written,
then it has a `flow efficiency` line reading `13%` (52 / 404 = 12.9, rounded to a whole percent, half up).
And given a total of 0m or a ledger whose Tasks or Waits table lacks the data to compute agent working,
then the line reads `not captured (<reason>)`, never `0%`.

**AC-7 The record shows a per-stage view from the same tables.** *(Under test: Done-when 2)*
Given the same ledger, in which 5h52m of waiting sits at the merge approval,
when the record is written,
then a per-stage line lists each stage that ran with its working and waiting minutes (`<stage> <working>m / <waiting>m; …`), and the 352 waiting minutes appear on the merge-approval stage and on no other. The sum of the stages' working minutes equals the record's `agent working` and the sum of their waiting minutes equals the sum of the item-held waits of measure 1, to the minute. A stage the ledger has no data for reads `not captured (<reason>)`.

**AC-8 Nothing is stored and the schema does not move.** *(Under test: Done-when 2)*
Given the hansei record template, the value grammar and the versions paragraph of `references/hansei.md`,
when the change is applied,
then the record's marker still carries the same version as in factory 2.2.0, no new header field or stored measure is added, the two new lines are listed as derived from the Tasks and Waits tables, and the baseline and the A3 measure table are unchanged (they are #92).
And given every record fixture of factory 2.2.0 (v3 to v5 as the standard reads them),
then each is still read by the baseline replay with the same result.

**AC-9 Existing measures are neither dropped nor redefined.**
Given measure 1 and its overlap rule,
when the two new lines are added,
then `lead time`, `agent working`, and the five waits read as before on the worked example, and the `flow efficiency` and per-stage lines follow the value grammar.

### C. The target (part of Done-when 1)

**AC-10 An experiment may state a target, fixed when written.**
Given an experiment written with `target: <value in the measure's unit>` after `direction:`,
when the override entry is later edited,
then the standard forbids editing the `target` line, and an experiment without one is unchanged and valid.

**AC-11 The A3 `target` line reads reached, not reached, or none.** *(Under test: Done-when 1)*
Given an experiment with `direction: down`, `target: 20` and an `after` median of 18,
when the A3 is written,
then the `target` line reads `20 — reached`; with an `after` median of 25 it reads `20 — not reached`; with `direction: up` the comparison is reversed.
And given an experiment with no target, the line reads `none (no target set)`; and given a target with an `after` reading that is not captured or not comparable, the line reads `none (<reason>)` naming that, never `reached` or `not reached`.
And given a run with no experiment, the line reads `none (<reason from the allowed table>)`.

**AC-12 The settle line shows the target beside before and after.**
Given a settled experiment with a target,
when the settle round asks the person keep, promote or drop,
then the question shows `before`, `target` and `after` together; with no target it shows `target none`.

### D. The targeted gemba walk (part of Done-when 1)

**AC-13 A targeted walk happens once, at the problem's stage, before the 5 Whys.** *(Under test: Done-when 1)*
Given a run whose chosen problem (moment (a) or (b) of section 4) points at a stage or a role,
when the lead prepares the 5 Whys,
then the lead does one targeted walk of that stage with the same commands, cap and data rules as the sample walk, before the chain is written, and at most one targeted walk happens in the run. The sample walk of each item is unchanged. The walk's time and cost stay outside the measures.

**AC-14 The A3 `gemba (targeted)` line and the chain cite the walk.**
Given that walk,
when the A3 is written,
then the line `gemba (targeted)` holds the walk's one-line result in the grammar of the sample walk's line, and the 5 Whys chain cites it as `evidence: gemba <stage> <row>`.
And given a problem that points at no stage or role, or a walk that could not be done,
then the line reads `none (<reason>)` or `not captured (<reason>)` as the honesty rule says, and the chain says why no walk was possible. It never reads "found nothing" for a walk that did not run.

### E. v1 stays valid; the check knows both versions (Done-when 3)

**AC-15 The check accepts every existing v1 A3.** *(Under test: Done-when 3)*
Given the v1 A3 fixtures that pass the check in factory 2.2.0 (including the worked example of `references/a3.md` section 3),
when the check runs on them after the change,
then each passes with the same result, and the baseline replay reads them with the same result.

**AC-16 The check decides the version by the marker and applies that version's lines.** *(Under test: Done-when 3)*
Given one fixture whose first line is the v1 marker and has none of the three new lines, and one fixture whose first line is the v2 marker and has them,
when the check runs on both,
then the v1 fixture passes as v1 and the v2 fixture passes as v2.
And given a v1-marked A3 that carries the three new lines, or a v2-marked A3 that lacks them,
then the check does not treat either as the other version: the first is refused or the extra lines are named as not part of v1, the second is refused (AC-1).
And given a marker of a version the standard does not know (for example v3),
then the comment is skipped and named, as the standard says today.

**AC-17 New runs post v2; a run in progress keeps working.**
Given a run that closes after the change,
when *Post A3* runs,
then it posts a v2 A3; and given a run whose interrupted close finds an A3 v1 already posted for the run, *Find A3* and *Edit A3* still find it and edit its `answer` line only, without rewriting it as v2.

### F. Tests and release (Done-when 4)

**AC-18 Tests pass.** *(Under test: Done-when 4)*
Given the branch,
when the whole acceptance suite runs,
then it passes, with the pinned version row of the tests updated to the new release and new tests for AC-1 to AC-17 that can be run offline.

**AC-19 The version is a new minor release.** *(Under test: Done-when 4)*
Given the plugin manifest and the changelog,
when the branch is checked,
then the version is `2.3.0` (the next minor after 2.2.0, no patch and no major), the changelog names the four changes, and the standard and tooling fingerprints are recomputed for the release.

## Out of scope

Everything the frame lists as deliberately faked, and what the map and the briefs exclude:

- **Flow efficiency as a baseline field and in the A3 measure table** (issue #92, Deferred on the map; trigger: #92 is picked up). The `flow efficiency` line exists on the hansei record only.
- **A hansei-record schema bump.** The marker version of the record does not move; the new lines are derived at close.
- **Changes to other plugins.** Only `plugins/factory` is touched.
- A run-level adjusted duration for the Obeya preview (#66), though the per-stage view should share its wait definitions if #66 lands first.
- Changing the problem rule of section 4, the sample rule of the gemba walk, or any existing measure.
- Any new wait kind, new stage, or change to how waits are detected.
- Backfilling waste tags, flow efficiency or targets onto records and A3s of earlier runs.
- Any automatic judgement of whether a tag is right; tagging is the lead's reading.

## Decisions (two-way doors, decided here)

All are cheap to undo by an edit to the standard text and its tests before the first run uses them; none is a one-way door.

1. **Waste tag values are the eight lowercase TIMWOODS names**; untagged reads `-`. Rejected: free-text tags, numbered codes. Cost to undo: one edit to the standard and its fixtures.
2. **The `waste` line counts tagged entries, not items** (the A3 example of #87 says "items"; the counts per type and the number of untagged entries are shown so the reader can tell). Rejected: counting distinct items per type. Cost to undo: one edit.
3. **`target` comparison is inclusive** (`down`: after median at or below the target counts as reached; `up`: at or above). Rejected: strict comparison. Cost to undo: one edit.
4. **`flow efficiency` is a whole percent, rounded half up**, from the ledger's `agent working` over `total`. Rejected: one decimal place.
5. **The v2 marker is `<!-- factory:a3 v2 -->`**, following the existing `v<N>` pattern the finder already reads; the architect may still change the exact lines. Rejected: a separate marker or a second comment type.
6. **The three new lines have a fixed place in the v2 template**; the position is the architect's call, as long as the order is fixed and the check enforces it (AC-1).

## Open questions

1. **Where does the A3 read waste tags from?** Tags live on andon comments, lead-state `## Findings` rows and ledger Waits rows. The hansei record carries none of them and may not gain a field (no schema bump), and `work/` is removed at merge, but the ledger comment on the slice ticket remains. Does the A3 read the closed items' ledger comments and andon comments, and does `## Findings` (a lead-state table) get a `Waste` column? Owner: architect.
2. **How are waits assigned to a stage in the per-stage view?** The Tasks table's `Waits` column ties waits to tasks; the person's merge wait sits after the last task. Owner: architect (the contract), checked by QA against the item #73 figures in AC-7.
3. **Exact line grammars**: the `waste` Pareto line, the per-stage line, and the position of the three new lines in the v2 template. Owner: architect.
4. **Allowed `none (<reason>)` reasons** for the three new lines. This requirement needs at least one reason per case in AC-2, AC-11 and AC-14; the wording is the architect's, to be added to the allowed-reasons table. Owner: architect.
5. **Does the settle line (AC-12) live in `skills/run/SKILL.md` step 9 only**, or also in the settle round's own skill? Owner: architect.
6. **Fingerprints and the pinned-version tests**: confirm that `2.3.0` is the next minor and that the release runbook (`docs/factory/release-runbook.md`) is followed for fingerprints. Owner: developer with devops.

## Unverified

What only live use shows: whether the waste tags are applied consistently by the lead across a real run, whether the targeted walk finds anything, and whether the waste Pareto changes which improvement the person picks. Checked after the next run closes with a v2 A3, by the lead reading that A3.
