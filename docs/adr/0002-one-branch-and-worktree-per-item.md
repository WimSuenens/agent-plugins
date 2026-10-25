---
status: proposed
---

# One branch and worktree per item, shared by every role

Each factory item gets `item/<id>` and one worktree, and all roles work in it, each writing only the paths it owns. Per-role branches would postpone integration to the end, which defeats a tracer bullet that crosses every role. Status lives in the tracker, never in files on the branch, where it would be invisible to other items and conflict on merge; `work/<id>/` is removed by the item's last commit.

**Provisional** until a factory item has run end to end on a real project.
