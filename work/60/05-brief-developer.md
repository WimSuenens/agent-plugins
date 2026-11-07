# Brief: developer — 60
Goal: Write the standard text for the gemba sample and bump the factory to 1.3.0, exactly as the contracts say.
Inputs: contracts/60-standard-changes.md (file-by-file list, section 6 AC map, section 9 for what is NOT yours); contracts/60-gemba-sample.md, 60-gemba-walk.md, 60-gemba-line.md; docs/requirements/60-gemba-sample.md; tracker issue 60; work/60/04-result-architect.md (open points); docs/adr/0011, 0012, 0013; docs/agents/factory.md (ownership).
Constraints:
- You own plugins/ only. Change only the files and sections the contracts list (hansei.md new section 6 and item 3a of section 5, SKILL.md step 8.3a as a pointer, baseline.md skip list for v3/v4/v5, plugin.json version 1.3.0, any others in 60-standard-changes). Do not renumber 8.4 onward.
- Do NOT touch tests/ (QA owns it; QA moves the version pins to v5) and do NOT write CHANGELOG, README or docs/factory/reference.md (docs-writer owns them). Existing tests may be red on old wording until QA updates them; say so in the result, do not edit them.
- Do not touch hooks/ or scripts/ (tooling fingerprint must equal 1.2.0's). Run plugins/factory/scripts/check-bump.sh against origin/main and plugins/factory/scripts/fingerprint.sh; quote both results in the result (standard fingerprint moves, tooling unchanged).
- Run the reference transcript filter of contracts/60-gemba-walk.md section 3 once on a real transcript of this machine's Claude Code (a local transcript file; do not commit it, quote nothing from it, no absolute home paths in the result or any committed file) and say in the result whether it worked and what you changed.
- Reuse the existing 5 Whys / blame-the-process rule by pointing to it; add no eighth measure, no hoshin view, no script reading gemba lines, no project data. No absolute home paths in any committed file.
- Commits start "#60 developer:"; commit at each checkpoint (hansei.md, SKILL.md, baseline.md, version bump).
Output: edits under plugins/factory/; result in work/60/06-result-developer.md (Status: working at start).
Done: every standard-change line of 60-standard-changes done; check-bump.sh exit 0; fingerprints quoted; transcript filter run once and reported; two-way decisions listed; known-red tests named.
