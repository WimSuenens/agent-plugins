<!-- factory:ledger v1 -->
## Ledger: #12 Export a report as CSV

- started: 2026-11-04T11:40Z
- start checks: author test: ok; drift: same as #9; freeze: none; baseline: #8 open with marker

### Tasks

| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | #31 | Build | developer | c44a10 | W1, W2 | 100 | done | resumed twice |
| 2 | #34 | QA | qa-engineer | d21f77 | W3 | 100 | findings | 1 finding; waste: defects |

### Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-04T12:02Z | 2026-11-04T12:41Z | yes | decision card on #12; waste: waiting |
| W2 | limits | c44a10 | 2026-11-04T13:05Z | 2026-11-04T13:20Z | yes | session limit, waste: waiting, resumed at reset |
| W3 | stalled | d21f77 | 2026-11-04T15:03Z | 2026-11-04T15:07Z | yes | waste: waiting; cut-mid-stream |
| W4 | andon | c44a10 | 2026-11-04T15:11Z | 2026-11-04T15:23Z | yes | no stop A1 kind 2: same-finding-twice; waste: defects |

### Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-04T12:41Z | decision card | chose B; waste: skills |
