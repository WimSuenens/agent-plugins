# Map: payments

## Factory run

- started: 2026-12-01T10:00:00Z
- step: 9
- in flight: none
- FREEZE: 1a2b3c4 (3.10.0)
- lead sessions: 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c
- closed in this run: #41 https://example.invalid/issues/41#issuecomment-1, #42 https://example.invalid/issues/42#issuecomment-2
- baseline: not yet

### Run waits

| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|
| R1 | person | lead | 2026-12-01T13:30Z | 2026-12-01T13:45Z | close the run now? |
| R2 | limits | lead | 2026-12-01T13:40Z | 2026-12-01T14:00Z | found at close: api-error:rate_limit |

## Destination
