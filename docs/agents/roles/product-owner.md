# Role file: product-owner

Project rules, checks and knowledge for the product-owner role, kept under version control. Only the product-owner role reads this file and its skills folder, `docs/agents/skills/product-owner/`.
It may add rules, checks and knowledge. It never lifts a protocol guard, an ownership rule or a one-way-door rule; such a line has no effect and the lead reports it.

## Rules and checks

## Knowledge

## Skills used

## Migrated memory

<!-- migrated: factory-product-owner/craft-card-already-sunk.md -->
---
name: craft-card-already-sunk
description: When part of a door is already irreversible before the choice (e.g. data already public), put it in its own block above the options so options only claim what they actually change
metadata:
  type: feedback
---

On a merge-style card, the branch's content was already public on a permanent PR ref; options only changed whether it also landed on main.

**Why:** without a separate "already public / already sunk" block, an option looks like it protects something it cannot, and the person overweights it.
**How to apply:** block order: Why now, Already sunk (whatever you choose), Same in all options, then options; each option's undo line names what *it* makes permanent, in bold. Distinguish policy switch (cheap, next item) from the one-time event (permanent). Related: [[craft-card-combined-doors]], [[card-undo-estimates]].

<!-- migrated: factory-product-owner/craft-card-combined-doors.md -->
---
name: craft-card-combined-doors
description: When a card bundles linked doors where one part is a cheap rename and one is unrecoverable (e.g. a freeze over time), make the unrecoverable part carry the undo line and the recommendation
metadata:
  type: feedback
---

Architects sometimes combine two linked one-way doors in one card (e.g. version label + whether to freeze the tool during a run). Options then differ only in a cheap-to-rename part plus a part that time makes permanent.

**Why:** the person weighs "Undoing it later" most; if every option reads "minutes to undo", the real one-way part (time passing on mixed state) gets hidden.
**How to apply:** put shared mechanisms in a "Same in all options" block; in each option, state the rule the person must follow (exact commands not to run, until which event) under Cost; name the unrecoverable part explicitly in bold in its undo line; list the architect's two-way sub-decisions once as "decided inside, overturnable". Raise an open question when a freeze rule may have uncovered paths (e.g. restarts). Related: [[card-undo-estimates]], [[craft-card-review-moment]].

<!-- migrated: factory-product-owner/craft-card-review-moment.md -->
---
name: craft-card-review-moment
description: When a proposal's expiry or review relies on a mechanism the map marks "Not yet specified", offer an option tied to an existing moment
metadata:
  type: feedback
---

On a card where an option says "expires / re-confirmed at <event>", check the map's "Not yet specified" and Deferred lists. If the event has no defined time or owner, the expiry is a trigger nobody trips over. Offer an option that ties it to a moment the person already attends (e.g. run close), and say so in the undo line of the original option.

**Why:** a deferral or expiry without an observable trigger is an abandonment (reversibility skill); found on a "bounds of local overrides" card where review was "at next hoshin", which the map had not defined.

**How to apply:** also check that the new option does not silently settle a deferred door; if it touches one, say in the technical detail that it stays deferred. Related: [[card-undo-estimates]].

<!-- migrated: factory-product-owner/craft-failed-ac-status.md -->
---
name: craft-failed-ac-status
description: How to record a human-only AC that failed at the acceptance demo and is re-judged after a fix
metadata:
  type: feedback
---

