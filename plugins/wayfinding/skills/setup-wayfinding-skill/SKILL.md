---
name: setup-wayfinding-skill
description: Configure a repo for /wayfinding:wayfinder — runs the upstream repo setup if it hasn't happened yet, then deterministically wires the wayfinding tracker conventions (the slice ticket type, locked/provisional tagging, the Deferred list) into the tracker doc and creates the wayfinder:slice label. Run once per repo before first use of /wayfinding:wayfinder.
disable-model-invocation: true
---

# Setup the wayfinding overlay

`/wayfinding:wayfinder` reads a repo's `docs/agents/issue-tracker.md` for its tracker-specific mechanics, under a `## Wayfinding operations` heading. Upstream's `/setup-matt-pocock-skills` writes that file, but seeds it with its own plain vocabulary (no `slice` type, no locked/provisional tagging) — it has no knowledge of this overlay plugin. Skip this step and `/wayfinding:wayfinder` silently falls back to upstream behaviour.

This skill closes that gap deterministically — no manual copy-paste, no separate `gh label create` step.

## Process

### 1. Check configuration state

Look for `docs/agents/issue-tracker.md` and an `## Agent skills` block in `CLAUDE.md` or `AGENTS.md`.

If either is missing, invoke `/setup-matt-pocock-skills` first and let its interview run to completion (issue tracker, triage labels, domain docs) before continuing here.

### 2. Detect the tracker

Read the first heading of `docs/agents/issue-tracker.md`. Upstream's templates always start with one of:

- `# Issue tracker: GitHub`
- `# Issue tracker: GitLab`
- `# Issue tracker: Local markdown`
- anything else — a freeform "other" tracker the user described in prose during setup

### 3. Apply the wayfinding patch

Based on what step 2 found, replace the file's whole `## Wayfinding operations` section with the matching reference file's content, verbatim:

- GitHub → [references/issue-tracker-github.wayfinding.md](./references/issue-tracker-github.wayfinding.md)
- GitLab → [references/issue-tracker-gitlab.wayfinding.md](./references/issue-tracker-gitlab.wayfinding.md)
- Local markdown → [references/issue-tracker-local.wayfinding.md](./references/issue-tracker-local.wayfinding.md)

Each reference file is itself formatted as a patch note (what it applies to, what changes, then the replacement section) — read it, then perform the edit directly. Leave everything above `## Wayfinding operations` in the tracker doc untouched.

For an "other" tracker there is no template to key off — leave the section as upstream wrote it (or as the user described it) and tell them plainly that this tracker isn't automated yet, same gap as today.

### 4. Create the `wayfinder:slice` label, idempotently

- **GitHub**: `gh label list --search wayfinder:slice --json name --jq '.[].name'` — if empty, `gh label create wayfinder:slice --description "Wayfinder: a thin slice shipped to teach"`.
- **GitLab**: `glab label list` — if `wayfinder:slice` isn't present, `glab label create wayfinder:slice --description "Wayfinder: a thin slice shipped to teach"`.
- **Local markdown**: no label system — nothing to do.

### 5. Report completion

Tell the user setup is done, and that this repo's router is `/wayfinding:ask-me` — not `/ask-matt`, which doesn't know this overlay exists. Mention they can edit `docs/agents/issue-tracker.md` by hand afterward; re-running this skill is only needed to switch trackers or restart from scratch.
