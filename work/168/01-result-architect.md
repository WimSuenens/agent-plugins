# Result: architect — 168
Status: done
Abnormality: none
Progress:
  Done: contract contracts/168-skill-frontmatter.md written and checked with paths.sh
  Next: none
Summary: One contract. Confirmed by running Ruby Psych over all 20 SKILL.md files that exactly obeya and run fail strict parsing (colon-space in description). Fix is double-quoting both descriptions (both contain an apostrophe; none a double quote or backslash). QA seam is a glob-based script under tests/factory/ that parses every frontmatter and prints the failing path. Patch bump 2.12.2 to 2.12.3 applied by the lead at merge; contract lists the tests that hard-code 2.12.2 and break on the bump (QA updates them). No ADR; two-way door.
Artifacts: contracts/168-skill-frontmatter.md
Decisions: quote style double quotes / block scalar and rewording rejected / one edit to undo; parser choice left to QA (Ruby Psych suggested) / any parser
Open questions: none
