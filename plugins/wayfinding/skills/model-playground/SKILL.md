---
name: model-playground
description: Turn the current .dbml model into a throwaway Vue or React app seeded with its worked example, so a human can click through the shape and react before it locks.
disable-model-invocation: true
---

# Model Playground

A **reaction instrument** for the data model specifically — the same instrument `/prototype` is for UI feel and state-machine ergonomics, aimed at a schema instead. Reach for this when the honest question is "does this shape feel right to work inside," not "does it hold up under real infrastructure" (that's a `/beachhead` question) and not "is it internally consistent" (that's `/wayfinding:dbml`'s).

This skill frames and hands off; `/prototype` still owns the disposability rules — throwaway code, never persisted, cheap because the fake costs far less than the real thing. Don't re-derive those here, invoke it.

## Before building

1. **Load the shape.** Read the repo's `.dbml` file (see `/wayfinding:dbml` for where it lives — run that skill first if it doesn't exist yet, there's nothing to prototype against without it) and its worked example.
2. **Name the reaction under test**, the same discipline `/beachhead` applies to a slice: one or two sentences on what a bad reaction would look like — "creating a Booking with three LineItems takes more clicks than it should," "the Org → Membership cardinality is confusing to navigate." Write it down before building; a reaction nobody defined in advance is nothing to fail.
3. **Pick the stack.** Vue or React — whichever the target codebase already runs (check `package.json`); if there's no surrounding app yet, default to whichever the human names, or ask.

## Build it

Hand off to `/prototype` for the actual build, with this app's shape:

- One screen or list per entity in the `.dbml`, seeded in-memory from its worked example — no backend, nothing persisted past the session.
- Forms that respect the relations as constraints the human *feels*, not just reads: a foreign picker limited to what the model allows, a cardinality the UI actually enforces.
- At least one flow that crosses the relation named as under test, end to end.

## Resolve it

The human reacts live — this is HITL; the agent never stands in for that reaction. Capture it as the ticket's resolution comment: what felt right, what didn't, and which relation, if any, it contradicts.

A contradicted relation is a finding for `/wayfinding:wayfinder`'s Resurvey, same as a slice's would be: if the relation was still **provisional**, revise the `.dbml` via `/wayfinding:dbml` and move on; if it was already **locked**, stop and re-triage everything that hung off it.

Done when: the human has said yes, no, or needs-changes about the specific reaction under test — not when the UI is polished. Throw the app away once the reaction is recorded; nothing here is meant to outlive the ticket.
