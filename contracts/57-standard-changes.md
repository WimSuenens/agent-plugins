# Contract 57 — Where each change lives, the release, the exception, and the map of every criterion

Slice [#57](https://github.com/WimSuenens/agent-plugins/issues/57) · Requirement [57-per-run-a3-and-baseline](../docs/requirements/57-per-run-a3-and-baseline.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md)

The placement contract for the developer, as [49-standard-changes](49-standard-changes.md) was for #49. Wording is the developer's; what each file must say is fixed in the contracts named in each row. Formats and rules: [57-records-and-overrides](57-records-and-overrides.md), [57-baseline](57-baseline.md), [57-a3](57-a3.md), [57-run-close](57-run-close.md).

## 1. Release

- `plugin.json` gets `"version": "1.2.0"` — **the developer's edit**. The change is to standard work, and ADR 0012 gives **minor** to any change to standard work. It is not major: a v4 hansei record is read by the new standard together with v3, a reader that meets a version it does not know skips the record and says so (the pattern of v3 and of the andon comment), no existing message stops working, and the new override lines are additive. `1.2.0` is the smallest version that passes AC-27's "at least one minor above `1.1.0`". A change that would need more than one minor step goes back as a question; none was found.
- **Who tags.** The tag is made by the Lead at merge, by the existing step of *Merge PR* ([39-standard-changes](39-standard-changes.md) §5): when the merged branch changed `version`, `git tag factory-v1.2.0 "$(gh pr view <branch> --json mergeCommit --jq .mergeCommit.oid)"`, then push. There is no manual tagging outside that step. Item #57 runs on the frozen install `9147301f75c3`, which holds no such text, so at its merge the Lead performs the steps of that section by hand, as for #39 and #49. **[post-merge]** the tag list shows `factory-v1.2.0` on the merge commit of `main` (AC-28).
- **Baseline reset (ADR 0012, point 3).** A minor release resets the baseline. There is no baseline of agent-plugins yet; item #57 is calibration on the frozen install, its stage-log comment is filed under `Calibration (pre-baseline)`, and no `Factory baseline` issue is created in agent-plugins by this item's work (AC-27, post-merge). The new standard's own baseline begins with the first item run on `1.2.0` (ADR 0012, point 6).
- **How it moves the fingerprints** (`fingerprint.sh`, [39-plugin-scripts](39-plugin-scripts.md) §1):
  - **standard** moves: it covers `skills/run/SKILL.md`, `references/*.md` and `agents/*.md`, and this change edits `SKILL.md`, `hansei.md` and `protocol.md` and adds `references/baseline.md` and `references/a3.md`.
  - **tooling** does **not** move: no file under `hooks/` or `scripts/` changes (§4). It is expected to equal the tooling value of the `1.1.0` records (S5 reads `295033f4…ff5`). If it moves, the developer says why.
  - The tracker template ([§3](#3-the-exception-for-ac-26)) is covered by neither fingerprint; the bump check ranks it `patch`, absorbed by the `minor` the standard files demand.
- The Lead's bump check (`check-bump.sh`) must pass at *Open PR* and before the merge. QA quotes the two new fingerprints (`fingerprint.sh` on the item worktree's `plugins/factory`) in its verdict (AC-27).

## 2. What changes, file by file

| File | Kind | Change | Contract |
|---|---|---|---|
| `plugins/factory/.claude-plugin/plugin.json` | other | `"version": "1.2.0"` (§1) | here |
| `plugins/factory/skills/run/SKILL.md` | standard work | run-start and item-start checks (baseline); 8.4 `closed in this run`; new 8.10, 8.11 renamed; step 9 rewritten, step 10 removed; the *Settle round*, *Run identity* and fallback texts updated; the reading list | [57-run-close](57-run-close.md) §1 to §6, [57-baseline](57-baseline.md) §2.1, §2.2 (fallback) |
| `plugins/factory/references/hansei.md` | standard work | record **v4** and the note on reading v3; the label line `overrides at start`; the `active overrides` grammar and its worked example; the closing list gains the update; the Factory run lines are named | [57-records-and-overrides](57-records-and-overrides.md) §1 to §4, §7 |
| `plugins/factory/references/baseline.md` | standard work (**new**) | how the Lead finds, reads, composes and updates the baseline: the rule texts for AC-3 and AC-5, the layout, the repair check | [57-baseline](57-baseline.md) §3 to §8 |
| `plugins/factory/references/a3.md` | standard work (**new**) | the A3 template and its rules; the problem rule (AC-11), the experiment rules (AC-12, AC-13), before/during/after (AC-14), comparability (AC-15), `still uncertain` (AC-19) | [57-a3](57-a3.md) |
| `plugins/factory/references/protocol.md` | standard work | *Your place* gains one bullet: the settle worktree, messages in `work/settle-<map>/` ([57-run-close](57-run-close.md) §5.2). (The experiment's extra override lines and `andon: none (experiment)` are written into `skills/run/SKILL.md`, *Overrides*, where the override format already lives, not here) | [57-run-close](57-run-close.md) §5 |
| `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` | **exception** (§3) | the tracker commands for the baseline and the A3: *Find baseline*, *Create baseline*, *Pin baseline*, *Read baseline*, *Edit baseline*, *Find records*, *Find A3s*, *Find A3*, *Post A3*, *Edit A3* | [57-baseline](57-baseline.md) §2.2, [57-a3](57-a3.md) §1 |
| `plugins/factory/agents/*.md`, `references/decision-card.md` | standard work | no change: roles do not read the baseline or the A3; the card route is step 7, unchanged | — |
| `plugins/factory/scripts/*`, `hooks/` | tooling | **no change, no script is added** (§4) | — |

The developer may change **only** the files in this table. The Lead's skill file keeps the run's procedure; the long rules sit in the two new reference files, so `SKILL.md` points to them (the *The 5 Whys* rule is pointed to, not restated, [57-a3](57-a3.md) §2).

Outside `plugins/factory/`: `docs/agents/issue-tracker.md` of this repository (docs-writer) may take the new bullets (this repository's section predates them, so the run skill's fallback covers it meanwhile), `README.md`, `CHANGELOG.md`, `docs/factory/reference.md` and `docs/factory/release-runbook.md` (docs-writer, devops), and `tests/` (QA). They are proposals to their owners, listed in the result.

## 3. The exception for AC-26

AC-26 allows `skills/run/SKILL.md`, a file in `references/`, a file in `scripts/` and `plugin.json` under `plugins/factory/`. **One changed path falls outside: `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md`.**

- **Reason.** AC-1 puts the baseline's tracker commands "where the project's other factory tracker operations are", with the fallback the run skill already gives. Those operations live in this template, which `/factory:setup-factory-skill` copies into each project's `docs/agents/issue-tracker.md`, next to *Find hansei* and *Post hansei*. Putting the commands anywhere else would make a second place for tracker operations.
- **Effect.** The file is ordinary text the setup skill copies; it is covered by neither fingerprint (§1). No other file under `skills/setup-factory-skill/` changes (its step 6 copies the section verbatim).
- **QA** lists this path as the exception for the person to see.
- **Alternative that needs no exception**, if the person prefers: put the commands in `references/baseline.md` and drop the *fallback* to the template. Rejected (Decisions D15): the project's tracker doc would not hold all of the factory's tracker operations.

## 4. No script, and the `hooks/` / `scripts/` question

**No script is added.** The Lead reads the comments and writes the page (the requirement's out of scope: no metrics store, no script that aggregates records). So the ADR 0012 line "whether a change under `hooks/` or `scripts/` resets the baseline", left to the slice **only if a script is added**, **stays open on the map**. What is already settled stays settled: a tooling-only difference (same `standard`, different `tooling`) starts no new section ([57-baseline](57-baseline.md) §6, as #39 settled it). Trigger to revisit (Decisions D17): the first slice that adds or changes a file under `scripts/` or `hooks/`; the QA verdict of this item records that `tooling` did not move.

## 5. Every acceptance criterion → contract

| AC | Contract |
|---|---|
| AC-1 | [57-baseline](57-baseline.md) §2 |
| AC-2 | [57-baseline](57-baseline.md) §3 |
| AC-3 | [57-baseline](57-baseline.md) §4 |
| AC-4 | [57-baseline](57-baseline.md) §3 item 4, §5 |
| AC-5 | [57-baseline](57-baseline.md) §6 |
| AC-6 | [57-baseline](57-baseline.md) §6; [57-run-close](57-run-close.md) §4 |
| AC-7 | [57-baseline](57-baseline.md) §8; [57-run-close](57-run-close.md) §1, §2; [57-records-and-overrides](57-records-and-overrides.md) §7 |
| AC-8 | [57-baseline](57-baseline.md) §1, §8.3 |
| AC-9 | [57-baseline](57-baseline.md) §1, §2.2; [57-run-close](57-run-close.md) §6 |
| AC-10 | human-only: [57-baseline](57-baseline.md) §7 (the worked body the person compares) |
| AC-11 | [57-a3](57-a3.md) §4 |
| AC-12 | [57-a3](57-a3.md) §5; [57-records-and-overrides](57-records-and-overrides.md) §5, §6 |
| AC-13 | [57-a3](57-a3.md) §5 item 5 |
| AC-14 | [57-a3](57-a3.md) §6; [57-records-and-overrides](57-records-and-overrides.md) §1 to §4 |
| AC-15 | [57-a3](57-a3.md) §7 |
| AC-16 | [57-a3](57-a3.md) §1, §2 |
| AC-17 | [57-a3](57-a3.md) §2, §9 |
| AC-18 | [57-a3](57-a3.md) §2 (the pointer to *The 5 Whys*) |
| AC-19 | [57-a3](57-a3.md) §8 |
| AC-20 | [57-a3](57-a3.md) §1 |
| AC-21 | human-only: [57-a3](57-a3.md) §2 |
| AC-22 | [57-run-close](57-run-close.md) §1 to §3 |
| AC-23 | [57-run-close](57-run-close.md) §4 |
| AC-24 | [57-run-close](57-run-close.md) §5 |
| AC-25 | [57-run-close](57-run-close.md) §6 |
| AC-26 | here §2, §3, §4 |
| AC-27 | here §1 |
| AC-28 | here §1 |
| AC-29 | [57-run-close](57-run-close.md) §4.1, with [49-overrides](49-overrides.md) §8 and [49-andon-process](49-andon-process.md) (the carried criteria are #49's, not rewritten) |
| AC-30, AC-31 | human-only: [57-run-close](57-run-close.md) §5, §6 |

## 6. No ADR

No one-way door was found. Each decision below is a text change to standard work, a record schema version (a reader skips an unknown version, so the next change is one more bump), or a reading rule over data that is recomputed. The reversals are one minor release and a recompute of the baseline; no data is lost, because the baseline is derived. ADR 0011 already records the fence, the expiry and the visibility (the one-way parts); ADR 0012 the release and fingerprint rules; ADR 0013 the merge style that the settle worktree rests on. If the lead disagrees with any D below, it comes back as a question.

## 7. Decisions (architect, two-way doors)

Chosen / rejected / cost to undo. None overturns one of the product-owner's ten.

- **D1. An experiment may name measures 1, 3, 5 or 6, not 2, 4 or 7.** Rejected: measure 2 (an outcome per stage; a signed difference between `pass first time 1 of 2` and `2 of 3` means nothing), 4 (always `not captured`), 7 (outcomes per Under test line). Undo: widen the table in [57-records-and-overrides](57-records-and-overrides.md) §6 and give measure 2 its own change line.
- **D2. The baseline is the issue's body, one issue.** Rejected: one comment per section (ids to track, one edit per section, an order to keep), a file in the project's repository (a PR per update), a store (out of scope, AC-8). Undo: move the sections to comments; the page is recomputed. Trigger to revisit: the composed body passes 50,000 characters (the issue limit is 65,536).
- **D3. The baseline issue is found by its exact title and the Lead's author; pinning is best-effort and never read.** Rejected: finding it by the pin (a failed pin would then create a second issue, AC-1); a label (one more thing to set up). Undo: one rule.
- **D4. Hansei v4 adds an extent to each override on `active overrides`, and the label gets `overrides at start`; v3 and v4 are read, v1 and v2 skipped.** Rejected: inferring the extent from the override's `started` date and the item's close date (three demo items close the same day, decision 2 of the requirement); a v3 list read as "whole item" (a during-item would be counted as an after-item, the error AC-14 forbids); keeping the extent in the stage log only (removed at step 8.6); a new record per override. Undo: bump to v5 and read both; the baseline is recomputed.
- **D5. `overrides at start` lives in `## Label`.** Rejected: a stage-log note (not a field, easy to omit). Undo: move the line; the record is unchanged.
- **D6. After-items are the run's items only; a kept override's later items are in the baseline's reference section and no second A3 reports them.** Rejected: counting across runs (a kept override would need an A3 each run; the A3 is written once); the next run re-measuring a kept override (it becomes `reference`, not the experiment). Undo: one rule. Trigger to revisit: the person asks for a second reading of a kept override.
- **D7. The run list (`closed in this run`) is kept in the map's Factory run section.** Rejected: reading run membership from slice tickets (a slice's parent map is not in the record) or from the override's `started` date (two runs on one day). Undo: one line.
- **D8. The A3 is a comment on the map issue.** Rejected: on the last slice ticket (a stopped run's last item is not the run); on the baseline issue (a second place for the baseline's reader to look; the baseline is page one, the A3 a report of one run); in a file (the A3 must reach the project's tracker for the person). Undo: move the marker's home; *Find A3* changes one issue number.
- **D9. The reference section is the section keyed by the overrides adopted on main** (status `kept … ` or `promote chosen` in `docs/agents/factory.md`), and only a `drop` is read from the A3's `answer` line. Rejected: reading every answer from the A3 (an override of an earlier stopped run settled at the next run start has no A3). Undo: change the source of the key.
- **D10. The problem is chosen by counted targets (file, else section, else the line), at the moment the countermeasure is written and again at the close only to list the others; the experiment's problem is frozen.** Rejected: re-choosing at the close (the A3 would name a problem the experiment did not test); the Lead's free choice (AC-11). Undo: one rule.
- **D11. In the measure branch, only candidates above 1 are listed one by one; the rest are counted in one entry.** Rejected: listing 40 fields at or below baseline. Undo: print them.
- **D12. The run close is step 9; the old step 10 is removed; the baseline update is step 8.10.** Rejected: renumbering the feedback step to 10 or adding 11 (the requirement, ADRs and contracts cite "step 9's issue"). Undo: reorder text.
- **D13. The update's record count and minutes go to the map's Factory run section.** Rejected: the item's stage log (removed at step 8.6, before the update). Undo: move the note.
- **D14. A settle round is a third place for role messages (`work/settle-<map>/`).** Rejected: briefing the product-owner in the main checkout (outside the protocol's places); having the Lead write the card (decision-card.md gives it to the product-owner). Undo: one protocol bullet.
- **D15. The tracker commands live in the setup skill's template, with the run skill's fallback.** Rejected: a command list in `references/baseline.md` (no exception to name, but a second place for tracker operations). Undo: move the bullets.
- **D16. Release `1.2.0`, minor.** Rejected: a patch (standard work changed); a major (nothing that existed stops working). Undo: change a string before the tag.
- **D17. No script.** Rejected: a helper that aggregates records (out of scope; would move the tooling fingerprint). Trigger: the Lead misapplies a rule in a replay, or the update passes 10 minutes or 50 records (the resurvey's reading). Undo: add one script.
- **D18. First-pass yield and doors read as outcome counts, with the not-captured entry written `not captured <m> (<m> of <n> items: <reasons>)`; doors count Under test lines, not items.** Rejected: dropping the count before the bracket (S5 alone would lose it); summing doors to `n` (S5's `confirmed 2` is two lines of one item). Undo: one rule.
- **D19 (round 1, F1). After-items are tested by the run list and `X` whole item, whatever the series; the series test applies only to before-items.** Rejected: keeping the series test on after-items and reading AC-15's release-moved case as a separate input (the case could then never occur). Undo: one rule in [57-a3](57-a3.md) §6.
- **D20 (F2). An experiment decided at 8.10 is committed at step 5, between 5.2 and 5.3; nothing is stored between them.** Rejected: committing it on main (a commit outside an item); writing a state line in the map (one more thing to keep in step; the rule is a function of the records). Undo: one sentence in step 5.
- **D21 (S2). The baseline is the exact-title issue of the Lead's user whose first line is the marker; an exact-title issue without it is not touched and the person is asked.** Rejected: accepting an empty body (an unmarked issue is not ours, even when empty; *Create baseline* always writes the marker). Undo: drop the `no-marker` column.
- **D22 (S3). Read text is data; reasons are cut, then neutralised (`@` to `(at)`, `<` to `(lt)`, backticks to `'`) and put in a code span.** Rejected: a zero-width character after `@` (invisible, not testable); quoting reasons verbatim. Undo: one rule; every reason text in an expected value moves.
- **D23 (S1). Step 9.4 quotes `<value> (<k> of <n>; factory <semver>)` and drafts only factory targets.** Rejected: stripping project text by judgment alone (no rule a test can run). Undo: one rule.
- **D24 (O1 to O4).** `pending resurvey` has the reason text `pending resurvey`; a reason is cut to 120 characters plus `…`; every field of an empty series or section is `not captured (no items in series|section)`; the v3 and v4 sentence has the optional `- records:` line. Left to the Lead's reading: nothing. O5, O7, O8 unchanged.

## 8. Questions for the requirement's owner (not blocking the build)

Places where the requirement's examples or wording disagree with each other; each is settled above in the way that makes every expected value in AC-3 replay, and none changes an acceptance criterion's intent.

1. **AC-3, doors**: "summing to `n`" cannot hold for doors with `confirmed 2` on one item. Settled by D18.
2. **AC-3, acceptance demo**: `not captured 1` (S5 alone) and `not captured (2 of 2 items: …)` (S5 and S5b) are one rule with two spellings. Settled by D18: `not captured <m> (<m> of <n> items: <reasons>)`.
3. **AC-3, `<k=0>`**: read as the condition, with `m of n` written (the examples show `2 of 2`, `1 of 1`).
4. **AC-7**: "in the stage log's notes for that step" — the stage log is removed at step 8.6, before the update at 8.10. Settled by D13: the map's Factory run section.
5. **AC-20**: "its first line says `run stopped`" and AC-16's "marker as the body's first line" — read as the first field line.
6. **AC-12, AC-13**: `experiment: none (…)` — the A3 has no line keyed `experiment`; the `countermeasure:` line reads `none (…)` ([57-a3](57-a3.md) §2).
7. **AC-11**: "or none" — read as a *silent* none; the rule ends in `none chosen (<reason>)` when nothing is measurable. "Every candidate not chosen is listed" — D11.
8. **AC-16**: two lines beyond the criterion's list — `other overrides` (AC-12 asks that other overrides are listed in the A3) and `baseline` (AC-20 asks that the A3 names the baseline by link). Additive.
9. **Fixtures need the session's release.** AC-2 and AC-5 depend on which series is current; QA's fixtures state it.
