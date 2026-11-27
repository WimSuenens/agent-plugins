# Contract 286 — Release 3.10.0: version, changelog, fingerprints, the pins that move, every text that states a changed rule, and the map of every criterion

Slice [#286](https://github.com/WimSuenens/agent-plugins/issues/286) · Requirement [286-run-level-timing](../docs/requirements/286-run-level-timing.md) · Map [#278](https://github.com/WimSuenens/agent-plugins/issues/278) · Sister contracts [286-run-timing](286-run-timing.md), [286-a3-v4-and-runs](286-a3-v4-and-runs.md) · Follows the shape of [94-release](94-release.md)

## Paths

Paths:
- plugins/factory/.claude-plugin/plugin.json
- CHANGELOG.md
- README.md
- docs/factory/reference.md
- docs/factory/release-runbook.md
- tests/factory/
- contracts/286-release.md
shared: plugins/factory/.claude-plugin/plugin.json, CHANGELOG.md

`plugin.json` is the developer's (the `version` line only). `CHANGELOG.md`, `README.md`, `docs/factory/reference.md` and `docs/factory/release-runbook.md` are the docs-writer's. `tests/factory/` is QA's. The ADR number is not on the `shared:` line: this slice adds no ADR (its one-way doors are ADRs 0024 to 0026, already on main). `CONTEXT.md` is shared through [286-run-timing](286-run-timing.md).

## 1. Release class and version

The lead ran the release-class check on the expected paths before the brief; its answer line, quoted:

> `needs: minor bump (standard work), 3.9.1 -> 3.10.0`

- `plugins/factory/.claude-plugin/plugin.json` `version`: `3.9.1` becomes **`3.10.0`**. The slice changes `skills/run/SKILL.md` and `references/*.md` (standard work, a minor bump). No major: no project has to migrate (records, ledgers, overrides, v1 to v3 A3s and the baseline marker `v1` stay valid; an open run section without the new lines closes with `run timing: not captured (…)`). `factory-state` stays 2.
- A new minor starts **series 3.10** in every baseline (`baseline.md` section 6); the before-reading of the map is the first run started on 3.10.0 (Q1, the lead's answer).
- **Fingerprints.** `standard` moves (SKILL.md and references); `tooling` moves (`scripts/a3-check.sh`, `scripts/run-state.sh` change; `scripts/run-timing.sh` is new). Both are recomputed by `bash plugins/factory/scripts/fingerprint.sh plugins/factory` after the last change and written in the changelog entry's last line, never invented.
- The developer changes the version line after rebasing on `main`, as for every `shared:` entry.

## 2. Docs (docs-writer)

- **`CHANGELOG.md`**: `## factory 3.10.0 (#286)` above the 3.9.1 entry, in its form (`Release:` line, a minor release, no migration, restart sessions), the slice and map links, the three contracts, and bullets: the run's timing is always on (ADR 0024); the Factory run section gains `lead sessions` and the `### Run waits` table, with `run-state.sh add-session`, `add-run-wait`, `lead-sessions`; the new `scripts/run-timing.sh` (`gaps`, `line`); A3 v4 with its four lines and `a3-check.sh` v4; the baseline's Runs section. Then **Tests**, and **Unverified** (what only the post-merge run shows: AC-C6, the before-reading; whether `${CLAUDE_SESSION_ID}` substitutes in the person's Claude Code, if the runtime proof could not show it). Last line: the two fingerprints.
- **`docs/factory/release-runbook.md`**: a short 3.10.0 note: no migration; a run already open when 3.10.0 is installed closes with `run timing: not captured (run section has no Run waits table)` and is named, not counted, in Runs; a 3.9.x session that reads a v4 A3 skips it as an unknown version (the old rule), so it does not see that A3's `answer` line: settle a run under the release that posted its A3.
- **`README.md`** line 177 and **`docs/factory/reference.md`** line 84 state the A3's marker (`v2`; both are already behind, v3 shipped in 2.18.0): each says the A3 posted is v4 from 3.10.0, and v1 to v3 are still read. Nothing else in either file is required.

## 3. Test pins that move (QA)

Found by `grep -rn` over `tests/factory/` for each sentence and string this slice changes. QA moves each; the developer touches none.

| Test | Check | Now | After |
|---|---|---|---|
| `test_slice6_text.sh:57` | `version-3-9-1` | `"version": "3.9.1"` | `"version": "3.10.0"` |
| `test_a3_check.sh:48` | `marker-v4-skipped` | `v4` → exit 3 | `v4` is known; the skipped case becomes `v5` (AC-C1) |
| `test_baseline_a3.sh:155` | `ac16-marker-prose-is-the-posted-version` | `` exactly `<!-- factory:a3 v3 -->`. `` | the v4 marker sentence of a3.md section 1 |
| `test_lean_rules.sh:158`, `test_slice2_loop.sh:194` | baseline reads A3 markers | `an A3 of marker v1, v2 or v3 is read; …` | `an A3 of marker v1, v2, v3 or v4 is read; any other version is skipped and named` |
| `test_slice2_loop.sh:197` | `review-a3-section9-v3` | `` …and prints `ok v1`, `ok v2` or `ok v3` `` | the section 9 sentence with v4 |
| `test_slice2_loop.sh:198` | `review-a3-section9-skipped` | `for a marker that is not v1, v2 or v3 (exit 3)` | `… not v1, v2, v3 or v4 (exit 3)` |
| `test_slice2_loop.sh:199` | `review-a3check-header-skipped` | `a version not 1, 2 or 3` | `a version not 1, 2, 3 or 4` |
| `test_slice3_table.sh` | `run-size-cap` | router plus references ≤ 158,000 bytes (156,445 today) | raised by the slice's real growth, with the comment extended as before |

Pins that must **not** move (the developer keeps the text): `test_run_split.sh` `e1-router-at-most-70000` (SKILL.md ≤ 70,000 bytes; 65,898 today); `test_standard_text.sh:102` (the *Cut-offs at close* item 1 sentence); `test_slice2_loop.sh:196` and `:200` (the v3 phrases of a3.md); `test_lead_gaps_230.sh` (`run-state.sh start` checks: `started:`, `step: 0`, `in flight: none`, `FREEZE: none yet`, `previous run:`, `closed in this run: none`, the rest of the body kept, exit 8); `test_slice4_text.sh:46`; `test_board_status.sh` *AC-8* (the Factory run template: no status word in it, its `in flight`, `FREEZE`, `step` lines); `test_a3_check.sh:32–33` (the worked examples of a3.md section 3 are the v2 and v1 ones, unchanged).

## 4. Every text that states a changed rule

**Search terms** (each run as `grep -rnF` over the repository, `--exclude-dir` `worktrees`, `node_modules`, `.git`, `work`, `.nuxt`, `.output`; contracts and requirements of earlier slices are history and stay as they are):
`factory:a3 v3`, `ok v3`, `v1, v2 or v3`, `v1, v2 and v3`, `not v1, v2 or v3`, `not 1, 2 or 3`, `` `1`, `2` and `3` ``, `A3 posted is v3`, `v3 A3`, `a3 v4`, `known versions`, `3.9.1`, `3.9`, `the same \`started\``, `` `started:` now (UTC) ``, `started: <UTC time`, `Run waits`, `run waits`, `lead sessions`, `computed from hansei records`, `pure function of the records`, `No script computes a figure`, `Runs section`, `whole-run`, `run timing`, `discipline: off`. Figures were searched in digit form; the version has no word form. The partial-statement case (a text naming three A3 versions where there are now four) is covered by the `v1, v2 or v3`, `not 1, 2 or 3`, `` `1`, `2` and `3` `` and `v3 A3` terms.

**Stale texts found**, each changed in this slice (path and who):

| Text | Says now | Changed by | Contract |
|---|---|---|---|
| `plugins/factory/references/a3.md:10` | posted marker v3; known versions 1, 2, 3 | developer | [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §5 |
| `plugins/factory/references/a3.md:13` | `when its marker is v2 or v3` | developer | idem §5 |
| `plugins/factory/references/a3.md:74` | `A v3 A3 may also carry … calibration experiments` | developer | idem §5 |
| `plugins/factory/references/a3.md:300` (section 9) | `ok v1`, `ok v2` or `ok v3`; not v1, v2 or v3 | developer | idem §5 |
| `plugins/factory/references/a3.md:357` | `In a v3 A3, after not detectable` | developer | idem §5 |
| `plugins/factory/references/baseline.md:10` | figures computed from hansei records only | developer | idem §4.4 |
| `plugins/factory/references/baseline.md:128` | `an A3 of marker v1, v2 or v3 is read` | developer | idem §4.4 |
| `plugins/factory/references/baseline.md:226` | pure function of records, answer lines, statuses, release | developer | idem §4.4 |
| `plugins/factory/references/run-close-run.md:11` | `The A3 posted is v3` | developer | idem §5; [286-run-timing](286-run-timing.md) §5.2 |
| `plugins/factory/scripts/a3-check.sh:2,5,6` | v2 or v3; `ok v3`; `a version not 1, 2 or 3` | developer | [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §3 |
| `plugins/factory/scripts/run-state.sh:16` | the lines `start` writes | developer | [286-run-timing](286-run-timing.md) §2.1 |
| `plugins/factory/skills/run/SKILL.md:112` | the Factory run template without `lead sessions` and the table | developer | idem §1.1, §5.3 |
| `plugins/factory/references/run-overrides.md:60` | the new section's lines | developer | idem §5.4 |
| `plugins/factory/references/run-route.md:61` | `the same \`started\`, \`closed in this run\` and \`baseline\`` | developer | idem §5.5 |
| `plugins/factory/.claude-plugin/plugin.json:3` | `3.9.1` | developer | §1 |
| `CONTEXT.md:130, 132, 134` | in flight undefined; Lead gaps during items; Runs figures all medians | architect (this stage) | [286-run-timing](286-run-timing.md) §8 |
| `README.md:177`, `docs/factory/reference.md:84` | A3 marker v2 | docs-writer | §2 |
| tests listed in §3 | old versions and markers | qa-engineer | §3 |

Not stale (they name the old versions as history and stay): `CHANGELOG.md` entries of earlier releases, `tests/factory/fixtures/split/run-skill-3.0.0.md` (a frozen copy), the `v3-ok.md` fixture (a v3 A3 stays valid), `plugins/factory/references/hansei.md:29, 38, 141, 484` and `skills/setup-factory-skill/SKILL.md:186` (the item label's `lead sessions`, a different line with the same name, unchanged).

## 5. Every criterion to a contract or an ADR

| AC | Contract and section | ADR |
|---|---|---|
| A1 | [286-run-timing](286-run-timing.md) §1, §5; [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §2, §3 | 0024 |
| A2 | [286-run-timing](286-run-timing.md) §0 *Always on*, §5.1 item 1 | 0024 |
| B1 | [286-run-timing](286-run-timing.md) §1.2, §2.1, §2.2 | 0025 |
| B2 | [286-run-timing](286-run-timing.md) §4.4; [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §2.1, §3, §4.2 | 0025 |
| B3 | [286-run-timing](286-run-timing.md) §1.1, §2.3 | 0025 |
| B4 | [286-run-timing](286-run-timing.md) §5.1 item 3, §5.2 (9.0), §5.3 | 0025 |
| B5 | [286-run-timing](286-run-timing.md) §3, §2.3, §5.2 b–c | 0025 |
| B6 | [286-run-timing](286-run-timing.md) §4.3, §4.6 | 0025 |
| B7 | [286-run-timing](286-run-timing.md) §4.3 | 0025 |
| C1 | [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §2, §3 | 0026 |
| C2 | [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §2 (sections 4–7 unchanged), §3 | 0026 |
| C3 | [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §0, §4.1, §4.2 | 0026 |
| C4 | [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §4.2 | 0026 |
| C5 | [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §1, §4.4 | 0026 |
| C6 | [286-a3-v4-and-runs](286-a3-v4-and-runs.md) §4.3; [286-run-timing](286-run-timing.md) §0 Q2 | 0025, 0026 |

## 6. Non-functional targets

- **bash 3.2**: `run-timing.sh` starts `#!/bin/bash`, uses no `mapfile`, `declare -A`, `${v,,}`, `&>>`, `;&`, and writes `${arr[@]+"${arr[@]}"}` for a possibly empty array under `set -u`. Time arithmetic is done in `awk` from the digits (days from the civil date), never with `date -d` or `date -j` (they differ between GNU and BSD). The CI check `factory tests (macos)` runs the suite under `/bin/bash`.
- **No new dependency**: `run-timing.sh` needs only `awk`, `sed`, `grep`; it does not call `jq` (the run-close scan's `jq` need is `cut-offs.sh`'s, as today).
- **Pure function**: the same body, ledgers, close instant and flags give the same bytes; no clock is read.
- **No data leaves the project**: neither script calls the network or `gh`; the Lead posts with the project's own tracker operations; no command names `--repo`.
