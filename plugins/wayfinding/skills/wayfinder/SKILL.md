---
name: wayfinder
description: Chart a huge, foggy effort as a map of one-way doors on the issue tracker, clear only those, then push the fog back by shipping thin slices — resurveying the map after each one.
disable-model-invocation: true
---

A loose idea has arrived — too big for one agent session, and wrapped in fog: the way from here to the **destination** isn't visible yet. This skill charts the way as a **shared map** on the repo's issue tracker.

**Fog of war clears by moving.** Conversation, reading, and prototypes push it back a little; a slice running against real infrastructure pushes it back further than all three, and leaves the ground behind it walked. So the map is not resolved to clarity before anything is built. It resolves the **one-way doors** — the decisions whose reversal costs a rewrite — and then advances by shipping, resurveying after each slice as the view opens up.

The destination varies per effort, and naming it is the first act of charting — it shapes every ticket. Unlike a plan-only map, this one is **allowed to reach its destination**: the effort ends when the product has no one-way doors left ahead of it, not when the last question has been answered.

## Decide by the cheapest means

Your attention is the scarce input, not agent sessions. Route every question by **what kind of answer would settle it**:

- Settled by a **fact about the world** — an API's behaviour, a spec, a third-party constraint → **research** (AFK).
- Settled by a **fact about the system once built** — does this shape hold up, does this integration work → **slice** (AFK build, HITL review).
- Settled by a **reaction** — does this feel right to use, does this look right → **prototype** (HITL).
- Settled only by **your preference or authority** — product intent, business constraint, taste → **grilling** (HITL).
- Blocked by a **manual precondition** — an account, a credential, data that must exist → **task**.

Grilling is the most expensive instrument here, so it is the last resort rather than the default. `/grilling`'s own rule already says facts are the agent's job; this ranking is that rule applied to ticket types.

## Refer by name

Every map and ticket is an issue, so it has a **name** — its title. In everything you narrate and everything the map records, refer to it by that name. A wall of `#42, #43, #44` is illegible; names read at a glance. The name wraps its link, so the id rides inside it.

## The Map

The map is a single issue on this repo's issue tracker, labelled `wayfinder:map` — the canonical artifact. Its tickets are child issues of the map.

The map is an **index**, not a store. It lists what has been settled and points at the tickets holding the detail; a decision lives in exactly one place — its ticket — so the map only gists and links.

The **durable** artifacts are `CONTEXT.md`, the ADRs, and — when the destination has a real data model — `docs/model.dbml`. The map is scaffolding: it churns, shrinks, and is eventually closed. Anything that must outlive the effort belongs in the domain model, written the moment it crystallises via `/domain-modeling`, or in the shared shape, drawn the moment it crystallises via `/wayfinding:dbml`.

**Where the map, its child tickets, blocking, and frontier queries physically live is tracker-specific.** The issue tracker should have been provided to you — run `/wayfinding:setup-wayfinding-skill` if not (it configures the tracker and wires in the `slice` type and Deferred conventions automatically). Consult the tracker doc's "Wayfinding operations" section for how *this* repo expresses them. Absent a tracker, default to local markdown.

### The map body

The whole map at low resolution, loaded once per session. Open tickets are **not** listed — they are open child issues, found by query.

```
## Destination

<what reaching the end of this map looks like. One or two lines; every session orients to it before choosing a ticket.>

## Notes

<domain; skills every session should consult; standing preferences for this effort>

## Beachhead

<the slice currently being aimed at, or shipped — see /beachhead. One line.>

## Decisions so far

<!-- the index — one line per closed ticket, each tagged [locked] or [provisional] -->

- [<closed ticket title>](link) — [locked] <one-line gist of the answer>

## Deferred

<!-- two-way doors, consciously unanswered. Each carries a trigger. -->

- <the question, one line> — **trigger:** <the observable condition that reopens it>

## Not yet specified

<!-- fog: in-scope questions you can't phrase sharply yet; graduates as the frontier advances -->

## Out of scope

<!-- work ruled beyond the destination; closed, never graduates -->
```

When the destination has a data model worth sharing, name `/wayfinding:dbml` in `## Notes` the moment its file exists, alongside `CONTEXT.md` — Work a ticket's step 3 already tells every session to consult whatever Notes names, so this is how concurrent sessions land on one shape instead of each re-deriving it from whichever ticket they happened to pick up.

