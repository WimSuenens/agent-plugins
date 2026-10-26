# Decision card

How a one-way door reaches the person. The product-owner writes the card; the lead posts it and walks the person through it.

The reader is the **decision-maker** named in `docs/agents/factory.md`. At `non-technical`, write for someone who owns the product and its budget but has never read the code. At `technical`, keep the same structure and add the technical detail inline.

## Template

```
## Decision: <one sentence in everyday words: what are we choosing?>

**Why now:** <what stays stuck while this is open>

### Option A: <name in everyday words>
- **For users:** <what they notice>
- **Cost and time:** <in days or weeks of work, and money where it applies>
- **Undoing it later:** <how much work, in days or weeks>

### Option B: <…>
<same three lines>

**Recommendation:** A, because <one reason in everyday words>.
**If we're wrong:** <what happens then, and what it costs to change course>

**Want to dig deeper?** Reply with a number:
1. **Ask me** — I explain with an example or comparison until it is clear.
2. **Look it up** — `/research` writes a sourced report on the options.
3. **Show me** — `/prototype` builds a throwaway version you can look at or click through. <when a prototype was already built: "Already built: <link>">
4. **Question me** — `/grilling` asks you questions until your own answer is clear.
```

## Rules

- **Consequences, not mechanisms.** Every option is described by what changes for users, cost, time, and the effort to undo it. The technical mechanism appears only at `technical`, after those three lines.
- **Every unavoidable term carries its meaning beside it**, in brackets, the first time it appears: "a queue (a waiting line where tasks are picked up one by one)".
- **A prototype built ahead of the card is linked under Show me**, so the person can look before choosing.
- **Two or three options.** More than three goes back to the architect to narrow down.
- **The recommendation is the product-owner's own pick**, with the architect's leaning noted when the two differ.
- **"Undoing it later" is concrete.** It is what makes this a one-way door, so it carries the most weight: "about three weeks of rework across every screen", never "hard to reverse".

## After the choice

The lead records the person's choice and their reason as a comment on the slice ticket. The architect writes the ADR, linking that comment. The card itself lives in `work/<id>/`, so it disappears with the item; the ADR and the ticket comment are what remain.
