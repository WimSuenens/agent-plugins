# Result: developer — 60
Status: done
Progress:
  Done: hansei.md (v5, gemba row, item 3a, section 6); SKILL.md (8.3a pointer, 8.4, Done when, Andon kind 7 and Procedure sentences, reading list); baseline.md (v3/v4/v5, item 7, records line); plugin.json 1.3.0. All committed as "#60 developer: ...".
  Next: none (QA moves the pins; docs-writer writes CHANGELOG, README, reference.md)
Summary: Every line of contracts/60-standard-changes section 2 is done under plugins/factory/ in four files (SKILL.md, hansei.md, baseline.md, plugin.json); no hooks/, scripts/, tests/ or docs touched. The walk is described once, in hansei.md section 6; SKILL.md 8.3a and hansei.md item 3a point to it; the 5 Whys is pointed to, not restated. Reference commands are text, no script.
  check-bump.sh against origin/main: "pass: minor bump needed, 1.2.0 -> 1.3.0", exit 0.
  fingerprint.sh (plugin dir): release 1.3.0; standard fa204f845da2d8e6e7dddbfa85c5fcdd3165b9f143b5ef74cf742dc45744648c (1.2.0: b0f96401e7e4f5fe46aab86ab7dff5ecf50e92f7cd2b9d5e6d85b8b8841cbc67, moved); tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5 (equal to 1.2.0's, unchanged).
  Transcript filter (contracts/60-gemba-walk section 3), run once on a local agent transcript of this machine: worked unchanged. jq exit 0, no stderr, CALL and RESULT lines in equal number, FINAL line produced; nothing quoted or kept. I changed nothing in the filter. Real-project readability stays unverified item 3. Note the partial-cap path (head -c on a 200k view) and the commits fallback were not run by me; T8 covers them.
Artifacts: plugins/factory/skills/run/SKILL.md, plugins/factory/references/hansei.md, plugins/factory/references/baseline.md, plugins/factory/.claude-plugin/plugin.json
Decisions:
  - baseline.md item 6 also says "A v4 or v5 record" for the extent-grammar skip (v5 carries the same line) / rejected leaving v4 only (a v5 record would be unguarded) / cost to undo: one phrase
  - baseline.md section 7 line "The optional records: line is written as one of the three forms shown ... more than one schema" replaces "exactly as shown ... both schemas" / needed because v4+v5 or all three are now possible / one sentence
  - hansei.md worked example and its stage-log label example both moved to factory 1.3.0 (same item; label path and release) / rejected moving only the header / one find-and-replace
  - hansei.md section 6 also holds a short copy of the sample-rule example (#14) and the one-line contrasts of the line; the contract's full variant table is not copied (QA fixtures) / rejected copying all variants / add rows if QA finds a gap
  - the Andon sentence is placed as a paragraph before "A stop can lose work in flight" in Procedure, not as a numbered step, so steps 1-7 keep their numbers / rejected a step 8
Open questions: none
Known-red tests (old wording, QA moves them to v5; I did not edit tests/):
  - test_standard_text.sh: ac1-plugin-version, ac1-version-own-line, ac14-marker-first-line, ac14-example-marker
  - test_andon_text.sh: ac24-marker-v4, ac29-version-is-minor-above-1.1.0
  - test_baseline_a3.sh: o4-records-line-in-template, o4-records-line-rule, o4-section3-item6-names-the-line, v4-reads-v3-and-v4, v4-marker-prose-is-v4, ac26-the-one-exception, r3-v4-skip-line
  - test_fingerprint.sh: ac2-install-path-release, ac2-plugin-dir-release, ac2-real-plugin-json, ac4-version-moves-release (these pin the real plugin.json at 1.2.0; the contract expected this file unchanged, so the pin needs a version bump too)
  - Green: test_baseline_replay.sh, test_andon_replay.sh, test_andon_kind3_kind4.sh, test_check_bump.sh, test_cut_offs.sh, test_token_spend.sh. No repo lint command exists beyond these test scripts.
  - Home-path search over the added lines of the diff: only `~/.claude/projects` (allowed); no absolute home path, no project data (examples use example/shop).
