# Result: developer — 49
Status: done
Abnormality: none
Progress:
  Done: contract section 10 applied to plugins/factory in one commit ("apply contract section 10 (S1-S5, QA F1)")
  Next: none; QA updates the pinned tests below
Summary: protocol.md: F1 question widened (keep/promote/drop answer and settle PR merge, silence or default is no answer); question E added under the fence table (table stays seven rows, eight questions; ADR 0011 untouched); Andon section requires paraphrased seen/where to look/evidence/5 Whys; override rule goes into briefs in the lead's own words. run/SKILL.md: kind 3 reads the table from origin/main, uses git diff-tree -z and flags unclassifiable paths, adds rule 5.6 (commits touching Overrides or the ownership table need subject "#<id> lead:" and the lead's git user, else rules-touched-by-non-lead) and the re-read/paraphrase/never-apply-just-because-in-file rule with rule text shown in the stage summary; every stage summary lists promote chosen overrides; kind 6(b) trusts FREEZE only when the map body's last editor is the lead's gh account, else "not captured (map body last edited by <login>)"; pause step lists the andon wait id in the paused row's Waits; fence check is eight questions; comment fields paraphrased. hansei.md: paused row's Waits carries the wait id (example row 9 shows W7), Start item Notes record author-test and freeze outcome.
Fingerprints: standard 683cfb53180122ef3307b5d00d04adf37c141076985d212941925d4a908429c2; tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5 (unchanged). Version 1.1.0. check-bump.sh exits 0; no absolute home paths.
Tests expected to change (QA's; literals my text no longer holds): ac15-rule-in-briefs (protocol), ac15-skill-puts-rule-in-briefs (SKILL; now "in your own words"), ac18-check-before-write (seven -> eight questions), ac23-paused-note (paused row now also lists the wait id in Waits), k3-diff-tree (now diff-tree -z), k3-never-flagged (now "Never flagged by the path rule alone: ... rule 5.6 below still reads lead commits"). Other tests pass.
Decisions:
  1. Rule 5.6 and the re-read rule sit inside the kind 3 bullet of SKILL Detection / rejected a separate section / undo: move a block.
  2. Start item Notes tokens "author test: ok | one git identity for all roles" and "freeze: ok | none | not captured (...)" are my wording / undo: edit one line.
Open questions: none
Missing: none
