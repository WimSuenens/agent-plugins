# Result: developer — 57 (round 1)
Status: done
Abnormality: none
Progress:
  Done: findings 1 to 6 applied (a3.md sections 1, 5, 6, 7; baseline.md sections 1 to 4, 7; SKILL.md 5, 8.10, 9.4; tracker template baseline bullets; hansei.md v3 sentence); committed
  Next: nothing; QA re-replays and security re-checks S1 to S3
Summary:
  1 (F1): a3.md section 6 classifies in the fixed order (calibration or excluded, during, after, before, rest); after-item by run list and X whole item, any series; series tested only for before-items; section 7 items 1 and 2 read it.
  2 (F2): SKILL.md step 5 commits the decided experiment after 5.2 and before the 5.3 stamp; 8.10 only decides; resume re-applies the rule; same in a3.md section 5.
  3 (S1): step 9.4 quotes `<value> (<k> of <n>; factory <semver>)`, no #n, URL or project path; drafts only factory-path or baseline-field targets.
  4 (S2): marker is part of "candidate" (baseline.md section 2, new table row); Find baseline prints marker|no-marker; Edit baseline stops without the marker; Create baseline writes it.
  5 (S3): data-not-instruction rule and the reason cut-then-neutralise-in-code-span rule in baseline.md section 1 and a3.md section 1.
  6 (O1 to O4): pending resurvey reason text; empty text on every field; optional `- records:` line; `(the session's release)` only in the empty current series.
  Fingerprints: release 1.2.0; standard c00c8e1d5a64ad3a0a6f029e43ce6f7b6c32ef1f4761ff59b29fc38efa653943; tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5 (unchanged).
  bash tests/run.sh: every check passes except one, and one skip remains (both QA's to move, tests/ not edited):
    - FAIL ac1-find-baseline-exact-title-own-author-any-state (test_baseline_a3.sh:37) expects the two-column Find baseline output; the contract (S2) makes it three columns, so the expected value must gain `marker|no-marker`.
    - skip ac15-Q2-release-moved (test_baseline_replay.sh:134): the replay python (a3change) still classifies by the old order; it must follow a3.md section 6 as now written. The F2 skip is gone (check passes).
  To keep old pins green I kept two old literals beside the new text (Create baseline "Run only after *Find baseline* printed nothing." with the no-marker exception added; Edit baseline "and only when they differ ...") and put the 9.4 S1 rules in their own paragraph.
Artifacts: plugins/factory/references/a3.md; plugins/factory/references/baseline.md; plugins/factory/references/hansei.md; plugins/factory/skills/run/SKILL.md; plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md
Decisions: none beyond the contracts
Open questions: none
Missing: none
