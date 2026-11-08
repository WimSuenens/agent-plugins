<!-- factory:ledger v1 -->
## Ledger: #12 replay

- started: 2026-11-04T11:40Z
- start checks: replay

### Tasks

| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | #31 | Requirement | product-owner | a1c9e2 | - | 53942 | done | 9 ACs, 2 decisions |
| 2 | #32 | Contracts and ADRs | architect | b7d031 | W1 | 81277 | done | 1 card |
| 3 | #33 | Build | developer | c44a10 | W2, W3 | 138578 | done | resumed after a limit and after a sleep |
| 4 | #34 | QA | qa-engineer | d21f77 | W6 | 70114 | findings | 1 finding |
| 5 | #35 | Security | security-reviewer | a41f09 | - | 48820 | pass | 2 low |
| 6 | #36 | Build (round 2) | developer | c44a10 | W7 | 141210 | done | QA finding fixed; paused by A1 |
| 7 | #37 | QA (round 2) | qa-engineer | d21f77 | - | 74480 | pass |  |
| 8 | #38 | Documentation | docs-writer | e90b55 | W4 | not captured (failure notice carried no token count) | done | done, then stalled; Done list checked, not resumed |

### Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | person | - | 2026-11-04T12:02Z | 2026-11-04T12:41Z | yes | decision card on #12: export format |
| W2 | limits | c44a10 | 2026-11-04T13:05Z | 2026-11-04T13:20Z | yes | developer failed: session limit, resumed at reset |
| W3 | interrupted | c44a10 | 2026-11-04T13:52Z | 2026-11-04T14:10Z | yes | developer failed: server_error at 14:09Z; sleep 13:53Z–14:08Z; start from cut-offs.sh; resumed |
| W4 | stalled | e90b55 | 2026-11-04T15:49Z | 2026-11-04T16:00Z | yes | docs-writer failed: no progress for 600s, after its done result; start from cut-offs.sh; accepted, not resumed |
| W5 | person | - | 2026-11-04T16:09Z | 2026-11-04T16:21Z | yes | merge and clean up? |
| W6 | stalled | d21f77 | 2026-11-04T15:03Z | 2026-11-04T15:07Z | yes | found at close: cut-mid-stream; QA recovered by itself, no notice |
| W7 | andon | c44a10 | 2026-11-04T15:11Z | 2026-11-04T15:23Z | yes | no stop A1 kind 2: same-finding-twice |
| W8 | andon | lead | 2026-11-04T16:01Z | 2026-11-04T16:09Z | yes | no stop A2 kind 3: role-outside-role |

### Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-04T12:41Z | decision card | chose B on the export-format card |
| 2026-11-04T13:40Z | overturn | overturned the architect's CSV delimiter decision |
| 2026-11-04T16:21Z | approval | merge and clean up: yes |