**Deferred and Not yet specified are different things.** Fog is *unspecifiable* — you can't phrase the question yet. Deferred is *specifiable and deliberately unanswered* — you can phrase it, you have judged it a two-way door, and you have written the condition that brings it back. Fog graduates into tickets or into Deferred; Deferred graduates into a ticket when its trigger fires.

### Tickets

Each ticket is a **child issue** of the map. Its body is the question, sized to one agent session:

```
## Question

<the decision, investigation, or slice this ticket resolves>
```

Each ticket carries a `wayfinder:<type>` label — one of `research`, `slice`, `prototype`, `grilling`, `task`.

A session **claims** a ticket by assigning it to the dev driving the map, **first**, before any work, so concurrent sessions skip it. That assignee *is* the claim.

Blocking uses the tracker's **native** dependency relationship, so the frontier renders in the tracker's own UI. A ticket is **unblocked** when every ticket blocking it is closed; the **frontier** is the open, unblocked, unclaimed children.

The answer isn't part of the body — it's recorded on resolution. Assets are linked from the issue, not pasted in.

## Ticket Types

Every ticket is **HITL** — worked *with* a human who speaks for themselves — or **AFK**, driven by the agent alone. A HITL ticket only resolves through that live exchange; the agent never stands in for the human's side of it.

- **Research** (AFK): Reading documentation, third-party APIs, or local knowledge bases to surface a fact a decision waits on. Resolved by a `/research` **subagent**. Fire these generously and in parallel — they cost you nothing.
- **Slice** (AFK build, HITL gate): A thin vertical cut, shipped to main, whose purpose is to **teach**. Where a task *does* in order to unblock a decision, a slice *ships* in order to produce one. Built through `/to-tickets` → `/implement` → `/tdd` → `/code-review`; resolved when it is merged and its resolution comment records what the build taught, including any decision it contradicted. Use when the honest answer to "how would we know?" is "build it and see," and the real thing costs about what a fake would.
- **Prototype** (HITL): Raise the fidelity of the discussion with a cheap, rough artifact to react to, via `/prototype`. Use when the fake is much cheaper than the real thing — UI look and feel, a state machine's ergonomics. When the reaction wanted is to the **data model itself**, reach for `/wayfinding:model-playground` instead — it seeds a throwaway Vue/React app from the current `.dbml` so the human clicks through the shape rather than reading it.
- **Grilling** (HITL): Conversation, via `/grill-with-docs`. Reserved for questions only your preference or authority settles.
- **Task** (HITL or AFK): Manual work a decision waits on — provisioning access, signing up for a service, moving data so its shape can be seen. Reach for `/wizard` where a human must click through it. The answer records what was done and any facts later tickets depend on.

## Fog of war

The map is *deliberately* incomplete: don't chart what you can't yet see. Beyond the live tickets lies the **fog of war** — decisions you can tell are coming but can't yet pin down. Resolving a ticket clears the fog ahead of it; shipping a slice clears more of it than resolving three.

**Fog or ticket?** The test is whether you can state the question precisely now — *not* whether you can answer it now. Ticket when the question is already sharp. Leave it in **Not yet specified** when you can't yet phrase it that sharply. A sharp question that is a two-way door goes to **Deferred**, not to a ticket.

## Out of scope

Fog only ever gathers *toward* the destination. Work beyond the destination is **out of scope** — it isn't fog, and it isn't deferred either; deferral is about timing, scope is about the boundary.

When a ticket turns out to sit past the destination, **close it** and leave one line in **Out of scope**: the gist, why it's out, and a link to the closed ticket. It stays out of **Decisions so far**, which records the route actually walked.

Out-of-scope work never graduates. It returns only if the destination is redrawn, and then as a fresh effort.

## Invocation

Three modes. **Never resolve more than one HITL ticket per session**; AFK tickets have no such cap.

### Chart the map

User invokes with a loose idea.

