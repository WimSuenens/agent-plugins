# Result: developer — 39
Status: done
Progress:
  Done: fingerprint.sh + 1.0.0 (161e348); check-bump.sh; token-spend.sh; references/hansei.md; run/SKILL.md and tracker patch (last commit)
  Next: qa-engineer and security-reviewer
Summary:
  All four contracts built under plugins/factory/. Scripts pass fixture tests on bash 3.2 and 5, and fingerprint.sh reproduces the contract's worked example for both the frozen install and 84f282e (identical standard/tooling lines). token-spend.sh reproduces the PO transcript example exactly (387472 / peak 53942 / 11 messages). check-bump.sh gives the AC-9, AC-10 and item-39 outputs (on this branch now: "pass: minor bump needed, 0.0.0 -> 1.0.0"). `claude plugin validate plugins/factory` passes. The repo has no test or lint command; the test scripts are in the scratchpad, not committed (tests/ is qa's path).
  Branch fingerprints now: standard 1536e9e0bc403f9512d18465ccfac4c33e149780ae1822438af46dfd622304f0, tooling 53634291c854e7974b9b03633e19d19d5e18c4b2f6ea316b504c7fd67d4cb9b0 (will move if anything under plugins/ changes).
Artifacts:
  plugins/factory/.claude-plugin/plugin.json (version 1.0.0)
  plugins/factory/scripts/fingerprint.sh, check-bump.sh, token-spend.sh
  plugins/factory/references/hansei.md (new)
  plugins/factory/skills/run/SKILL.md
  plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md
  Run: bash plugins/factory/scripts/fingerprint.sh plugins/factory; bash plugins/factory/scripts/check-bump.sh; bash plugins/factory/scripts/token-spend.sh [--since T] [--until T] <jsonl>...
  Fixture tests (not committed): /private/tmp/claude-501/-Users-wimsuenens-Projects-portfolio-agent-plugins/b3146b4a-f9f3-49bc-a33a-9f3c202be9b0/scratchpad/t_fp.sh, t_cb.sh, t_ts.sh
Outside plugins/ (docs-writer): README.md and CHANGELOG.md (release 1.0.0, hansei record, bump rule); this repo's docs/agents/issue-tracker.md (replace its Factory operations section with the patched one); .claude-plugin/marketplace.json untouched (no version, as required).
Decisions:
  - check-bump.sh lists plugin.json in the refusal's path lines only when it is the sole changed path; contract example 2 (1.0.1 bump, lists only developer.md) conflicts with its literal "one line per changed path". Plugin.json still counts as a change for the level (a json-only change needs a patch bump). / rejected: always list it / cost to undo: one line.
  - `security-reviewer: spend not captured (...); peak context …` instead of the contract example's bare `not captured (...)` before "peak", so the "spend" key stays on the line. / rejected: contract wording / cost: one line in hansei.md.
  - n/a allowed only in measures 2 and 5 in hansei.md (contract grammar table says 2, 3, 5, but its measure 3 definition says roles that never ran read 0). / rejected: allowing n/a in 3 / cost: one line.
  - token-spend.sh exits 2 on bad arguments (unlisted in contract); old plugin.json without a valid version counts as 0.0.0 in check-bump.sh.
  - Version in plugin.json is parsed with sed, not jq, so fingerprint.sh and check-bump.sh need no jq.
Open questions:
  - Architect: the two contract conflicts above (example 2 path listing; n/a in measure 3).
  - Tooling tests live outside the repo; qa-engineer may want to adopt the fixtures into tests/.
