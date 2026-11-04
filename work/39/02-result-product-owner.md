# Result: product-owner — 39
Status: done
Progress:
  Done: inputs read; requirement written and committed (#39 product-owner: requirement for the hansei record)
  Next: none
Summary: Requirement for the hansei record at release 1.0.0: 22 Given/When/Then criteria in six groups (release and fingerprint, bump poka-yoke, stage log, record content and honesty rule, what reaches agent-plugins, #39's calibration record). Every Under test line maps to one or more criteria: Measures AC-15/17/22, Capture AC-12/18, Honesty AC-16, What reaches agent-plugins AC-20/21, ADR 0012 releases and fingerprint AC-2/3/5, bump poka-yoke AC-8/9. Human-only criteria (demo session with `claude --plugin-dir`): AC-9, 12, 17, 18 (second half), 19 (second half), 21. Post-merge: AC-7 (tag), AC-22 (#39's calibration record). Everything under Deliberately faked is out of scope. Also out of scope: the baseline-reset rule for tooling changes (this slice only makes them visible, AC-5) and the andon on a changed fingerprint. Found while writing: measure 7 (doors) is only known after the resurvey, which runs after work/ is removed. Resolved as decision 1. No one-way door found.
Artifacts: docs/requirements/39-hansei-record.md
Decisions:
- Measure 7 filled by editing the same hansei comment after the resurvey ("pending resurvey" until then; "not captured" if no resurvey) / rejected: resurvey before merge, second comment / undo: ~1 hour of text in step 8.
- "n/a" only for a stage that didn't run, separate from "not captured" / rejected: "not captured" for skipped stages / undo: template change plus schema bump.
- Poka-yoke covers all of plugins/factory/ and checks the level (minor for standard work, patch for the rest) / rejected: standard-work paths only (ADR 0012 wording) / undo: minutes, narrow one rule in Open PR.
- "Active overrides" field (ADR 0011) included now, reading "none" / rejected: add with the overrides slice / undo: drop a field before aggregation exists.
- Lead time runs from first stage start to the person's merge approval / rejected: to the merge itself (after the record is posted) / undo: template definition change.
- Token spend includes the Lead, summed from the main transcript over the item's window / undo: drop a row.
Open questions:
- Architect: how tooling changes are told apart in the record (two fingerprints or another way); where the fingerprint computation lives; the record layout and marker (contract).
- Architect: where the post/edit hansei tracker operations live (run skill vs each project's issue-tracker.md, which older projects lack).
- Architect: add Hansei record and Stage log to CONTEXT.md.
- Lead with the person: which scratch project and slice host the demo item; the AC-9 throwaway branch must never be pushed to WimSuenens/agent-plugins.
- Lead: who creates the factory-v1.0.0 tag (Lead in Merge PR, or devops in Delivery).
