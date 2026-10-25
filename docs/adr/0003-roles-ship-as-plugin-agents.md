---
status: proposed
---

# Roles ship as plugin agents, guarded by one plugin-level hook

The seven roles ship as plugin agents (`factory:developer`, …) so they update with the plugin, instead of being copied into each repo's `.claude/agents/`. Claude Code ignores `hooks` in a plugin agent's frontmatter, so the memory guard is one `PreToolUse` hook in `hooks/hooks.json` that reads the caller from the hook input's `agent_type` and blocks only factory roles reading another role's memory.

## Consequences

If `agent_type` or `memory` turns out not to work for plugin agents, the fallback is the copy: `setup-factory-skill` writes the agents into `.claude/agents/` with per-agent hooks, and pays for it with copies that drift from plugin updates.

**Provisional** until the validation run confirms `agent_type` and `memory` for plugin agents.
