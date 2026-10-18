# The psychology behind good app and UI design

Research notes, October 2026. Every principle traces back to a primary source: the original paper, a replication or meta-analysis, a standard, or the original author's book. DOIs were checked against Crossref where one is given. If a claim could not be verified, it is labelled as unverified.

## How to read this

Each principle uses the same block:

- **Mechanism**: why the mind does this.
- **Evidence**: a grade and its sources. The grade is one of three:
  - **replicated**: robust, and survives replication or meta-analysis.
  - **contested**: real, but the effect size or how far it generalises is disputed (failed replications, meta-analyses near zero, strong moderators).
  - **folklore**: widely repeated, but with no solid primary support, or misattributed.
- **Design implication**: what to do with it.
- **Manipulative form**: how the same mechanism gets turned against the user. Given for persuasion principles. Section 9 tests these against a three-check rule.

Two cross-cutting cautions:

1. **Most behavioural effects are moderate and depend on context.** A lab effect with d ≈ 0.3 does not promise a 10x conversion lift. Popular numbers ("2000%", "70–90%", "2x") are almost always the most extreme figure from one condition, stripped of its denominator.
2. **Most heuristics called a "law" are not empirical laws.** Fitts's and Hick–Hyman's laws are fitted quantitative models. "Jakob's law" and "Tesler's law" are practitioner maxims. Section 3 keeps the two apart.

---

## 1. Perception

The visual system groups and ranks what it sees before conscious attention arrives. Layout either works with that pre-attentive organisation or makes the user fight it.

### 1.1 Gestalt grouping: proximity, similarity, common region, continuity, figure–ground

- **Mechanism.** The visual system parses a scene into objects using cues that, in the natural world, reliably mean "these belong together":
  - near each other (proximity)
  - alike in colour, shape or size (similarity)
  - inside a shared boundary (common region)
  - lying along a smooth path (continuity)
  - distinct from the background (figure–ground)

  Grouping happens early and automatically, so users perceive structure before they read any label.
