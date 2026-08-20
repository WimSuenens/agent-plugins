---
name: beachhead
description: Pick the thin slice that would falsify the map's one-way doors soonest, frame it, and hand it to the build chain.
disable-model-invocation: true
---

# Beachhead

A **beachhead** is the thinnest slice that lands on real ground: it runs end to end, ships to main, and **exercises every seam the map's locked decisions touched**. Its job is to falsify those decisions while they are still cheap to be wrong about.

This skill picks and frames the slice. It builds nothing — `/to-spec`, `/to-tickets`, `/implement` do that, unchanged.

**A beachhead is not a prototype.** A prototype is throwaway code that answers a question; a beachhead is production code whose *first* job is answering one. The output stays. Reach for `/prototype` when the fake is much cheaper than the real thing; reach for this when they cost about the same and you want the learning to persist in the codebase rather than on a dead branch.

You will run this several times per map — once for the first slice, then again at each **Advance** step of `/wayfinding:wayfinder`. The judgement is the same every time; only the remaining doubt has moved.

## Pick the slice

Work from the map. Ticket detail is available by zooming, but the selection is made at the map's resolution.

1. **List the exposure.** Read Decisions-so-far and pull every **[provisional]** decision, plus every **[locked]** one that shipped code has not yet exercised. This list is the doubt the slice exists to attack. If it is empty, there is nothing to falsify — say so and route back to `/wayfinding:wayfinder`'s Advance step.
2. **Find the seams each one touches.** Invoke `/codebase-design` for the vocabulary. A decision about temporality touches the read path; a decision about tenancy touches every query boundary. Name the seam, not the file.
3. **Draft candidate slices.** Each candidate is one narrow but **complete** path through every layer, describable as a sentence a non-developer understands — "an admin creates an org unit and sees it in the hierarchy an hour later." Two or three candidates is enough.
4. **Score by exposure per unit of build.** The winner touches the most doubtful decisions for the least work. A slice that exercises three provisional decisions beats a slice that exercises one, at equal cost. Reach for real infrastructure — real tenant, real identity provider, real database — because **a mock falsifies nothing**: the seams a mock stands in for are exactly the ones carrying the doubt.
5. **Put the candidates to the user** as a numbered list, each with the decisions it would test and the work it implies, and your recommendation. Wait for the choice. Selection is theirs.

## Frame it

Once chosen, write the frame before any build. Post it on the map's `slice` ticket:

```
## Question

<what this slice is built to find out — the decisions it puts under load>

## Behaviour

<the end-to-end path, one or two sentences, from the user's perspective>

## Under test

- [<decision>](link) — <what result would contradict it>

## Deliberately faked

- <what is stubbed, and which deferred decision that stub belongs to>
```

**Under test** is the load-bearing section. A decision listed without a stated contradiction is not really under test — you would ship the slice, see it work, and learn nothing. Write the observation that would prove you wrong, before you know the answer.

**Deliberately faked** is how deferral survives contact with code. Every stub is a two-way door someone chose not to open; naming it here keeps the choice visible in the diff instead of hardening into an accident. Where the stub corresponds to a line in the map's **Deferred** section, link it, and consider whether shipping the slice *is* that line's trigger.

Update the map's Beachhead section to name the chosen slice.

## Hand off

Hand the framed slice to the build chain:

- **Big enough to need a spec** → `/to-spec`, scoped to this slice alone rather than the whole map, then `/to-tickets`, then `/implement` per ticket.
- **Small enough not to** → `/to-tickets` straight from the frame, then `/implement`.

`/implement` closes out with `/code-review` as usual. Its Spec axis reads the slice's spec or the frame — not the map, which describes an effort no single slice implements.

When the slice merges, return to `/wayfinding:wayfinder`'s **Resurvey** with the **Under test** list in hand: each line is a question the build has now answered.

## Sizing

A beachhead is done when it is **merged and demoable**, so it has to fit through the build chain without stalling.

- **Too thin** when it exercises no seam a mock wouldn't have — a slice that proves the framework starts is not a beachhead.
- **Too fat** when its ticket set can't be worked in a handful of sessions, or when it puts more than a few decisions under test at once and a failure won't tell you which one broke.
- **Wrong shape** when it is horizontal: a whole layer, complete and connected to nothing. The slice is vertical or it teaches nothing.

When the honest answer is that no thin slice reaches the doubtful decision, that is a finding: the decision may need a `prototype` or `research` ticket instead, or the architecture may have no seam there yet — which is `/improve-codebase-architecture`'s question, not this one's.
