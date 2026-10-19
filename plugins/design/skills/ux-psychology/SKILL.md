---
name: ux-psychology
description: UX-psychology vocabulary — named principles (Gestalt, Hick, Fitts, defaults, loss aversion, goal gradient, dark patterns, …), each with its mechanism and evidence grade. Use when designing or critiquing UI, justifying a design decision, judging whether a persuasion technique is manipulative, or when another skill needs the UX-psychology vocabulary.
---

# UX psychology

Design from **mechanism**: why the mind does this. A principle you can explain predicts where it stops working; a trick you can only name does not. Use these terms exactly, so a finding, a design rule and an ADR all say the same thing.

## Evidence grades

Every principle carries one grade. Quote the grade, never a statistic: popular numbers ("2000%", "70–90%", "2x") are almost always the most extreme figure from one condition, stripped of its denominator.

- **replicated**: survives replication or meta-analysis. Build on it.
- **contested**: real, but size or generality is disputed. Use it as a hypothesis, test it.
- **folklore**: widely repeated, no solid primary support. Use it as a convention at most, never as a justification.

A "law" is often a maxim: Fitts and Hick–Hyman are fitted models; Jakob's and Tesler's are essays.

## Glossary

Each entry: **term** (grade): mechanism → design implication. Persuasion principles add the **manipulative form**: the same mechanism turned against the user, judged by the three-check test below.

### Perception

The visual system groups and ranks a screen before conscious attention arrives.

- **Proximity, similarity, common region, continuity, figure–ground** (replicated): Gestalt grouping; near, alike, enclosed or aligned things read as one group, perceived before any label. → Tighter spacing inside a group, looser between. A container (common region) overrides proximity, so use it sparingly. Things that look alike will be read as doing the same thing. An icon that vanishes on a bright photo is a figure–ground failure.
- **Visual hierarchy / pop-out** (replicated): an item unique on one feature (colour, size, luminance, motion) is found pre-attentively; varied distractors kill pop-out. → Hierarchy is contrast on few dimensions, used rarely. Saturated colour everywhere means nothing pops out.
- **Von Restorff / isolation** (replicated): an item distinct from its context is remembered better, through memory and not only attention. → One distinctive element per view (primary CTA, recommended badge, error). Inconsistent icons or off-system images are accidental isolates. Limit: banner blindness, where salient-but-ad-like elements are ignored. **Manipulative form:** visual interference, a bright "Accept" beside a grey "no thanks".

### Attention and memory

