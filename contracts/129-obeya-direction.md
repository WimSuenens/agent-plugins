# Contract 129 — Obeya direction

Issue [#129](https://github.com/WimSuenens/agent-plugins/issues/129) · Spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121) · [contract 126](126-obeya-read-model.md)

Paths:
- docs/direction.md
- contracts/obeya/direction.schema.json
- apps/obeya/server/source/direction.ts
- apps/obeya/app/components/DirectionPanel.vue
- apps/obeya/test/direction.test.mjs
- plugins/factory/agents/product-owner.md
- plugins/factory/skills/run/SKILL.md
- plugins/factory/skills/setup-factory-skill/assets/factory.md
- docs/agents/factory.md

## 1. The document

A project has one direction document, `docs/direction.md`, owned by the product-owner (ownership table). The Obeya renders it and never writes it.

```
---
goal: <one line: where the project is going, in the end>
current: <one line: the current heading>
---

# Direction

## History

- 2026-11-10: <what changed the direction, and why; name the idea>
```

- `goal` and `current` are single-line front matter fields; both are required.
- `## History` is required and may be empty. Each line is `- YYYY-MM-DD: <text>`, oldest first. Any other line in the section is a parse failure.
- Everything else in the file is free prose and is not read.

## 2. Who updates it

When intake triage decides an idea has the outcome **direction** ([contract 110](110-idea-intake.md)), the product-owner updates `docs/direction.md` in the same item: `current` (and `goal` if it moved) and one new History line naming the idea. Earlier lines stay.

## 3. Read model

`GET /api/projects/<id>/directions` returns `Direction` objects ([schema](obeya/direction.schema.json)): `id`, `goal`, `current`, `history` (`date`, `change`), `ref` (`docs/direction.md`) and `provenance`.

- Present on the main checkout: one object, `merged`.
- A worktree copy that equals the main one is not repeated. A changed or new one is a further object, `in-flight` on the worktree's branch (id `direction@<branch>`).
- Missing everywhere: an empty list. This is not an error; the page shows "No direction yet" and how to create the file.
- Malformed (no front matter, no `goal`, no `current`, no History section, a bad History line): no object, and a parse-failure with path `docs/direction.md` and the reason, on `parse-failures`.

## 4. Page

`DirectionPanel` shows goal, heading, history, the source path and the provenance chip for each object, or the empty state. A theme places it; it does not compute it.
