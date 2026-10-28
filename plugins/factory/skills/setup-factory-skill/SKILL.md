---
name: setup-factory-skill
description: Wire a repo for the factory plugin — runs the wayfinding setup if needed, writes docs/agents/factory.md and its AGENTS.md pointer, adds the factory operations to the tracker doc, and prepares the GitHub Project board. Run once per repo.
disable-model-invocation: true
---

# Setup the factory

`/factory:run` and the seven role agents read two repo files: `docs/agents/factory.md` (decision-maker, role model overrides, path ownership, worktree location, tracker ids) and the `## Factory operations` section of `docs/agents/issue-tracker.md`. This skill writes both, once.

## Process

### 1. Check configuration state

Look for `docs/agents/issue-tracker.md` with a `## Wayfinding operations` section that mentions the `slice` type, and an `## Agent skills` block in `AGENTS.md` or `CLAUDE.md`.

If either is missing, invoke `/wayfinding:setup-wayfinding-skill` first and let it run to completion. Factory items are wayfinder slices, so the wayfinding conventions come first.

**Done when** the tracker doc carries the slice conventions and the `## Agent skills` block exists.

### 2. Check the tracker

Read the first heading of `docs/agents/issue-tracker.md`. The factory supports `# Issue tracker: GitHub` only. For any other tracker, stop and tell the user plainly: the factory needs GitHub for now, and Azure DevOps and others wait on a real project to design against. Point them at `https://github.com/WimSuenens/agent-plugins/issues` to ask for theirs.

**Done when** the tracker is GitHub, or the user has been told why setup stops.

### 3. Ask the decision-maker level

Ask the user one question: who decides one-way doors in this repo, and could they follow a technical explanation?

- **non-technical** (default): owns the product and budget, has not read the code.
- **technical**: can weigh an architecture trade-off.

**Done when** the user has answered.

### 4. Ask about role models

Each role runs on the default model in its agent file:

| Role | Default |
|---|---|
| product-owner, architect, qa-engineer, security-reviewer | `inherit` (the lead's model) |
| developer, devops | `sonnet` |
| docs-writer | `haiku` |

When an existing `docs/agents/factory.md` has a `## Role models` table, show its overrides and ask whether to keep or change them; keep is the default. Otherwise show the defaults and ask one question: override any of them for this repo? On yes, ask per role, offering `haiku`, `sonnet`, `opus`, or `fable` with the default preselected. Only these four work: the lead passes the override as the spawn's `model`, which takes no pinned id and no `inherit`.

**Done when** the user has kept the overrides, declined, or picked a model for every role they want overridden.

### 5. Write `docs/agents/factory.md`

Copy [assets/factory.md](./assets/factory.md) to `docs/agents/factory.md`, replacing the whole file if one exists. Then fit it to the repo:

- Set `decision-maker:` to the answer from step 3.
- When step 4 produced overrides, replace the `None` line under `## Role models` with a `| Role | Model |` table, one row per overridden role, and keep the paragraph that explains the format.
- Point `src/` and `tests/` in the ownership table at where this repo keeps its code and tests. Look at the directory layout and the test command in the repo's own config; use one row per directory when there are several.
- Keep the other ownership rows as written unless the repo already uses a different home for that material (an existing `adr/` folder, a `docs/decisions/`, a runbook folder); then point the row there.

**Done when** every path in the ownership table names a directory this repo has, or one the factory will create.

### 6. Patch the tracker doc

Add [references/issue-tracker-github.factory.md](./references/issue-tracker-github.factory.md)'s section to `docs/agents/issue-tracker.md` as its patch note describes. Leave every other section untouched.

**Done when** exactly one `## Factory operations` section exists.

### 7. Prepare the Project board

The factory tracks status in a GitHub Project with a single-select `Factory status` field. Run `gh auth status`; when the token lacks the `project` scope, ask the user to run `gh auth refresh -s project` and wait.

1. List the owner's projects: `gh project list --owner <owner> --format json`. Ask the user to pick one or to create a new one (`gh project create --owner <owner> --title "<repo> factory"`), then link it to the repo: `gh project link <number> --owner <owner> --repo <owner>/<repo>`.
2. Look for the field: `gh project field-list <number> --owner <owner> --format json`. When `Factory status` is missing, create it:
   `gh project field-create <number> --owner <owner> --name "Factory status" --data-type SINGLE_SELECT --single-select-options "Backlog,Ready,Designed,In progress,In review,Ready to deploy,Done"`
3. Read the project id, the field id, and the seven option ids from `gh project field-list` and `gh project view <number> --owner <owner> --format json`, and fill the Tracker tables in `docs/agents/factory.md`.

**Done when** every cell in both Tracker tables holds a value.

### 8. Keep item folders out of trunk

Item folders in `work/` are removed by the last commit on each item branch. Nothing to ignore; confirm no `work/` rule in `.gitignore` hides them, since roles commit their messages.

**Done when** `git check-ignore work/x` prints nothing.

### 9. Add the pointer

In the `## Agent skills` block, add this subsection after the last existing `###` subsection, unless a `### Factory` subsection is already there:

```markdown
### Factory

Slices are built by the factory's role agents. See `docs/agents/factory.md`.
```

**Done when** exactly one `### Factory` subsection exists in the block.

### 10. Report completion

Tell the user setup is done and name the next step:

- No wayfinder map yet → `/factory:run` with the idea; the lead charts a map with `/wayfinding:wayfinder` first.
- A framed slice ticket exists → `/factory:run #<n>`.

Mention that improvements to the factory itself go to `https://github.com/WimSuenens/agent-plugins/issues` with the `plugin:factory` label, and that `/factory:run` offers to draft one at the end of every item.