- **Evidence: replicated.**
  - Wertheimer (1923) set out the original laws ([doi:10.1007/BF00410640](https://doi.org/10.1007/BF00410640)), and Rubin (1915) described figure–ground.
  - Palmer (1992) added common region and showed it can **override proximity**: elements that are far apart but share a region group together ([doi:10.1016/0010-0285(92)90014-S](https://doi.org/10.1016/0010-0285(92)90014-S)). Palmer & Rock (1994) added uniform connectedness ([doi:10.3758/BF03200760](https://doi.org/10.3758/BF03200760)).
  - Field, Hayes & Hess (1993) gave continuity a psychophysical basis in contour integration ([doi:10.1016/0042-6989(93)90156-Q](https://doi.org/10.1016/0042-6989(93)90156-Q)).
  - Wagemans et al.'s (2012) century review confirms the grouping principles are robust. It also notes they interact and compete rather than adding up ([doi:10.1037/a0029333](https://doi.org/10.1037/a0029333)).
- **Design implication.**
  - Spacing is the cheapest structural signal: tighter spacing inside a group, looser between groups.
  - Use a container (common region) when proximity alone is ambiguous. Because it overrides proximity, use it sparingly.
  - Things that look alike will be read as doing the same thing, so similarity has to match function.
  - Figure–ground failures are the root of "the icon disappears on some photos": the icon loses its separation from the background.

### 1.2 Visual hierarchy and pre-attentive guidance

- **Mechanism.** A small set of features guide attention before focused processing: colour, size, orientation, motion, luminance contrast. An item that is **unique** on one of these features "pops out". Search slows as targets and distractors become more similar, and as the distractors become more varied.
- **Evidence: replicated.**
  - Treisman & Gelade's (1980) feature-integration theory ([doi:10.1016/0010-0285(80)90005-5](https://doi.org/10.1016/0010-0285(80)90005-5)).
  - Duncan & Humphreys (1989) on target–distractor similarity ([doi:10.1037/0033-295X.96.3.433](https://doi.org/10.1037/0033-295X.96.3.433)).
  - Wolfe & Horowitz (2004) list which attributes actually guide attention ([doi:10.1038/nrn1411](https://doi.org/10.1038/nrn1411)).
- **Design implication.**
  - Hierarchy comes from contrast on a **few** dimensions, used **rarely**.
  - Saturated colour everywhere makes the distractors more varied, so nothing pops out any more. This is the mechanism behind "a muted palette strengthens hierarchy".
  - Reserve the strongest signal (saturated accent, largest size, motion) for the one thing that matters most on the screen.

### 1.3 Von Restorff (isolation) effect

- **Mechanism.** An item that differs from its context is remembered better and draws attention.
- **Evidence: replicated.**
  - Von Restorff (1933), *Psychologische Forschung* 18 ([doi:10.1007/BF02409636](https://doi.org/10.1007/BF02409636)).
  - **Correction:** Hunt (1995), "The subtlety of distinctiveness: What von Restorff really did" ([doi:10.3758/BF03214414](https://doi.org/10.3758/BF03214414)), shows the popular retelling ("the odd one grabs attention") is incomplete. Von Restorff found the advantage even when the isolated item came **early** in a list, before it could be seen as different. Distinctiveness works on memory, relative to context, and not only by capturing attention.
  - **Limit:** banner blindness. Benway & Lane (1998) found users ignore highly salient elements that look like advertising ([doi:10.1177/154193129804200504](https://doi.org/10.1177/154193129804200504)). Distinctiveness only helps when the element also reads as relevant.
- **Design implication.**
  - Make one element per view distinctive: the primary CTA, a "recommended" badge, an error.
  - Every extra isolate weakens all the others.
  - Inconsistent icon styles or off-system product photos create **accidental** isolates that pull attention to noise.
- **Manipulative form.** Visual interference. The option the business wants is made distinctive and the alternative is made invisible: a grey "no thanks" link beside a bright "Accept" button. This appears in Gray et al. (2018) and in DSA Art. 25(3)(a), "giving more prominence to certain choices".

---

## 2. Attention and memory

### 2.1 Working-memory limits: Cowan's 4±1, not Miller's 7±2

- **Mechanism.** People can hold only a few chunks active at once. Anything the interface makes them remember across screens uses up that small capacity.
- **Evidence: replicated for Cowan's ~4. Folklore for "7±2 menu items".**
  - Miller (1956) ([doi:10.1037/h0043158](https://doi.org/10.1037/h0043158)) was a playful essay on the limits of absolute judgement and immediate memory span. Its main contribution was the idea of **chunking**. It did not set a design limit on menus or nav items.
  - Cowan (2001) reviewed tasks that stop people rehearsing or chunking, and put the real capacity at about **3–5 chunks** ([doi:10.1017/S0140525X01003922](https://doi.org/10.1017/S0140525X01003922)).
  - **Correction:** "never more than 7 items in a menu" misapplies a *recall* limit to a *recognition* task. A visible menu does not have to be held in memory.
- **Design implication.**
  - Don't make users carry information between steps. Show the order summary at payment, and keep the product title visible in a sticky header.
  - Prefer recognition over recall: show options instead of asking users to remember codes.
  - Chunk long strings (card numbers, IBANs) into groups of about 4.

### 2.2 Cognitive load theory

- **Mechanism.** Learning and task performance suffer when total demand on working memory is too high. There are three kinds of load:
  - **intrinsic**: the task's inherent complexity
  - **extraneous**: imposed by poor presentation
  - **germane**: spent building understanding

  Design can only reduce extraneous load.
- **Evidence: replicated for the core effects. The theory's measurement is criticised.**
  - Sweller (1988) ([doi:10.1207/s15516709cog1202_4](https://doi.org/10.1207/s15516709cog1202_4)); Sweller, van Merriënboer & Paas (1998) ([doi:10.1023/A:1022193728205](https://doi.org/10.1023/A:1022193728205)).
  - The split-attention effect (related information placed apart) and the redundancy effect (the same information shown twice) are repeatedly replicated in instructional settings.
  - De Jong (2010) criticises how load is measured and argues the theory is hard to falsify ([doi:10.1007/s11251-009-9110-0](https://doi.org/10.1007/s11251-009-9110-0)). The findings are solid; the three-type accounting is not.
- **Design implication.**
  - Split attention: put labels, errors and help next to the thing they describe.
  - Redundancy: drop redundant labels like "Price:", and drop icons that only repeat a word.
  - Avoid decorative noise that competes with content.

### 2.3 Serial-position effect (primacy and recency)

- **Mechanism.** In free recall, people remember the first items best (rehearsed into long-term memory) and the last items best (still in short-term memory). The middle is lost.
- **Evidence: replicated.** Murdock (1962) ([doi:10.1037/h0045106](https://doi.org/10.1037/h0045106)); Glanzer & Cunitz (1966) separated the two components.
- **Design implication.** Put the most important items first and last in lists and nav: key actions at the ends of a tab bar, the key benefit at the start of a feature list. The effect is about *recall* of sequences, so it matters most for things people will need to remember afterwards (onboarding messages, plan features), less for things they will scan while looking at them.

### 2.4 Zeigarnik effect (and Ovsiankina): replication status matters

- **Mechanism (claimed).** Unfinished tasks are remembered better than finished ones, because an open goal keeps them active.
- **Evidence: contested. The memory claim fails meta-analysis; the related resumption tendency holds.**
  - Zeigarnik (1927), *Psychologische Forschung* 9 ([doi:10.1007/BF02409755](https://doi.org/10.1007/BF02409755)).
  - Ovsiankina (1928) described the related tendency to **resume** interrupted tasks ([doi:10.1007/BF00410261](https://doi.org/10.1007/BF00410261)).
  - Ghibellini & Meier (2025, University of Bern), "Interruption, recall and resumption: a meta-analysis of the Zeigarnik and Ovsiankina effects", *Humanities and Social Sciences Communications* 12 ([doi:10.1057/s41599-025-05000-w](https://doi.org/10.1057/s41599-025-05000-w)). They found **no memory advantage for unfinished tasks**, but a general tendency to resume them. They conclude the Zeigarnik effect "lacks universal validity" and may have depended on situational factors (experimenter authority, task involvement) common in early studies.
- **Design implication.**
  - Don't justify progress bars or checklists with "users remember unfinished tasks". Justify them by resumption (Ovsiankina) and by goal-gradient motivation (5.2).
  - Make interrupted work easy to *resume*: saved drafts, "continue where you left off".
- **Manipulative form.** Fake incompleteness: "Your profile is 60% complete" when the missing 40% is data only the business needs. It manufactures an open loop to extract information.

### 2.5 Peak–end rule

- **Mechanism.** People judge a past experience mostly by its most intense moment and its end, and largely ignore how long it lasted (duration neglect).
- **Evidence: replicated.**
  - Kahneman, Fredrickson, Schreiber & Redelmeier (1993), the cold-water study ([doi:10.1111/j.1467-9280.1993.tb00589.x](https://doi.org/10.1111/j.1467-9280.1993.tb00589.x)).
  - Redelmeier & Kahneman (1996), colonoscopy ([doi:10.1016/0304-3959(96)02994-6](https://doi.org/10.1016/0304-3959(96)02994-6)). Redelmeier, Katz & Kahneman (2003) ran it as a randomized trial ([doi:10.1016/S0304-3959(03)00003-4](https://doi.org/10.1016/S0304-3959(03)00003-4)).
  - Alaybek et al. (2022) meta-analysed 174 effect sizes. The peak-end effect on retrospective evaluations was large (r = .58), and the effect of duration was close to zero ([doi:10.1016/j.obhdp.2022.104149](https://doi.org/10.1016/j.obhdp.2022.104149)).
- **Design implication.**
  - Invest in the worst moment (errors, payment failure, waiting) and in the last moment (confirmation, success state, offboarding).
  - A graceful cancellation flow shapes the memory of the whole relationship.
- **Manipulative form.** Engineering a pleasant ending to mask a bad experience, for example a celebratory confetti screen after a purchase that included hidden fees.

---

## 3. Interaction cost

### 3.1 Hick–Hyman law

- **Mechanism.** Choice reaction time grows with the information in the choice set: RT = a + b·log₂(n+1). People process the alternatives somewhat like a binary search.
- **Evidence: replicated within its domain. Folklore when stretched beyond it.**
  - Hick (1952) ([doi:10.1080/17470215208416600](https://doi.org/10.1080/17470215208416600)) and Hyman (1953) ([doi:10.1037/h0056940](https://doi.org/10.1037/h0056940)).
  - The law holds for **practised, known stimulus–response mappings**. For unfamiliar menus, users scan items one by one, and time grows roughly linearly with the number of items.
  - Landauer & Nachbar (1985) found the log relationship in menu *selection* when items were ordered and familiar ([doi:10.1145/317456.317470](https://doi.org/10.1145/317456.317470)).
  - **Correction:** "fewer options always = faster decisions" conflates Hick–Hyman (perceptual choice time) with choice overload (preference decisions, 4.2). They are different phenomena.
- **Design implication.** Grouping and ordering (alphabetical, by frequency) turn linear scanning into something closer to log-time search. Cutting options matters most for novices and for unordered lists.

### 3.2 Fitts's law

- **Mechanism.** The time to acquire a target grows with distance and shrinks with size: MT = a + b·log₂(D/W + 1), in the Shannon formulation.
- **Evidence: replicated.** Fitts (1954) ([doi:10.1037/h0055392](https://doi.org/10.1037/h0055392)); MacKenzie (1992) for HCI ([doi:10.1207/s15327051hci0701_3](https://doi.org/10.1207/s15327051hci0701_3)). It is one of the most robust models in HCI, and the basis of ISO 9241-411 pointing-device evaluation.
- **Design implication.**
  - Make primary actions large, and close to where the pointer or thumb already is.
  - Screen edges and corners act as infinitely deep targets on desktop.
  - On phones, thumb reach matters: Bergstrom-Lehtovirta & Oulasvirta (2014) model the thumb's functional area ([doi:10.1145/2556288.2557354](https://doi.org/10.1145/2556288.2557354)), which supports sticky bottom action bars.
  - Parhi, Karlson & Bederson (2006) found about 9.2–9.6 mm targets were needed for one-handed thumb use ([doi:10.1145/1152215.1152260](https://doi.org/10.1145/1152215.1152260)).
  - This links to WCAG 2.5.8 (section 7).
- **Manipulative form.** Asymmetric targets: a huge "Accept all" next to a tiny "Manage options".

### 3.3 Doherty threshold (~400 ms)

- **Claim.** Productivity rises sharply when system response time falls below about 400 ms.
- **Evidence: contested.**
  - The source is Doherty & Thadani (1982), "The Economic Value of Rapid Response Time", an **IBM report**, not a peer-reviewed study. I could not access it, so its data and method are unverified here.
  - The better-supported response-time bands come from Miller (1968): about 0.1 s feels instantaneous, about 1 s keeps flow, about 10 s holds attention ([doi:10.1145/1476589.1476628](https://doi.org/10.1145/1476589.1476628)). Card, Robertson & Mackinlay (1991) build on them ([doi:10.1145/108844.108874](https://doi.org/10.1145/108844.108874)).
- **Design implication.**
  - Acknowledge input within about 100 ms: pressed state, optimistic UI.
  - Show progress for anything over about 1 s.
  - Use determinate progress plus the option to background the task for anything near 10 s.

### 3.4 Tesler's law (conservation of complexity)

- **Claim.** Every application has an irreducible amount of complexity. The only question is whether the user or the system (its designers and engineers) handles it.
- **Evidence: folklore (a maxim, not a finding).** It is attributed to Larry Tesler (Xerox PARC, later Apple). It is documented mainly through his interview in Dan Saffer's *Designing for Interaction* (New Riders, 2006). There is no empirical test, and it isn't the kind of claim that could be tested. It is useful as a framing device, not as evidence.
- **Design implication.** Before removing a field, ask where its complexity goes. Smart defaults, address lookup and inferred values move complexity to the system. Simply hiding a necessary choice moves it to a later, worse moment.

### 3.5 Progressive disclosure

- **Mechanism.** Show the essentials first and reveal advanced options on demand. This cuts extraneous load and the number of visible choices for novices, while keeping power available.
- **Evidence: contested.**
  - The closest primary evidence is Carroll & Carrithers (1984), the "training wheels" interface. Blocking advanced functions helped novices finish tasks faster with fewer errors ([doi:10.1145/358198.358218](https://doi.org/10.1145/358198.358218)).
  - Later studies are mixed on transfer to the full interface, and most practitioner claims come from essays, not experiments.
- **Design implication.**
  - Hide by frequency of use, not by importance to the business.
  - Make the disclosure control obvious, and keep revealed options in a stable place.
- **Manipulative form.** "Progressive disclosure" of costs or terms: fees, auto-renewal and data sharing behind an "advanced" expander. This is the FTC's category of design that "hide[s] or delay[s] disclosure of material information".

### 3.6 Jakob's law (conventions)

- **Claim.** Users spend most of their time on other sites and apps, so they expect yours to work the same way.
- **Evidence: replicated for the mechanism. The "law" is an essay.**
  - The phrasing comes from Jakob Nielsen's Alertbox essays (c. 2000), not from a study.
  - The underlying mechanism is positive transfer of learned skills to similar tasks, and interference when similar-looking things behave differently. It is well established in the transfer-of-training literature (Singley & Anderson, *The Transfer of Cognitive Skill*, Harvard UP, 1989).
- **Design implication.** Follow platform conventions for navigation, form controls, gestures and icon meanings. Spend novelty only where it is your product's actual value.

---

## 4. Decision-making

### 4.1 Defaults

- **Mechanism.** Defaults work through three channels, identified by Jachimowicz et al. (2019):
  - **endorsement**: "the designer recommends this"
  - **endowment**: the default becomes the reference point, so leaving it feels like a loss
  - **effort**: changing it costs something

  McKenzie, Liersch & Finkelstein (2006) showed people read policy defaults as implicit recommendations ([doi:10.1111/j.1467-9280.2006.01721.x](https://doi.org/10.1111/j.1467-9280.2006.01721.x)).
- **Evidence: replicated, with large heterogeneity.**
  - Johnson & Goldstein (2003, Columbia), "Do Defaults Save Lives?", *Science* ([doi:10.1126/science.1091721](https://doi.org/10.1126/science.1091721)). Organ-donor consent was 86–99.98% in opt-out countries and 4.25–27.5% in opt-in countries. In their online experiment, 42% agreed under opt-in and 82% under opt-out. Registered consent is not the same as actual donations.
  - Madrian & Shea (2001): automatic enrolment raised 401(k) participation among new hires from about 37% to about 86%. Many employees also stayed at the default contribution rate and fund, even when those were suboptimal ([doi:10.1162/003355301753265543](https://doi.org/10.1162/003355301753265543)).
  - Jachimowicz, Duncan, Weber & Johnson (2019) meta-analysed 58 studies (N = 73,675) and found d = 0.68 [0.53, 0.83] ([doi:10.1017/bpp.2018.43](https://doi.org/10.1017/bpp.2018.43)). Some studies found null or even negative effects. Defaults were stronger in consumer domains and weaker in environmental ones, and most of the variation between studies was not explained.
  - **Seed claim corrected:** "70–90% of users never change defaults" has **no primary source I could find**. The figure circulates in practitioner writing without a study behind it. Default effects are real but vary enormously by domain. **Folklore** as a specific number.
- **Design implication.**
  - Set defaults to what most users would choose if they thought about it, or to the safest option.
  - Because defaults read as recommendations, a default is a statement of advice. Own it.
  - Preset quantity chips based on real purchase data are a legitimate smart default.
- **Manipulative form.** Preselection: pre-ticked add-ons, insurance, newsletter or data-sharing boxes. This is "sneak into basket" in Brignull's catalogue and "preselection" in Gray et al. (2024). Under the GDPR, pre-ticked consent boxes do not count as valid consent (CJEU *Planet49*, C-673/17, 2019).

### 4.2 Choice overload (the jam study)

- **Mechanism (claimed).** Too many options raise the cost of deciding and the fear of regret, which leads to deferring the decision or being less satisfied with it.
- **Evidence: contested.**
  - Iyengar & Lepper (2000), "When choice is demotivating", *JPSP* ([doi:10.1037/0022-3514.79.6.995](https://doi.org/10.1037/0022-3514.79.6.995)).
  - **Seed claim corrected, attribution:** Sheena Iyengar ran the study as a Stanford doctoral student with Mark Lepper (Stanford), at Draeger's supermarket in Menlo Park, California. It was published in 2000, around when Iyengar joined Columbia. "Columbia ran a study" is loose.
  - **Seed claim corrected, numbers:** the 24-jam display drew **more** shoppers to stop (about 60% vs about 40%). The "3% vs 30%" figures are the share **of those who stopped** who later redeemed a discount coupon. They are not shares of all passers-by, and not same-visit sales.
  - Scheibehenne, Greifeneder & Todd (2010) meta-analysed 63 conditions from 50 experiments (N = 5,036). The mean effect was **about zero**, with large variance between studies ([doi:10.1086/651235](https://doi.org/10.1086/651235)).
  - Chernev, Böckenholt & Goodman (2015) found a reliable effect only under particular moderators:
    - complex choice sets
    - difficult decision tasks
    - uncertain preferences
    - an effort-minimising goal

    ([doi:10.1016/j.jcps.2014.08.002](https://doi.org/10.1016/j.jcps.2014.08.002))
  - "Decision fatigue" as a separate concept relies on ego-depletion research, which has had major replication failures. I did not research it in depth here; don't lean on it.
- **Design implication.**
  - Large assortments are fine when options are easy to compare: sorted, filterable, with clear attributes.
  - Reduce options, or add a recommended pick, when options are complex, users don't know what they want, or they want to decide fast (plan pickers, onboarding).
- **Manipulative form.** Deliberately overwhelming people to push them toward a default or "recommended" option chosen for margin, not fit. Also making comparison hard ("comparison prevention" in Brignull's catalogue).

### 4.3 Anchoring and contrast (relative thinking)

- **Mechanism.** Estimates and valuations get pulled toward a reference number (anchoring). Price differences are judged relative to the price around them, not in absolute terms (relative thinking or mental accounting).
- **Evidence: replicated for explicit anchors. Contested for incidental anchors and large real-money stakes.**
  - Tversky & Kahneman (1974) ([doi:10.1126/science.185.4157.1124](https://doi.org/10.1126/science.185.4157.1124)). Anchoring replicated with large effects in Many Labs 1 (Klein et al., 2014, [doi:10.1027/1864-9335/a000178](https://doi.org/10.1027/1864-9335/a000178)).
  - Ariely, Loewenstein & Prelec's (2003) Social-Security-number anchoring of willingness to pay showed a weak or failed replication in Maniadis, Tufano & List (2014) ([doi:10.1257/aer.104.1.277](https://doi.org/10.1257/aer.104.1.277)).
  - Relative thinking comes from Tversky & Kahneman's (1981) calculator/jacket problem ([doi:10.1126/science.7455683](https://doi.org/10.1126/science.7455683)) and from Thaler (1985) on mental accounting ([doi:10.1287/mksc.4.3.199](https://doi.org/10.1287/mksc.4.3.199)). I did not verify the replication status of the specific calculator/jacket item.
  - **Seed claim:** "a $50 plan next to a $1,900 laptop (just 2.6%)" is a fair illustration of relative thinking. I found no primary study of that specific add-on framing.
- **Design implication.**
  - Show prices alongside honest reference points: the cost of the problem solved, the base product.
  - Order plans deliberately; the first price seen sets the reference.
- **Manipulative form.**
  - Fake reference prices ("was $199", never sold at that).
  - Anchoring with an artificially inflated preset quantity.
  - Hiding the absolute cost behind a relative one ("only 2.6% of your purchase") when that cost recurs monthly.

### 4.4 Decoy (asymmetric dominance) effect

- **Mechanism.** Adding an option that is clearly worse than option A but not clearly worse than B makes A look better. The decoy gives the chooser a reason to pick A.
- **Evidence: contested.**
  - Huber, Payne & Puto (1982) ([doi:10.1086/208899](https://doi.org/10.1086/208899)); Simonson (1989) on reason-based choice ([doi:10.1086/209205](https://doi.org/10.1086/209205)).
  - Frederick, Lee & Baskin (2014) found the effect largely disappears when attributes are shown perceptually or the product is experienced ([doi:10.1509/jmr.12.0061](https://doi.org/10.1509/jmr.12.0061)).
  - Yang & Lynn (2014) reported widespread failures to replicate ([doi:10.1509/jmr.14.0020](https://doi.org/10.1509/jmr.14.0020)).
  - Huber, Payne & Puto (2014) replied that the effect is robust under the original conditions: numeric attributes in a stylised comparison ([doi:10.1509/jmr.14.0208](https://doi.org/10.1509/jmr.14.0208)).
  - Those conditions do describe a pricing table, which is why decoys are plausible there and much less so elsewhere.
  - The famous *Economist* subscription example comes from Dan Ariely's book *Predictably Irrational* (2008), as a classroom demonstration. I found no peer-reviewed publication of it.
- **Design implication.** Middle-tier framing in pricing tables is plausible but weak. Don't build strategy on it.
- **Manipulative form.** Fake tiers that nobody is meant to buy, added only to make the target look good.

### 4.5 Framing

- **Mechanism.** The same outcome described as a gain or as a loss changes choices. There are three types (Levin, Schneider & Gaeth, 1998, [doi:10.1006/obhd.1998.2804](https://doi.org/10.1006/obhd.1998.2804)):
  - risky-choice framing
  - attribute framing ("80% lean" vs "20% fat")
  - goal framing ("what you gain" vs "what you lose")
- **Evidence: replicated.** Tversky & Kahneman (1981) ([doi:10.1126/science.7455683](https://doi.org/10.1126/science.7455683)). Kühberger's (1998) meta-analysis found reliable small-to-moderate effects ([doi:10.1006/obhd.1998.2781](https://doi.org/10.1006/obhd.1998.2781)). Gain/loss framing replicated in Many Labs 1.
- **Design implication.** Wording is a design decision. Choose the frame that helps users decide accurately ("You'll keep your 12 projects"), and keep the frame consistent across options.
- **Manipulative form.** Confirmshaming ("No thanks, I don't like saving money") and loss frames built on losses that aren't real.

### 4.6 Loss aversion

- **Mechanism.** Outcomes are judged as gains or losses relative to a reference point, and losses weigh more than equal gains.
- **Evidence: contested. The direction is broadly supported; the magnitude and generality are disputed.**
  - Kahneman & Tversky (1979), prospect theory ([doi:10.2307/1914185](https://doi.org/10.2307/1914185)).
  - The "2x" figure comes from **Tversky & Kahneman (1992)**, whose median loss-aversion coefficient was λ ≈ 2.25 ([doi:10.1007/BF00122574](https://doi.org/10.1007/BF00122574)). It is an estimate from risky monetary gambles, not a constant of nature.
  - Gal & Rucker (2018), "The Loss of Loss Aversion" ([doi:10.1002/jcpy.1047](https://doi.org/10.1002/jcpy.1047)), argue many findings are better explained by status-quo or inertia effects. They say losses often do not loom larger, especially for small stakes.
  - Mrkva, Johnson, Gächter & Herrmann (2020; N = 17,720) found loss aversion is real but moderated. It is lower with domain knowledge and higher in older consumers ([doi:10.1002/jcpy.1156](https://doi.org/10.1002/jcpy.1156)).
  - Brown, Imai, Vieider & Camerer (2024) meta-analysed 607 estimates and found a mean λ ≈ 1.96 (95% interval 1.82–2.10), with wide variation between studies ([doi:10.1257/jel.20221698](https://doi.org/10.1257/jel.20221698)).
  - **Seed claim corrected:** "losses are ~2x as powerful as gains (Kahneman)" is a roughly right *average* from a specific kind of task, credited to Tversky & Kahneman (1992). It does not reliably carry over to an upgrade dialog.
- **Design implication.** Accurately telling users what they will actually lose is legitimate and useful, for example "Downgrading will archive 3 projects over the free limit". Make the reference point real.
- **Manipulative form.** The seed example (named files + countdown + "I'll risk it" dismiss button) stacks three patterns:
  1. **Fake urgency**, if the countdown is arbitrary.
  2. **Confirmshaming** ("I'll risk it" frames declining as reckless).
  3. **Possibly a false loss**, if the files would not actually be deleted.

  Each is a named dark pattern (section 9). The same screen is honest only if the deadline and the deletion are real and the decline label is neutral ("Not now").

### 4.7 Status-quo bias

- **Mechanism.** People disproportionately stick with the current state. This comes from loss aversion relative to the status quo, the cost of switching, and regret avoidance (switching and regretting it feels worse than staying and regretting it).
- **Evidence: replicated.** Samuelson & Zeckhauser (1988) ([doi:10.1007/BF00055564](https://doi.org/10.1007/BF00055564)); Kahneman, Knetsch & Thaler (1991) ([doi:10.1257/jep.5.1.193](https://doi.org/10.1257/jep.5.1.193)). It largely overlaps with default effects, and Gal & Rucker argue it explains much of what gets attributed to loss aversion.
- **Design implication.**
  - Migrations and redesigns face real resistance. Let users keep familiar settings, and offer a temporary "classic" mode.
  - To get adoption, make the new state the default *for new users*.
- **Manipulative form.** Roach motel or hard-to-cancel flows, which exploit inertia by making exit expensive. This is DSA Art. 25(3)(c), "making the procedure for terminating a service more difficult than subscribing to it".

---

## 5. Motivation and habit

### 5.1 Fogg Behaviour Model (B = MAP)

- **Mechanism (claimed).** A behaviour happens when motivation, ability and a prompt meet at the same moment. Low ability (high friction) can be offset by high motivation, and the reverse.
- **Evidence: contested.**
  - Fogg (2009), *Persuasive '09* ([doi:10.1145/1541948.1541999](https://doi.org/10.1145/1541948.1541999)), and the book *Tiny Habits* (2019).
  - It is a conceptual framework, presented without a quantitative test of its interaction claims. Its parts have independent support: friction and effort affect uptake (as in default effects), and prompts and cues matter in habit research. The model itself has not been validated as predictive.
- **Design implication.** It works as a diagnostic: when users don't act, ask whether motivation, ability (friction) or the prompt is missing. Reducing friction is usually the cheapest of the three to fix.
- **Manipulative form.** Prompts timed to moments of low self-control. Nagging, meaning repeated prompts after the user has declined, is a Gray et al. (2018) strategy and DSA Art. 25(3)(b).

### 5.2 Goal-gradient effect and endowed progress

- **Mechanism.** Effort speeds up as people near a goal. Perceived progress, even artificial progress, raises motivation.
- **Evidence.**
  - **Goal-gradient: replicated.** Hull (1932), with rats running faster near the reward ([doi:10.1037/h0072640](https://doi.org/10.1037/h0072640)). Kivetz, Urminsky & Zheng (2006) showed that members of a "buy 10 coffees, get one free" programme bought coffee more often as they approached the reward ([doi:10.1509/jmkr.43.1.39](https://doi.org/10.1509/jmkr.43.1.39)). Ran Kivetz and Oleg Urminsky were at **Columbia** Business School, and the café was near Columbia.
  - **Endowed progress: contested.** Nunes & Drèze (2006), "The Endowed Progress Effect", *JCR* ([doi:10.1086/500480](https://doi.org/10.1086/500480)), was a field study at a car wash.
    - Customers got either an 8-stamp card or a 10-stamp card with 2 stamps pre-filled. Both needed 8 more washes.
    - **Completion was about 34% vs about 19%**, roughly 1.8x, and the endowed group also finished faster. The 34/19 figures are from my reading of the paper and match the "82% higher" figure reported elsewhere. I could not re-open the paywalled article to confirm them.
    - The abstract attributes the effect to perceived task completion, not to a wish to avoid wasting the free stamps.
    - I found few independent direct replications, so it is a single strong field result plus lab follow-ups in the same paper.
  - **Seed claim corrected, attribution:** the car-wash study is **not Columbia**. It was Joseph Nunes (USC Marshall) and Xavier Drèze (then at Wharton, per my recollection; not verified). The seed claim merged it with the Columbia coffee-card study.
  - **Seed claim corrected, magnitude:** "about double completion" slightly overstates about 1.8x.
- **Design implication.**
  - Show progress, and count real steps the user has already done (account created, email verified), so they don't start at 0%.
  - "Never start at 0%" is legitimate only when the credited progress is **real**.
- **Manipulative form.** Fabricated progress, such as a bar starting at 20% for nothing done. Also streak and gradient mechanics that drive purchases beyond what the user needs.

### 5.3 Variable reward and the "hook" loop

- **Mechanism.** Under variable-ratio reinforcement schedules (unpredictable reward), behaviour is maintained at high rates and keeps going after rewards stop. Dopamine neurons signal reward-prediction error, so unexpected rewards drive learning.
- **Evidence: contested in its application.**
  - Schedule effects are robust in animals (Ferster & Skinner, *Schedules of Reinforcement*, 1957). Schultz, Dayan & Montague (1997) cover the prediction-error signal ([doi:10.1126/science.275.5306.1593](https://doi.org/10.1126/science.275.5306.1593)).
  - The "hook" loop (trigger → action → variable reward → investment) is from Nir Eyal's practitioner book *Hooked* (2014). It is a synthesis, not a tested model.
  - The jump from pigeon schedules to "this feed design causes compulsive use" is mostly asserted, not demonstrated. Whether problematic technology use exists, and how big it is, remains contested.
- **Design implication.**
  - Novelty and unpredictable discovery in content (new recommendations, fresh results) can make a product rewarding.
  - Pair it with stopping cues: "You're all caught up", ends to the feed, digests instead of a drip of notifications.
- **Manipulative form.**
  - Infinite feeds with no stopping point.
  - Loot-box-style randomised rewards for money.
  - Notification timing tuned to pull users back rather than to inform them.

  These are the attention-capture patterns discussed in Gray et al. (2024), the "social engineering" and "interface interference" families.

### 5.4 IKEA effect

- **Mechanism.** People value things more when they built them, as long as they finish. Effort that succeeds signals competence and creates a feeling of ownership.
- **Evidence: replicated.**
  - Norton, Mochon & Ariely (2012), *JCP* 22(3) ([doi:10.1016/j.jcps.2011.08.002](https://doi.org/10.1016/j.jcps.2011.08.002)). The effect **disappeared when participants built and then destroyed their creations, or failed to complete them**.
  - Sarstedt, Neubert & Barth (2017) conceptually replicated it ([doi:10.1561/107.00000039](https://doi.org/10.1561/107.00000039)).
- **Design implication.**
  - Letting users set up or customise something real before signup (a workspace, a playlist, a configured report) raises how much they value the product.
  - The setup has to be **completable** and meaningful. Failed or tedious setup reverses the effect.
- **Manipulative form.** Holding user-built work hostage behind a signup or paywall without saying so upfront. That makes the investment a sunk-cost trap.

### 5.5 Endowment effect

- **Mechanism.** People value things more once they own them. Willingness to accept (selling price) exceeds willingness to pay (buying price).
- **Evidence: contested.**
  - Kahneman, Knetsch & Thaler (1990), the mug experiments: median selling prices were roughly twice median buying prices ([doi:10.1086/261737](https://doi.org/10.1086/261737)).
  - Plott & Zeiler (2005) found the gap disappears with careful procedures: training, anonymity, incentive-compatible elicitation ([doi:10.1257/0002828054201387](https://doi.org/10.1257/0002828054201387)).
  - Whether the effect is a basic preference or an artefact of the procedure is still debated.
- **Design implication.** Free trials with full features and user-created data both generate a sense of ownership. Be honest about what happens at trial end.
- **Manipulative form.** Forced continuity: a free trial that silently converts to paid. It is in Brignull's catalogue and the FTC's "unauthorized charges" category.

### 5.6 Commitment and consistency

- **Mechanism.** After a small commitment, people act consistently with it, to keep a coherent self-image.
- **Evidence: replicated, but the effect is small and depends on conditions.**
  - Freedman & Fraser (1966), foot-in-the-door ([doi:10.1037/h0023552](https://doi.org/10.1037/h0023552)).
  - Burger's (1999) review found the effect reliable but modest, and moderated by self-perception and by whether the first request was actually carried out ([doi:10.1207/s15327957pspr0304_2](https://doi.org/10.1207/s15327957pspr0304_2)).
- **Design implication.**
  - Start with a small, easy, genuinely useful step ("What do you want to track?") before larger asks.
  - Let users state their goals; these become reference points for later prompts.
- **Manipulative form.** Low-balling: getting a "yes" to one thing, then changing the terms. Bait-and-switch is in Brignull's catalogue.

---

## 6. Trust and social influence

### 6.1 Reciprocity

- **Mechanism.** A near-universal social norm: people feel obliged to return favours (Gouldner, 1960, [doi:10.2307/2092623](https://doi.org/10.2307/2092623)).
- **Evidence: replicated for the norm. Folklore for the popular superlatives.**
  - Regan (1971): participants given an unsolicited Coke bought more raffle tickets from the giver ([doi:10.1016/0022-1031(71)90025-4](https://doi.org/10.1016/0022-1031(71)90025-4)).
  - Falk (2007) ran a field experiment with about 10,000 solicitation letters. A small gift raised the donation rate by about 17%, and a large gift by about 75% ([doi:10.1111/j.1468-0262.2007.00800.x](https://doi.org/10.1111/j.1468-0262.2007.00800.x)).
  - **Seed claim corrected:** "Cialdini ranked reciprocity the single most powerful driver" is not supported. *Influence* (1984; expanded edition 2021, which added "unity") presents the principles side by side without ranking them. I found no source for a ranking.
  - **Seed claim corrected:** "free samples increase purchases by up to 2000%" traces to a 2014 *Atlantic* article on retail sampling ("in some cases by as much as 2,000 percent"), citing industry figures. It is a best-case anecdote, not a study, and not specific to Costco. **Folklore** as a statistic.
- **Design implication.**
  - Give real value before asking: a useful partial result, a working free tier, a genuinely helpful report before signup.
  - The value has to be real and unconditional to read as a gift and not as bait.
- **Manipulative form.** A "gift" that is actually a hook, such as a "free report" that can't be read without signing up, revealed only after the user has done the work. That is a bait-and-switch.

### 6.2 Social proof

- **Mechanism.** When unsure what to do, people infer the right action from what others do (descriptive norms).
- **Evidence: replicated, but small and context-dependent.**
  - Goldstein, Cialdini & Griskevicius (2008) varied hotel towel-reuse messages ([doi:10.1086/586910](https://doi.org/10.1086/586910)):
    - standard environmental message: 35.1% reuse
    - descriptive norm ("most guests reuse"): 44.1%
    - room-specific norm: 49.3%
  - Bohner & Schlüter (2014) failed to replicate it in Germany ([doi:10.1371/journal.pone.0104086](https://doi.org/10.1371/journal.pone.0104086)). Scheibehenne, Jamil & Wagenmakers (2016) pooled the studies in a Bayesian synthesis and supported a small positive effect ([doi:10.1177/0956797616644081](https://doi.org/10.1177/0956797616644081)).
  - Muchnik, Aral & Taylor (2013) randomly up-voted comments on a news site. This produced herding, with final ratings about 25% higher, while negative manipulation was corrected by the crowd ([doi:10.1126/science.1240466](https://doi.org/10.1126/science.1240466)).
- **Design implication.**
  - Put real ratings and reviews at the point of decision, next to the title or price.
  - The more specific and similar the reference group ("teams like yours"), the stronger the norm.
- **Manipulative form.** Fake social proof (invented "12 people are viewing this" or "Jane from Leeds just bought" notifications) and fake reviews. Mathur et al. (2019) found such messages on shopping sites, some generated at random. The FTC's 2024 rule on fake reviews and testimonials (16 CFR Part 465) bans fake reviews.

### 6.3 Aesthetic–usability effect

- **Mechanism.** Attractive interfaces are *perceived* as easier to use. This is a halo effect: a positive overall impression ("beautiful") colours specific judgements ("usable").
- **Evidence: replicated for perceived usability. Contested for actual performance.**
  - Kurosu & Kashimura (1995, Hitachi Design Center), "Apparent usability vs. inherent usability", CHI companion ([doi:10.1145/223355.223680](https://doi.org/10.1145/223355.223680)). Japanese participants rated 26 ATM layouts, and aesthetics correlated strongly with apparent usability.
  - Tractinsky (1997) replicated it in Israel with an even stronger correlation ([doi:10.1145/258549.258626](https://doi.org/10.1145/258549.258626)).
  - Tractinsky, Katz & Ikar (2000), "What is beautiful is usable": the aesthetic effect on ratings persisted *after* use ([doi:10.1016/S0953-5438(00)00031-X](https://doi.org/10.1016/S0953-5438(00)00031-X)).
  - Hassenzahl & Monk (2010) argue the link is indirect, running through a general "goodness" judgement ([doi:10.1080/07370024.2010.500139](https://doi.org/10.1080/07370024.2010.500139)).
  - Sonderegger & Sauer (2010) found effects on rated usability and some on performance ([doi:10.1016/j.apergo.2009.09.002](https://doi.org/10.1016/j.apergo.2009.09.002)).
- **Design implication.**
  - Visual polish buys tolerance for minor friction and raises first-impression trust.
  - It also hides usability problems in testing: users praise attractive prototypes. Measure task success, not only ratings.

### 6.4 Credibility signals

- **Mechanism.** Users judge credibility fast, from surface cues (design quality, consistency, errors), because deeper evaluation is costly. These snap judgements largely hold up after longer exposure.
- **Evidence: replicated for the direction (appearance drives first-impression trust).**
  - Fogg et al. (2001), "What makes Web sites credible?" ([doi:10.1145/365024.365037](https://doi.org/10.1145/365024.365037)).
  - Fogg et al. (2003, Stanford Persuasive Technology Lab; about 2,600 participants), "How do users evaluate the credibility of Web sites?" ([doi:10.1145/997078.997097](https://doi.org/10.1145/997078.997097)). "Design look" was the most frequently mentioned factor, in about 46% of comments.
  - Lindgaard et al. (2006): visual-appeal judgements formed in **50 ms** were consistent with judgements made over longer exposure ([doi:10.1080/01449290500330448](https://doi.org/10.1080/01449290500330448)).
  - Tuch et al. (2012): low visual complexity and high prototypicality (looking like a typical site of its kind) gave the best first impressions ([doi:10.1016/j.ijhcs.2012.06.003](https://doi.org/10.1016/j.ijhcs.2012.06.003)).
  - Reinecke et al. (2013) modelled first impressions from colourfulness and complexity ([doi:10.1145/2470654.2481281](https://doi.org/10.1145/2470654.2481281)).
  - Caveat: Fogg 2003 is descriptive comment-coding, not an experiment.
- **Design implication.**
  - Consistency (grid, spacing, icon style, imagery) and conventional layout are credibility signals in their own right.
  - Typos, broken images and off-system elements cost trust out of proportion to their size.
  - Show contact information, real people and clear policies.
- **Manipulative form.** Borrowed credibility: fake trust badges, "as seen on" logos without permission, and disguised ads styled as content (in Brignull's catalogue).

---

## 7. Accessibility as a lens

WCAG 2.2 (W3C Recommendation, 5 Oct 2023, [w3.org/TR/WCAG22](https://www.w3.org/TR/WCAG22/)) is a normative standard, not a psychology finding. Its thresholds are graded by the evidence behind them. The pattern: **accessibility criteria are the extreme end of the same perceptual and motor mechanisms**, so meeting them usually improves the design for everyone.

| Criterion (level) | Requirement | Mechanism it protects | Overlap with craft claims |
|---|---|---|---|
| **1.4.3 Contrast (Minimum)** (AA) | Text ≥ 4.5:1; large text (≥ 18pt, or ≥ 14pt bold) ≥ 3:1 | Figure–ground, legibility. The Understanding document says 4.5:1 compensates for the contrast loss typical of about 20/40 vision. | "Paragraphs at slightly lower contrast" is fine **only above 4.5:1**. Muted palettes must still pass. |
| **1.4.11 Non-text Contrast** (AA) | UI components and meaningful graphics ≥ 3:1 against adjacent colours | Figure–ground for controls and icons | "Icons over images need a container": a scrim or chip guarantees 3:1 whatever the photo. Soft dividers are fine if they're decorative, but input borders must reach 3:1. |
| **1.4.12 Text Spacing** (AA) | Content survives line height 1.5, paragraph spacing 2x, letter spacing 0.12em, word spacing 0.16em | Readability for low-vision and dyslexic readers | Tight line height and fixed-height badges break under user overrides. |
| **1.4.8 Visual Presentation** (AAA) | Lines ≤ 80 characters; line spacing ≥ 1.5 | Line-length readability | Matches the typographic line-length convention (section 8). |
| **2.5.8 Target Size (Minimum)** (AA, new in 2.2) | Targets ≥ 24×24 CSS px, or spaced so a 24px circle on each target doesn't overlap another (exceptions: inline, essential, equivalent, user-agent) | Fitts's law at the motor-impairment extreme | Preset quantity chips and steppers must meet it. 2.5.5 (AAA) asks for 44×44. |
| **2.4.11 Focus Not Obscured (Minimum)** (AA, new in 2.2) | A focused element is not entirely hidden by author content | Visibility of state | **Sticky headers and sticky bottom action bars** must not cover the focused field. |
| **2.3.3 Animation from Interactions** (AAA) | Motion triggered by interaction can be turned off unless essential | Vestibular disorders (motion causes nausea and dizziness) | Respect the `prefers-reduced-motion` media feature ([Media Queries Level 5](https://www.w3.org/TR/mediaqueries-5/#prefers-reduced-motion)). Replace parallax and zooms with fades. |
| **2.2.2 Pause, Stop, Hide** (A) / **2.3.1 Three Flashes** (A) | Auto-moving content can be paused; no more than three flashes per second | Attention capture, seizure risk | Auto-advancing carousels and countdown animations. |
| **1.3.1 / 3.3.2 Labels** (A) | Inputs have programmatic and visible labels or instructions | Recognition over recall | "Remove redundant labels" applies to *display values* ("Price:"), **never** to form inputs. Placeholder-as-label fails. |
| **1.4.1 Use of Color** (A) | Colour is not the only way information is conveyed | Similarity grouping without relying on hue | Badges and status need text or shape as well as colour. |

Evidence grade for the thresholds: **replicated** for the underlying mechanisms:

- Contrast sensitivity drives legibility: Legge, Rubin & Luebker (1987), "Psychophysics of reading V", *Vision Research* 27(7), 1165–1177. Reading speed for normal vision stays flat over a wide range of contrast and drops at low contrast; low-vision readers need far more.
- Fitts's law (3.2).

The **specific cut-offs** (4.5:1, 24px) are consensus engineering choices, not thresholds found by experiment.

---

## 8. Visual craft rules (seed claims): mechanism and evidence

Most craft rules are **applications** of the mechanisms above, not findings in their own right. The grade below rates evidence for the *rule as stated*.

| Craft rule | Mechanism(s) | Evidence / grade |
|---|---|---|
| Icons over images need a container or contrast. Design for content variance, not one screen. | Figure–ground (1.1); WCAG 1.4.11 | **Replicated** mechanism. A scrim or chip is the only way to guarantee 3:1 against unknown images. |
| Catalog imagery must be consistent (background, lighting). | Similarity grouping (1.1); accidental isolates (1.3); low complexity → trust (6.4) | Mechanism replicated; the rule itself is **folklore** (no direct study). It follows from Tuch et al. (2012) on complexity. |
| Consistent grid and margins (e.g. 24px) → calm, order, trust | Proximity and alignment (1.1); low complexity and prototypicality → first impression (Tuch 2012; Reinecke 2013) | Consistency → trust is **replicated** in direction. "24px" specifically is **folklore**: any consistent scale works. |
| Muted palette; saturated colour everywhere weakens hierarchy | Pop-out depends on uniqueness and distractor homogeneity (Duncan & Humphreys 1989); Von Restorff (1.3) | **Replicated** mechanism. |
| One font family; build hierarchy with size, weight, colour, line height | Similarity (consistency); fewer dimensions vary, so each variation means more | **Folklore** as a rule; it is a reasonable default for lowering visual complexity. Two well-paired families are not shown to hurt. |
| Small uppercase labels need letter-spacing | All-caps text is read more slowly as running text (Tinker, *Legibility of Print*, 1963). Uppercase glyphs are uniform in height, which raises crowding. Small extra letter spacing speeds word recognition (Perea, Moret-Tatay & Gómez, 2011, [doi:10.1016/j.actpsy.2011.04.003](https://doi.org/10.1016/j.actpsy.2011.04.003)). Crowding limits recognition (Pelli & Tillman, 2008, [doi:10.1038/nn.2187](https://doi.org/10.1038/nn.2187)). | **Contested**: the effects are small. Arditi & Cho (2007) found uppercase is *more* legible at very small sizes and near the acuity limit ([doi:10.1016/j.visres.2007.06.010](https://doi.org/10.1016/j.visres.2007.06.010)). The popular "word shape" explanation for why lowercase reads faster is itself folklore. |
| Badges must be instantly scannable: short copy, no redundant icon | Glanceability; redundancy effect (2.2); Von Restorff only works if badges are rare | Mechanism **replicated** (redundancy effect in cognitive load theory); the badge rule is an application. |
| Title stands out "without shouting"; paragraphs get more line height and slightly lower contrast | Hierarchy through contrast on few dimensions (1.2); line-length and spacing research | Line length: Dyson & Haselgrove (2001) found long lines (100 characters per line) are read *faster* on screen, while about 55 cpl supports better comprehension ([doi:10.1006/ijhc.2001.0458](https://doi.org/10.1006/ijhc.2001.0458)). Dyson's (2004) review ([doi:10.1080/01449290410001715714](https://doi.org/10.1080/01449290410001715714)) concludes readers *prefer* moderate lengths. The 45–75 character convention comes from print typography (Bringhurst, *The Elements of Typographic Style*). **Contested**. Lower body contrast is aesthetic, not a readability gain (Legge et al. 1987), and must stay ≥ 4.5:1. |
| Proximity: rating next to title, quantity next to add-to-cart | Proximity (1.1); split attention (2.2); social proof at the decision point (6.2) | **Replicated** mechanisms. |
| Consistent icon style (filled vs outline, weight), limited colours | Similarity: mixed styles imply different meanings, or create accidental isolates | Mechanism **replicated**; the rule is an application. |
| Soft dividers; spacing creates relationships (too much whitespace disconnects) | Proximity vs common region (Palmer 1992): dividers and boxes are strong grouping cues and override spacing, so use them lightly | **Replicated** mechanism. Excess whitespace breaks proximity grouping. |
| Remove redundant labels ("Price:"); keep labelling consistent | Redundancy effect; signal-to-noise | Mechanism replicated. **Exception: form inputs must keep labels** (WCAG 1.3.1, 3.3.2). |
| Don't bake a variable (1 kg) into the title | Consistency between state and display (the title contradicts the selected option); IA hygiene | **Folklore** in the sense of no study, but it prevents a real state-mismatch bug. |
| Primary CTA shouldn't shout (all caps) | All caps read more slowly (Tinker 1963), though this barely matters for 1–2 words; social convention that caps mean shouting (RFC 1855, *Netiquette Guidelines*, 1995: "UPPER CASE LOOKS AS IF YOU'RE SHOUTING") | **Folklore** as a usability rule (short labels are unaffected); tone is a legitimate brand reason. |
| Show total price in the CTA to remove uncertainty | Uncertainty reduction; honest anchoring (4.3) | Blake, Moshary, Sweeney & Tadelis (2021), a StubHub field experiment ([doi:10.1287/mksc.2020.1261](https://doi.org/10.1287/mksc.2020.1261)), found that **hiding** fees until checkout raised spending and purchase rates. Showing the total upfront may cost short-term revenue. It is the honest option, and hiding fees is the "hidden costs" dark pattern (FTC 2022). The FTC's 2024 fee rule requires all-in pricing for live-event tickets and short-term lodging. **Replicated** that price salience changes behaviour. |
| Sticky title in nav (context) | Working memory (2.1), recognition over recall | Mechanism replicated. Check WCAG 2.4.11 and 1.4.10 Reflow (sticky bars consume the viewport when zoomed). |
| Sticky bottom action bar | Fitts and thumb reach (3.2) | Mechanism replicated. Must not obscure focus (2.4.11). |
| Preset quantity chips based on purchase data | Defaults (4.1); Hick (3.1); Fitts (larger targets) | **Replicated** mechanisms. Manipulative if the presets are inflated above typical need (anchoring, 4.3). |

---

## 9. Dark patterns: taxonomy and a three-check test

### 9.1 The literature

- **Brignull (2010).** Harry Brignull coined "dark patterns" and launched darkpatterns.org (now [deceptive.design](https://www.deceptive.design/), renamed "deceptive patterns"). The original catalogue includes:
  - trick questions
  - sneak into basket
  - roach motel
  - privacy Zuckering
  - price comparison prevention
  - misdirection
  - hidden costs
  - bait and switch
  - confirmshaming
  - disguised ads
  - forced continuity
  - friend spam

  It is practitioner work, not peer-reviewed. Book: *Deceptive Patterns* (2023).
- **Gray, Kou, Battles, Hoggatt & Toombs (2018), CHI**, "The Dark (Patterns) Side of UX Design" ([doi:10.1145/3173574.3174108](https://doi.org/10.1145/3173574.3174108)). They grouped Brignull-style patterns into five strategies:
  - **nagging**
  - **obstruction**
  - **sneaking**
  - **interface interference**
  - **forced action**
- **Mathur et al. (2019), CSCW**, "Dark Patterns at Scale" ([doi:10.1145/3359183](https://doi.org/10.1145/3359183)). They crawled about 11K shopping sites (about 53K product pages) and found **1,818** dark-pattern instances: 15 types in 7 categories:
  - sneaking
  - urgency
  - misdirection
  - social proof
  - scarcity
  - obstruction
  - forced action

  183 sites used outright deceptive practices, and 22 third-party providers sold dark patterns as ready-made services.
- **Luguri & Strahilevitz (2021)**, *Journal of Legal Analysis* ([doi:10.1093/jla/laaa006](https://doi.org/10.1093/jla/laaa006)). An experiment with a fake identity-protection service: mild dark patterns roughly **doubled** sign-ups over control, and aggressive ones roughly **quadrupled** them. Mild patterns provoked little backlash. This is the best evidence that the patterns *work*, which is why they're regulated.
- **Gray, Santos, Bielova & Mildner (2024), CHI**, "An Ontology of Dark Patterns Knowledge" ([doi:10.1145/3613904.3642436](https://doi.org/10.1145/3613904.3642436)). It harmonises 10 academic and regulatory taxonomies into a three-level ontology with **64** defined types. The high-level strategies are:
  - obstruction
  - sneaking
  - interface interference
  - forced action
  - social engineering
- **EU Digital Services Act, Regulation (EU) 2022/2065, Art. 25** ([EUR-Lex](https://eur-lex.europa.eu/eli/reg/2022/2065/oj)). Online platforms "shall not design, organise or operate their online interfaces in a way that deceives or manipulates the recipients of their service or in a way that otherwise materially distorts or impairs the ability of the recipients of their service to make free and informed decisions." Art. 25(3) names three examples:
  - (a) giving more prominence to certain choices
  - (b) repeatedly requesting a choice already made
  - (c) making termination harder than subscribing

  Art. 25(2) excludes practices already covered by the Unfair Commercial Practices Directive and the GDPR. Those still apply; they are just not double-covered.
- **FTC Staff Report, "Bringing Dark Patterns to Light" (September 2022)** ([ftc.gov](https://www.ftc.gov/reports/bringing-dark-patterns-light)). Four categories:
  1. design elements that **induce false beliefs**
  2. design elements that **hide or delay disclosure of material information**
  3. design elements that **lead to unauthorized charges**
  4. design elements that **obscure or subvert privacy choices**

### 9.2 The three-check test

A persuasive technique is acceptable only if it passes all three checks:

1. **Truthful framing.** The loss, scarcity, urgency, social proof or progress it claims is real.
2. **Symmetric exit.** Declining is as easy, visible and emotionally neutral as accepting.
3. **Endorsement.** The user would endorse the technique if they understood how it works. This is a publicity test: would it survive being explained on the screen itself?

How it maps to the taxonomies:

| Check | Catches (Gray et al. 2024 high-level / named patterns) | Regulatory anchor |
|---|---|---|
| 1. Truthful framing | **Sneaking** and **social engineering**: fake urgency or countdowns, fake scarcity, fake social proof, fake reference prices, hidden costs, bait and switch, disguised ads, fabricated progress | FTC categories 1 and 2; UCPD misleading actions and omissions |
| 2. Symmetric exit | **Obstruction**, **interface interference** and **forced action**: roach motel or hard-to-cancel, confirmshaming, visual interference (prominence asymmetry), nagging, preselection, forced registration | DSA Art. 25(3)(a), (b), (c); FTC category 4 (privacy) |
| 3. Endorsement | The remainder: techniques that are true and symmetric but exploit a bias against the user's interest, such as variable-reward loops tuned to compulsion, or defaults set for margin rather than fit. Also forced continuity and unauthorized charges, where the user never agreed. | DSA Art. 25(1) "materially distorts or impairs … free and informed decisions"; FTC category 3 |

Check 3 is the most subjective. It matches the core of the definitions that academic and regulatory sources converge on: impairing autonomy or informed choice. Checks 1 and 2 can be operationalised; check 3 needs judgement.

### 9.3 Manipulative forms of the persuasion principles (sections 4–6)

| Principle | Honest use | Manipulative form | Fails check |
|---|---|---|---|
| Defaults (4.1) | Pre-select what most would choose; easy to change | Pre-ticked add-ons or consent ("sneak into basket", preselection) | 2, 3 |
| Choice overload (4.2) | Curate, recommend, filter | Overwhelm to push the margin option; comparison prevention | 3 |
| Anchoring / contrast (4.3) | Real reference points | Fake "was" prices; inflated preset quantities; relative framing hiding recurring cost | 1 |
| Decoy (4.4) | Clear, differentiated tiers | Phantom tiers nobody is meant to buy | 3 |
| Framing (4.5) | Accurate gain or loss description | Confirmshaming; trick wording, double negatives | 1, 2 |
| Loss aversion (4.6) | Tell users what they will actually lose | Invented losses; countdown timers that reset | 1 |
| Status quo (4.7) | Respect familiar settings | Roach motel; termination harder than signup | 2 |
| Fogg prompts (5.1) | Timely, relevant prompts; respects "no" | Nagging after a decline | 2 |
| Goal gradient (5.2) | Credit real completed steps | Fabricated progress; streak anxiety | 1, 3 |
| Variable reward (5.3) | Novel content with stopping cues | Infinite scroll, randomised paid rewards, re-engagement notification bait | 3 |
| IKEA effect (5.4) | Real setup the user keeps | User-built work held hostage behind an undisclosed paywall | 1, 3 |
| Endowment (5.5) | Full-feature trial, clear end | Forced continuity (silent trial-to-paid conversion) | 1, 3 |
| Commitment (5.6) | Small useful first step | Low-ball / bait-and-switch | 1 |
| Reciprocity (6.1) | Unconditional value first | "Gift" revealed as gated after effort | 1 |
| Social proof (6.2) | Real, verifiable reviews and counts | Fake activity notifications, fake reviews | 1 |
| Aesthetic / credibility (6.3–6.4) | Polish that matches real quality | Fake trust badges; disguised ads | 1 |

---

## Product moment → principles index

| Moment | Primary principles | Watch for |
|---|---|---|
| **Onboarding** | Goal gradient with real credited steps (5.2); IKEA effect: build something real (5.4); commitment, starting small (5.6); progressive disclosure (3.5); Jakob's law (3.6); reciprocity, value before signup (6.1); Ovsiankina resumption (2.4) | Fabricated progress; work held hostage; forced registration |
| **Forms** | Cognitive load and split attention: labels next to fields (2.2); chunking, Cowan ~4 (2.1); smart defaults (4.1); Tesler, moving complexity to the system (3.4); Fitts and target size (3.2, WCAG 2.5.8); proximity (1.1) | Removing input labels; pre-ticked consent; trick wording |
| **Pricing** | Anchoring and relative thinking (4.3); decoy, weak (4.4); choice overload moderators (4.2); framing (4.5); defaults (4.1) | Fake reference prices; phantom tiers; hidden recurring costs |
| **Paywall / upgrade** | Loss aversion, honest losses only (4.6); endowment (5.5); status quo (4.7); framing (4.5) | Confirmshaming; fake countdowns; asymmetric dismiss; nagging |
| **Checkout** | All-in price in the CTA (8, Blake et al. 2021); working memory, order summary visible (2.1); Fitts and sticky action bar (3.2); peak–end, the confirmation screen (2.5); Doherty/Miller response times (3.3) | Hidden costs / drip pricing; sneak into basket; focus obscured by sticky bars (WCAG 2.4.11) |
| **Retention** | Peak–end, including offboarding (2.5); variable reward with stopping cues (5.3); commitment (5.6); status quo (4.7) | Roach motel; nagging; compulsion loops |
| **Empty states** | Reciprocity, show value (6.1); goal gradient and commitment, one first step (5.2, 5.6); figure–ground and hierarchy, one primary action (1.2, 1.3) | Fake social proof to fill the void |
| **Product page** | Proximity, rating by title, quantity by CTA (1.1); social proof (6.2); Von Restorff, one primary CTA (1.3); visual hierarchy and muted palette (1.2); credibility and consistency (6.4); preset chips (4.1); WCAG contrast (7) | Fake scarcity or viewers; fake reviews; inflated preset quantities |

---

## Corrections to popular claims (summary)

1. **Jam study.** Run by Iyengar (then a Stanford PhD student) and Lepper (Stanford) at Draeger's in Menlo Park, not a "Columbia study". "3% vs 30%" is the share of shoppers *who stopped* that later redeemed a coupon. The large display attracted *more* shoppers. Meta-analytic mean effect is about zero (Scheibehenne et al. 2010); the effect appears only under specific moderators (Chernev et al. 2015).
2. **"70–90% never change defaults".** No primary source found. Defaults are robust but vary widely (d = 0.68, with mostly unexplained heterogeneity).
3. **Car-wash card.** Nunes & Drèze (USC / Wharton), not Columbia. Completion was about 34% vs 19% (about 1.8x, not "double"). The coffee-card study (Kivetz, Urminsky & Zheng) is the Columbia one, and it shows goal gradient, not endowed progress.
4. **Cialdini "ranked reciprocity most powerful".** He did not rank the principles.
5. **"Free samples +2000%".** A best-case industry anecdote reported in a 2014 magazine article, not research.
6. **Loss aversion "2x (Kahneman)".** λ ≈ 2.25 comes from Tversky & Kahneman (1992). The 2024 meta-analysis gives about 1.96 with wide heterogeneity. Gal & Rucker (2018) dispute how far it generalises; Mrkva et al. (2020) defend it with moderators.
7. **Zeigarnik effect.** The 2025 meta-analysis found no memory advantage for unfinished tasks; the resumption tendency (Ovsiankina) holds.
8. **Miller's 7±2.** Not a menu limit. Working-memory capacity is about 4 chunks (Cowan 2001), and visible menus rely on recognition, not recall.
9. **Von Restorff.** Distinctiveness works on memory relative to context, not merely by grabbing attention (Hunt 1995).
10. **Decoy effect.** Fragile outside numeric, stylised comparisons (Frederick et al. 2014; Yang & Lynn 2014).
11. **Doherty threshold.** Based on a 1982 IBM report, not peer-reviewed research.
12. **Tesler's and Jakob's "laws".** Practitioner maxims, not empirical laws.

## Could not verify

- Full text of Nunes & Drèze (2006). The 34% / 19% figures and Drèze's 2006 affiliation are from memory, consistent with secondary reports.
- Exact denominators in Iyengar & Lepper (2000). The roughly 60% / 40% stop rates and 3% / 30% redemption rates are consistent across sources; exact counts are not given here.
- Doherty & Thadani (1982): not accessible; its method is unverified.
- Any primary source for "70–90% of users never change defaults".
- Replication status of the Tversky & Kahneman calculator/jacket relative-thinking item.
- A peer-reviewed publication of the *Economist* subscription decoy example.
- Exact percentages in Luguri & Strahilevitz (2021). The "roughly 2x / 4x" multipliers are reported consistently, but the exact rates differ between the paper summaries and a later presentation.
- Legge, Rubin & Luebker (1987): cited by journal, volume and pages; the DOI could not be confirmed via Crossref.

---

## Sources

**Perception**
- Wertheimer, M. (1923). Untersuchungen zur Lehre von der Gestalt II. *Psychologische Forschung*, 4. [doi:10.1007/BF00410640](https://doi.org/10.1007/BF00410640)
- Palmer, S. E. (1992). Common region. *Cognitive Psychology*, 24, 436–447. [doi:10.1016/0010-0285(92)90014-S](https://doi.org/10.1016/0010-0285(92)90014-S)
- Palmer, S. E., & Rock, I. (1994). Uniform connectedness. *Psychonomic Bulletin & Review*, 1, 29–55. [doi:10.3758/BF03200760](https://doi.org/10.3758/BF03200760)
- Field, D. J., Hayes, A., & Hess, R. F. (1993). Contour integration. *Vision Research*, 33, 173–193. [doi:10.1016/0042-6989(93)90156-Q](https://doi.org/10.1016/0042-6989(93)90156-Q)
- Wagemans, J., et al. (2012). A century of Gestalt psychology in visual perception I. *Psychological Bulletin*, 138, 1172–1217. [doi:10.1037/a0029333](https://doi.org/10.1037/a0029333)
- Treisman, A., & Gelade, G. (1980). Feature-integration theory. *Cognitive Psychology*, 12, 97–136. [doi:10.1016/0010-0285(80)90005-5](https://doi.org/10.1016/0010-0285(80)90005-5)
- Duncan, J., & Humphreys, G. W. (1989). Visual search and stimulus similarity. *Psychological Review*, 96, 433–458. [doi:10.1037/0033-295X.96.3.433](https://doi.org/10.1037/0033-295X.96.3.433)
- Wolfe, J. M., & Horowitz, T. S. (2004). What attributes guide visual attention? *Nature Reviews Neuroscience*, 5, 495–501. [doi:10.1038/nrn1411](https://doi.org/10.1038/nrn1411)
- von Restorff, H. (1933). Über die Wirkung von Bereichsbildungen im Spurenfeld. *Psychologische Forschung*, 18, 299–342. [doi:10.1007/BF02409636](https://doi.org/10.1007/BF02409636)
- Hunt, R. R. (1995). The subtlety of distinctiveness. *Psychonomic Bulletin & Review*, 2, 105–112. [doi:10.3758/BF03214414](https://doi.org/10.3758/BF03214414)
- Benway, J. P., & Lane, D. M. (1998). Banner blindness. *Proc. HFES*. [doi:10.1177/154193129804200504](https://doi.org/10.1177/154193129804200504)

**Attention and memory**
- Miller, G. A. (1956). The magical number seven, plus or minus two. *Psychological Review*, 63, 81–97. [doi:10.1037/h0043158](https://doi.org/10.1037/h0043158)
- Cowan, N. (2001). The magical number 4 in short-term memory. *Behavioral and Brain Sciences*, 24, 87–114. [doi:10.1017/S0140525X01003922](https://doi.org/10.1017/S0140525X01003922)
- Sweller, J. (1988). Cognitive load during problem solving. *Cognitive Science*, 12, 257–285. [doi:10.1207/s15516709cog1202_4](https://doi.org/10.1207/s15516709cog1202_4)
- Sweller, J., van Merriënboer, J., & Paas, F. (1998). Cognitive architecture and instructional design. *Educational Psychology Review*, 10, 251–296. [doi:10.1023/A:1022193728205](https://doi.org/10.1023/A:1022193728205)
- de Jong, T. (2010). Cognitive load theory… some food for thought. *Instructional Science*, 38, 105–134. [doi:10.1007/s11251-009-9110-0](https://doi.org/10.1007/s11251-009-9110-0)
- Murdock, B. B. (1962). The serial position effect of free recall. *J. Exp. Psych.*, 64, 482–488. [doi:10.1037/h0045106](https://doi.org/10.1037/h0045106)
- Zeigarnik, B. (1927). Das Behalten erledigter und unerledigter Handlungen. *Psychologische Forschung*, 9, 1–85. [doi:10.1007/BF02409755](https://doi.org/10.1007/BF02409755)
- Ovsiankina, M. (1928). Die Wiederaufnahme unterbrochener Handlungen. *Psychologische Forschung*, 11, 302–379. [doi:10.1007/BF00410261](https://doi.org/10.1007/BF00410261)
- Ghibellini, R., & Meier, B. (2025). Interruption, recall and resumption: a meta-analysis of the Zeigarnik and Ovsiankina effects. *Humanities and Social Sciences Communications*, 12. [doi:10.1057/s41599-025-05000-w](https://doi.org/10.1057/s41599-025-05000-w)
- Kahneman, D., Fredrickson, B. L., Schreiber, C. A., & Redelmeier, D. A. (1993). When more pain is preferred to less. *Psychological Science*, 4, 401–405. [doi:10.1111/j.1467-9280.1993.tb00589.x](https://doi.org/10.1111/j.1467-9280.1993.tb00589.x)
- Redelmeier, D. A., & Kahneman, D. (1996). Patients' memories of painful medical treatments. *Pain*, 66, 3–8. [doi:10.1016/0304-3959(96)02994-6](https://doi.org/10.1016/0304-3959(96)02994-6)
- Redelmeier, D. A., Katz, J., & Kahneman, D. (2003). Memories of colonoscopy: a randomized trial. *Pain*, 104, 187–194. [doi:10.1016/S0304-3959(03)00003-4](https://doi.org/10.1016/S0304-3959(03)00003-4)
- Alaybek, B., et al. (2022). All's well that ends (and peaks) well? A meta-analysis of the peak-end rule and duration neglect. *OBHDP*, 170, 104149. [doi:10.1016/j.obhdp.2022.104149](https://doi.org/10.1016/j.obhdp.2022.104149)

**Interaction cost**
- Hick, W. E. (1952). On the rate of gain of information. *QJEP*, 4, 11–26. [doi:10.1080/17470215208416600](https://doi.org/10.1080/17470215208416600)
- Hyman, R. (1953). Stimulus information as a determinant of reaction time. *J. Exp. Psych.*, 45, 188–196. [doi:10.1037/h0056940](https://doi.org/10.1037/h0056940)
- Landauer, T. K., & Nachbar, D. W. (1985). Selection from alphabetic and numeric menu trees using a touch screen. *CHI '85*. [doi:10.1145/317456.317470](https://doi.org/10.1145/317456.317470)
- Fitts, P. M. (1954). The information capacity of the human motor system. *J. Exp. Psych.*, 47, 381–391. [doi:10.1037/h0055392](https://doi.org/10.1037/h0055392)
- MacKenzie, I. S. (1992). Fitts' law as a research and design tool in HCI. *Human–Computer Interaction*, 7, 91–139. [doi:10.1207/s15327051hci0701_3](https://doi.org/10.1207/s15327051hci0701_3)
- Parhi, P., Karlson, A. K., & Bederson, B. B. (2006). Target size study for one-handed thumb use. *MobileHCI '06*. [doi:10.1145/1152215.1152260](https://doi.org/10.1145/1152215.1152260)
- Bergstrom-Lehtovirta, J., & Oulasvirta, A. (2014). Modeling the functional area of the thumb. *CHI '14*. [doi:10.1145/2556288.2557354](https://doi.org/10.1145/2556288.2557354)
- Miller, R. B. (1968). Response time in man-computer conversational transactions. *AFIPS FJCC*. [doi:10.1145/1476589.1476628](https://doi.org/10.1145/1476589.1476628)
- Card, S. K., Robertson, G. G., & Mackinlay, J. D. (1991). The information visualizer. *CHI '91*. [doi:10.1145/108844.108874](https://doi.org/10.1145/108844.108874)
- Doherty, W. J., & Thadani, A. J. (1982). *The Economic Value of Rapid Response Time*. IBM report GE20-0752. (Not accessed.)
- Saffer, D. (2006). *Designing for Interaction*. New Riders. (Tesler interview.)
- Carroll, J. M., & Carrithers, C. (1984). Training wheels in a user interface. *CACM*, 27, 800–806. [doi:10.1145/358198.358218](https://doi.org/10.1145/358198.358218)
- Singley, M. K., & Anderson, J. R. (1989). *The Transfer of Cognitive Skill*. Harvard University Press.

**Decision-making**
- Johnson, E. J., & Goldstein, D. (2003). Do defaults save lives? *Science*, 302, 1338–1339. [doi:10.1126/science.1091721](https://doi.org/10.1126/science.1091721)
- Madrian, B. C., & Shea, D. F. (2001). The power of suggestion. *QJE*, 116, 1149–1187. [doi:10.1162/003355301753265543](https://doi.org/10.1162/003355301753265543)
- McKenzie, C. R. M., Liersch, M. J., & Finkelstein, S. R. (2006). Recommendations implicit in policy defaults. *Psychological Science*, 17, 414–420. [doi:10.1111/j.1467-9280.2006.01721.x](https://doi.org/10.1111/j.1467-9280.2006.01721.x)
- Jachimowicz, J. M., Duncan, S., Weber, E. U., & Johnson, E. J. (2019). When and why defaults influence decisions. *Behavioural Public Policy*, 3, 159–186. [doi:10.1017/bpp.2018.43](https://doi.org/10.1017/bpp.2018.43)
- Iyengar, S. S., & Lepper, M. R. (2000). When choice is demotivating. *JPSP*, 79, 995–1006. [doi:10.1037/0022-3514.79.6.995](https://doi.org/10.1037/0022-3514.79.6.995)
- Scheibehenne, B., Greifeneder, R., & Todd, P. M. (2010). Can there ever be too many options? *JCR*, 37, 409–425. [doi:10.1086/651235](https://doi.org/10.1086/651235)
- Chernev, A., Böckenholt, U., & Goodman, J. (2015). Choice overload: a conceptual review and meta-analysis. *JCP*, 25, 333–358. [doi:10.1016/j.jcps.2014.08.002](https://doi.org/10.1016/j.jcps.2014.08.002)
- Tversky, A., & Kahneman, D. (1974). Judgment under uncertainty. *Science*, 185, 1124–1131. [doi:10.1126/science.185.4157.1124](https://doi.org/10.1126/science.185.4157.1124)
- Tversky, A., & Kahneman, D. (1981). The framing of decisions. *Science*, 211, 453–458. [doi:10.1126/science.7455683](https://doi.org/10.1126/science.7455683)
- Klein, R. A., et al. (2014). Investigating variation in replicability ("Many Labs"). *Social Psychology*, 45, 142–152. [doi:10.1027/1864-9335/a000178](https://doi.org/10.1027/1864-9335/a000178)
- Maniadis, Z., Tufano, F., & List, J. A. (2014). One swallow doesn't make a summer. *AER*, 104, 277–290. [doi:10.1257/aer.104.1.277](https://doi.org/10.1257/aer.104.1.277)
- Thaler, R. (1985). Mental accounting and consumer choice. *Marketing Science*, 4, 199–214. [doi:10.1287/mksc.4.3.199](https://doi.org/10.1287/mksc.4.3.199)
- Huber, J., Payne, J. W., & Puto, C. (1982). Adding asymmetrically dominated alternatives. *JCR*, 9, 90–98. [doi:10.1086/208899](https://doi.org/10.1086/208899)
- Simonson, I. (1989). Choice based on reasons. *JCR*, 16, 158–174. [doi:10.1086/209205](https://doi.org/10.1086/209205)
- Frederick, S., Lee, L., & Baskin, E. (2014). The limits of attraction. *JMR*, 51, 487–507. [doi:10.1509/jmr.12.0061](https://doi.org/10.1509/jmr.12.0061)
- Yang, S., & Lynn, M. (2014). More evidence challenging the robustness and usefulness of the attraction effect. *JMR*, 51, 508–513. [doi:10.1509/jmr.14.0020](https://doi.org/10.1509/jmr.14.0020)
- Huber, J., Payne, J. W., & Puto, C. (2014). Let's be honest about the attraction effect. *JMR*, 51, 520–525. [doi:10.1509/jmr.14.0208](https://doi.org/10.1509/jmr.14.0208)
- Levin, I. P., Schneider, S. L., & Gaeth, G. J. (1998). All frames are not created equal. *OBHDP*, 76, 149–188. [doi:10.1006/obhd.1998.2804](https://doi.org/10.1006/obhd.1998.2804)
- Kühberger, A. (1998). The influence of framing on risky decisions: a meta-analysis. *OBHDP*, 75, 23–55. [doi:10.1006/obhd.1998.2781](https://doi.org/10.1006/obhd.1998.2781)
- Kahneman, D., & Tversky, A. (1979). Prospect theory. *Econometrica*, 47, 263–291. [doi:10.2307/1914185](https://doi.org/10.2307/1914185)
- Tversky, A., & Kahneman, D. (1992). Advances in prospect theory. *J. Risk & Uncertainty*, 5, 297–323. [doi:10.1007/BF00122574](https://doi.org/10.1007/BF00122574)
- Gal, D., & Rucker, D. D. (2018). The loss of loss aversion. *JCP*, 28, 497–516. [doi:10.1002/jcpy.1047](https://doi.org/10.1002/jcpy.1047)
- Mrkva, K., Johnson, E. J., Gächter, S., & Herrmann, A. (2020). Moderating loss aversion. *JCP*, 30, 407–428. [doi:10.1002/jcpy.1156](https://doi.org/10.1002/jcpy.1156)
- Brown, A. L., Imai, T., Vieider, F. M., & Camerer, C. F. (2024). Meta-analysis of empirical estimates of loss aversion. *JEL*, 62, 485–516. [doi:10.1257/jel.20221698](https://doi.org/10.1257/jel.20221698)
- Samuelson, W., & Zeckhauser, R. (1988). Status quo bias in decision making. *J. Risk & Uncertainty*, 1, 7–59. [doi:10.1007/BF00055564](https://doi.org/10.1007/BF00055564)
- Kahneman, D., Knetsch, J. L., & Thaler, R. H. (1991). Anomalies: the endowment effect, loss aversion, and status quo bias. *JEP*, 5, 193–206. [doi:10.1257/jep.5.1.193](https://doi.org/10.1257/jep.5.1.193)

**Motivation and habit**
- Fogg, B. J. (2009). A behavior model for persuasive design. *Persuasive '09*. [doi:10.1145/1541948.1541999](https://doi.org/10.1145/1541948.1541999)
- Hull, C. L. (1932). The goal-gradient hypothesis and maze learning. *Psychological Review*, 39, 25–43. [doi:10.1037/h0072640](https://doi.org/10.1037/h0072640)
- Kivetz, R., Urminsky, O., & Zheng, Y. (2006). The goal-gradient hypothesis resurrected. *JMR*, 43, 39–58. [doi:10.1509/jmkr.43.1.39](https://doi.org/10.1509/jmkr.43.1.39)
- Nunes, J. C., & Drèze, X. (2006). The endowed progress effect. *JCR*, 32, 504–512. [doi:10.1086/500480](https://doi.org/10.1086/500480)
- Ferster, C. B., & Skinner, B. F. (1957). *Schedules of Reinforcement*. Appleton-Century-Crofts.
- Schultz, W., Dayan, P., & Montague, P. R. (1997). A neural substrate of prediction and reward. *Science*, 275, 1593–1599. [doi:10.1126/science.275.5306.1593](https://doi.org/10.1126/science.275.5306.1593)
- Eyal, N. (2014). *Hooked*. Portfolio. (Practitioner framework.)
- Norton, M. I., Mochon, D., & Ariely, D. (2012). The IKEA effect. *JCP*, 22, 453–460. [doi:10.1016/j.jcps.2011.08.002](https://doi.org/10.1016/j.jcps.2011.08.002)
- Sarstedt, M., Neubert, D., & Barth, K. (2017). The IKEA effect: a conceptual replication. *J. Marketing Behavior*, 2, 307–312. [doi:10.1561/107.00000039](https://doi.org/10.1561/107.00000039)
- Kahneman, D., Knetsch, J. L., & Thaler, R. H. (1990). Experimental tests of the endowment effect. *JPE*, 98, 1325–1348. [doi:10.1086/261737](https://doi.org/10.1086/261737)
- Plott, C. R., & Zeiler, K. (2005). The WTP–WTA gap, the "endowment effect," subject misconceptions… *AER*, 95, 530–545. [doi:10.1257/0002828054201387](https://doi.org/10.1257/0002828054201387)
- Freedman, J. L., & Fraser, S. C. (1966). Compliance without pressure. *JPSP*, 4, 195–202. [doi:10.1037/h0023552](https://doi.org/10.1037/h0023552)
- Burger, J. M. (1999). The foot-in-the-door compliance procedure. *PSPR*, 3, 303–325. [doi:10.1207/s15327957pspr0304_2](https://doi.org/10.1207/s15327957pspr0304_2)

**Trust and social**
- Gouldner, A. W. (1960). The norm of reciprocity. *ASR*, 25, 161–178. [doi:10.2307/2092623](https://doi.org/10.2307/2092623)
- Regan, D. T. (1971). Effects of a favor and liking on compliance. *JESP*, 7, 627–639. [doi:10.1016/0022-1031(71)90025-4](https://doi.org/10.1016/0022-1031(71)90025-4)
- Falk, A. (2007). Gift exchange in the field. *Econometrica*, 75, 1501–1511. [doi:10.1111/j.1468-0262.2007.00800.x](https://doi.org/10.1111/j.1468-0262.2007.00800.x)
- Cialdini, R. B. (1984; new & expanded ed. 2021). *Influence*. Harper Business.
- Goldstein, N. J., Cialdini, R. B., & Griskevicius, V. (2008). A room with a viewpoint. *JCR*, 35, 472–482. [doi:10.1086/586910](https://doi.org/10.1086/586910)
- Bohner, G., & Schlüter, L. E. (2014). A room with a viewpoint revisited. *PLoS ONE*, 9, e104086. [doi:10.1371/journal.pone.0104086](https://doi.org/10.1371/journal.pone.0104086)
- Scheibehenne, B., Jamil, T., & Wagenmakers, E.-J. (2016). Bayesian evidence synthesis… hotel towel reuse. *Psychological Science*, 27, 1043–1046. [doi:10.1177/0956797616644081](https://doi.org/10.1177/0956797616644081)
- Muchnik, L., Aral, S., & Taylor, S. J. (2013). Social influence bias. *Science*, 341, 647–651. [doi:10.1126/science.1240466](https://doi.org/10.1126/science.1240466)
- Kurosu, M., & Kashimura, K. (1995). Apparent usability vs. inherent usability. *CHI '95 Companion*. [doi:10.1145/223355.223680](https://doi.org/10.1145/223355.223680)
- Tractinsky, N. (1997). Aesthetics and apparent usability. *CHI '97*. [doi:10.1145/258549.258626](https://doi.org/10.1145/258549.258626)
- Tractinsky, N., Katz, A. S., & Ikar, D. (2000). What is beautiful is usable. *Interacting with Computers*, 13, 127–145. [doi:10.1016/S0953-5438(00)00031-X](https://doi.org/10.1016/S0953-5438(00)00031-X)
- Hassenzahl, M., & Monk, A. (2010). The inference of perceived usability from beauty. *HCI*, 25, 235–260. [doi:10.1080/07370024.2010.500139](https://doi.org/10.1080/07370024.2010.500139)
- Sonderegger, A., & Sauer, J. (2010). The influence of design aesthetics in usability testing. *Applied Ergonomics*, 41, 403–410. [doi:10.1016/j.apergo.2009.09.002](https://doi.org/10.1016/j.apergo.2009.09.002)
- Fogg, B. J., et al. (2001). What makes Web sites credible? *CHI '01*. [doi:10.1145/365024.365037](https://doi.org/10.1145/365024.365037)
- Fogg, B. J., et al. (2003). How do users evaluate the credibility of Web sites? *DUX '03*. [doi:10.1145/997078.997097](https://doi.org/10.1145/997078.997097)
- Lindgaard, G., et al. (2006). You have 50 milliseconds to make a good first impression. *BIT*, 25, 115–126. [doi:10.1080/01449290500330448](https://doi.org/10.1080/01449290500330448)
- Tuch, A. N., et al. (2012). The role of visual complexity and prototypicality regarding first impression of websites. *IJHCS*, 70, 794–811. [doi:10.1016/j.ijhcs.2012.06.003](https://doi.org/10.1016/j.ijhcs.2012.06.003)
- Reinecke, K., et al. (2013). Predicting users' first impressions of website aesthetics. *CHI '13*. [doi:10.1145/2470654.2481281](https://doi.org/10.1145/2470654.2481281)

**Accessibility and typography**
- W3C (2023). *Web Content Accessibility Guidelines (WCAG) 2.2*. [w3.org/TR/WCAG22](https://www.w3.org/TR/WCAG22/); Understanding docs: [w3.org/WAI/WCAG22/Understanding](https://www.w3.org/WAI/WCAG22/Understanding/)
- W3C. *Media Queries Level 5*, `prefers-reduced-motion`. [w3.org/TR/mediaqueries-5](https://www.w3.org/TR/mediaqueries-5/#prefers-reduced-motion)
- Legge, G. E., Rubin, G. S., & Luebker, A. (1987). Psychophysics of reading V: the role of contrast in normal and low vision. *Vision Research*, 27(7), 1165–1177.
- Tinker, M. A. (1963). *Legibility of Print*. Iowa State University Press.
- Arditi, A., & Cho, J. (2007). Letter case and text legibility in normal and low vision. *Vision Research*, 47, 2499–2505. [doi:10.1016/j.visres.2007.06.010](https://doi.org/10.1016/j.visres.2007.06.010)
- Perea, M., Moret-Tatay, C., & Gómez, P. (2011). The effects of interletter spacing in visual-word recognition. *Acta Psychologica*, 137, 345–351. [doi:10.1016/j.actpsy.2011.04.003](https://doi.org/10.1016/j.actpsy.2011.04.003)
- Pelli, D. G., & Tillman, K. A. (2008). The uncrowded window of object recognition. *Nature Neuroscience*, 11, 1129–1135. [doi:10.1038/nn.2187](https://doi.org/10.1038/nn.2187)
- Zorzi, M., et al. (2012). Extra-large letter spacing improves reading in dyslexia. *PNAS*, 109, 11455–11459. [doi:10.1073/pnas.1205566109](https://doi.org/10.1073/pnas.1205566109)
- Dyson, M. C., & Haselgrove, M. (2001). The influence of reading speed and line length on the effectiveness of reading from screen. *IJHCS*, 54, 585–612. [doi:10.1006/ijhc.2001.0458](https://doi.org/10.1006/ijhc.2001.0458)
- Dyson, M. C. (2004). How physical text layout affects reading from screen. *BIT*, 23, 377–393. [doi:10.1080/01449290410001715714](https://doi.org/10.1080/01449290410001715714)
- Bringhurst, R. *The Elements of Typographic Style*. Hartley & Marks.
- Hambridge, S. (1995). RFC 1855: Netiquette Guidelines. IETF. [rfc-editor.org/rfc/rfc1855](https://www.rfc-editor.org/rfc/rfc1855)
- Blake, T., Moshary, S., Sweeney, K., & Tadelis, S. (2021). Price salience and product choice. *Marketing Science*, 40, 619–636. [doi:10.1287/mksc.2020.1261](https://doi.org/10.1287/mksc.2020.1261)

**Dark patterns and regulation**
- Brignull, H. (2010–). Deceptive patterns catalogue. [deceptive.design](https://www.deceptive.design/); *Deceptive Patterns* (2023).
- Gray, C. M., Kou, Y., Battles, B., Hoggatt, J., & Toombs, A. L. (2018). The dark (patterns) side of UX design. *CHI '18*. [doi:10.1145/3173574.3174108](https://doi.org/10.1145/3173574.3174108)
- Mathur, A., et al. (2019). Dark patterns at scale: findings from a crawl of 11K shopping websites. *PACM HCI*, 3(CSCW). [doi:10.1145/3359183](https://doi.org/10.1145/3359183)
- Luguri, J., & Strahilevitz, L. J. (2021). Shining a light on dark patterns. *Journal of Legal Analysis*, 13, 43–109. [doi:10.1093/jla/laaa006](https://doi.org/10.1093/jla/laaa006)
- Gray, C. M., Santos, C. T., Bielova, N., & Mildner, T. (2024). An ontology of dark patterns knowledge. *CHI '24*. [doi:10.1145/3613904.3642436](https://doi.org/10.1145/3613904.3642436)
- Regulation (EU) 2022/2065 (Digital Services Act), Art. 25. [eur-lex.europa.eu/eli/reg/2022/2065/oj](https://eur-lex.europa.eu/eli/reg/2022/2065/oj)
- U.S. Federal Trade Commission (2022). *Bringing Dark Patterns to Light* (Staff Report, Sept. 2022). [ftc.gov/reports/bringing-dark-patterns-light](https://www.ftc.gov/reports/bringing-dark-patterns-light)
- CJEU, Case C-673/17 *Planet49* (2019): pre-ticked checkboxes do not give valid consent.
