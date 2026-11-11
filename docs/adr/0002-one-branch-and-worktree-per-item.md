---
status: proposed, amended by 0015, location revised by #109
---

# One branch and worktree per item, shared by every role

Each factory item gets `item/<id>` and one worktree, and all roles work in it, each writing only the paths it owns. Per-role branches would postpone integration to the end, which defeats a tracer bullet that crosses every role. Status lives in the tracker, never in files on the branch, where it would be invisible to other items and conflict on merge; `work/<id>/` is removed by the item's last commit.

**Location (revised, #109).** The worktrees live in the project's own agent folder, `.claude/worktrees/<id>` (`frontier-<map>`, `settle-<map>` for rounds), not beside the repository at `../wt/<id>`. They stay inside the project, so no extra permission is needed for a path outside it. The folder is in `.gitignore` (setup adds it), and test, lint and search runs exclude it, so the main checkout never scans the worktrees. The clean-up guard refuses an empty worktree path and the main checkout. A project with worktrees at the old location finishes them there or lets setup move them. This reverses only where the worktree sits; one branch and one worktree per item stands. Contract [109-worktree-folder](../../contracts/109-worktree-folder.md).

**Provisional** until a factory item has run end to end on a real project.
