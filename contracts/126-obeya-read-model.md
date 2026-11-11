# Contract 126 — Obeya read model

Issue [#126](https://github.com/WimSuenens/agent-plugins/issues/126) · Spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121) · [ADR 0019](../docs/adr/0019-the-obeya-is-a-lens-and-holds-no-truth.md)

Paths:
- contracts/obeya/
- apps/obeya/server/
- apps/obeya/shared/
- apps/obeya/scripts/gen-types.mjs
- apps/obeya/test/
- tests/factory/stub-gh/gh

The schemas in `contracts/obeya/*.schema.json` (JSON Schema draft-07) are the contract. This page describes behaviour and points at them. Another factory or tool can implement the same read model from the schemas alone.

## 1. Objects

| Schema | Meaning |
|---|---|
| `item.schema.json` | A board card: factory status, kind, role, and the **effort** it belongs to (its parent map, or `null`). |
| `decision.schema.json` | An ADR or a decision card, with an `order` (and a `date` where there is one). |
| `direction.schema.json` | The project's goal and current direction. |
| `andon.schema.json` | An andon, with its item, reason and whether it is resolved. |
| `intake-entry.schema.json` | An idea in the intake queue, its outcome and reason. |
| `parse-failure.schema.json` | An artifact the app could not read: its `path` and the `reason`. |
| `provenance.schema.json` | `merged`, `in-flight` on a named `item`, or `event`. Every object carries one. |

No object assumes a file origin. `ref` and `path` are names in the source's own terms (a path for the repo source, a url for a tracker).

Provenance in v1: an artifact on the main checkout is `merged`; an artifact that exists only in a live worktree, or differs from the main copy, is `in-flight` on that worktree's branch; a fact read from the tracker is `event`.

## 2. API

`GET /api/projects/<id>/<kind>` returns a JSON array of validated objects, for `items`, `decisions`, `directions`, `andon`, `intake` and `parse-failures`. Empty lists are valid while a view is not built.

| Status | When |
|---|---|
| 200 | An array; every element has been validated against its schema. |
| 404 | No project with that id. |
| 409 | The project path is missing or not a git repository. |
| 502 | The tracker could not be read. |
| 500 | The source produced an object that fails its schema. It is never served. |

## 3. Visible degradation

An artifact that is missing a required block or fails its schema becomes one parse-failure object with the path and the reason. It is never dropped. For ADRs v1 requires: a file name `NNNN-<slug>.md`, a front matter block with `status:`, and a `# title` heading. A board card not linked to an issue is a parse-failure too.

## 4. Source seam

`ReadModelSource` (`apps/obeya/server/source/types.ts`) is the one interface that supplies read-model objects. Nothing outside `server/source/` reads the filesystem or runs `gh`. The v1 repo source reads the main checkout and every worktree from `git worktree list`, and the tracker through `TrackerAdapter`. `OBEYA_SOURCE_MODULE` names a module whose default export replaces the source (for an event-fed source later, and for tests).

## 5. Tracker adapter

`TrackerAdapter.cards(tracker)` returns board cards. The `gh` implementation runs only `project item-list`, `issue list|view` and `pr list|view`; any other command is refused in code. A project names its board with `tracker: {owner, projectNumber}` in `OBEYA_PROJECTS`; without it there are no items.

## 6. Generated types

`npm run gen:types` (in `apps/obeya`) writes `shared/generated/read-model.d.ts` and `shared/generated/schemas.json` (the schemas bundled for runtime validation) from the schemas. `npm run check:types` exits 1 when they are stale, and `npm run build` runs it first, so a stale generated file fails the build.
