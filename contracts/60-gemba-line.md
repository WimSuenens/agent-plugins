# Contract 60 — The gemba line, hansei schema v5, and how old and new records are read

Slice [#60](https://github.com/WimSuenens/agent-plugins/issues/60) · Requirement [60-gemba-sample](../docs/requirements/60-gemba-sample.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) · Changes [39-hansei-record](39-hansei-record.md) §1 and [57-records-and-overrides](57-records-and-overrides.md) §1; builds on [57-baseline](57-baseline.md) §3

Serves AC-4, AC-5, AC-8. Where the walk is done: [60-gemba-walk](60-gemba-walk.md); which row: [60-gemba-sample](60-gemba-sample.md).

## 1. The marker and the version

The first line is exactly `<!-- factory:hansei v5 -->`. The marker's regex (`^<!-- factory:hansei v([0-9]+) -->$`) is unchanged.

**Why v5 and not a field inside v4.** `hansei.md` *Marker* bumps the version on any change to a field's key or order. A new header key is such a change, and a v4 reader meeting an unknown key would read a record it does not fully understand instead of skipping and saying so. v5 makes that reader skip the record and name it. `hansei.md`'s *Versions* paragraph gains: `v5 (release 1.3.0) adds a header line gemba after stage-log cross-check; no measure changes, so v3, v4 and v5 measures may be compared.` The measures stay seven, numbered 1 to 7, with their keys, order and grammar unchanged.

**Which versions the standard reads.** `v3, v4 and v5.` (The paragraph in `hansei.md` and the baseline's skip list both change; §4.)

## 2. The line

Placed in the header block **directly after `stage-log cross-check` and before `### Measures`**. Always present, exactly once, one line. Key `gemba`, written `- gemba: <walk>` like every header line.

```
- stage-log cross-check: largest gap <N>m (<row>: <evidence>)
- gemba: <walk>

### Measures
```

Grammar (fixed words in `code`; `;` followed by a space separates the parts; no part holds `;` or a newline):

```
walk     := "not captured (no role stage ran)"
          | row "; not captured (" reason ")"
          | row "; read " source " " n " chars" [ ", partial (cap)" ] "; found " found "; changes " changes
row      := "row " # " " stage " (" role [ ", already flagged: " first-word-of-Result ] ")"
source   := "transcript" | "commits and result file"
found    := "nothing (" d " Done items and " c " constraints checked)"
          | "nothing in the part read (" n " chars of " m ")"
          | "difference: " sentence
changes  := "nothing" | "process item: " item " (" url ")" | "none: needs a plugin change"
```

- `#` and `stage` are the row's cells as the log writes them (`row 9 Build (round 2) (developer)`). `role` is the row's `Role`. `first-word-of-Result` is the first word of the row's `Result` (or `paused by A<n>`), only when the row came from the all-role-rows fallback ([60-gemba-sample](60-gemba-sample.md) §1 step 4).
- `n`, `m`, `d`, `c`: plain integers. `n` is the total characters the walk read (`wc -c`, brief included) and is at most 30000; `m` is the brief's characters plus the whole view's. `partial (cap)` is written if and only if `n < m` for a walk that read evidence; `found nothing in the part read` is written if and only if the walk is partial and found nothing.
- `reason`: short, at most 80 characters, no home path, no transcript text.
- `sentence`: [60-gemba-walk](60-gemba-walk.md) §4. `item`: the chain's `process item to change`, one line. `url`: the Andon comment's URL.
- **Consistency.** `found difference` goes with `changes process item: …` or `changes none: needs a plugin change`, never `nothing`; `found nothing…` goes with `changes nothing`. `found` or `changes` that names a person, a role's care or competence, or a model with no process item is never written ([60-gemba-walk](60-gemba-walk.md) §5).
- The line holds no transcript text, no 5 Whys text and no raw record text; the chain lives in the andon comment, which the `abnormalities` line also links.
- **Not a measure.** The line is a header line; `n` is a label on it, enters no measure and no baseline section. The honesty rule holds: a walk not done reads `not captured (…)`, never `found nothing`, never 0.

## 3. Worked examples

A record header (item #12 of `hansei.md`'s worked example; W12 picks row 2, [60-standard-changes](60-standard-changes.md) §6):

```
<!-- factory:hansei v5 -->
## Hansei: #12 Export a report as CSV

- series: release
- plugin: factory 1.3.0
- standard: 3c0f8a2e5b7d4619a8c3e1f50b7d2a4c6e9f1b3d5a7c9e0f2b4d6a8c1e3f5b7d
- tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652
- context: wayfinding 5a136f2eaa0a; mattpocock-skills 1.3.1
- active overrides: replay-before-build (since 2026-11-04; from 2026-11-04T15:11Z)
- abnormalities: 2 (same-finding-twice 1, role-outside-role 1): A1 https://github.com/example/shop/issues/12#issuecomment-111; A2 https://github.com/example/shop/issues/12#issuecomment-222
- stage-log cross-check: largest gap 6m (Build: last developer commit 14:52Z after logged end 14:46Z)
- gemba: row 2 Requirement (product-owner); read transcript 18342 chars; found nothing (4 Done items and 3 constraints checked); changes nothing

### Measures
```

The other forms (each one line):

| Case | Line |
|---|---|
| difference, local item | `- gemba: row 4 Build (developer); read transcript 22720 chars; found difference: Done item 3 has no trace in the calls or the commit diffs, process object: the brief; changes process item: the brief named no output path for Done item 3 (https://github.com/example/shop/issues/14#issuecomment-333)` |
| difference, in the plugin's text | `- gemba: row 6 QA (qa-engineer); read commits and result file 9120 chars; found difference: the row's Result says pass while the commit diffs add a test that is not run, process object: standard text; changes none: needs a plugin change` |
| fallback to commits, nothing found | `- gemba: row 3 Contracts and ADRs (architect); read commits and result file 4410 chars; found nothing (5 Done items and 2 constraints checked); changes nothing` |
| cap hit, nothing found | `- gemba: row 4 Build (developer); read transcript 30000 chars, partial (cap); found nothing in the part read (30000 chars of 201240); changes nothing` |
| all rows flagged | `- gemba: row 5 QA (qa-engineer, already flagged: findings); read transcript 12010 chars; found nothing (2 Done items and 1 constraints checked); changes nothing` |
| not done | `- gemba: row 4 Build (developer); not captured (transcript and commits unreadable)` |
| no role row | `- gemba: not captured (no role stage ran)` |

A line that is **refused** and never written: `found difference: the developer skipped the third Done item` (names an actor; chain ending `the developer should have checked`); `found difference: the agent's model is too weak to follow a three-item brief` (names a model; countermeasure a model swap). Accepted: `found difference: Done item 3 named no output path, process object: the brief`, chain ending `process item to change: the brief template lists no output path per Done item`.

## 4. Reading records (AC-8)

Both places change; the figures do not.

1. **`hansei.md` *Which versions the standard reads*:** `v3, v4 and v5.` A v3 or v4 record has no gemba line and is read without one; **no `not captured` entry is created** for it. A v5 record's measures enter the series of its release exactly as v4's do.
2. **`references/baseline.md` section 3 item 2 (Version):** `v3`, `v4` and `v5` are readable; any other version is `skipped: #<id> <url> (schema v<n>)` as before.
3. **A v5 record is malformed** when the header block has not exactly one line starting `- gemba: `. The baseline reads it as unreadable, skips it whole and names it: `skipped: #<id> <url> (gemba line missing)` for none, `skipped: #<id> <url> (gemba line repeated)` for two or more. The check counts lines that start `- gemba: ` and never reads their content: **no baseline or A3 field reads, parses or counts the content of a gemba line**, and no script is added. (The test replay in `tests/` reproduces this presence check only; the same rule.)
4. **The optional `- records:` line** of a series block (section 7 of `baseline.md`) names the schemas the series holds, in ascending order, when it holds more than one: `schema v3 and v4 read together` (unchanged), `schema v4 and v5 read together`, `schema v3, v4 and v5 read together`. A series of one schema carries no such line (unchanged).
5. **Unchanged:** the seven measures, their medians, the sections, the series test, the standard test (a different `standard` under the same `M.N` still excludes), the A3 (it reads no gemba line, and its `standard changes proposed` and `other problems seen` already list kind 7 abnormalities, which is how a walk's andon reaches the person at the run close).
6. **Not added:** a view of gemba lines over items or runs, a count of `found nothing` against `difference`, a hoshin view, an eighth measure.

## 5. The characters-read figure

`n` is a label of the line, not a measure. It is the observable for the deferred observer subagent: its trigger is the Lead's context running out during a walk, and the first line that reads `partial` is where to look. No standard text computes anything over it.
