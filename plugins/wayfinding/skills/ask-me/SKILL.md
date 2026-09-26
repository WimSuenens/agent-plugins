---
name: ask-me
description: Ask which skill or flow fits your situation, in a repo running the wayfinding overlay. A thin override of ask-matt's routing for the one flow this overlay changes.
disable-model-invocation: true
---

# Ask Me

This is `/ask-matt` for a repo running the `wayfinding` overlay. `ask-matt` ships inside upstream's plugin, which Claude Code copies into a read-only cache — it can't be edited in place, so this is a separate skill rather than a patch.

1. Invoke `/ask-matt` (use `/mattpocock-skills:ask-matt` if the name is ambiguous with this skill) to load its full router.
2. Apply the override below on top of it. It touches only the one flow the overlay changes — the wayfinder on-ramp and its precondition. Everything else `/ask-matt` said — the main flow, on-ramps, codebase health, vocabulary, crossing sessions, standalone skills — stands as-is.

## The override

- **A huge, foggy effort — greenfield, or a build too big for one session** → `/wayfinding:wayfinder`, not bare `/wayfinder`.
  It charts a map on the issue tracker but resolves only the **one-way doors** — decisions whose
  reversal costs a rewrite. Everything else is **deferred with a trigger**. Fog then clears by
  moving: `/beachhead` picks the thin slice that would falsify those decisions soonest and hands
  it to `/to-spec` → `/to-tickets` → `/implement`; the map is **resurveyed** after every merge.
- **It dissolves, it doesn't hand off.** Each slice carries its own spec, so there is no final
  collapse of the map into one. The map closes mid-build, once no one-way doors remain ahead —
  unlike upstream's wayfinder, which hands the cleared map to `/to-spec` as one collapse.
- `/reversibility` holds the door vocabulary (one-way, two-way, trigger, locked, provisional).
  Its three-part test is the ADR test from `/domain-modeling` — one test, two uses.
- A data model complex enough that slices could drift on its shape → `/wayfinding:dbml` draws it
  once as a `.dbml` file with relation notes and a worked example; `/wayfinding:model-playground`
  turns that file into a throwaway Vue/React app so the human can react to the shape before it
  locks, instead of reading a schema and guessing.
- Upstream `/wayfinder` stays available for efforts whose destination genuinely is a **document**
  rather than running software.
- A well-scoped feature still belongs on the plain main flow: `/grill-with-docs` → `/to-spec` →
  `/to-tickets` → `/implement` — nothing above changes that.

**Precondition**: `/wayfinding:setup-wayfinding-skill`, not bare `/setup-matt-pocock-skills` — it runs the same interview and additionally wires in the tracker's `slice` type, the Deferred conventions, and the `wayfinder:slice` label.
