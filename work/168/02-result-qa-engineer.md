# Result: qa-engineer — 168
Status: done
Abnormality: none
Progress:
  Done: frontmatter test written and shown failing for the right reason; seven pinned-version tests made version-agnostic; checked in a scratch copy with the two fixes and a 2.12.3 bump.
  Next: none (lead builds the developer brief; after the fix, the lead applies the bump and the CHANGELOG entry).
Summary:
  Targeted test: `bash tests/factory/test_skill_frontmatter.sh` (wired in automatically: tests/run.sh globs tests/factory/test_*.sh). Full suite: `bash tests/run.sh`.
  It parses every plugins/*/skills/*/SKILL.md with Ruby Psych (safe_load), checks mapping, string description, name == directory; prints `frontmatter: FAIL <path> <msg>` / `frontmatter: ok <n> files`.
  Today it fails for the expected reason: obeya (line 2 column 133) and run (line 2 column 86) "mapping values are not allowed in this context"; the two byte-equality rows fail too (parse error). Rows that pass today: line 3 starts with `description: `, other lines equal origin/main.
  Byte-equality compares the parsed description to fixtures tests/factory/fixtures/frontmatter/{obeya,run}.description (pre-slice text from main); other lines are diffed against origin/main minus line 3.
  Pinned versions (gemba, integrator, andon_text, standard_text, ownership_tdd, fingerprint, lean_rules) now read plugin.json (semver shape, own-line check against the read version); test_fingerprint's fixture dir and the "version moves release" row use the read version and 9.9.9; lean_rules reads the newest `## factory ` CHANGELOG entry.
  Check: scratch copy with both descriptions quoted and plugin.json at 2.12.3: frontmatter test 7/7 ok, full suite green except test_lean_rules ac19-changelog-has-the-standard-fingerprint. That row is expected: the SKILL.md edits move the standard fingerprint and the newest CHANGELOG entry (2.12.3, lead) must carry the new fingerprints from scripts/fingerprint.sh. Tooling fingerprint row passes (unchanged).
  Contract discrepancy: the contract says 20 SKILL.md files ("18 of 20 pass", "ok 20 files"); the repo has 18, so 16 of 18 pass today and the fixed run prints `frontmatter: ok 18 files`. The test uses the glob count, not 20. The architect may correct the text.
Artifacts: tests/factory/test_skill_frontmatter.sh; tests/factory/fixtures/frontmatter/obeya.description; tests/factory/fixtures/frontmatter/run.description; edits to tests/factory/test_{gemba,integrator,andon_text,standard_text,ownership_tdd,fingerprint,lean_rules}.sh
Decisions: Ruby Psych as the parser / PyYAML, Node yaml / cost to undo: one script. Fixtures for the pre-slice descriptions instead of `git show main` / main will hold the fixed text after merge, so a git read would go stale / cost: none. Version pins replaced by semver-shape plus own-line checks, not pinned to 2.12.3 / a pin breaks on the next bump.
Open questions: none
