# Result: qa-engineer — 49 (round 2)
Status: done
Abnormality: none
Progress:
  Done: six pinned tests moved to contract section 10; F1 skip is plain checks; fixtures for rule 5.6, question E (11, 12), diff-tree -z (accented, newline, leading quote), FREEZE author check, promote chosen; C8 control replay; clean-export run; reviews/qa-49.md updated
  Next: none
Summary: Verdict pass (round 2). tests/run.sh exits 0: 950 passed, 2 skipped (the two docs-writer items of O3: ownership row in docs/agents/factory.md, CHANGELOG 1.1.0). F1 closed. AC-3: new control C8 (security L4 vs QA F4) not flagged; kind 2 text unchanged in round 2, so 5/5 flagged and 0/8 controls stand. Final fingerprints (AC-29): release 1.1.0; standard 683cfb53180122ef3307b5d00d04adf37c141076985d212941925d4a908429c2; tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5. check-bump.sh exit 0. Human-only list unchanged (AC-7, 9, 10, 11, 14, 20, 25, 28) with two live checks added (paraphrase/re-read in a live Lead; the gh graphql map-editor read for kind 6(b), plus an E-refusal ask for AC-20); post-merge AC-30.
Artifacts: reviews/qa-49.md; tests/factory/test_andon_text.sh, test_andon_kind3_kind4.sh, fixtures/ac19-overrides.tsv, fixtures/ac3-controls.tsv
Decisions:
  1. Fixtures 11 and 12 are the contract's (silence as keep, gist); my earlier extras were renumbered 13 to 16 / rejected keeping two sets with the same numbers / cost to undo: edit one tsv.
  2. Kind 6(b) and rule 5.6 are tested as transcriptions of the text on scratch repos and strings; the live gh call is left to the demo / rejected faking gh / cost to undo: none.
Open questions: O1 (AC-8 wording: draft file vs stage log) and O3 (docs-writer: ownership row, CHANGELOG 1.1.0; devops runbook) as in reviews/qa-49.md.
Missing: none
