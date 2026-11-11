---
status: proposed
---

# Local countermeasures stop at a wide fence and end with their run

The Lead may try a **local countermeasure** without asking the person: a change to the factory's standard, written as an **override** in one project's `docs/agents/factory.md` and tried there before anyone proposes it for the plugin. Spreading a proven one to the plugin (**yokoten**) stays the person's decision card. Before this decision nothing said what an override may not touch or how long it may stay, so the slices that build the andon and the per-run improvement loop had no bounds to work from. A skipped approval or a skipped check can't be taken back, so the person set the bounds: [decision on #37](https://github.com/WimSuenens/agent-plugins/issues/37#issuecomment-6641342929), option C plus an andon follow-up and a poka-yoke check.

## Decision

1. **The fence is wide.** The standard holds a "Never overridable locally" list. The Lead reads it (`references/protocol.md`, read by `skills/run/SKILL.md`), and it names:
   - merge and production approvals;
   - the decision-card route for one-way doors;
   - QA and security verdicts as merge gates;
   - the andon itself: the abnormality list, and the right of any role to raise one;
   - the memory rules and the shell-scope rules;
   - the honesty rule for measures: no measure is dropped or redefined to look better, and a measure that isn't captured reads "not captured".
2. **Prevention first: poka-yoke at the source.** The Lead checks every new override against the fence before it writes it, and refuses any override that touches a fenced item.
3. **Detection second.** At the start of every run, the Lead checks the project's active overrides against the fence. Any role that sees an override crossing the fence can raise it as an **andon abnormality**. This adds an entry to the map's abnormality list.
4. **Visibility.** Every active override is listed by name and start date in each hansei record ("Active overrides" field) and in the project's hoshin view.
5. **Expiry at the close of the run.** An override ends at the close of the run it started in. At that close, the person gets one line per active override, next to the run's A3: start date, and before/after numbers against the baseline. The person chooses one of three:
   - **keep** it for another run;
   - **promote** it, which means a yokoten decision card;
   - **drop** it. The override is then removed from `docs/agents/factory.md`, and the baseline gets a note.

## Consequences

- No item merges or ships without the person's yes, and no QA or security verdict is skipped. The line can always be stopped, and no measure disappears, whatever a project overrides.
- Each override costs the person about 2 minutes per run. That time is batched into the run close, which the person attends anyway. Overrides can't pile up unseen between hoshin reviews, whose timing and owner the map still lists as not specified.
- An override can't stay in place longer than one run without a fresh yes. Renewal still lets an experiment span runs, so this ADR does **not** settle how long a countermeasure experiment is measured. That stays deferred until its trigger fires: the first countermeasure experiment starts.
- **Two-way, left to a slice:** how an override is written down, and which rule wins when two overrides, or an override and the plugin, disagree. Also two-way: the exact wording and placement of the fence list, the name of the hansei field, and how the keep/promote/drop choice is recorded.
- **Undo cost:** moving back to a hoshin-only review (option A) is about half a day of text changes and loses nothing. Loosening one fenced item later takes its own decision card and about half a day. Narrowing the fence afterwards can't make up for checks skipped or measures not recorded while it was narrow, so the fence starts wide.

## Considered options

- **A: Wide fence, overrides reviewed at the next hoshin.** Rejected. It gives the same protection, but it ties expiry to a review moment the map hasn't defined, so overrides could stay unreviewed for many runs.
- **B: Narrow fence, only merge, production and the decision-card route protected.** Rejected. The Lead could skip a security review, redefine an abnormality, or stop recording a measure. The person would only see it in hansei after items had gone through. Skipped checks need to be re-run item by item, and unrecorded measures are lost for good, which forces a baseline reset.
- **Detection only (a run-start check, with no check at write time).** Rejected by the person's follow-up. An override that crosses the fence should never be written, not just be caught afterwards.

Complements [0005](0005-one-way-doors-reach-the-person-as-decision-cards.md): yokoten and loosening the fence both reach the person as cards.

## Revision (#116)

Decided in spec #108 (the improvement loop). The wide fence, the write-time check and the run-start check stay as decided above. What changes is how long a local countermeasure lives and where the other kind goes:

- **Every finding is classified** with one test: would this hold in a project with a different stack, business and person? No: project-local. Yes: factory-fundamental. The class and its reason are recorded in the project.
- **A project-local improvement is kept permanently.** The Lead applies it through the role files, which the fence already binds, and writes a trace row (`docs/agents/improvements.md`) saying what changed and why. It no longer expires at the end of a run. A later cycle reports its before and after against the same measure, with `not captured` where it was not measured.
- **Expiry now applies to an override only**, the try-out form of a countermeasure: point 5 (keep, promote, drop at the run close) is unchanged for it. An override that proved itself is written into a role file and traced.
- **A factory-fundamental finding is drafted as a sanitised proposal** (the A3 is its format), shown to the person, and submitted to the marketplace repository only after their approval; the decision where the change belongs is taken in a separate session there. Yokoten of an override stays a decision card.
- Data egress: the protocol's question E allows only an issue the person approved to leave the project.

Consequences. Role files grow and are reviewed through version control instead of at a run close. A permanent improvement that turns out wrong is removed by editing the role file and its trace row; the cost is a commit. Undo cost of this revision: restoring expiry is a text change of about half a day.

**Provisional** until a run has closed with at least one override that went through keep, promote or drop.
