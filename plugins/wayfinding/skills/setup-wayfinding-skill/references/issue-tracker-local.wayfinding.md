# Patch: `issue-tracker-local.md` → Wayfinding operations

**Apply to:** the local-markdown tracker doc, if that's what `/setup-matt-pocock-skills` configured.

**How:** replace the whole `## Wayfinding operations` section with the block below.

---

## Wayfinding operations

Used by `/wayfinding:wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.scratch/<effort>/map.md` — the Destination / Notes / Beachhead / Decisions-so-far / Deferred / Fog / Out-of-scope body.
- **Child ticket**: `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in the body. A `Type:` line records the ticket type (`research`/`slice`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NN, NN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.scratch/<effort>/issues/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer to the map's Decisions-so-far in the form `- [<title>](<path>) — [locked|provisional] <gist>`. A one-way door also gets an ADR under `docs/adr/` via `/domain-modeling`.
- **Slice ticket**: `Type: slice`. Its body is the `/beachhead` frame (Question / Behaviour / Under test / Deliberately faked). Its implementation tickets live in the ordinary `.scratch/<slice-slug>/issues/` directory `/to-tickets` writes; link that directory from the slice file. The slice resolves when those are done and the work is merged, and its `## Answer` records what the build taught.
- **Deferred**: plain lines in `map.md` under `## Deferred`, each ending in `— **trigger:** <condition>`. Deferred items get no ticket file — giving them numbers invites them onto the frontier, which is the weight this layer exists to avoid.