When a human-only AC fails at the demo and the fix goes back through contracts, add a *Status:* line under the AC: what failed, where the evidence is (tracker comment / issue numbers, never a `work/` path), the schema/version the fix lands in, and who re-judges it (e.g. the person's rule "on QA's word unless QA demands a re-run").

**Why:** requirements land on main; `work/` is gone by then, and QA needs to know what basis replaces the demo for the re-judgement.

**How to apply:** also check that every table row touched by the failure has its new testable wording (e.g. a fix to token spend needs its own line in the measure's row, even if the brief only lists other rows). See [[craft-record-timing]].

<!-- migrated: factory-product-owner/craft-fired-triggers.md -->
---
name: craft-fired-triggers
description: Slice fires a deferred trigger -> pin a testable value; slice must not fire one -> keep it out of ACs; pin fuzzy frame thresholds to countable checks
metadata:
  type: feedback
---

When a slice frame or ADR names this slice as the trigger for a deferred door (e.g. reconcile cadence, how a user gets an initial password), do not leave the criterion open. Pin a slice-only value as configuration (e.g. "1-minute interval, change within 2 minutes"), make the AC record the measured outcome, and list it under Decisions with undo cost.

**Why:** "within a reasonable time" is not testable by qa without a question; and the frame usually says "record what was learned", which needs a measurement in an AC.

**How to apply:** scan ADR "Not decided here" lists for triggers that this slice fires; also check vendor-specific gotchas in ADR worked examples (e.g. forced password change at first logon vs. the demo client) and raise them to the architect as open questions.

**The reverse case:** when the frame says a deferral's trigger is "a test hits it" and the slice should not fire it, keep that behaviour out of the ACs and name the deferred default in Out of scope, saying no criterion tests it. Likewise pin a frame's fuzzy threshold ("~40 lines", "no external dependency") to a countable check (`wc -l` over named files; only builtins plus /bin, /usr/bin) so the Under test line maps to a pass/fail AC.

<!-- migrated: factory-product-owner/craft-record-timing.md -->
---
name: craft-record-timing
description: For a record posted at a fixed moment, check each field is actually known then; fields known later need a pending value and a fill-in step
metadata:
  type: feedback
---

When a requirement has a record posted at one moment (e.g. a hansei comment at merge approval, before cleanup), walk each field against the step order of the process. A field produced by a later step (e.g. resurvey after merge) can't be filled then. Settle it in the requirement: a "pending" value plus an edit of the same record, and "not captured" if the later step never runs.

**Why:** found on a hansei-record slice where measure 7 (doors at resurvey) came after `work/` removal. Left open, QA can't test it and the honesty rule would be broken silently.

**How to apply:** also separate "n/a" (stage didn't run) from "not captured" (not measured). Mark real-session criteria [human-only] and after-merge checks [post-merge] so QA can sort them. Related: [[craft-fired-triggers]].

<!-- migrated: factory-product-owner/craft-validation-data-exists.md -->
---
name: craft-validation-data-exists
description: Before naming replay data in an AC, fetch it and confirm it has the shape the brief claims; build controls as field-edited copies of the real record
metadata:
  type: feedback
---

A brief said "the hansei records already on #39 and #49". They were manual comments with no marker; the only readable release record was in another repo (the sandbox) and an older-schema one next to it. Naming them blind would have promised a replay that finds nothing.

**Why:** Replay rules (aggregations, detection) are only as honest as their data; "5 of 5" results need real cases.
**How to apply:** `gh api .../comments` and grep for the marker before writing the validation table. List each real record (where, schema, what it shows), state what is missing in the doc and in the result's Open questions, and write controls as copies of the real record changed in named fields only, with the expected outcome written before the replay. Give expected numbers for the real record in the AC itself (QA can check them without a question).

Also for demos: seeds are typed by the person in the demo window; say the exact words, and add a line "if the Lead declines a seed, record it as not exercised, not a pass".

<!-- migrated: factory-product-owner/feedback-card-budget-constraint.md -->
---
name: feedback-card-budget-constraint
description: When the person states a budget limit (e.g. "no spending now"), carry it into the card's title, Why now and recommendation, and mark options that break it
metadata:
  type: feedback
---

When a person revises a card with a budget constraint (e.g. "free/self-hosted only, no spending now"), state that constraint in the decision sentence and in **Why now**, add an option that meets it, and label any remaining option that breaks it ("kost geld, past niet bij..."). Keep at most three options by merging close variants (e.g. Google + Microsoft as one "systems retailers run" option) rather than dropping the contrast.

**Why:** the person rejected a paid recommendation for a €0 one; a card that hides the constraint makes them re-argue it.

**How to apply:** on any card revision triggered by a budget remark; also put the cost of breaking the constraint later in "If we're wrong". Related: [[feedback-card-near-two-way]], [[feedback-card-undo-estimates]].

<!-- migrated: factory-product-owner/feedback-card-near-two-way.md -->
---
name: card-near-two-way
description: For "which system/vendor first" cards — research ranks by builder cost; weigh target-user credibility, and state why a cheap-to-undo choice still needs the person
metadata:
  type: feedback
---

Research notes rank integration candidates on API ease and cost to the builder. A card's recommendation should also weigh what the destination's user would recognise as proof (e.g. retail staff don't live in GitHub). The lead asked for exactly this judgement.

**Why:** The first real proof sells the product. A technically easy target can prove the mechanism but miss the value.
**How to apply:** When a choice is cheap to undo in code (the adapter is swappable, about 1-2 weeks) but still reaches a card, say why in the result: it costs money or decides what the proof shows. Put the shared ground ("same in all options") above the options. Never invent prices the research lacks. Write "not yet checked" and raise an open question instead.

<!-- migrated: factory-product-owner/feedback-card-undo-estimates.md -->
---
name: card-undo-estimates
description: Decision cards need day/week figures; architects usually give only low/medium/high — convert and flag for architect confirmation
metadata:
  type: feedback
---

Architect options files usually rate build effort and undo cost qualitatively (low/high). The card template forbids "hard to reverse"; it needs days/weeks.

**Why:** "Undoing it later" is what makes a door one-way; the person weighs it most.
**How to apply:** Turn the ratings into plausible day/week figures yourself, phrase them as "ongeveer", and add an open question asking the architect to confirm them before the lead posts the card. For a language/runtime rewrite, "about as long as everything built so far" is a usable concrete framing. Lead corrections (e.g. scope removals) must be stripped from every option, not just footnoted.

<!-- migrated: factory-product-owner/feedback-no-shell-inputs.md -->
---
name: no-shell-inputs
description: product-owner toolset sometimes lacks Bash (draft + report blocked); when it has gh/git, read the frame and check validation data exists
metadata:
  type: feedback
---

Toolset varies per run. Sometimes only Read/Write/Edit/Grep/Glob: no `gh`, no git commit, so issue frames are unreadable unless the brief quotes them. Then draft from the brief, ADRs and code, mark it draft, report `blocked`, list the missing frame, and define metric-style criteria with synthetic known-answer fixtures. The lead accepted this and sent the frame verbatim next round.

When Bash is present (checked in item 57): read `gh issue view` for the frame and map, and `git commit` own paths. Use the absolute worktree path: `../wt/<id>` is relative to the repo, which sits under `portfolio/`, not `Projects/` (a first write landed in the wrong folder; delete strays).

**Why:** An empty-handed block wastes a round; a requirement built on missing data wastes the next.
**How to apply:** Try Bash first. Mapping a frame: Under test lines that only a partner or judge can falsify go in a table with "what we hand over", not forced ACs. Check the draft against the frame's Behaviour for contradictions (a frame said "a tool change shows up", which conflicted with an epoch guard that refused every changed script).

See [[craft-validation-data-exists]] for checking the data a brief names.

