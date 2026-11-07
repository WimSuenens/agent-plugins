# Factory

How the `factory` plugin runs in this repo.

## Decision-maker

decision-maker: technical

## Role models

None, roles use the plugin defaults.

| Role | Model |
|---|---|
| developer | opus |

## Ownership

| Path | Owner |
|---|---|
| `docs/requirements/` | product-owner |
| `plugins/` | developer |
| `docs/agents/factory.md` section `## Overrides` | lead |

## Worktrees

Item worktrees live at `../wt/<id>`, on branch `item/<id>`.

## Tracker

Factory operations are in `docs/agents/issue-tracker.md`, under `## Factory operations`. The board view groups by `Factory status`.

Resolved ids for the GitHub Project:

| Key | Value |
|---|---|
| owner | fixt |
| project number | 77 |
| project id | PVT_fixture01 |
| field id (`Factory status`) | fld_status |

| Status | Option id |
|---|---|
| Backlog | o_backlog |
| Ready | o_ready |
| Designed | o_designed |
| In progress | o_inprogress |
| In review | o_inreview |
| Ready to deploy | o_rtd |
| Done | o_done |

## Overrides

### keep-me

- status: active
- rule: do not touch this text
