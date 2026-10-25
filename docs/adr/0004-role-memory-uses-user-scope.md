---
status: proposed
---

# Role memory uses user scope and holds craft only

Each role's memory uses the `user` scope (`~/.claude/agent-memory/`). A git-tracked `project` memory would diverge between item branches and vanish with a deleted branch, and `local` memory may split per worktree. The price is that memory is shared across every project on the machine, so it holds craft (patterns, gotchas, style), never project facts; those live in `work/`, `docs/`, and ADRs.

**Provisional** until scope behaviour across worktrees has been checked.
