# Contract 109 — Worktrees in the project's agent folder

Issue [#109](https://github.com/WimSuenens/agent-plugins/issues/109) · Parent map [#108](https://github.com/WimSuenens/agent-plugins/issues/108) · Revises [ADR 0002](../docs/adr/0002-one-branch-and-worktree-per-item.md) on location

Paths:
- plugins/factory/scripts/worktree.sh
- plugins/factory/skills/run/SKILL.md
- plugins/factory/skills/setup-factory-skill/
- plugins/factory/references/protocol.md
- plugins/factory/references/hansei.md
- docs/adr/0002-one-branch-and-worktree-per-item.md
- docs/agents/factory.md
- CONTEXT.md
- tests/factory/
- contracts/109-worktree-folder.md
- plugins/factory/.claude-plugin/plugin.json
- CHANGELOG.md
- README.md
- .gitignore

## 1. The location

Every factory worktree lives in `.claude/worktrees/` inside the main checkout: `<id>` for an item (branch `item/<id>`), `frontier-<map>` (branch `frontier/<map>`), `settle-<map>` (branch `settle/<map>`). The old location, `../wt/<name>` beside the repository, is gone from the standard.

## 2. `scripts/worktree.sh`

| Command | Behaviour | Exit |
|---|---|---|
| `dir` | prints `.claude/worktrees` | 0 |
| `add item <id>` / `frontier <map>` / `settle <map>` | creates the worktree and branch from the main checkout's HEAD; prints the absolute path | 0; 2 usage or a non-numeric id; 3 the folder is not ignored; 4 git refused |
| `ignore` | adds `/.claude/worktrees/` to the main checkout's `.gitignore`; prints `added`, or `already present` and changes nothing; any existing line that ignores the folder counts | 0 |
| `legacy` | lists worktrees at `<main parent>/wt/*` as `<path>\t<branch>` | 0 none; 10 some |

All commands work from the main checkout or from any worktree of it. `add` refuses while the folder is not ignored, so a worktree never shows up as untracked in the main checkout.

## 3. The clean-up guard

Step 8.6.0 of the run (`references/hansei.md`) stops when the item's worktree path is empty (`close: no worktree for item/<id>`) or equals the main checkout, the first entry of `git worktree list` (`close: worktree is the main checkout`). It finds the worktree by branch, so a worktree at either location is found.

## 4. Setup and migration

`setup-factory-skill` step 8 runs `worktree.sh ignore`, makes the repo's test, lint and search commands exclude `.claude/worktrees`, writes the new `## Worktrees` text, and runs `worktree.sh legacy`. For each worktree found it offers **move or finish**: move with `git worktree move`, or finish the item where it is. The run skill reads `legacy` before step 5.2 and finishes an item at its old location in place.

## 5. Text that names the location

`skills/run/SKILL.md` (steps 3.1, 5.2, the settle round, the path rule in 5.4), `references/protocol.md` (*Messages* path rule), `references/hansei.md` (the guard), `assets/factory.md` and `docs/agents/factory.md` (`## Worktrees`), `CONTEXT.md` (**Worktree folder**), ADR 0002. History (earlier contracts, reviews, changelog entries, the 1.x fixture) keeps `../wt/`.

## 6. Release

Standard work changed, so a minor release: `2.3.1` becomes `2.4.0`. No `factory-state` change; a project with worktrees at the old location keeps working (§4).

## 7. Tests

`tests/factory/test_worktree_folder.sh`: the script seam (every command and exit code, idempotent `ignore`, `legacy`) and the standard-text seam (the location in each text, no `../wt/` left in the standard, the guard run at the new location and against the main checkout).
