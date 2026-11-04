# Result: architect — 39
Status: done
Progress:
  Done: feedback 17 applied in 7e87566 (scripts contract), cb1a155 (hansei contract), f93ca28 (stage log, standard changes), d3e959a (stage-log example)
  Next: none
Summary: Finding 1: contracts/39-plugin-scripts.md token-spend example now reads `~/.claude/projects/<project>/<session id>/subagents/agent-<agent id>.jsonl`. I also added a common rule that script stderr names files by basename only. Finding 2: the label's `plugin root` line is written with the home directory as `~`, both in stage-log §1 and in the §5 example. Fingerprint failures carry basename-only messages, so no home path reaches the record. Session ids stay in the committed lead state, accepted (see Decisions). Merge strategy untouched. Finding 3, aligned with feedback 15:
- Scripts §1: absent `version` gives the pre-release label. An empty or non-semver `version` is exit 2. An unreadable file in either set is exit 2 with stdout empty (all or nothing).
- Scripts common rules: a semver is defined strictly, with no leading zeros.
- Scripts §2: paths are read with `-z`. A base version that is not a semver is exit 2. A HEAD version like `1.08.0` is refused. New examples: `references/café.md` and `1.08.0`. The check runs at three points: item PR, frontier PR, before merge.
- Scripts §3: `--` ends options, exit 2 on bad usage, exit 3 names the file by basename.
- Hansei §2/§5: Find hansei filters by `.user.login`. Post and Edit use `mktemp` and then `rm -f`.
- Standard changes §3: plugin root rule for reference files, and the step 3 frontier check. §5: bump re-check before `gh pr merge`, and the semver check before tagging.
Re-verified: all 7 token lines add up, lead time 4h33m - 51m - 15m = 3h27m, and the suggested versions in every check-bump example are right. A jq run on sample comments confirmed the author filter drops an impostor's marker comment. Fingerprint hashes were not recomputed: the frozen install and 84f282e are unchanged, so the example stands.
Artifacts: contracts/39-plugin-scripts.md, contracts/39-hansei-record.md, contracts/39-stage-log.md, contracts/39-standard-changes.md
Decisions:
- Lead session ids stay in the committed lead state and so in history after a --merge merge / rejected: keeping them out of git (a fresh session resuming the item could no longer find the Lead's transcripts at close) / undo: one label line and the close's lookup; they are random ids that grant no access and only locate a file on this machine.
- Label `plugin root` written with $HOME as `~`, script calls take the path from SKILL.md's `Plugin root:` line instead / rejected: absolute path in the label / undo: one line.
- Semver is strict (no leading zeros, per semver.org) in fingerprint, check-bump and the tag check / rejected: accept `1.08.0` and strip zeros (two spellings of one release, octal trap in bash arithmetic) / undo: one regex.
- check-bump: a non-semver version on the base is exit 2, not a silent 0.0.0 / rejected: treating it as 0.0.0 (would pass any bump from a broken main) / undo: one branch.
- fingerprint: `"version": ""` is exit 2, only an absent key gives the pre-release label / rejected: empty = absent (QA F3) / undo: one condition.
- Frontier-round bump refusal goes to the person, noted in the Factory run section / rejected: a feedback brief to the architect (a frontier PR should not touch plugins/factory at all, and no role there owns plugins/) / undo: one sentence.
- Bump re-check before merge also covers frontier PRs (Merge PR serves both) / rejected: items only / undo: one clause.
Open questions:
- For the developer (via lead): plugins/factory/references/hansei.md, Label example (~l.251) still shows `/Users/p/...`. It should read `~/...` per stage-log §1. Its lines 9, 22 and 31 write `${CLAUDE_PLUGIN_ROOT}` and should write `<plugin root>` (the path from SKILL.md's line). The contract now fixes these exit codes, which the build must match: fingerprint exits 2 on an unreadable file and on an empty version; check-bump exits 2 on a non-semver base and refuses `1.08.0` at HEAD; token-spend exits 2 on bad usage and accepts `--`.
- Lesson for the tracker doc owner: any command splicing a value into `gh api --jq` must take a value that can't contain quotes (`gh api --jq` has no `--arg`).
