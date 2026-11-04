## Decision: When the Lead tries out a change to its own way of working in one project, what is it never allowed to switch off, and how long may such a change stay in place before you look at it again?

**Why now:** The map lets the Lead try a countermeasure locally (a local countermeasure: a change to the factory's standard written into one project's `docs/agents/factory.md`, tried there before anyone proposes it for the plugin) without asking you. Until the bounds are set, the slices that build the andon (stop-the-line) and the per-run improvement loop cannot say what the Lead may and may not change, and the first local override has no fence. A skipped approval or a skipped check cannot be taken back afterwards, which is why this is your call and not the Lead's.

**Same in all options:**
- The Lead may change its own working method locally without asking you (decided on the map: "Changing the standard").
- Taking a local change into the plugin for every project (yokoten: spreading a proven improvement) stays a decision card for you.
- Every active override is listed, with its start date, in each hansei record (the fixed-format look-back comment left on every closed item) and in the project's hoshin view (the per-project page with measures over time and the current themes).
- How an override is written down and which rule wins when two disagree is left to a later slice; it is cheap to change.

### Option A: Wide fence, overrides reviewed at the next hoshin (the proposal as written)
- **For users:** You keep every approval and every check you have today: no item merges or reaches production without your yes, no QA or security verdict (the testers' and security reviewer's pass/fail) is skipped, the line can always be stopped, and no measure disappears to make numbers look better. An override can stay in place across several runs until the next hoshin review (the across-runs look at a project's direction), where you confirm it or it ends.
- **Cost and time:** About 1 day of work on the standard. About 5 minutes of your attention per active override at each hoshin review.
- **Undoing it later:** Loosening the fence later is about half a day of text changes, and nothing is lost meanwhile. The weak spot is the review moment: when or by whom a hoshin review is held is not yet specified on the map, so overrides could linger for many runs. Moving to a stricter expiry later costs about 1 day of text changes plus about 1 hour per project to walk through the overrides that piled up.

Technical detail: the fence is a "Never overridable locally" list in `references/protocol.md`, read by `skills/run/SKILL.md`: merge and production approvals; the decision-card route for one-way doors; QA and security verdicts as merge gates; the andon itself (the abnormality list and the right of any role to raise one); the memory rules and the shell-scope rules; the honesty rule for measures (no measure dropped or redefined to look better; uncaptured reads "not captured"). The Lead checks the project's overrides against that list at the start of every run and refuses any that crosses it. The hansei record gains an "Active overrides" field (name, start date); the hoshin view lists the same. Expiry: at each hoshin, every override is re-confirmed by you, promoted via a card, or removed.

### Option B: Narrow fence, only your direct approvals protected
- **For users:** Your yes is still needed for every merge, every production action and every one-way decision. Everything else is the Lead's to tune per project: it could, for example, skip the security review on small items, change what counts as an abnormality, or stop recording a measure. You would see those changes listed in the hansei records, but only after items had already gone through without them.
- **Cost and time:** About half a day of work on the standard. Same 5 minutes per override at each hoshin review.
- **Undoing it later:** Expensive and partly impossible. Every item merged while a check was switched off needs that check run after the fact, about half a day per item; whatever already reached end users stays out there until it is found. A measure that was not recorded is lost for those items for good, and the project's baseline (its reference numbers for "before") has to be reset and refilled, which takes several items of measuring without improving.

Technical detail: the "Never overridable locally" list holds only merge and production approvals and the decision-card route. QA and security gates, the andon, memory and shell scope, and the honesty rule become overridable. Visibility and hoshin expiry as in A. Your merge approval then rests on verdicts whose scope the Lead may have narrowed, which you would only learn by reading the override list.

### Option C: Wide fence, overrides end with the run unless you renew them
- **For users:** The same protection as A. In addition, every override ends at the close of the run in which it started. At the run's close, where you already see the run's A3 (the one-page write-up of one problem and its countermeasure experiment), you get one line per active override and choose: keep it for another run, propose it for the plugin (a card), or drop it. No override runs for long without your knowledge.
- **Cost and time:** About 1.5 days of work on the standard. About 2 minutes of your attention per active override per run, batched with the run's close, which you attend anyway.
- **Undoing it later:** Cheap. Moving back to A (review at hoshin only) is about half a day of text changes and loses nothing. Loosening the fence later is also about half a day.

Technical detail: fence, run-start check and hansei/hoshin visibility exactly as in A. The run's closing step (the per-run loop that replaces today's step 9) lists each active override with its start date and its before/after numbers against the baseline, and records your keep / promote / drop per override; a dropped override is removed from `docs/agents/factory.md` and the baseline gets a note. Renewal allows an experiment to span runs, so it does not settle the deferred question "how long a countermeasure experiment is measured"; that stays deferred to its trigger.

**Recommendation:** C, because it protects every approval and check you rely on today and gives each override a review moment that already exists (the run's close) instead of one the map has not defined yet, at a cost of a couple of minutes per override.
**If we're wrong:** If renewing overrides every run turns out to be tedious, moving to A's hoshin-only review is about half a day of text changes with nothing lost. If the wide fence turns out to block a countermeasure worth trying, that one rule can be loosened by its own card, about half a day. Choosing B and being wrong is the costly direction: skipped checks and unrecorded measures cannot be recovered.

**Want to dig deeper?** Reply with a number:
1. **Question me** — `/grilling` asks you questions until your own answer is clear.
2. **Ask me** — I explain with an example or comparison until it is clear.
3. **Look it up** — `/research` writes a sourced report on the options.
4. **Show me** — `/prototype` builds a throwaway version you can look at or click through.
