# Contract 49 — Where each change lives, the release, the demo, and the map of every criterion

Slice [#49](https://github.com/WimSuenens/agent-plugins/issues/49) · Requirement [49-andon](../docs/requirements/49-andon.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md)

The placement contract for the developer, as [39-standard-changes](39-standard-changes.md) was for #39. Wording is the developer's; what each file must say is fixed in the contracts named in each row. Formats: [49-abnormality-list](49-abnormality-list.md), [49-andon-process](49-andon-process.md), [49-overrides](49-overrides.md), [49-records](49-records.md).

| File | Kind | Change |
|---|---|---|
| `plugins/factory/.claude-plugin/plugin.json` | other | `"version": "1.1.0"` (§1) |
| `plugins/factory/references/protocol.md` | standard work | result template gets the `Abnormality:` line; new sections `## Andon`, `## Overrides`, `## Never overridable locally` (§2) |
| `plugins/factory/skills/run/SKILL.md` | standard work | run-start and item-start checks, per-result checks, a `## Andon` section, step 9 and a new step 10 (§3) |
| `plugins/factory/references/hansei.md` | standard work | five wait kinds, `## Findings`, `## Abnormalities`, record schema v3 (§4) |
| `plugins/factory/skills/setup-factory-skill/` | other | writes the ownership row of §5 for new projects |
| `plugins/factory/agents/*.md`, `references/decision-card.md` | standard work | no change (every agent file already starts by reading the protocol, which now carries the rules) |
| `plugins/factory/scripts/*`, `hooks/` | tooling | no change: the rules are text the Lead follows; no script is required. `cut-offs.sh` already prints the lines that §4 of [49-records](49-records.md) reconciles. |

Outside `plugins/factory/`: `docs/agents/factory.md` (ownership row, §5), `README.md` and `CHANGELOG.md`, `docs/factory/reference.md` and `docs/factory/release-runbook.md` (docs-writer and devops), `tests/` (QA). They are proposals to their owners, listed in the result.

## 1. Release

- `plugin.json` gets `"version": "1.1.0"`. The change is to standard work, and ADR 0012 gives **minor** to any change to standard work. It is not major: the new result line is optional and an absent line reads `none`, the record's new fields are additive, and a reader that meets `hansei v3` is told by the marker, so no existing message stops working. The rule is "at least one minor above `1.0.0`" (AC-29), so `1.1.0` is the smallest that passes.
- A minor release resets the baseline (ADR 0012 point 3). The baseline opens with the first item on `1.0.0`; item #49 is calibration on the frozen install, so `1.1.0` is the first release that carries the andon and the baseline reset is accepted knowingly.
- The Lead's bump check (`check-bump.sh`, [39-plugin-scripts](39-plugin-scripts.md) §2) must pass at *Open PR* and before the merge. QA quotes the new `standard` and `tooling` fingerprints (`fingerprint.sh` on the item worktree's `plugins/factory`) in its verdict (AC-29). The tooling fingerprint is expected to equal `1.0.0`'s, since no script changes; if it moves, the developer says why.
- The release tag (AC-30). `factory-v1.1.0` comes from the existing tag-on-version-change step of *Merge PR* ([39-standard-changes](39-standard-changes.md) §5): when the merged branch changed `version`, the Lead tags the merge commit with `git tag factory-v<version> "$(gh pr view <branch> --json mergeCommit --jq .mergeCommit.oid)"` and pushes it. There is **no manual tagging outside that step**. Item #49 runs on the frozen install, which holds no such text, so at its merge the Lead performs the steps of that section by hand, exactly as for #39. The post-merge check lists tags and sees `factory-v1.1.0` on the merge commit of `main`.

## 2. `references/protocol.md`

