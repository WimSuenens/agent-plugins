<!-- factory:ledger v1 -->
## Ledger: #225 Reference pages for agents: generated Agents page and a Reference section, in English and Dutch

- started: 2026-11-14T18:57Z
- start checks: author test: one git identity for all roles; freeze: none; drift: no earlier record for 3.2.0; baseline: #62 open with marker

### Tasks

| # | Task | Stage | Role | Agents | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | #226 | Requirement | product-owner | aaf04b | - | 64348 | done | 19 ACs, 6 decisions, direction.md created |
| 2 | #227 | Contracts and ADRs | architect | aff4ca | - | 63494 | done | 2 contracts, no ADR |
| 3 | #228 | Tests | qa-engineer | a81ef5 | - | 161786 | done | tests red until build; 7 mutants caught on a reference site |
| 4 | #229 | Build | developer | acef8f | - | 70345 | done | 12 files in apps/site, all inside Paths; suite 263 pass, 1 skipped |
| 5 | #233 | QA | qa-engineer | ad395d | - | 41912 | pass | no findings; AC-19 post-merge; Summary shortened once on request |
| 6 | #234 | Security | security-reviewer | ad20eb | - | 37395 | pass | 3 findings (1 low, 2 medium off-list) confirmed expected; Summary shortened once on request |
| 7 | #235 | Delivery | devops | aba4e5 | - | 24032 | done | nothing to change; existing site workflow deploys on merge |
| 8 | #236 | Documentation | docs-writer | a8b401 | - | 90011 | done | README fixed; no changelog entry; raised A1 (kind 1) |
| 9 | #237 | Contracts and ADRs (round 2) | architect | a945a8 | - | 51273 | done | 188 contracts marked superseded in part; Summary shortened once on request |

### Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|
| W1 | andon | lead | 2026-11-14T19:38Z | 2026-11-14T19:38Z | yes | no stop A1 kind 1: incomplete stale-text list in the contract; no agent paused |
| W2 | person | - | 2026-11-14T19:47Z | 2026-11-14T19:49Z | yes | merge and clean up? |

### Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-14T19:49Z | approval | merge and clean up: yes |


