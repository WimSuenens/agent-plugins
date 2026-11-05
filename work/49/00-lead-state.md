# Lead state: #49 Andon

- **Board item id:** PVTI_lAHOBIbaa84BqOBFzhGaUn0
- **Status:** Backlog
- **Map:** #34 (Lean factory run), run step 5 done; next is step 6
- **Branch / worktree:** `item/49` at `../wt/49`
- **Next step:** Requirement (product-owner), with the carry-overs below in the brief
- **Open questions:** none
- **Calibration:** frozen factory `9147301f75c3` (installed sha checked at item start: matches the FREEZE line on #34). No `/plugin marketplace update`, no `/reload-plugins`. Pre-release standard has no fingerprint script and no `## Label`; this log is manual.

## Running agents

none

## Carry-overs (from #39, map #34)

- Contract text before code fixes.
- Validate any detection or measurement rule on the data that showed the defect; QA or the developer runs the replay (the architect has no process scope).
- Demo of the new standard: terminal session `claude --plugin-dir <worktree>/plugins/factory`, restarted after the last change to `plugins/`; check the filled `Plugin root:` line before trusting it.
- Sandbox repo WimSuenens/factory-sandbox (Project #10) for demos; nothing from it lands on agent-plugins except step-9 issues the person approves.
- Binding ADRs: 0011 (fence), 0012 (releases, freeze), 0013 (merge style: keep `--merge`). No absolute home paths in `work/`.
- Two-way decisions go to the person in chat with each stage summary; one-way doors as decision cards.

## Stage log (manual)

| # | Stage | Role | Agents | Start (UTC) | End (UTC) | Duration | Waits | Peak ctx | Result | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Start item | lead | - | 2026-11-05T22:50Z | 2026-11-05T22:51 | ~1m | - | - | done | boardZ at Backlog, worktree + work/49 created |

## Waits

| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |
|---|---|---|---|---|---|---|

## Person's touches

| Time (UTC) | Kind | What |
|---|---|---|
| 2026-11-05T22:41Z | other | started run at step 5 (item #49), set carry-overs |
