# Brief: product-owner — 57

Goal: Turn slice #57 into a requirement with testable acceptance criteria: a run ends with one A3 on one problem and one countermeasure experiment, measured before and after against a per-project baseline issue the plugin tells the project to set up, replacing today's batch-at-the-end step 9.

Inputs:
- Slice ticket #57 (the frame: Question, Behaviour, Under test, Deliberately faked) and the map #34 (Destination: the "Done when" lines on A3 and baseline; Decisions so far: Baseline, Loops, Standard work, Changing the standard, Measures, Bounds of a local countermeasure, What reaches agent-plugins; Deferred; Out of scope).
- `docs/requirements/39-hansei-record.md` and `docs/requirements/49-andon.md` (style, terms, and the unexercised AC-9, AC-10, AC-28 which this slice carries into its demo; do not rewrite them).
- ADRs 0011 (the fence), 0012 (releases, fingerprint, freeze), 0013 (merge style).
- Standard work as it stands on this branch, to see what the criteria change: `plugins/factory/skills/run/SKILL.md` (steps 8 to 10, Andon, Settle round), `plugins/factory/references/hansei.md`, `plugins/factory/references/protocol.md`.
- `CONTEXT.md` for the Factory terms.

Constraints:
- This item is calibration on the frozen pre-release factory (series: calibration (pre-baseline)). The new standard is demoed in a separate session started with `claude --plugin-dir <worktree>/plugins/factory` on the sandbox repo; criteria that only a person can judge there are marked [human-only], as in requirement 49.
- Honesty rule: a measure not captured reads "not captured", never 0; no average that hides a missing value. Measurement data and the baseline live in the project where the factory runs, never in agent-plugins; only a person-approved step-9 issue (no project data, no code, no raw records) reaches agent-plugins.
- The fence of ADR 0011 stays: the experiment is a local override; promoting it to the plugin is a decision card for the person (one-way door), never automatic. Expiry at run close is keep, promote or drop (AC-28 of #49).
- Fix contract text before code: criteria must be checkable on the text of the plugin and on fixtures. Any rule that detects or measures something (for example summing the hansei records into a baseline per release series) must name the data it is validated on, the data that showed the defect or the shape: the hansei records already on #39 and #49 in this tracker, replayed by QA or the developer.
- Two-way decisions are left to the roles inside the slice (do not decide them by assumption: leave them to the architect, record in Decisions): the baseline issue's form, the A3 template and where it is posted, how long an experiment is measured (items "after"; one run only), whether a `hooks/` or `scripts/` change resets the baseline (only if a script is added).
- Out of the slice: hoshin view and themes, gemba sample, "blame the process first" in the standard, metrics store, significance testing, comparing projects.
- A role does not stop at a question you can decide; a one-way door found while writing goes back as `needs-decision`.
- No absolute home path in any file you write.

Output: `docs/requirements/57-per-run-a3-and-baseline.md` (commit it as `#57 product-owner: ...`), and your result `work/57/02-result-product-owner.md` (write it with `Status: working` as soon as you start).

Done:
- User outcome in plain words, serving the map's third and fourth "Done when" lines (the baseline part), with the terms used.
- Acceptance criteria in Given/When/Then, each traceable to an Under test line of #57; the A3 content (problem, 5 Whys that blame the process first, countermeasure, before/after with item counts and release, what is still uncertain); the baseline's setup, recording, update, reset and history rules; what step 9 becomes; the run-close order with the settle round.
- Each criterion marked as checked by QA on the branch, [human-only] for the acceptance demo, or [post-merge]. The demo must be able to provoke AC-9, AC-10 and AC-28 (a paused agent and an override in force at run close) and say what the person types.
- A short "Deliberately not in this slice" list matching the frame.
- Open questions and the two-way decisions left to later roles listed.