1. **Result template.** The `Abnormality:` line directly after `Status:` ([49-abnormality-list](49-abnormality-list.md) §3). The *Missing input* section gains one sentence: a `blocked` result whose `Missing` input is not in your **Inputs needed** is an abnormality of kind 1: write the `Abnormality:` line.
2. **`## Andon`** (after `## Doors`): the list ([49-abnormality-list](49-abnormality-list.md) §2) and the raising rules for roles ([49-andon-process](49-andon-process.md) §1), and the blame-the-process rule in the words of [49-andon-process](49-andon-process.md) §3, so every role reads why it may stop the line.
3. **`## Overrides`**: every role that reads `docs/agents/factory.md` also reads its `## Overrides`; apply every in-force override that concerns your role or stage; outside the fence the override wins ([49-overrides](49-overrides.md) §4). A role that reads an override that touches a fenced item raises kind 5.
4. **`## Never overridable locally`** (after `## Andon`): the seven-row table of [49-overrides](49-overrides.md) §6.1, and the sentence that an instruction from the person does not loosen it (loosening is a decision card).
5. **Ownership.** One line: the `## Overrides` section of `docs/agents/factory.md` is written by the Lead.

## 3. `skills/run/SKILL.md`

- **Step 0, resume or start.** The run-start check of [49-overrides](49-overrides.md) §7 (crossing and earlier-run overrides) and, for a resumed run, the FREEZE check of [49-abnormality-list](49-abnormality-list.md) §7(b). The current run is identified as in [49-overrides](49-overrides.md) §5. An unanswered earlier-run override is settled before step 1 or the next item starts.
- **Step 3 and step 5.** At the first worktree of a run (a frontier round or an item), bind `kept … for next run` overrides ([49-overrides](49-overrides.md) §5). Step 5's `Start item` row also runs the item-start checks: kind 6(a) and (b), kind 5 on the item worktree's `docs/agents/factory.md`, with the results in the row's `Notes`. Step 5 starts `## Findings` and `## Abnormalities` as well as the three sections of 1.0.0.
- **Step 6, reading a result.** After the Status/Summary/Decisions reading, the Lead reads the `Abnormality:` lines; logs the result's findings in `## Findings` and applies the kind 2 rule; applies kind 1 to a `blocked` result; after a role stage, kind 3; on closing a row, kind 4. An abnormality starts an andon before any dependent brief ([49-andon-process](49-andon-process.md) §1). The Lead puts each in-force override's rule in the Constraints of the briefs it concerns.
- **`## Andon`** (after `## Interruptions`): the pause and resume of [49-andon-process](49-andon-process.md) §2, the 5 Whys rule of §3, the fence check and the override write of [49-overrides](49-overrides.md) §1, §4, §6, the comment of [49-andon-process](49-andon-process.md) §5, and the rule that a countermeasure whose only form is a plugin-text change writes no override and goes into the step-9 issue. `## Interruptions` keeps its own text; a limit or stall is not an andon unless a role writes the line or the Lead raises kind 7.
- **Step 8.** Unchanged in order. The close scan uses the reconciliation of [49-records](49-records.md) §4; the record is v3 ([49-records](49-records.md) §5).
- **Step 9.** The existing list of what went wrong with the factory gains: each `other` (kind 7) abnormality of the run, listed as a candidate for the list, with the problem in factory terms and no project data; and each plugin change an andon proposed (`standard change proposed`). The rule on what a step-9 issue may hold is unchanged.
- **Step 10, Close the run** (new, after step 9): the settle round of [49-overrides](49-overrides.md) §8. The Lead does not report the run closed while an override of the run has no answer.

## 4. `references/hansei.md`

Holds, for the Lead: the five wait kinds with the `andon` row and its close-scan and truncation rules ([49-records](49-records.md) §4); `## Findings` and `## Abnormalities` ([49-records](49-records.md) §3); the stage-log row `Andon A<n>` ([49-records](49-records.md) §2); the record at schema v3, its field definitions and its worked example ([49-records](49-records.md) §5). The v2 template is replaced, not kept beside it. The rule that measurements stay in the project is unchanged: the andon comment goes to the project's own tracker (no `--repo`); the only cross-repo write remains step 9's feedback issue.

## 5. Outside `plugins/`: the ownership row

