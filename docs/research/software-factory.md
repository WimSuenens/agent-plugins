# The software factory

The concept behind the `factory` plugin: a lead plus seven role agents that take an idea to a destination, building one wayfinder slice at a time. This document is the base to extend from. It records what the design is, why each part is shaped the way it is, what has been verified, and where the extension points are. The decisions themselves are ADRs [0001](../adr/0001-factory-roles-talk-through-files.md)–[0008](../adr/0008-two-way-decisions-flow-back-to-the-lead.md), with 0006 superseded by 0007; all are provisional until a real item has run.

Origin: a design session on 2026-10-25, debriefed into a six-lesson course and processed into this repo.

## The problem

Long-lived Claude Code sessions that refer to each other fill their context windows: every exchange stays in both. Three levers exist, lightest first:

1. **Subagents** do verbose work in their own window and return a summary.
2. **Agent teams** are full sessions with peer messaging. They are experimental, cost significantly more tokens, and are documented for one codebase.
3. **Disposable sessions** keep everything that matters in files, so any session can be dropped.

The factory combines 1 and 3: one lead session delegates to role subagents, and all state lives in files and the tracker. A fork does not help, because it starts with a copy of the whole history.

## The team

| Role | Agent | Owns |
|---|---|---|
| Lead | the main session, via `/factory:run` | the plan, routing, the tracker, the person |
| Product owner | `factory:product-owner` | requirements and acceptance criteria; decision cards |
| Architect | `factory:architect` | contracts, ADRs, technology choices |
| Developer | `factory:developer` | building against the contracts, tracer bullet first |
| QA engineer | `factory:qa-engineer` | tests from the criteria; the release verdict |
| Security reviewer | `factory:security-reviewer` | independent review; critical and high block |
| DevOps | `factory:devops` | pipelines, environments, deploy, rollback |
| Docs writer | `factory:docs-writer` | docs and changelog, before merge |

Two principles from human teams carry over: contracts and decisions live in files, and the roles that check work are independent of the roles that produce it.

## Writing roles for agents

Every role file follows the same skeleton: a one-line mission, **Inputs needed**, output, authority, and a **Done** list that is checkable and exhaustive. The frontmatter `description` opens with one leading word (*Requirements, Architecture, Implementation, Verification, Security review, Delivery, Documentation*), since it is the pointer the lead delegates by. Boundaries are phrased positively ("contract friction goes to the architect as a question"). Shared rules live once, in [protocol.md](../../plugins/factory/references/protocol.md), which every role reads first. Commands come from the repo itself ("the repo's own test and lint commands"), never copied in.

## Communication

Hub-and-spoke through files in `work/<id>/`, named `NN-<type>-<role>.md`, in four types: **brief**, **result** (`done`, `blocked`, `needs-decision`), **feedback**, and **question**. The lead reads only `Status` and `Summary`. A role missing an input returns `blocked` and lists it; it does not guess. The brief template and each role's *Inputs needed* are two halves of one contract.

## Private memory

Each role has `memory: user`: a directory under `~/.claude/agent-memory/` whose `MEMORY.md` index loads into that role's prompt. It holds craft, not project state; a lesson another role needs is promoted into a shared artifact through a result. A plugin-level `PreToolUse` hook ([guard-memory.sh](../../plugins/factory/scripts/guard-memory.sh)) blocks a factory role from touching another role's memory, identified by the hook input's `agent_type`. It prevents accidental peeking; it is not a security boundary.

## Branches and tracking

One branch `item/<id>` and one worktree per item, shared by every role, each writing only the paths it owns (the table in the repo's `docs/agents/factory.md`). The tracker holds identity, status, and visibility; `work/<id>/` holds machine-facing messages and is deleted by the item's last commit. Status is a `Factory status` single-select field on a GitHub Project, with seven values: Backlog, Ready, Designed, In progress, In review, Ready to deploy, Done. The PR merges only when the QA and security verdicts are both `pass`.

## Wayfinding

A factory run starts from an idea: the lead grills the person about the destination (What, For whom, Done when, Not), passes it to `/wayfinding:wayfinder` to chart the route, and then cuts slice after slice with `/wayfinding:beachhead`, resurveying after each merge until the map dissolves ([ADR 0007](../adr/0007-factory-owns-destination-and-slicing.md)). A factory item is one such `wayfinder:slice` ticket with its frame. Roles report every two-way decision back; the lead and the person can overturn one through a feedback brief without stopping the stage ([ADR 0008](../adr/0008-two-way-decisions-flow-back-to-the-lead.md)). The product owner turns the frame into acceptance criteria: one per **Under test** line, and every **Deliberately faked** item out of scope.

## Decision cards

One-way doors go to the person, never to an agent. The product owner writes a [decision card](../../plugins/factory/references/decision-card.md): the choice in one everyday sentence, two or three options described by consequence (for users, cost and time, effort to undo), a recommendation, and what happens if it is wrong. The card ends with a menu to dig deeper: an explanation by example, `/research`, `/prototype`, or `/grilling`. The level (`non-technical` or `technical`) is set per repo, and defaults to `non-technical`.

## What is verified

Checked against the Claude Code documentation and the installed CLI on 2026-10-25:

- Plugin agents ignore `hooks`, `mcpServers`, and `permissionMode` in their frontmatter, which is why the guard is a plugin-level hook.
- Subagents receive the project's `CLAUDE.md` hierarchy (the original drafts assumed they did not).
- Hook input carries `agent_type` inside a subagent; exit code 2 blocks a `PreToolUse` call, and stderr becomes the reason.
- A skill with `disable-model-invocation: true` can't be invoked by the model or preloaded into a subagent, which is why wayfinder and beachhead became model-invoked.
- `gh project item-edit`, `item-add`, `field-list`, `field-create`, `create`, and `link` flags, on gh 2.94.0.
- The guard script, against twelve sample inputs, with and without `jq`.

Open, and tracked as `plugin:factory` issues: the exact `agent_type` value and memory directory name for a plugin agent, whether `memory` and `skills` work for plugin agents, memory scope across worktrees, and the message templates on a real item.

## Extension points

- **A new role** (a UX designer when there is a UI; backend and frontend developers working in parallel on sub-branches off `item/<id>`): add an agent file with the same skeleton, add it to the `roles` list in `guard-memory.sh`, give it a row in the ownership table of `assets/factory.md`, and give it a stage in `/factory:run`.
- **A new tracker** (Azure DevOps, GitLab): add a `references/issue-tracker-<tracker>.factory.md` patch with the same operations, and a branch in the setup's tracker check. Azure DevOps needs a decision first: custom states in an inherited process (preferred) or default states plus a `status:<name>` tag.
- **Cross-project work**: treat the other project as another role, with each project's lead writing briefs into the other's `work/` inbox and sharing a contracts folder. Undesigned beyond that.
- **Windows**: the guard is bash and needs Git Bash or WSL; a PowerShell version would set `shell: "powershell"` on the hook.

## Further reading

- Claude Code docs: [subagents](https://code.claude.com/docs/en/sub-agents), [agent teams](https://code.claude.com/docs/en/agent-teams), [hooks](https://code.claude.com/docs/en/hooks), [plugins reference](https://code.claude.com/docs/en/plugins-reference), [skills](https://code.claude.com/docs/en/skills)
- Azure CLI, [`az boards work-item`](https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest), for the Azure DevOps extension
