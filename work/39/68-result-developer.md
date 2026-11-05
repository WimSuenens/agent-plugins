# Result: developer — 39
Status: done
Progress:
  Done: all six findings of 67-feedback-developer, commit "#39 developer: path rule, one-call close with git clean, glob pathspec, I4 whitelist, basename --"
  Next: none; QA moves the tests below and re-verifies
Summary: protocol.md Messages carries the no-home-path rule; run/SKILL.md has the pointer (step 4) and step 8.6 as one shell call with "${w:?}", ':(glob)' pathspec, git clean -f -d -x -q plus a [ ! -e ] test; hansei.md section 5 step 6 mirrors it; security-reviewer.md has the git log -S"$HOME/" checklist line; Merge PR keeps --merge with the reason clause; cut-offs.sh whitelists api-error markers (^[a-z_]+$ else other) and uses basename --. Close commands run as one call in a scratch repo: a 03-dump/ directory is not staged and is removed, work/ ends gone; a nested repo under work/<id>/ stops the chain (rc 1, git rm staged, nothing committed). check-bump.sh exits 0. tests/run.sh: test_standard_text.sh fails on the old close wording (below); the other suites pass.
Artifacts: plugins/factory/{references/protocol.md,references/hansei.md,skills/run/SKILL.md,agents/security-reviewer.md,scripts/cut-offs.sh,skills/setup-factory-skill/references/issue-tracker-github.factory.md}
Decisions:
- basename -- applied to every basename call in cut-offs.sh only / rejected: also fingerprint.sh and token-spend.sh (outside the finding) / undo: n/a; the same perl one-liner there.
- Lead-state pointer placed in run/SKILL.md step 4 (covers briefs too) / rejected: a second line at the briefs step / undo: move the sentence.
Open questions: none (security: token-spend.sh and fingerprint.sh still call basename without --, same L12 class)
Tests QA must move (test_standard_text.sh): close-C6-* and close-H6-* (symlink-guard-before-add, add-nn-before-add-u, add-before-commit, commit-staged-only, lead-state-before-rm, rm-chain): expect "${w:?}", the ':(glob)work/<id>/[0-9][0-9]-*.md' pathspec, and `git clean -f -d -x -q` plus `[ ! -e` instead of `rm -rf`; close-ha-commit-before-rm, close-step1-four-commands, close-run-clean, close-run-work-gone, close-run-commits, close-run-lead-state-in-history (the extracted close commands use "$w" and rm -rf). Also flip sleep-wake-inside-alone-not-asleep in test_cut_offs.sh to expect `interrupted`.

## Lead overturn: basename -- in all scripts
Decision "basename -- in cut-offs.sh only" overturned (Source: lead). `basename --` now in every basename call of fingerprint.sh and token-spend.sh too; behaviour otherwise unchanged. test_fingerprint.sh 77, test_token_spend.sh 93, test_cut_offs.sh 62 (1 skipped) pass; test_standard_text.sh failures are the close-* assertions listed above (fail=1 counter, same cause).