- **Working-memory limit** (replicated for Cowan's ~4 chunks; folklore for "7±2 menu items"): only a few chunks stay active at once; a visible menu is recognition, not recall. → Never make users carry information between screens: keep the summary visible, the title sticky. Prefer recognition over recall. Chunk long strings in groups of ~4.
- **Cognitive load** (replicated effects, criticised accounting): design can only cut **extraneous** load. → **Split attention**: put labels, errors and help next to their target. **Redundancy**: drop labels and icons that repeat what's already obvious ("Price:" next to €4.99).
- **Serial position** (replicated): first and last items in a sequence are recalled best. → Key items at the ends of lists and tab bars; matters for what users must remember later, less for what they scan.
- **Zeigarnik** (contested: the memory claim fails meta-analysis) vs **Ovsiankina** (replicated tendency to resume interrupted tasks). → Justify checklists by resumption and goal gradient, not by "users remember unfinished tasks". Make resuming easy: drafts, "continue where you left off". **Manipulative form:** manufactured incompleteness ("profile 60% complete" for data only the business needs).
- **Peak–end** (replicated): experiences are judged by their most intense moment and their end; duration is mostly ignored. → Invest in the worst moment (errors, payment failure, waits) and the last (confirmation, offboarding). **Manipulative form:** a celebratory ending masking hidden fees.

### Interaction cost

- **Hick–Hyman** (replicated for practised, ordered choices; folklore stretched beyond): choice time grows with log(options) only when items are familiar and ordered; unfamiliar lists are scanned linearly. → Group and order lists; cut options mainly for novices and unordered sets. Not the same as choice overload.
- **Fitts** (replicated): acquisition time grows with distance, shrinks with size. → Primary actions large and near the thumb or pointer; sticky bottom action bars on mobile; screen edges are deep targets on desktop. **Manipulative form:** a huge "Accept all", a tiny "Manage options".
- **Response-time bands** (replicated: ~0.1 s instant, ~1 s flow, ~10 s attention; the "400 ms Doherty threshold" is contested, from an unreviewed report). → Acknowledge input within ~100 ms; show progress past ~1 s; determinate progress plus backgrounding near 10 s.
- **Tesler's law** (folklore, a useful maxim): complexity is conserved; someone handles it. → Before removing a field, ask where its complexity goes. Defaults, lookups and inference move it to the system; hiding it moves it to a worse moment.
- **Progressive disclosure** (contested): essentials first, the rest on demand. → Hide by frequency of use, never by business preference; keep revealed options in a stable place. **Manipulative form:** fees, renewals and data sharing behind an "advanced" expander.
- **Jakob's law** (replicated mechanism, positive transfer; the "law" is an essay). → Follow platform conventions; spend novelty only where it is the product's value.

### Decision-making

- **Defaults** (replicated, large variance): read as recommendations, become the reference point, and cost effort to change. → Default to what most users would choose on reflection, or the safest option; a default is advice, so own it. Presets from real usage data are smart defaults. **Manipulative form:** preselection, pre-ticked add-ons or consent.
- **Choice overload** (contested; meta-analytic average near zero): appears only with complex options, uncertain preferences or a wish to decide fast. → Large sets are fine when easy to compare (sort, filter, clear attributes); curate or recommend for plan pickers and onboarding. **Manipulative form:** overwhelm to push the high-margin option; comparison prevention.
- **Anchoring / relative thinking** (replicated for explicit anchors): values pull toward a reference; price differences feel relative. → Show prices against honest references; order plans deliberately, since the first price seen sets the ruler. **Manipulative form:** fake "was" prices, inflated preset quantities, "just 2.6%" hiding a monthly cost.
- **Decoy / asymmetric dominance** (contested; holds mainly for numeric comparison tables). → Weak lever in pricing tables; never build strategy on it. **Manipulative form:** phantom tiers nobody is meant to buy.
- **Framing** (replicated): the same outcome as gain or loss changes choices. → Wording is design: choose the frame that helps users decide accurately, and keep it consistent across options. **Manipulative form:** confirmshaming, trick wording, double negatives.
- **Loss aversion** (contested in size and reach): losses weigh more than equal gains, measured mostly on risky gambles. → Tell users accurately what they will lose ("Downgrading archives 3 projects"). **Manipulative form:** invented losses, resetting countdowns, "I'll risk it" dismiss buttons.
- **Status-quo bias** (replicated): people stick with the current state. → Let users keep familiar settings through redesigns; make the new behaviour the default for new users. **Manipulative form:** roach motel, where cancelling is harder than subscribing.

### Motivation and habit

- **Fogg behaviour model, B = MAP** (contested as a model; useful diagnostic): behaviour needs motivation, ability and a prompt at once. → When users don't act, ask which is missing; reducing friction is usually cheapest. **Manipulative form:** nagging after a decline.
- **Goal gradient** (replicated) / **endowed progress** (contested, one strong field study): effort accelerates near a goal; perceived head start raises completion. → Show progress and credit real steps already done (account created, email verified) so nobody starts at 0%. **Manipulative form:** fabricated progress, streak anxiety.
- **Variable reward** (replicated in animals; its application to apps is contested): unpredictable reward sustains behaviour. → Novel content can make a product rewarding; pair it with stopping cues ("You're all caught up"). **Manipulative form:** infinite feeds, randomised paid rewards, notification bait.
- **IKEA effect** (replicated): people value what they built, as long as they finished it. → Let users build something real before signup; setup must be completable, or the effect reverses. **Manipulative form:** user-built work held behind an undisclosed signup or paywall.
- **Endowment effect** (contested): ownership raises valuation. → Full-feature trials and user data create ownership; state plainly what happens at trial end. **Manipulative form:** forced continuity, a silent trial-to-paid conversion.
- **Commitment and consistency** (replicated, modest): a small commitment makes the next consistent act likelier. → Start with one small, genuinely useful step. **Manipulative form:** low-ball, bait-and-switch.

### Trust and social influence

- **Reciprocity** (replicated as a norm; "the most powerful principle" is folklore): a gift creates a pull to return it. → Give real, unconditional value before asking: a usable partial result, a working free tier. **Manipulative form:** a "free" result revealed as gated only after the user did the work.
- **Social proof** (replicated, small and context-dependent): under uncertainty, people copy others. → Real ratings at the decision point (by the title or price); the more similar the reference group, the stronger. **Manipulative form:** fake activity ("12 people viewing"), fake reviews.
- **Aesthetic–usability effect** (replicated for perceived usability; contested for performance): attractive interfaces are rated easier. → Polish buys tolerance and first-impression trust, and hides problems in testing: measure task success, not ratings.
- **Credibility signals** (replicated in direction): trust is judged in ~50 ms from consistency, low complexity and typicality. → Consistent grid, spacing, icon style and imagery are credibility signals in themselves; typos and off-system elements cost trust out of proportion.

### Accessibility

WCAG thresholds are the extreme end of the same perceptual and motor mechanisms, so meeting them improves the design for everyone. The thresholds themselves (4.5:1, 24 px) are consensus engineering, not experimental findings — treat them as floors.

- **Contrast** (WCAG 1.4.3 / 1.4.11, AA): text ≥ 4.5:1 (large text ≥ 3:1); UI components and meaningful icons ≥ 3:1. Figure–ground for everyone, at its limit.
- **Target size** (2.5.8, AA): ≥ 24×24 CSS px or equivalent spacing; 44×44 is the AAA comfort size. Fitts at its limit.
- **Focus not obscured** (2.4.11, AA): sticky headers and action bars must not cover the focused element.
- **Motion** (2.3.3; `prefers-reduced-motion`): interaction-triggered motion can be turned off; parallax and zoom become fades.
- **Labels** (1.3.1 / 3.3.2): form inputs always keep a visible label; "remove redundant labels" applies to displayed values only. Placeholder-as-label fails.
- **Use of colour** (1.4.1): status and badges carry text or shape as well as hue.

## The three-check test

A persuasive technique is **honest** only if it passes all three; failing any one makes it a **dark pattern**:

1. **Truthful framing**: the loss, scarcity, urgency, social proof or progress it claims is real.
2. **Symmetric exit**: declining is as easy, visible and emotionally neutral as accepting.
3. **Endorsement**: the user would endorse the technique if they understood it — it would survive being explained on the screen itself.

Check 2 is observable on the screen. Check 1 often isn't: a discount's reference price or a countdown's deadline lives in the business, not the pixels — name what would settle it. Check 3 takes judgement, so state the reasoning when it's the one that fails. When a finding needs the named pattern or its regulatory anchor (EU DSA Art. 25, FTC), read [references/dark-patterns.md](references/dark-patterns.md).
