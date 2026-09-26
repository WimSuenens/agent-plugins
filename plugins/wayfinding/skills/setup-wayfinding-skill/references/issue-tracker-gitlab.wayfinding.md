# Patch: `issue-tracker-gitlab.md` → Wayfinding operations

**Apply to:** the tracker doc that `/setup-matt-pocock-skills` wrote (wherever your `CLAUDE.md` / `AGENTS.md` `### Issue tracker` block points — commonly `docs/agents/issue-tracker.md`).

**How:** replace the whole `## Wayfinding operations` section with the block below. Everything above it is untouched.

Two deltas from upstream: the `slice` label joins the type vocabulary, and `Resolve` now carries the locked/provisional tag plus the ADR step.

---

## Wayfinding operations

Used by `/wayfinding:wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Destination / Notes / Beachhead / Decisions-so-far / Deferred / Fog / Out-of-scope body. `glab issue create --label wayfinder:map`. (On GitLab tiers with native epics, an epic may hold the map instead; a labelled issue works everywhere.)
- **Child ticket**: an issue carrying `Part of #<map>` at the top of its description and labels `wayfinder:<type>` — one of `research`, `slice`, `prototype`, `grilling`, `task`. Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: GitLab's **native blocking link** — the canonical, UI-visible representation. Add it with the `/blocked_by #<n>` quick action, posted as a note (`glab issue note <child> --message "/blocked_by #<blocker>"`). Native blocking links are a Premium/Ultimate feature; on the free tier (or where unavailable) fall back to a `Blocked by: #<n>, #<n>` line at the top of the description. A ticket is unblocked when every blocker is closed.
- **Frontier query**: `glab issue list -F json` scoped to the map's children, drop any with an open blocker — a native `blocked_by` link to an open issue (`glab api projects/:id/issues/:iid/links`), or an open issue in the `Blocked by` line — or an assignee; first in map order wins.
- **Claim**: `glab issue update <n> --assignee @me` — the session's first write.
- **Resolve**: `glab issue note <n> --message "<answer>"`, then `glab issue close <n>`, then append a context pointer to the map's Decisions-so-far in the form `- [<title>](<url>) — [locked|provisional] <gist>`. A one-way door also gets an ADR under `docs/adr/` via `/domain-modeling`.
- **Slice ticket**: label `wayfinder:slice`. Its body is the `/beachhead` frame (Question / Behaviour / Under test / Deliberately faked). It stays open across the whole build and closes when the implementation MR merges; its resolution note records what the build taught and any decision it contradicted. Link the implementation tickets `/to-tickets` produced back to it so the build is reachable from the map.
- **Deferred**: plain lines in the map body under `## Deferred`, each ending in `— **trigger:** <condition>`. Deferred items are deliberately **not** issues: giving them ids invites them onto the frontier, which is the weight this layer exists to avoid.
