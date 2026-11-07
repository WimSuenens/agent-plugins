# Contract 60 — Picking the stage to walk

Slice [#60](https://github.com/WimSuenens/agent-plugins/issues/60) · Requirement [60-gemba-sample](../docs/requirements/60-gemba-sample.md) · ADRs [0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md), [0013](../docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md) · Builds on [39-stage-log](39-stage-log.md), [57-run-close](57-run-close.md)

Serves AC-1. The rule below is the whole rule: it reads the stage log and the item's id, nothing else. Wording is the developer's; every term, test and tie-break here must be in `references/hansei.md` (new section 6, *The gemba walk*), once. Where it sits and how the line reads: [60-gemba-line](60-gemba-line.md), [60-standard-changes](60-standard-changes.md).

## 1. The rule

Input: the stage log (`## Stage log` of the lead state, or a manual log of the same shape) and `<id>`, the slice ticket's number.

1. **Role row.** A row whose `Role` is one of `product-owner`, `architect`, `developer`, `qa-engineer`, `security-reviewer`, `devops`, `docs-writer`, and whose `Agents` cell is not `-`.
2. **Flagged.** A row is flagged when its `Result`, trimmed and lowercased, does **not** start with `done` or `pass`, or its `Notes` contain `paused by A` followed by a digit. (`findings`, `blocked`, `refused`, `needs-decision`, `block`, `approved`, anything else: flagged. `done, then stalled` and `pass (3 medium, 2 low)`: not flagged.) A log with no `Notes` column has no row paused by an andon; a log with no `Result` column has no eligible row (go to step 4).
3. **Eligible rows.** The role rows that are not flagged, **in the order the log lists them** (not sorted by the `#` cell; a log may start its `#` at 0 or skip numbers). Let `n` be their count.
4. **Pick.**
   - `n >= 1`: the sampled row is the eligible row at index `<id> mod n`, counting from 0 (integer remainder; `n = 1` always gives index 0).
   - `n = 0` and the log has role rows: the eligible set is **every role row**; apply the same index to it, with `n` its count. The line marks the row `already flagged` (grammar: [60-gemba-line](60-gemba-line.md) §2).
   - the log has no role row: no stage is picked; the line reads `not captured (no role stage ran)`.
5. **Nothing else.** No duration, no `Waits`, no `Peak ctx`, no judgement, no earlier record, no random choice. A row's `#` in the line is the log's `#` cell, or its position counted from 0 when the log has no `#` column.

Two rows of one role (a feedback round) are two rows. A row of one stage with several agents (`Agents` `a1c9e2, b7d031`) is one row.

## 2. Worked example (a fictional item #14)

```
| # | Stage              | Role          | Agents | Result   | Notes          |
|---|--------------------|---------------|--------|----------|----------------|
| 1 | Start item         | lead          | -      | done     |                |
| 2 | Requirement        | product-owner | a1c9e2 | done     |                |
| 3 | Contracts and ADRs | architect     | b7d031 | done     |                |
| 4 | Build              | developer     | c44a10 | done     |                |
| 5 | QA                 | qa-engineer   | d21f77 | findings |                |
| 6 | Andon A1           | lead          | c44a10 | done     | kind 2 …       |
| 7 | Build (round 2)    | developer     | c44a10 | done     | paused by A1   |
| 8 | QA (round 2)       | qa-engineer   | d21f77 | pass     |                |
| 9 | Merge approval     | person        | -      | approved |                |
```

Role rows: 2, 3, 4, 5, 7, 8. Flagged: 5 (`findings`) and 7 (`paused by A1`). Eligible, in log order: 2, 3, 4, 8, so `n = 4`. `14 mod 4 = 2`, so the sampled row is the eligible row at index 2: **row 4, Build, developer**. A second reader with only the standard's text lists the same four rows and gets the same index.

Variants the text must settle (QA writes them as fixtures, [60-standard-changes](60-standard-changes.md) §5):

| Variant | Expected |
|---|---|
| every role row flagged, 3 role rows, id 7 | the set is all 3 role rows; index `7 mod 3 = 1`; the line says `already flagged` |
| exactly one eligible row | that row, whatever the id |
| two rows of one role | both are rows; each counts once in `n` |
| `Result` `done, then stalled` | eligible |
| `Result` `pass (3 medium, 2 low)` (manual log) | eligible |
| `Agents` `-` on a `developer` row | not a role row |
| a `lead` row, a `person` row | not a role row |
| no `Notes` column | no row is paused; the other tests apply |
| log numbered from 0 (L57) | order is the listing order; the `#` printed is the cell |
| no role row | `not captured (no role stage ran)` |

## 3. Questions this contract answers

- *Does an andon row count?* No: its `Role` is `lead`.
- *Is a row `paused by A1` ever walked while another is available?* No. When it is the only role row, the fallback of step 4 applies.
- *Why the log's order and not the `#`?* L57 numbers from 0 and C49 has no `Notes` column; the listing order is the one thing every log has.
