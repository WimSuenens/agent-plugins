---
status: proposed
---

# Role knowledge lives in the project; user scope keeps personal preferences only

Revised by slice 115 (spec #108). This record first put role memory in the `user` scope (`~/.claude/agent-memory/`), shared across every project on the machine, so it could hold craft only and not project facts. That was provisional, and it tied what a role learns to one machine and kept it from the next user of the repository.

## Decision

1. Each role's knowledge lives in the project, under version control: a role file `docs/agents/roles/<role>.md` and a skills folder `docs/agents/skills/<role>/`. The agents no longer declare `memory: user`.
2. There is exactly one agent per role, shipped in the plugin. The role files are data the agent reads; they never become a second agent.
3. A role reads only its own file and folder. The plugin's `PreToolUse` hook refuses a read of another role's file or folder, as it did for agent memory ([0003](0003-roles-ship-as-plugin-agents.md)). Shared project documents stay readable under the ownership table and the brief's inputs.
4. A role file may add rules, checks and knowledge, and never lift a protocol guard, an ownership rule or a one-way-door rule. The fence of [0011](0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md) is permanent for role files; it does not expire with a run.
5. Knowledge several roles need is promoted by the lead into the glossary or a domain plugin, not copied into each role file.
6. User scope keeps only personal preferences. Setup creates the role files and migrates existing user-scope memory into them.

## Consequences

- What a role learned shows in the project's history, where a team member can review and correct it.
- Role files can diverge between item branches and vanish with a deleted branch that was never merged; the price of version control, accepted because roles commit them on the item branch and they merge with it.

**Provisional** until a project has run with role files across two items.
