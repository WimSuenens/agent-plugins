# Routing snippet

This replaces the `ask-matt` edit from the earlier draft. **You cannot patch `ask-matt`** when upstream is installed as a plugin: Claude Code copies the plugin into a read-only cache, and your edits are overwritten on the next update. Patching it would mean forking, which is exactly what the overlay avoids.

Instead, put the routing where it belongs — in the project. `/setup-matt-pocock-skills` already writes an `### Issue tracker` block into the repo's `CLAUDE.md` / `AGENTS.md`, so that file is the established home for per-repo agent config. Append this block to it:

```md
### Wayfinding

This repo plans through `/wayfinding:wayfinder`, not upstream `/wayfinder`.

- **A huge, foggy effort — greenfield, or a build too big for one session** → `/wayfinding:wayfinder`.
  It charts a map on the issue tracker but resolves only the **one-way doors** — decisions whose
  reversal costs a rewrite. Everything else is **deferred with a trigger**. Fog then clears by
  moving: `/beachhead` picks the thin slice that would falsify those decisions soonest and hands
  it to `/to-spec` → `/to-tickets` → `/implement`; the map is **resurveyed** after every merge.
- **It dissolves, it doesn't hand off.** Each slice carries its own spec, so there is no final
  collapse of the map into one. The map closes mid-build, once no one-way doors remain ahead.
- `/reversibility` holds the door vocabulary (one-way, two-way, trigger, locked, provisional).
  Its three-part test is the ADR test from `/domain-modeling` — one test, two uses.
- Upstream `/wayfinder` stays available for efforts whose destination genuinely is a **document**
  rather than running software.
- A well-scoped feature belongs on the plain main flow: `/grill-with-docs` → `/to-spec` →
  `/to-tickets` → `/implement`.
```

Two notes on cost:

- This is **always-loaded context** in every session in that repo, unlike a skill body which loads only when invoked. Fifteen lines is a fair price for routing you'd otherwise have to remember; trim it if the repo's `CLAUDE.md` is already long.
- Add it **per repo**, only where you actually run this flow. A repo doing ordinary feature work doesn't need it. For a global default instead, the same block goes in `~/.claude/CLAUDE.md`.
