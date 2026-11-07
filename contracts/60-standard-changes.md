# Contract 60 — Where each change lives, the release, what QA writes, and the map of every criterion

Slice [#60](https://github.com/WimSuenens/agent-plugins/issues/60) · Requirement [60-gemba-sample](../docs/requirements/60-gemba-sample.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md)

The placement contract for the developer, as [57-standard-changes](57-standard-changes.md) was for #57. Wording is the developer's; what each file must say is fixed in [60-gemba-sample](60-gemba-sample.md) (the rule), [60-gemba-walk](60-gemba-walk.md) (the walk) and [60-gemba-line](60-gemba-line.md) (the line and the reading of records).

## 1. Release

- `plugins/factory/.claude-plugin/plugin.json` gets `"version": "1.3.0"` (the developer's edit). Standard work changes, so ADR 0012 gives **minor**; nothing that existed stops working (v3 and v4 records are still read, the new line is additive in a new schema version), so not major. `1.3.0` is the smallest version that passes AC-10.
- `scripts/check-bump.sh` ranks the diff `minor` (it changes `skills/run/SKILL.md` and `references/*.md`) and needs `version` above `1.2.0`: it passes with `1.3.0`. It must pass at *Open PR* and before the merge. `plugin.json` is the only file the bump check requires to move.
- **Fingerprints** (`fingerprint.sh`): **standard** moves (`SKILL.md`, `hansei.md`, `baseline.md`); **tooling** does **not** move, because no file under `hooks/` or `scripts/` changes (§3). If it moves, the developer says why. QA quotes both new values in its verdict.
- **Who tags.** The Lead, at merge, by the existing *Merge PR* step (`factory-v1.3.0` on the merge commit). #60 runs on the frozen install `9147301f75c3`, which has none of that text, so at its merge the Lead performs the steps by hand, as for #57. **[post-merge]** AC-10: `factory-v1.3.0` on the merge commit of `main`; the close of #60 carries no gemba line (the frozen install has no text for it) and creates no `Factory baseline` issue in agent-plugins.
- **Baseline.** The minor bump starts series `1.3`; the first item on 1.3.0 is its first record ([57-baseline](57-baseline.md), not rewritten).
- **No home path, no project data.** Every file the diff adds or changes holds no path that starts at a user's home directory (`~/` is allowed, as in ADR 0013) and no name, number or link from another project than this repository's own issues. Examples in the standard use `example/shop`.

## 2. What changes, file by file

| File | Kind | Change | Contract |
|---|---|---|---|
| `plugins/factory/.claude-plugin/plugin.json` | other | `"version": "1.3.0"` | here §1 |
| `plugins/factory/skills/run/SKILL.md` | standard work | step 8: new **8.3a** (one sentence: do the gemba walk of `references/hansei.md` section 6, after the token totals and before filling the template); 8.4 says the template carries the `gemba` line; the *Done when* of step 8 gains the walk; *Andon* gains one sentence under kind 7 and *Procedure* that an andon raised by the walk takes the rows of [60-gemba-walk](60-gemba-walk.md) §5 (no wait, no stop, no resume, no override); the reading list names section 6 at 8.3a | [60-gemba-walk](60-gemba-walk.md) §1, §5 |
| `plugins/factory/references/hansei.md` | standard work | marker `v5` (Marker, Layout, worked example); *Versions* gains the v5 sentence; *Which versions the standard reads* reads `v3, v4 and v5`; Header fields table gains the `gemba` row with the grammar; Layout gains the line; the worked example gains the line of [60-gemba-line](60-gemba-line.md) §3 (and its release text moves to 1.3.0); section 5 gains item **3a**; **new section 6, *The gemba walk***: the rule, the evidence, the commands, the cap, the comparison, the sentence, the 5 Whys path, the not-captured cases, the one-line *why gemba transfers* | all of 60-gemba-* |
| `plugins/factory/references/baseline.md` | standard work | section 3 item 2 reads `v3`, `v4` and `v5`; item 6 and section 7 take the `records:` line of [60-gemba-line](60-gemba-line.md) §4.4; a new item 7 in section 3 for the v5 gemba-line presence check ([60-gemba-line](60-gemba-line.md) §4.3); `grep -n 'v3 and v4'` for every other mention | [60-gemba-line](60-gemba-line.md) §4 |
| `plugins/factory/references/a3.md`, `protocol.md`, `decision-card.md`, `agents/*.md`, `scripts/*`, `hooks/` | — | **no change** (roles do not walk; the A3 reads no gemba line; no script) | — |

The developer may change **only** the files in this table, under `plugins/factory/`. Outside it: `CONTEXT.md` (architect, done here), `CHANGELOG.md` and `README.md` (docs-writer: the 1.3.0 entry, the unverified list of AC-10, the README text for the line), `docs/factory/reference.md` (docs-writer: an entry for each `60-*` contract, §9), `tests/` (QA).

**The walk is described once.** The whole procedure is in `hansei.md` section 6. `SKILL.md` 8.3a and `hansei.md` section 5 item 3a name the place and point to section 6; neither restates a step. *The 5 Whys* is pointed to, not restated (AC-7): one change to it edits the walk too.

## 3. No script

The bounded read is **text in `hansei.md`** (fenced command blocks with `<placeholders>`), no script, so only the **standard** fingerprint moves and `tooling` is unchanged. Rejected: a `scripts/gemba-view.sh` (moves `tooling`, adds a file the bump check would rank `patch` beside a `minor`, and the requirement lets "no script reads gemba lines" stand either way; a script that only prepares the view would be allowed but gains no property the `head -c` does not already give). Trigger to revisit: the Lead misapplies a command in a real run, or the filter needs a second jq version. This also leaves the ADR 0012 line "whether a change under `hooks/` or `scripts/` resets the baseline" open on the map, as #57 left it.

## 4. No ADR

No one-way door was found. `/wayfinding:reversibility` test on each choice: the record version (a reader skips a version it does not know; a later change is one more bump, v6, and v5 records stay readable), the sample rule (one text rule, no data), the cap (one number), the placement 8.3a (one line moved), the andon reuse (one sentence), the baseline skip rule (a recompute of a derived page). None is costly to reverse, none is a surprise that needs a record beyond this contract, and the real trade-offs are written as Decisions below with what was rejected. ADR 0011 (fence: the gemba line is a record field, not a fenced item and cannot be overridden away because it is part of the record whose layout the fence holds), 0012 (release and fingerprints) and 0013 (merge style, no home paths) bind and are not changed.

## 5. What QA writes in `tests/` (offline, before the replay)

All checks follow the standard's **text** step by step on fixtures QA writes, in the style of the existing `tests/factory/` suites (`lib.sh`; a text check reads the file, a replay check runs the extracted command). QA writes its own expected rows for W12, C49 and L57 **before** reading the author's cross-check in the requirement, and states them in the verdict. The architect has replayed none of them.

| Test | AC | Fixture and check |
|---|---|---|
| T1 sample rule, text | 1 | `hansei.md` section 6 holds the rule: role row, flagged test (`done`/`pass` prefix, `paused by A<digit>`), listing order, `<id> mod n` from 0, the all-role-rows fallback, no role row; no mention of duration, `Waits`, `Peak ctx`, randomness or an earlier record in the rule |
| T2 sample rule, replay | 1 | W12 (13 rows, `hansei.md` section 4), C49 (the #49 comment), L57 (the #57 comment): QA's own expected row each; the fixtures of [60-gemba-sample](60-gemba-sample.md) §2 table (all flagged, one eligible, two rows of a role, `done, then stalled`, `Agents` `-`, lead row, person row, no `Notes` column, log numbered from 0); a second reader who has only the section's text picks the same row on every input. A fixture where the rule would need a measure the log lacks contradicts |
| T3 evidence order | 2 | the walk text names transcript first, then commits and result file; a fixture whose result `Summary` says `done` while the transcript shows otherwise reads as the transcript shows; the text never lets the walk start from `Summary`, the completion notice or the stage summary; the result file is read without `Summary` (run the `awk` on a result fixture: the `Summary:` field and its continuation lines are gone, `Progress` and `Artifacts` stay) |
| T4 comparison | 2, 3 | the walk text names the brief (`Done`, `Constraints`, `Output`) and the row (`Result`, `Notes`, `Waits`) and exactly three things |
| T5 found, three fixtures | 3 | one stage-log row (`done`, no note), a brief of three `Done` items and two `Constraints`; (a) third item untraced while `Summary` claims it → `difference`, one sentence naming the item and a process object; (b) all met → `nothing (3 Done items and 2 constraints checked)`; (c) an edit to a path the role does not own → `difference`. (b) without counts is refused; none is writable from the stage log alone |
| T6 the line | 4 | the template's first line is `<!-- factory:hansei v5 -->`; exactly one `- gemba: ` line, directly after `- stage-log cross-check:` and before `### Measures`; the measures stay seven, numbered 1 to 7, keys and order identical to v4; the grammar of [60-gemba-line](60-gemba-line.md) §2 accepts every row of its §3 table and the worked example, and rejects: a line in the measures, a second gemba line, `found nothing` with no counts, `n` over 29900, `difference` with `changes nothing`, a line holding `;` inside the sentence; the text says why v5 and not a field in v4 |
| T7 not captured | 5 | fixtures (a) transcript deleted, commits and result readable → `read commits and result file`; (b) both unreadable and (d) an id with no transcript and no commits → `row …; not captured (…)`; (c) no role row → `not captured (no role stage ran)`; none reads `found nothing` or a 0; a partial walk reads `partial (cap)`; a partial walk with nothing found reads `found nothing in the part read (<n> chars of <m>)` |
| T8 cap | 6 | extract the command blocks of section 6 and run them on a generated 200,000-character transcript fixture (JSONL of `assistant` and `user` entries with `tool_use` and `tool_result` blocks): the printed total is at most 30000 and `n` at most 29900, the line reads `partial (cap)` and `n` equals `wc -c` of the returned text; a smaller fixture reads the whole view and is not partial; the budget shrinks by the brief's size; no text of section 6 lets one walk exceed 30000 (search for an unbounded `cat`, `gh issue view`, `git log -p` or `jq` without `head -c`); one extra bounded read at most |
| T9 5 Whys | 7 | the text points to `skills/run/SKILL.md` *The 5 Whys* and does not restate its refusal list (no copy of "careless", "too weak" in section 6); fixtures (a) `the developer skipped the third Done item` and (b) `the agent's model is too weak …` are refused by that rule applied to the `found` sentence and the chain, (c) is accepted; a refused line is not written; a `difference` never ends `changes nothing` |
| T10 the andon path | 7, 9 | the walk text and SKILL's kind 7/Procedure sentence put the 5 Whys in a kind 7 andon with no paused agent, no `## Waits` entry, no override, `paused: no agent paused`, the row `Waits` `-`; replay measure 1 on the W12 log plus one such andon row after the approval: `agent working + the five waits = total` still holds and `andon` is unchanged |
| T11 old records | 8 | apply the baseline text (and `tests/factory/baseline_replay.py`, extended for v5 by QA) to v3, v4 and v5 records: the three versions are read, a v3 or v4 record creates no `not captured` entry for a gemba line, a v5 record's measures enter its series like v4's, a v5 record with no gemba line and one with two are `skipped … (gemba line missing)` / `(gemba line repeated)`, the `records:` line reads as [60-gemba-line](60-gemba-line.md) §4.4; every figure on the existing baseline fixtures is identical to before. No test, script or baseline field reads the **content** of a gemba line; no hoshin view, no count of `found nothing` against `difference` exists (search the diff) |
| T12 placement | 9 | `SKILL.md` step 8 has 8.3a after 8.3 and before 8.4, and says it comes after the approval; `hansei.md` section 5 item 3a names the same place; the walk's procedure appears in section 6 only (search for a second description); the *why gemba transfers* line appears once in `plugins/factory/` |
| T13 release and hygiene | 10 | `plugin.json` `1.3.0`; `check-bump.sh` passes; QA quotes both fingerprints (`tooling` unchanged: equal to `1.2.0`'s); the diff against `main` under `plugins/factory/` touches only `SKILL.md`, `references/hansei.md`, `references/baseline.md` and `plugin.json` (no new agent, no script); no absolute home path (a search for a path that starts at a user's home directory on macOS, Linux or Windows; the contract itself spells none of them out so that its own search passes) and no project data in any added or changed file; the changelog's 1.3.0 entry lists the five unverified items as unverified |

**Pins that move.** Tests written for #39 to #57 pin the v4 marker and the two-version reading: `tests/factory/test_standard_text.sh` (lines of `ac14-marker-*`, `ac14-example-marker`), `test_andon_text.sh` (`ac24-marker-v4`), `test_baseline_a3.sh` (the `v4-*` and `r3-*` pins, `o4-*` lines), `test_baseline_replay.sh` and `baseline_replay.py` (readable versions `{3, 4}`, the `records:` line). QA updates them to v5 and keeps a v4 fixture alongside, so the three-version reading is tested. The fingerprint tests (`test_fingerprint.sh`) are expected unchanged.

## 6. Every acceptance criterion → contract

| AC | Contract |
|---|---|
| AC-1 | [60-gemba-sample](60-gemba-sample.md) §1, §2; tests T1, T2 |
| AC-2 | [60-gemba-walk](60-gemba-walk.md) §2, §4; T3, T4 |
| AC-3 | [60-gemba-walk](60-gemba-walk.md) §4; T5 |
| AC-4 | [60-gemba-line](60-gemba-line.md) §1, §2; T6 |
| AC-5 | [60-gemba-walk](60-gemba-walk.md) §6; [60-gemba-line](60-gemba-line.md) §2, §3; T7 |
| AC-6 | [60-gemba-walk](60-gemba-walk.md) §3; T8 |
| AC-7 | [60-gemba-walk](60-gemba-walk.md) §4 (the sentence), §5; T9, T10 |
| AC-8 | [60-gemba-line](60-gemba-line.md) §4; here §3; T11 |
| AC-9 | [60-gemba-walk](60-gemba-walk.md) §1, §7; here §2; T12 |
| AC-10 | here §1, §2, §5 T13; the changelog and README are the docs-writer's |

Worked example of W12 for the author's cross-check only ([60-gemba-line](60-gemba-line.md) §3): the requirement says six eligible rows and row 2; the example record uses that row. QA recomputes.

## 7. Answers to the requirement's open questions for the architect

1. **Line grammar (AC-4):** [60-gemba-line](60-gemba-line.md) §2, with worked lines in §3.
2. **Step number (AC-9):** **8.3a**, `hansei.md` section 5 item **3a**; no renumbering (D1).
3. **Where the 5 Whys of a difference is written (AC-7):** a **kind 7 andon with no paused agent**, as the requirement leaned ([60-gemba-walk](60-gemba-walk.md) §5).
4. **Does an andon at close fit the timing rules:** yes, with **no `andon` wait** and no override. The lead time ended at the approval (8.1); a wait after it would sit outside the total and break the sum. So the row exists (`Abnormalities`, stage log), the wait does not, measure 1 is unchanged, and `Held item` does not arise. Kind 7's "stop the line" is the record of the finding; the line has already stopped at the approval.
5. **Bounded read:** text in `hansei.md` section 6, no script; only the standard fingerprint moves ([60-gemba-walk](60-gemba-walk.md) §3).
6. **Baseline skip list:** `v3`, `v4`, `v5` readable ([60-gemba-line](60-gemba-line.md) §4); `hansei.md` *Which versions the standard reads* the same.
7. **`CONTEXT.md`:** *Gemba* added (this commit).

## 8. Decisions (architect, two-way doors)

Chosen / rejected / cost to undo. None overturns one of the product-owner's ten.

- **D1. The walk is 8.3a, not 8.4 with a renumbering.** Rejected: renumbering 8.4 to 8.12 (cited as 8.4, 8.6, 8.10, 8.11 by the skill, `baseline.md`, `a3.md`, `hansei.md`, the tests, the runbook and the reference; it would edit about twenty places for one insertion); putting the walk inside 8.3 (a different action under one number). Undo: renumber at the next rewrite of the close.
- **D2. Eligibility reads `Result` by prefix, lowercased, and `Notes` for `paused by A<digit>`; order is the log's listing order.** Rejected: sorting by the `#` cell (L57 starts at 0, manual logs skip numbers); an exact match on `done` (`done, then stalled`, `pass (3 medium, 2 low)` are in the logs). Undo: one rule.
- **D3. The 5 Whys of a difference is a kind 7 andon with no wait and no override.** Rejected: a comment of its own (one more marker, one more reader); an andon with a wait (breaks measure 1's sum); an override from the walk (a commit after the approval changes what was approved). Undo: one sentence in *Procedure*.
- **D4. The cap counts everything the walk reads, the brief included; `m` is the brief plus the whole view.** Rejected: capping the evidence only (the brief then sits outside the figure and AC-6 could be broken by a large brief). Undo: one number and one sentence.
- **D5. The reference filter keeps tool calls (name and 300 characters of input), results (first line, 200 characters), and the final reply (1,500 characters) as a *claim*.** Rejected: dropping the final reply (AC-6 keeps it, and it shows claim against call); treating it as evidence (the agent's own report). Undo: edit the filter.
- **D6. The commits fallback and the transcript are all-or-nothing per row.** Rejected: a mix (the line's `read` part could not say one source). Undo: one rule.
- **D7. A row's brief and result file are found by ordinal; its commits by role, subject prefix and the row's `Start` to the role's next row.** Rejected: matching by commit timestamp against the row's `End` (the cross-check records gaps of minutes) and by file name alone (feedback rounds reuse the role). Undo: one rule. A row whose brief is not found reads `not captured (brief not found)`.
- **D8. A `difference` sentence is the first one by brief order; the rest go to the chain's evidence.** Rejected: several differences in the line (one line, comparable lines). Undo: one rule.
- **D9. `changes` is `process item:` when the chain's last item is outside the plugin root, `none: needs a plugin change` when inside.** Rejected: asking the Lead to judge which (two Leads would differ). The plugin-change outcome carries no link (the requirement's grammar), because the `abnormalities` line links the comment. Undo: one rule.
- **D10. The baseline's presence check (one `- gemba: ` line in a v5 record) is not a field read.** Rejected: skipping the check (a v5 record without the line would silently pass, the opposite of AC-4's "malformed"); parsing the line (AC-8). Undo: drop the item 7 of section 3.
- **D11. The `records:` line names every schema the series holds.** Rejected: leaving it at `v3 and v4` (false for v4 plus v5). Undo: one line.
- **D12. `partial (cap)`.** The only reason that stops a walk is the cap; a reason slot that could hold anything else would invite free text. Undo: one grammar line.

## 9. Proposals to other owners (not written here)

- **docs-writer, `docs/factory/reference.md`**: `Fourteen contracts` becomes `Eighteen contracts`; a heading *Contracts added in 1.3.0* (or entries in the existing order) for `60-gemba-sample`, `60-gemba-walk`, `60-gemba-line`, `60-standard-changes`, each with: contract link, what it governs (the first paragraph of each contract), implemented in (`hansei.md` section 6; `SKILL.md` 8.3a; `baseline.md` section 3), and the ACs. The entries for `39-hansei-record` and `57-records-and-overrides` gain `Changed for 1.3.0 by 60-gemba-line §1, §2: the first line is v5 and a header line gemba follows stage-log cross-check`. The entry for `57-baseline` gains `Changed for 1.3.0 by 60-gemba-line §4`.
- **docs-writer, `CHANGELOG.md`**: the 1.3.0 entry with the five unverified items of the requirement, worded as unverified.
- **docs-writer, `README.md`**: the line and the walk in one short paragraph.
