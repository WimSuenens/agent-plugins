# Contract 134 — Obeya theme: Transit

Issue [#134](https://github.com/WimSuenens/agent-plugins/issues/134) · Spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121) · Builds on [contract 127](127-obeya-themes.md)

Paths:
- apps/obeya/app/themes/transit/
- apps/obeya/test/transit.test.mjs
- apps/obeya/test/transit-source.mjs

Transit is a theme (contract 127): it receives `view` and presents it. The API seam is unchanged.

## 1. The map is generated from the read model

- The main route is the direction. Decisions made are solid stations in `order`; "you are here" follows them; pending decisions are dashed stations ahead of it.
- Each effort (`item.effort`) is a coloured line, in order of first appearance; items with no effort ride a "No effort" line. Items are stations, drawn by status (done, running, ready, waiting on you, blocked, backlog), and carry their number as label.
- Intake is a feeder line below the route that merges into it at an interchange.
- An open andon is a track closure (hazard bar, text "CLOSED") on its item's station, or on the route when it names no item.

## 2. Layout rule

Stations sit on a fixed grid (`STEP` apart, wider than any label), so labels never overlap. A row is capped (`CAPS` in `layout.ts`: 20 decisions, 16 per line, 10 ideas, 8 pending); beyond the cap the oldest stations fold into one aggregate station (`+N`) whose details give the status tally. The map scrolls sideways inside its own region. Full lists (items, decisions, intake) are always shown below the map, scrollable.

## 3. Status, provenance, interaction

- Status is shown by station shape and by text (tooltip, `aria-label`, departures row), never colour or animation alone.
- Provenance is in every station's tooltip and label; in-flight objects also get a dashed ring.
- Hover, focus or press a station for its details; selecting a station highlights its departure row and the reverse. The selection is `useState('obeya-selection')`, so it survives a theme switch.
- The only animation (the running pulse) sits inside `@media (prefers-reduced-motion: no-preference)`. Fonts are system fonts; there is no network access.
