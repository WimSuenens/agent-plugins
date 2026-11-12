# Security review: 168 (skill frontmatter quoting, factory 2.13.0)

Verdict: pass

Findings: none (no critical, high, medium or low).

## Checks
- Skill text: `plugins/factory/skills/obeya/SKILL.md` and `run/SKILL.md` change only line 3, wrapping the value in double quotes. Neither value holds a `"` or `\`, so the quoting cannot change the parsed text; the fixtures hold the pre-change text and the test compares byte for byte. No instruction or permission text added.
- Changed paths against the contract: only `contracts/168-skill-frontmatter.md` and `docs/agents/roles/docs-writer.md` are off-list; both are the expected architect contract and docs-writer role knowledge (info, not findings).
- `tests/factory/test_skill_frontmatter.sh`: the ruby program sits in a single-quoted block with no shell interpolation; file names come from a fixed glob and `ARGV`; uses `YAML.safe_load`; no eval, no temp files, reads git only with `show` on a fixed ref and path. Variables are quoted.
- Version-pin tests: read `plugin.json` through `jq -r` and compare with a semver regex or the read value; `sed -i ''` runs on a temp copy only. No unsafe handling. The relaxed pins still assert semver.
- CHANGELOG and plugin.json: version 2.13.0 and fingerprints, no secrets.
- Secrets and home paths: `git grep` for the home path over HEAD (outside work/) and `git log -S` over `work/` return nothing; every file under `work/168/` is named `NN-<type>-<role>.md` (or the lead state).
- Dependency audit: no manifest or lockfile changed; runtime tools are ruby (Psych) and jq, stock.
