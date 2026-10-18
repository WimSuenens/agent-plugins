---
name: setup-design-skill
description: Wire a repo for the design plugin — writes docs/agents/design.md and its AGENTS.md pointer so every skill honours the design system and UX vocabulary. Run once per repo.
disable-model-invocation: true
---

# Setup the design overlay

Upstream skills (`/prototype`, `/code-review`, `/triage`, `/to-tickets`, …) know nothing about this plugin. They do read `AGENTS.md` (or `CLAUDE.md`) and the `docs/agents/*.md` files its `## Agent skills` block points at. This skill adds one more of those docs, `docs/agents/design.md`, so every skill that touches UI builds from the design system, names findings with the `/design:ux-psychology` vocabulary, and files one-way design decisions as ADRs.

## Process

### 1. Check configuration state

Look for an `## Agent skills` block in `AGENTS.md` or `CLAUDE.md`, and for `docs/agents/issue-tracker.md` and `docs/agents/domain.md`.

If any is missing, invoke `/setup-matt-pocock-skills` first and let its interview run to completion before continuing. `design.md` routes ADRs, glossary terms and review findings through the docs it writes.

**Done when** the block and both docs exist.

### 2. Write `docs/agents/design.md`

Copy [assets/design.md](./assets/design.md) to `docs/agents/design.md` verbatim, replacing the whole file if one exists.

Then adjust it to what the repo actually has:

- If design files live somewhere other than `design/` (look for an existing `system.md`, `direction.md`, tokens file or Storybook), point both paths at the real location.
- If `/wayfinding:reversibility` isn't installed (no `wayfinding` plugin), keep the one-way/two-way lists and drop the sentence naming the skill.

**Done when** every path in the file resolves to where this repo keeps (or will keep) its design files.

### 3. Add the pointer

In the `## Agent skills` block, add this subsection after the last existing `###` subsection, unless a `### Design` subsection is already there:

```markdown
### Design

UI work builds from the design system and is reviewed with the UX-psychology vocabulary. See `docs/agents/design.md`.
```

**Done when** exactly one `### Design` subsection exists in the block.

### 4. Report completion

Tell the user setup is done and name the next step for their situation:

- No `design/system.md` yet → `/design:design-system` (from scratch, or extracted from the existing UI).
- No direction and the product's visual identity is still open → `/design:direction` first; `design-system` reads its brief.

Re-running this skill is only needed after design files move.
