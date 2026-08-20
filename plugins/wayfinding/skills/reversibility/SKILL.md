---
name: reversibility
description: Shared vocabulary for sorting decisions by cost of being wrong — one-way doors, two-way doors, deferral triggers, and provisional vs locked. Use when triaging what must be settled before code, deciding whether a decision earns an ADR, writing a deferral trigger, or when another skill needs the door vocabulary.
---

# Reversibility

Sort decisions by **cost of being wrong**, not by how sharply you can phrase them. This vocabulary is the substrate under `/wayfinding:wayfinder` and `/beachhead`; reach for it directly whenever the question is *does this have to be settled now*.

## Glossary

Use these terms exactly. Consistent language is the whole point.

- **One-way door** — a decision whose reversal costs a rewrite rather than a refactor. Getting it wrong is discovered late and paid for once, in full. Settle it before code touches it.
- **Two-way door** — a decision you can walk back for the price of an ordinary change. Settling it early buys nothing: you settle it at the moment of maximum uncertainty and minimum feedback.
- **Blast radius** — how much of the system a reversal touches. A decision with a wide blast radius is a one-way door even when each individual edit is trivial; the radius is what makes it expensive, not the difficulty of the edit.
- **Trigger** — the observable condition that reopens a deferred decision. A deferral without a trigger is an abandonment.
- **Locked** — validated by shipped code, or irreversible by nature and settled deliberately. It constrains everything downstream.
- **Provisional** — reached by reasoning and not yet exercised by anything running. A guess wearing the formatting of a fact, and downstream work should be able to see that.

## The test

A decision is a **one-way door** when all three hold. These are the ADR criteria from `/domain-modeling`, and the overlap is deliberate: **every one-way door earns an ADR, and nothing else does.** One test, two uses.

1. **Hard to reverse** — the cost of changing your mind later is meaningful.
2. **Surprising without context** — a future reader will wonder why it was done this way.
3. **The result of a real trade-off** — there were genuine alternatives and one was picked for specific reasons.

Miss any of the three and it is a **two-way door**.

Judge the reversal, not the decision. "Which auth provider" sounds weighty and is usually a two-way door behind an adapter; "does an entitlement carry its own validity period" sounds like a schema detail and is a one-way door, because every query, every audit trail, and every historical answer depends on the answer.

Four shapes that are one-way doors more often than they look:

- **Temporality.** Whether history is recorded, and whether the record separates *what was true* from *what was believed*. Retrofitting time into a model that never had it touches every read path.
- **Identity and ownership.** What the stable key for a thing is, and which context owns it. Everything downstream keys off the answer.
- **Derived or asserted.** Whether a value is computed from other state or stated and then reconciled. The two produce different tables, different invariants, and different failure modes.
- **Isolation.** Tenancy, residency, and the boundaries regulation draws. Hard to reverse in ways no code review reveals.

## The three verdicts

Every question sorted lands on exactly one:

- **Lock now** — a one-way door on the route to the destination. Gets a ticket; its resolution gets an ADR.
- **Defer** — a two-way door. Gets one line and a **trigger**. No ticket, no session, no ADR.
- **Out of scope** — beyond the destination. Scope, not reversibility, lands it here; a one-way door past the destination is still out of scope.

## Writing a trigger

The trigger is what makes deferral a decision rather than a shrug. Make it something you trip over without going looking:

- **Observable.** A condition someone hits — "the first slice that reads org state as of a past date", "the second tenant onboards", "a customer asks for bulk export". Prefer conditions that arise from work already planned.
- **Attached to the work that fires it.** When a trigger names a slice, record it on the slice too, so the resurvey after that slice already knows to reopen the question.
- **Dated as a backstop** where no event will do. "Revisit by the pilot" beats an open condition nobody watches.

A trigger you cannot phrase observably means you mis-sorted: the decision is either a one-way door you are avoiding, or genuinely out of scope.

## Locked and provisional

Tag every recorded decision. The tag says how much weight downstream work may put on it.

A decision starts **provisional** when it came from conversation, reasoning, or a throwaway prototype. It becomes **locked** when shipped code has exercised it, or when it is irreversible by nature and the trade-off was made deliberately.

A provisional decision that a slice contradicts is the slice doing its job: overwrite it, record what the build taught, carry on. A **locked** decision that a slice contradicts is a different event — stop, and re-run the triage on everything that hung off it.
