# Patch: `issue-tracker-github.md` → Wayfinding operations

**Apply to:** the tracker doc that `/setup-matt-pocock-skills` wrote (wherever your `CLAUDE.md` / `AGENTS.md` `### Issue tracker` block points — commonly `docs/agents/issue-tracker.md`).

**How:** replace the whole `## Wayfinding operations` section with the block below. Everything above it is untouched.

Two deltas from upstream: the `slice` label joins the type vocabulary, and `Resolve` now carries the locked/provisional tag plus the ADR step.

---

## Wayfinding operations

Used by `/wayfinding:wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Destination / Notes / Beachhead / Decisions-so-far / Deferred / Fog / Out-of-scope body. `gh issue create --label wayfinder:map`.
- **Child ticket**: an issue linked to the map as a GitHub sub-issue (`gh api` on the sub-issues endpoint). Where sub-issues aren't enabled, add the child to a task list in the map body and put `Part of #<map>` at the top of the child body. Labels: `wayfinder:<type>` — one of `research`, `slice`, `prototype`, `grilling`, `task`. Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: GitHub's **native issue dependencies** — the canonical, UI-visible representation. Add an edge with `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, _not_ the `#number` or `node_id`). GitHub reports `issue_dependencies_summary.blocked_by` (open blockers only — the live gate). Where dependencies aren't available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Frontier query**: list the map's open children (`gh issue list --state open`, scoped to the map's sub-issues / task list), drop any with an open blocker (`issue_dependencies_summary.blocked_by > 0`) or an assignee; first in map order wins.
- **Claim**: `gh issue edit <n> --add-assignee @me` — the session's first write.
- **Resolve**: `gh issue comment <n> --body "<answer>"`, then `gh issue close <n>`, then append a context pointer to the map's Decisions-so-far in the form `- [<title>](<url>) — [locked|provisional] <gist>`. A one-way door also gets an ADR under `docs/adr/` via `/domain-modeling`.
- **Slice ticket**: label `wayfinder:slice`. Its body is the `/beachhead` frame (Question / Behaviour / Under test / Deliberately faked). It stays open across the whole build and closes when the implementation PR merges; its resolution comment records what the build taught and any decision it contradicted. Link the implementation tickets `/to-tickets` produced back to it so the build is reachable from the map.
- **Deferred**: plain lines in the map body under `## Deferred`, each ending in `— **trigger:** <condition>`. Deferred items are deliberately **not** issues: giving them ids invites them onto the frontier, which is the weight this layer exists to avoid.
