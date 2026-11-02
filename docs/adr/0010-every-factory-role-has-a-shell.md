---
status: proposed
---

# Every factory role has a shell, scoped by the protocol

The architect, product-owner and docs-writer get `Bash`, so all seven roles have a shell. Without one, the architect and product-owner could not read tracker issues named in their briefs or commit their own paths, so the lead inlined tracker content, committed on their behalf, and made small edits in their files: lead overhead, and a history where the author of a commit is not the role that did the work. The docs-writer must run the commands it documents, which it could not do at all.

The protocol scopes the shell per role. Architect and product-owner read the tracker (`gh issue view`, `gh issue list`) and git (`status`, `log`, `diff`), and `git add` and `git commit` the paths they own; they write nothing to the tracker and start no processes. The docs-writer is a full shell role, under the same rules on processes and shared resources as the developer, QA engineer, security reviewer and DevOps. Every role commits its own paths; the lead no longer commits for a role.

Complements [0001](0001-factory-roles-talk-through-files.md): briefs may now reference tracker issues by number instead of the lead copying them into files.

## Consequences

The scope is an agreement, not a technical boundary: nothing stops a scoped role running another command. Per-command restriction is impossible in agent frontmatter, because `tools` takes bare tool names and a specifier in `disallowedTools` removes the whole tool. The stricter fallback is a plugin-level `PreToolUse` hook that reads `agent_type` and enforces a per-role command allowlist, like the memory guard of [0003](0003-roles-ship-as-plugin-agents.md). It depends on #4 and is deferred in #27.

## Considered options

- **The lead commits and reads the tracker for shell-less roles.** Rejected after a second grilling. It is the overhead this decision removes.
- **A shell for the docs-writer only.** Rejected. The architect and product-owner would still depend on the lead for tracker reads and commits.

**Provisional** until a factory run confirms the scoped roles keep to their scope.