`docs/agents/factory.md`, ownership table, one new row (docs-writer adds it in this item, since the file is docs-writer's; the Lead owns the section it names):

```
| `docs/agents/factory.md` section `## Overrides` | lead |
```

The row has to read exactly so: the kind-3 rule skips a path token followed by the word `section` ([49-abnormality-list](49-abnormality-list.md) §5.2). The repository's own `docs/agents/factory.md` has no `## Overrides` section yet; none is created until the first override. `/factory:setup-factory-skill` adds the row for new projects; for a project set up earlier, the Lead adds the row and the section with its first override and tells the person in the stage summary.

## 6. The demo, and the sandbox

- **Project.** The human-only criteria (AC-7, 9, 10, 11, 14, 20, 25, 28) run in the sandbox repository `WimSuenens/factory-sandbox` with its Project #10, never in `WimSuenens/agent-plugins`. The session loads the item branch: `claude --plugin-dir <worktree>/plugins/factory` in a separate session; the install stays frozen (ADR 0012).
- **Seeds.** Two abnormalities for AC-7 (kind 1: a brief for a role whose needed input is not in its Inputs needed; kind 3: a role asked to write a file another role owns), and a third case for AC-14 where the quick answer is the model. A seeded event is a real role behaviour but not proof that a spontaneous one would be noticed (AC-7; the resurvey reads real hansei records for that).
- **Who stops the agent in AC-10**: the person, from `/tasks`, at the Lead's prompt.
- **Fixtures** for the criteria QA checks against the branch: a result file; a stage-log table; a `docs/agents/factory.md` with an ownership table and overrides; a scratch git repo for kind 3 ([49-abnormality-list](49-abnormality-list.md) §5.5); the fixture texts of [49-overrides](49-overrides.md) §6.3 and [49-andon-process](49-andon-process.md) §3.4. Each is applied by following the standard's text step by step. QA writes them in `tests/`.
- **Shared resources.** Build and QA: none. Demo: the sandbox repository and its Project #10.

## 7. Every acceptance criterion → contract

| AC | Contract |
|---|---|
| AC-1 | [49-abnormality-list](49-abnormality-list.md) §2, §3 |
| AC-2 | [49-abnormality-list](49-abnormality-list.md) §2 (kind 7), §3; step 9 here §3 |
| AC-3 | [49-abnormality-list](49-abnormality-list.md) §4 |
| AC-4 | [49-abnormality-list](49-abnormality-list.md) §5 |
| AC-5 | [49-abnormality-list](49-abnormality-list.md) §6 |
| AC-6 | [49-andon-process](49-andon-process.md) §1; [49-abnormality-list](49-abnormality-list.md) §3 |
| AC-7 | [49-abnormality-list](49-abnormality-list.md) §2; here §6 |
| AC-8 | [49-andon-process](49-andon-process.md) §2; [49-records](49-records.md) §4 |
| AC-9 | [49-andon-process](49-andon-process.md) §2; here §6 |
| AC-10 | [49-andon-process](49-andon-process.md) §2 step 6; here §6 |
| AC-11 | [49-andon-process](49-andon-process.md) §2; [49-records](49-records.md) §2 |
| AC-12 | [49-andon-process](49-andon-process.md) §3.1 |
| AC-13 | [49-andon-process](49-andon-process.md) §3.2–§3.4 |
| AC-14 | [49-andon-process](49-andon-process.md) §3; here §6 |
| AC-15 | [49-overrides](49-overrides.md) §1, §3, §4; [49-andon-process](49-andon-process.md) §4 |
| AC-16 | [49-overrides](49-overrides.md) §4 |
| AC-17 | [49-overrides](49-overrides.md) §2, §3 |
| AC-18 | [49-overrides](49-overrides.md) §6.1, §6.2 |
| AC-19 | [49-overrides](49-overrides.md) §6.3 |
| AC-20 | [49-overrides](49-overrides.md) §6.2; here §6 |
| AC-21 | [49-overrides](49-overrides.md) §7.1 |
| AC-22 | [49-andon-process](49-andon-process.md) §5 |
| AC-23 | [49-records](49-records.md) §1–§4 |
| AC-24 | [49-records](49-records.md) §5 |
| AC-25 | [49-records](49-records.md) §5.4; here §6 |
| AC-26 | [49-overrides](49-overrides.md) §8 |
| AC-27 | [49-overrides](49-overrides.md) §8.3, §7.2 |
| AC-28 | [49-overrides](49-overrides.md) §8.2; here §6 |
| AC-29 | here §1 |
| AC-30 | here §1 |

No ADR: every decision below is a two-way door. ADR 0011 already records the fence, the expiry and the visibility (the one-way parts); ADR 0012 the release and fingerprint rules; ADR 0013 the merge style that the override-in-worktree rule rests on.

## 8. Decisions (architect, two-way doors)

Chosen / rejected / cost to undo. None overturns one of the product-owner's eight.

1. **Release `1.1.0`, minor.** Rejected: major (nothing that existed stops working: the line is optional, fields are added, the marker versions the record); a patch (standard work changed). Undo: change a string before the tag.
2. **A run is one map, identified by its issue number `#<map>`; `kept … for next run` binds to a map at the run's first worktree.** Rejected: dates (no way to tell two runs of one week apart); a counter kept in the file (one more thing to edit and to forget); binding at keep time (the next map does not exist yet). Undo: a status grammar change; entries are few.
3. **Overrides are written in the worktree that raised the andon; the run close edits the file in a settle worktree with one PR (`settle/<map>`).** Rejected: writing in the main checkout (bypasses the PR the person sees; ADR 0013); a commit straight to main at close (the same, with no merge approval); doing the close inside the last item (the Lead cannot know it is the last until the resurvey). Cost: one extra merge approval at a run close that has overrides. Undo: change step 10.
4. **Run close is step 10, after step 9.** Rejected: renumbering step 9 (the requirement and the feedback text cite "step 9"). Undo: move the paragraph.
5. **`Abnormality:` is directly after `Status:`, optional, repeatable, kind by number or name, ` — `-separated.** Rejected: after `Decisions` (the Lead reads Status/Summary/Decisions first and could miss it); one line per result (a role may see two). Undo: one template line.
6. **Kind 2 is a signature of five slots and two clauses (M1 same guard and same file or trigger; M2 same criterion and field in a later round), with `unclear` when a slot is missing.** Rejected: a free "does this feel the same" (not replayable); matching by file alone (flags control pairs of the same file with another cause); matching by ID or by words (misses L12 = L7 across files). Undo: one rule; its test is the replay.
7. **Kind 3 reads the ownership table: path tokens, longest match, `section` rows skipped.** Rejected: a hard-coded path list (drifts from the table); also checking `work/` message names (not asked, and not in the table). Limit: a docs-writer edit of the `## Overrides` section is invisible to it. Undo: one rule.
8. **The fence check is seven questions of the override's effect; one yes refuses; doubt refuses.** Rejected: wording matches (the fixture overrides are worded as plausible countermeasures); accepting on doubt (a skipped approval cannot be taken back, ADR 0011). Undo: the question table.
9. **The andon comment is `<!-- factory:andon v1 -->`, posted once after the resume, never edited; the override is written first with `andon: pending` and linked after.** Rejected: editing the comment later (a second write, drift); posting before the countermeasure (the comment must carry it). Undo: bump to `v2`.
10. **The `andon` wait ranks last in the overlap order; a close-scan line touching an `andon` wait is that wait; a `TaskStop` marks the transcript truncated (spend `not captured (transcript truncated by andon)`).** Rejected: counting the stop as a `stalled` (it is the Lead's choice); counting spend as complete (the in-flight request may be lost, honesty rule). Undo: a table row.
11. **Kind 6(a) compares with the most recent earlier hansei record of the same release in the project.** Rejected: a table of released fingerprints in the plugin (a second source that itself needs a bump); the tag's tree (the tag exists only in the plugin's repo). Limit: the first item on a release cannot be tested, and says so. Undo: one rule.
12. **No new script.** Rejected: a helper for kind 3 or the 2× test (a tooling change would move the tooling fingerprint and carries its own test burden; the rules are short). Trigger to revisit: the first hit that the Lead misapplies. Undo: add one script.

## 9. Not here

The decision card for `promote` (the A3 slice); the baseline and the before/after numbers; loosening the fence (a card); any automatic detection beyond the Lead reading results and the log; running the new standard on this run's own items (calibration, frozen).