1. **Name the destination.** Run `/grill-with-docs` to pin down what this map is finding its way to. The destination fixes the scope, so it's settled first.
2. **Map the frontier.** Grill again, **breadth-first**: fan out across the whole space rather than deep on any thread, surfacing every open question you can see. Don't answer them — surface them.
3. **Triage every question by reversibility.** Invoke `/reversibility` and sort each into **lock now**, **defer**, or **out of scope**. This is the step that keeps the map light, and it is the step most easily skipped: a sharp question is not the same as a question worth a session. Charting is done when **every question surfaced in step 2 carries one of the three verdicts**, and each deferral carries a trigger. A destination with a real data model almost always owes it a lock-now ticket of its own — "what are the core entities and relations" — rather than letting the shape emerge slice by slice; `/reversibility`'s own examples name schema shape as a one-way door more often than it looks.
4. **Check the count.** Roughly five to seven "lock now" tickets is the shape of a well-triaged greenfield map. A larger set means two-way doors were sorted as one-way — re-run step 3 against the three-part test before creating anything.
5. **Create the map** (label `wayfinder:map`): Destination and Notes filled in, Decisions-so-far empty, Deferred holding the two-way doors and their triggers, the fog sketched into Not yet specified, Out of scope populated.
6. **Create the "lock now" tickets** as child issues, then wire blocking edges in a **second pass** (issues need ids before they can reference each other).
7. **Fire the research subagents** for every `research` ticket, in parallel, capturing findings on a throwaway `research/<name>` branch with a context pointer from the ticket.
8. **Name the beachhead.** Invoke `/beachhead` to pick the first slice, and write it into the map's Beachhead section. Charting ends here; it hand-resolves nothing.

### Work a ticket

User invokes with a map (URL or number). A ticket is **optional** — without one, you pick.

1. Load the **map** — the low-res view, not every ticket body.
2. Choose the ticket. If the user named one, use it. Otherwise take the first frontier ticket in order. **Claim it** before any work.
3. Resolve it — **zoom as needed**: fetch the full body of any related or closed ticket on demand; invoke the skills the `## Notes` block names, and the skill its type names.
4. Record the resolution: post the answer as a **resolution comment**, **close** the issue, and append a context pointer to Decisions-so-far tagged **[locked]** or **[provisional]** per `/reversibility`.
5. **Write the ADR** if the ticket was a one-way door — via `/domain-modeling`, which also owns the glossary update. This is where the effort's durable output accumulates.
6. Run **Resurvey** below.

### Resurvey

Run after every resolved ticket, and always after a slice merges — a slice teaches more than a conversation does, so this is where most of the map's movement happens. Work all five; the mode is done when each has been answered out loud, including with "nothing."

1. **What did it teach?** Take the resolution at face value and ask what is now known that wasn't. For a slice, that includes everything the build made obvious and nobody asked about. If what it taught touched the data model, refresh `/wayfinding:dbml` now, in this step — not batched for later — since this is the one step every ticket and every slice both pass through, and the map's Notes pointer to the file is only as good as how current it is.
2. **What did it invalidate?** Check the finding against Decisions-so-far. A contradicted **[provisional]** decision gets overwritten with a note on what corrected it. A contradicted **[locked]** decision stops the resurvey: re-run `/reversibility` across every ticket and deferral that hung off it, because the ground under them moved.
3. **Which triggers fired?** Walk **Deferred** and check each trigger against what just happened. A fired trigger becomes a ticket — re-triaged, since a two-way door can become a one-way door once something is built on it. Clear the line from Deferred so it lives only as its ticket.
4. **What graduated from fog?** Anything in **Not yet specified** now sharp enough to phrase goes to a ticket or to Deferred, per its reversibility. Clear the graduated patch.
5. **Does the destination still hold?** If the answer moved the destination, say so and stop — redrawing the destination is a charting act, not a step on the route.

Every third slice, run `/improve-codebase-architecture` before picking the next beachhead. Slices accrete; this is what stops the walking skeleton from calcifying into the architecture by default.

### Advance

After the resurvey, pick what happens next:

- **One-way doors on the frontier** → work a ticket.
- **Frontier clear, destination not reached** → `/beachhead` for the next slice.
- **No one-way doors left ahead and the rest is ordinary feature work** → the map has done its job. Note the closure on the map, close it, and drop into the plain main flow (`/grill-with-docs` → `/to-spec` → `/to-tickets` → `/implement`) for what remains.

The effort ends by **dissolving**, mid-build, not at a handoff gate. There is no final collapse of the map into one spec, because each slice already carried its own.

The user may run unblocked tickets in parallel, so expect other sessions to be editing the tracker concurrently.
