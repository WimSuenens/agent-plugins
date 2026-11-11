# Contract 112 — Integrator: dispatch plan

Issue [#112](https://github.com/WimSuenens/agent-plugins/issues/112) · Parent map [#108](https://github.com/WimSuenens/agent-plugins/issues/108) · Blocked by [#111](https://github.com/WimSuenens/agent-plugins/issues/111)

Paths:
- plugins/factory/agents/integrator.md
- plugins/factory/scripts/integrator.sh
- plugins/factory/references/protocol.md
- plugins/factory/scripts/guard-memory.sh
- plugins/factory/skills/run/SKILL.md
- plugins/factory/skills/setup-factory-skill/
- plugins/factory/.claude-plugin/plugin.json
- docs/agents/factory.md
- tests/factory/test_integrator.sh
- tests/factory/test_role_tasks.sh
- tests/factory/test_ownership_tdd.sh
- tests/factory/test_fingerprint.sh
- tests/factory/test_andon_text.sh
- tests/factory/test_gemba.sh
- tests/factory/test_standard_text.sh
- contracts/112-integrator.md
- CHANGELOG.md
- README.md

shared: plugins/factory/.claude-plugin/plugin.json, CHANGELOG.md

## 1. The role

`integrator` is a plugin role with its own agent definition. It reads the board afresh on each call and returns a dispatch plan. It keeps no state: the same board gives the same plan. It makes no tracker write and spawns no role; the lead spawns what the plan names.

## 2. `scripts/integrator.sh plan <board.json>`

Input: a board snapshot, `{"now", "slices": [...]}` in priority order. Output: `merge`, `order`, `advise`, `start`, `pause`, and `measure` lines (the header of the script is the reference). A slice in flight or merge-ready holds its paths. Overlap is decided by `paths.sh overlap`. A dependency not done pauses the slice; a dependency that changes the order is advised. A missing value is printed `not captured`.

Exit: 0 plan printed; 2 usage, jq missing, unreadable or malformed snapshot.

## 3. Events

The lead calls the integrator at: intake processed, slice ready, PR opened, merge done, map changed. Each call is a role task with the snapshot in its brief.

## 4. Authority split

Priority stays with the lead and the person. The integrator decides order only within it, and advises when it sees a dependency. The devops role stays limited to pipelines and environments.

## 5. Shell

The integrator reads the tracker and git, and runs `scripts/integrator.sh plan`. Nothing else.

## 6. Ownership

## 7. Tests

`tests/factory/test_integrator.sh`: the scripts seam (a plan from a fake board: starts, pauses with reasons, merge-first, dependencies, measures, determinism, usage) and the standard-text seam (events, authority split, no state, shell, ownership, run text).
