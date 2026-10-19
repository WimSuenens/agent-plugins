# Psychology-driven patterns

For `design-system` step 4: include the patterns for the product moments the context round named. Each pattern is where a principle becomes a rule a screen can follow. Every one must pass the three-check test (`/design:ux-psychology`); its honest boundary is stated with it.

## Forms

- **Smart defaults**: pre-fill the most common or safest value for every field you can infer; presets for common quantities. *Principle:* defaults (read as advice). *Boundary:* never pre-tick consent, add-ons or paid extras.
- **Labels above, errors below, validation on blur**: *Principle:* split attention, recognition over recall.
- **Ask only what this step needs; infer the rest** (address lookup, card type from number). *Principle:* Tesler — move complexity to the system.
- **Chunk long inputs** (card numbers, IBANs, codes) in groups of ~4. *Principle:* working-memory limit.

## Primary action

- **One primary action per view**, visually distinct, in thumb reach on mobile (sticky bottom bar on long pages, never covering focus). *Principle:* Von Restorff, Fitts.
- **The label states outcome and cost** ("Pay €49.00", "Add 2 kg — €9.80"). *Principle:* working-memory limit, anchoring (honest reference). *Boundary:* hidden costs fail check 1.
- **Decline is symmetric**: secondary actions are visible, neutral and as easy to hit. *Principle:* framing. *Boundary:* confirmshaming and grey-on-grey "no thanks" fail check 2.

## Progress and onboarding

- **Credit real completed steps**: count account creation, verified email, imported data. *Principle:* goal gradient, endowed progress. *Boundary:* progress for nothing done fails check 1.
- **Value before the ask**: the user gets a real, usable result or builds something real before signup. *Principle:* reciprocity, IKEA effect. *Boundary:* gating the result after the user did the work, without saying so upfront, fails checks 1 and 3.
- **Start small**: the first step is one easy, genuinely useful choice. *Principle:* commitment and consistency.
- **Resume, don't restart**: save progress automatically; offer "continue where you left off". *Principle:* Ovsiankina resumption.

## Pricing display

- **Honest reference points**: show price beside what it's relative to (base product, per-unit, per-month vs annual totals stated plainly). *Principle:* anchoring, relative thinking. *Boundary:* fake "was" prices and relative framing that hides a recurring cost fail check 1.
- **Recommend for uncertain buyers**: mark one plan as recommended when options are complex. *Principle:* choice overload moderators, defaults. *Boundary:* the recommendation must fit the user, not the margin (check 3).
- **All-in totals before commitment**: taxes and fees visible before the final step. *Boundary:* drip pricing fails check 1.

## Upgrade, downgrade and cancel

- **State real consequences**: what the user keeps, what changes, what they lose, with real numbers. *Principle:* loss aversion, framing. *Boundary:* invented losses and arbitrary countdowns fail check 1.
- **Exit as easy as entry**: cancel in as many steps as subscribe, with a neutral label ("Not now", "Cancel plan"). *Principle:* status quo. *Boundary:* roach motels fail check 2.
- **End well**: confirm clearly and leave the door open. *Principle:* peak–end.

## Empty states and confirmations

- **Empty states show the value to come and one first action.** *Principle:* reciprocity, commitment.
- **Confirmation screens are the "end" users remember**: state what happened, what's next, and how to undo. *Principle:* peak–end.
- **Feedback within ~100 ms; progress past ~1 s.** *Principle:* response-time bands.
- **Stopping cues in feeds** ("You're all caught up"). *Principle:* variable reward used honestly (check 3).
