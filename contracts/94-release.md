# Contract 94 — Release 2.3.0: version, changelog, fingerprints, the pins that change, every text that states a changed rule, and the map of every criterion

Slice [#94](https://github.com/WimSuenens/agent-plugins/issues/94) · Requirement [94-lean-extensions](../docs/requirements/94-lean-extensions.md) · Parent map [#93](https://github.com/WimSuenens/agent-plugins/issues/93) · Sister contracts [94-a3-v2](94-a3-v2.md), [94-hansei-lean](94-hansei-lean.md) · Follows the shape of [73-release](73-release.md)

Serves AC-18 and AC-19, and holds the repo-wide search the Done list asks for (§3) and the criterion map (§5).

## Paths

Paths:
- plugins/factory/.claude-plugin/plugin.json
- CHANGELOG.md
- README.md
- docs/factory/reference.md
- docs/factory/release-runbook.md
- tests/factory/
- contracts/94-release.md
shared: plugins/factory/.claude-plugin/plugin.json, CHANGELOG.md

`plugin.json` is the developer's (the `version` line only). `CHANGELOG.md`, `README.md`, `docs/factory/reference.md` and `docs/factory/release-runbook.md` are the docs-writer's. The three contracts are the architect's. `tests/factory/` is QA's. The ADR number is **not** on the `shared:` line: this slice adds no ADR (§4).

## 1. Version and fingerprints (AC-19; open question 6)

- `plugins/factory/.claude-plugin/plugin.json` `version`: `2.2.0` becomes **`2.3.0`**, confirmed. `check-bump.sh` classifies the change as standard work (it edits `skills/run/SKILL.md` and `references/*.md`), which needs a minor bump above main's `2.2.0`; the change adds lines and a script and removes no rule, so no major (no project has to migrate: A3 v1 comments, v3 to v5 records, 2.2.0 ledgers and overrides all stay valid). `factory-state` stays at 2.
- **Fingerprints.** `standard` moves (SKILL.md and references change). `tooling` moves as well: `scripts/a3-check.sh` is new, and `fingerprint.sh` counts `scripts/` in the tooling fingerprint. Both are recomputed for the release by `bash plugins/factory/scripts/fingerprint.sh plugins/factory` (the runbook's *Release checks*, step 5, followed as written); the values are noted in the changelog entry's last line, never invented, and any later change under 2.3.0 is a forgotten bump (andon kind 6).
- The developer touches the version line **after** rebasing on `main`, as the run skill says for `shared:` entries. `docs/factory/release-runbook.md` gets a short `2.3.0` note in its style (what changes, what does not: no migration, A3 v1 and records v3 to v5 are read as before, a 2.2.0 install ignores the new lines and cannot read a v2 A3 — it skips the comment and says so, which is the 2.2.0 behaviour for an unknown version; nothing to roll back in a project).

## 2. The changelog entry (AC-19)

`## factory 2.3.0 (#94)` above the 2.2.0 entry, in its form: release line (`Release: \`2.3.0\``, a **minor** release, no migration, restart sessions), slice and map links, the three contracts, and a bullet each for the four changes:

1. **#87 waste tags.** An optional `waste:` tag (the eight TIMWOODS names) on andon comments (a last line), ledger Waits (`What`) and Tasks (`Notes`) rows, and `## Findings` rows (a sixth column); the A3's `waste` line is the count per type with the untagged count; the tagging guide is in `references/hansei.md`.
2. **#88 flow efficiency and the per-stage view.** Two derived sub-lines under measure 1 of the hansei record; the record stays v5; nothing is added to the baseline or the A3 measure table.
3. **#89 the target.** An optional `target:` line on the run's experiment, never edited; the A3's `target` line reads reached, not reached or `none (<reason>)`; the settle line shows before, target and after.
4. **#90 the targeted walk.** One walk per run at the problem's stage before the A3's chain; the A3's `gemba (targeted)` line; the chain cites it.
5. **A3 v2** (`<!-- factory:a3 v2 -->`) carries the three lines; v1 stays valid; the new script `a3-check.sh` checks both versions.

Then, in the form of the earlier entries: **Tests** (the pinned version rows move to 2.3.0, new offline checks for AC-1 to AC-17, the `a3-check.sh` fixtures) and **Unverified** (what only a live run shows, from the requirement's *Unverified* section: tag consistency, whether the targeted walk finds anything, whether the Pareto changes which improvement the person picks; nothing ran in a live factory session). The entry's last line holds the two fingerprints.

## 3. Every text that states a changed rule (the repo-wide search)

Done with `grep -rn` over the repo (not `work/`, not `reviews/`). `E` = edited by this slice; `—` = states it generically and stays; `QA` = a test pin QA changes.

| Rule, name or figure | Where it is stated | Action |
|---|---|---|
| The A3 marker `<!-- factory:a3 v1 -->` and "fixed lines" | `plugins/factory/references/a3.md` sections 1, 2, 3 (E); `README.md` line 158 (E, docs-writer); `docs/factory/reference.md` line 84 (E, docs-writer); `CHANGELOG.md` line 186 (history, —); `docs/factory/release-runbook.md` lines 199, 202 (history of 1.2.0, —; 2.3.0 gets its own note); `contracts/57-a3.md` (history, —); tests `test_baseline_a3.sh` `ac16-*` (QA) | edit as in [94-a3-v2](94-a3-v2.md) §2 |
| *Find A3*, *Find A3s*, *Post A3*, *Edit A3* | `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` lines 43 to 46 and `docs/agents/issue-tracker.md` lines 83 to 86 | **no change**: the finder matches `v[0-9]+`; `Edit A3` "changes only the lines named in `references/a3.md`" |
| The A3 check ("Do not post an A3 whose `before`, `after` or `change` line is blank…") | `references/a3.md` section 9 (E); `SKILL.md` step 9.2 (E); test `ac17-check-before-post` (the sentence stays word for word, so no change) | script added, sentence kept |
| The reasons after `none (…)` (the six, "the same reason on all five") | `references/a3.md` section 2 table (E); tests `ac16-reason-*` (the six rows stay) | heading sentence now "all six", rows added |
| The experiment's lines ("eight more lines after `fence check`", the format block) | `SKILL.md` *Overrides* (E); `references/a3.md` section 5 "The experiment's lines" (E); test `ac12-skill-eight-lines` and the `EXPB` block cut (QA) | optional `target` after `direction`; substring kept |
| "never edited except `a3`" | `SKILL.md` *Overrides*, `a3.md` section 5 | named for `target` as well (E) |
| The settle line | `SKILL.md` *Settle round* item 1, lines 566 and 567 (E); `SKILL.md` step 9.3 text (E); `README.md` line 174 (—); `docs/factory/reference.md` line 98 (E, docs-writer); tests `ac23-experiment-line`, `ac23-other-line` in `test_baseline_a3.sh` and `ac26-one-line-experiment`, `ac26-one-line-other` in `test_andon_text.sh` (QA) | [94-a3-v2](94-a3-v2.md) §7 |
| The 5 Whys evidence alternatives | `SKILL.md` *The 5 Whys* (E) | `gemba <stage> #<item> row <#>` added |
| The gemba walk (sample rule, one walk per item, "never starts a second walk") | `references/hansei.md` section 6 (E: new subsection, and the sentence "The Lead never starts a second walk of another stage" gains "of the item; the run's targeted walk, `The targeted walk`, is separate"); `SKILL.md` step 8.3a (—); `references/baseline.md` section 3 item 7 (E); tests `v5-a3-md-has-no-gemba`, `v5-no-found-nothing-count-in-baseline-or-a3` (QA) | [94-a3-v2](94-a3-v2.md) §5 and §8 |
| Measure 1, lead time, agent working | `references/hansei.md` section 3 Measures row 1 (E: Source sentence), Layout (E: two sub-lines); `references/baseline.md` section 4 (—, unchanged); `docs/factory/reference.md` line 14 (—) | [94-hansei-lean](94-hansei-lean.md) §5 |
| The hansei record's "Fixed lines, fixed order" and the versions paragraph | `references/hansei.md` section 3 (E) | release note added to the versions paragraph |
| `## Findings` columns | `references/hansei.md` section 1 (E); `SKILL.md` *Detection* kind 2 (E); `docs/factory/reference.md` line 63 (—) | optional sixth column |
| The andon comment's fixed lines | `SKILL.md` *The comment* (E); tests in `test_andon_text.sh` that cut the template block (QA) | optional last line |
| The plugin version `2.2.0` | `plugin.json` (E); `CHANGELOG.md` line 5 (history, —); tests listed in §4 (QA) | `2.3.0` |
| The A3 reading `answer` lines | `references/baseline.md` lines 115, 118 (E: v1 or v2 sentence) | [94-a3-v2](94-a3-v2.md) §8 |

No other plugin is touched. `docs/requirements/94-lean-extensions.md` is the product-owner's and is unchanged.

## 4. ADR: none, and why

The test is hard to reverse, surprising without context, and a real trade-off. Every door here is a text edit of the standard plus its fixtures, reversed by a later release at the price of one edit: the three new keys and their place in the A3 (a v3 marker would carry a change), the tag vocabulary (a ninth type is an addition), the two sub-lines on the record (stop writing them), the percent rounding, the minute rule, the settle line. The one choice that looks weighty — adding two lines to a stored record without a version bump — is a two-way door because **no reader reads them**, and the trigger that reopens it is named: **#92** (flow efficiency as a baseline or A3 measure field) is the first reader of the sub-lines, and its slice moves the record to v6 if it needs a guarantee that the sub-lines are present. Recorded in the result's Decisions, not in `docs/adr/`.

## 5. Tests that pin the version, and the criterion map (AC-18)

**Pinned to `2.2.0`, QA moves to `2.3.0`** (found with `grep -rn "2\.2\.0" tests/`): `test_andon_text.sh:421` (`ac29-version-is-minor-above-1.1.0`), `test_gemba.sh:558` (`t13-plugin-json-2.2.0`), `test_standard_text.sh:20,21` (`ac1-plugin-version`, `ac1-version-own-line`), `test_ownership_tdd.sh:232,233` (`rel-plugin-json-version`, `rel-version-own-line`), `test_fingerprint.sh:29 to 36` (the copy named `.../factory/2.2.0` and the `release: 2.2.0` lines; the name of the scratch copy may stay, the expected release line must equal `plugin.json`) and line 95 (`2.2.1` patch fixture: becomes `2.3.1`), `test_release64.sh:16` (a retired skip, no change). The 2.2.0 skips for the 2.0.0 to 2.1.0 delta rows stay as they are.

| AC | Contract | Test, offline |
|---|---|---|
| AC-1, AC-2 | [94-a3-v2](94-a3-v2.md) §2, §3, §4, §6 | `a3-check.sh` fixtures |
| AC-3 | [94-a3-v2](94-a3-v2.md) §3.1 | replay of the count rule |
| AC-4, AC-5 | [94-hansei-lean](94-hansei-lean.md) §1 | 2.2.0 fixtures unchanged; text pins on the guide |
| AC-6, AC-7 | [94-hansei-lean](94-hansei-lean.md) §3, §4, §6 | replay of the minute and percent rules on §6.1 to §6.4 |
| AC-8, AC-9 | [94-hansei-lean](94-hansei-lean.md) §5 | marker pin `v5`; baseline replay unchanged |
| AC-10, AC-11, AC-12 | [94-a3-v2](94-a3-v2.md) §3.2, §7 | text pins; the four comparison cases |
| AC-13, AC-14 | [94-a3-v2](94-a3-v2.md) §3.3, §5 | text pins; `a3-check.sh` on the cite and no-walk lines |
| AC-15, AC-16, AC-17 | [94-a3-v2](94-a3-v2.md) §6, §8 | `a3-check.sh` on v1 and v2; text pins |
| AC-18 | this contract §5 | `bash tests/run.sh` prints `ALL PASSED` |
| AC-19 | this contract §1, §2 | `plugin.json` is `2.3.0`; the changelog entry names the four changes; `check-bump.sh` exits 0 from `2.2.0`; `fingerprint.sh` prints `release: 2.3.0` |

Every one of the 19 criteria maps to a contract above. No acceptance criterion maps to an ADR (§4).
