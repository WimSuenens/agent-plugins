---
status: proposed
---

# The Obeya is a lens over the repo and the tracker and holds no truth

Issue [#122](https://github.com/WimSuenens/agent-plugins/issues/122), under spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121).

## Context

The factory's state is spread over the tracker, the repo and in-flight worktrees. The Obeya room gives it one visible surface. A surface that stores its own copy of that state would create a second truth that drifts from the first, and the owner could not fix it by editing a file.

## Decision

- The Obeya is a **lens**. The repo and the tracker stay authoritative; the app stores nothing of its own beyond a cache and never writes to either.
- All data reaches the app through one **source seam**: one internal interface that supplies read-model objects. v1's source pulls from the main checkout, each live worktree and the tracker. The UI and the schemas do not assume a file origin.
- **Themes** are presentation over the read model. A theme never computes, filters or derives data; it only draws what the read model holds.
- Anything an artifact does not let the app parse becomes a visible parse-failure object, never a silent omission.

## Consequences

- Every fact on screen can be changed by editing its source, and the page follows.
- An event-fed database can replace the repo-reading source later without touching the UI or the schemas.
- Logic a theme would need must be added to the read model, so every theme shows the same numbers.
- The app is only as fresh as its polling of the sources.

## Way back

Swap the source behind the seam (an event-fed source) without changing the UI. Giving the app a store that is the truth for anything would supersede this ADR and needs a decision card, because it creates a second truth.
