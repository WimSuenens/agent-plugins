# Brief: product-owner — frontier-53 (covers #53, #54, #55 for map #50)
Goal: Write ONE decision card carrying three decisions (A = #53, B = #54, C = #55), in the order A, B, C.
Inputs: `plugins/factory/references/decision-card.md` (template and rules, read first); `work/frontier-53/02-options-architect.md` and `work/frontier-53/02-result-architect.md` (the architect's options, undo costs, leanings, dependencies); tracker #50, #53, #54, #55; `docs/agents/factory.md` (decision-maker: technical).
Constraints:
- Structure: a short opening (why now, what stays stuck), then three sections each in the card template (two or three options, For users / Cost and time / Undoing it later, then the technical mechanism after those lines, recommendation, If we're wrong), then a closing "Want to dig deeper?" block once for the whole card. Each section ends with an answer line the person can fill: `Decision A: <option>`.
- State the dependencies between the doors on the card: B1 depends on A1 (if A is overturned, B takes its alternative B2); C depends on B (needs Waiting on you and Blocked); A and C are independent. Say what each overturn does to the others.
- Say that after 2.0.0 undoing A or B is itself a 3.0.0 release, undoing C a minor. For C, say plainly that setting the limit to 1 restores one-at-a-time at once, and why it is still a card (ADR 0007 says the opposite).
- Settled by the person on 2026-11-07, not options: the whole map is one slice released as 2.0.0; old state mechanism kept until the run closes; migration is a `setup-factory-skill` step; status mapping Designed→Ready, In progress and In review→Running, Ready to deploy→Waiting on you; no acceptance demo.
- Recommendation is your own; note where it differs from the architect's leaning.
- Write no tracker comment (the lead posts it). No absolute path under the home directory.
Output: `work/frontier-53/04-card-product-owner.md` and a result `work/frontier-53/04-result-product-owner.md`. Commit your own paths, subject starting `#53 product-owner: `.
Done: one card in the template, three decisions with answer lines, dependencies stated, result written.
