---
name: dbml
description: Draw the shared data model as a .dbml file with relation notes and a worked example, so every wayfinder session sees the same shape without re-deriving it from code.
disable-model-invocation: true
---

# DBML

A **shared shape** other sessions can load instead of re-deriving one from code, migrations, or a scattered thread of ADRs. This skill draws it as a single `.dbml` file — real DBML syntax, not prose pretending to be a schema — because DBML is dense enough to hold the whole shape in one screen and standard enough that any renderer (dbdiagram.io, `@dbml/cli`) draws it back out as a diagram.

Hinted from `/wayfinding:wayfinder`: once the map's core-entities ticket locks, and again on that skill's Resurvey whenever a ticket or slice turns out to have touched the model — see its Notes-pointer and Resurvey steps for when.

## Where it lives

Read this repo's `docs/agents/domain.md` for the file-structure convention (single- vs. multi-context). If it already names a data-model path, use it. If it doesn't, default to `docs/model.dbml` beside the repo's `CONTEXT.md` (or `src/<context>/docs/model.dbml` beside each context's `CONTEXT.md` in a multi-context repo) — then add the path to `domain.md` so the default becomes the convention rather than a one-off guess.

## Draw it

1. **Reuse, don't invent.** Read `CONTEXT.md`'s glossary before naming anything — a table or column that drifts from the glossary's term is a naming bug, not a stylistic choice. If the concept isn't in the glossary yet, that's `/domain-modeling`'s gap to fill, not this skill's to paper over.
2. **Reconcile with what's shipped.** If code, migrations, or an ORM schema already exist, the `.dbml` describes *them* — read the real schema before drafting, and flag any place it has drifted from a locked decision rather than silently picking a side.
3. **Write the tables and refs** in DBML: `Table`, `Ref`, `Enum` as needed, one file, real column types.
4. **Explain the non-obvious relations in place.** For every relation whose shape traces to a locked decision, attach a DBML `Note` on the table or ref citing the ADR — `Note: 'ADR-0004: soft-deleted, never hard-removed'` — rather than restating the reasoning. A relation with no story behind it needs no note; don't narrate the obvious.
5. **Write one worked example**, as a `Note` on the `Project` block: a short, concrete walkthrough using the project's actual domain — real-sounding names and values, not `foo`/`bar`/`Lorem` — that touches every table at least once and shows the relations actually holding together. This is the seed data `/wayfinding:model-playground` will use, so make it something a prototype can populate a screen with, not just a schema sanity check.
6. **Check it parses.** Run `npx @dbml/cli` (or whatever DBML tooling the repo already has) if available; otherwise re-read the file for unbalanced refs and mismatched types by hand. A `.dbml` nobody can trust is worse than none.

## Keep it current

This file drifts the moment a ticket changes the model and nobody updates it — that's the failure mode it exists to prevent. Re-run this skill, don't hand-edit around it, whenever `/wayfinding:wayfinder`'s Resurvey finds that a ticket or slice touched the model, and confirm the map's `## Notes` still points here.

Done when: the file parses, every entity and relation from Decisions-so-far is represented, every non-obvious relation cites its ADR, the worked example touches every table, and `CONTEXT.md` or `domain.md` points at the file.
