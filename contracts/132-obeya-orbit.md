# Contract 132 — Obeya Orbit theme

Issue [#132](https://github.com/WimSuenens/agent-plugins/issues/132) · Spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121) · [Contract 127](127-obeya-themes.md)

Paths:
- apps/obeya/app/themes/orbit/
- apps/obeya/test/orbit.test.mjs

Orbit is a theme folder (`app/themes/orbit/index.vue`); the registry picks it up and the switcher lists it. It takes only the `view` prop and does not fetch, compute or reshape data.

- The project direction is the core. Each board item is a node on the ring of its factory status. Rings run from the core outwards: Waiting on you, Blocked, Running, Ready, Backlog, Done, then any other status. Each ring is labelled `STATUS · count` (`data-ring`, `data-count`) and every status also has a glyph, so status is never colour alone.
- A ring shows at most `floor(2πr/38)` slots (minimum 6). A fuller ring shows one fewer item and a `+N` node (`data-test="orbit-more"`, `data-hidden`) that opens the full list of that ring. Nodes never overlap.
- Selecting a node (click, Enter or Space) fills the inspector; the selection is kept in `useState`, so it survives a theme switch.
- Provenance is shown on every object: a dashed node edge plus a `provenance` chip in the inspector, and a chip on direction, decisions, andon, intake, pending decisions and the "corrupt signal" parse-failure card.
- The sync ring drains over the refresh interval read from the page's `data-refresh-seconds`.
- Offline: system monospace fonts, no network URLs. The sweep, pulses, flicker and sync drain stop under `prefers-reduced-motion: reduce`. Below 1100 px the layout is one column, the map first.
