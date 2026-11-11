# Contract 113 — Integrator: merge train and clean-up

Issue [#113](https://github.com/WimSuenens/agent-plugins/issues/113) · Parent map [#108](https://github.com/WimSuenens/agent-plugins/issues/108) · Blocked by [#112](https://github.com/WimSuenens/agent-plugins/issues/112)

Paths:
- plugins/factory/scripts/merge-train.sh
- plugins/factory/agents/integrator.md
- plugins/factory/references/protocol.md
- plugins/factory/skills/run/SKILL.md
- plugins/factory/.claude-plugin/plugin.json
- tests/factory/test_merge_train.sh
- tests/factory/test_role_tasks.sh
- tests/factory/test_integrator.sh
- tests/factory/test_ownership_tdd.sh
- tests/factory/test_fingerprint.sh
- tests/factory/test_andon_text.sh
- tests/factory/test_gemba.sh
- tests/factory/test_standard_text.sh
- tests/factory/test_lean_rules.sh
- contracts/113-merge-train.md
- CHANGELOG.md

shared: plugins/factory/.claude-plugin/plugin.json, CHANGELOG.md

## 1. Who does what

The integrator does the mechanical merge of approved slices, in the order of its plan's `merge` lines. The person still approves each merge (*merge and clean up?*); the lead passes the approval time to the integrator (`Approved: <time>`), and the integrator refuses to merge without it. The card turning `Done` stays the lead's tracker write; the integrator prints `done <id>`.

## 2. `scripts/merge-train.sh`

`rebase <worktree>`, `adr <worktree> <id>`, `bump <worktree> <id>`, `merge <worktree> <id> --approved <time>`, and `run` (all four, in order). The script header is the reference.

- **Rebase** on `origin/main`: a clash in `plugin.json` takes main's version (bump raises it); a clash in `CHANGELOG.md` keeps both entries, the branch's above main's; any other clash aborts the rebase and is reported (exit 3), the worktree kept.
- **ADR numbers**: a new `docs/adr/NNNN-*.md` whose number main uses for another file takes the next free number, references in the branch's changed files follow.
- **Bump**: after the rebase `check-bump.sh` must pass; when it refuses, the version is raised to the level it names and the changelog entry of the item follows. A missing entry or two entries for one version is reported (exit 4), never dropped.
- **Merge**: the bump check gates the merge again; push, `gh pr merge --merge`, tag `factory-v<version>` when the version changed, remove the worktree and the branch (local and remote).
- **Failure**: a failed push or merge exits 5 and keeps the worktree and branch; the line says so for the lead to report. A clean-up that does not finish exits 6.

Exit: 0 ok; 2 usage; 3 rebase clash; 4 bump or changelog problem; 5 merge failed; 6 merged, clean-up unfinished.

## 3. Failure stops the train

On a non-zero exit the integrator does not start the next slice, keeps the worktree and reports the line and exit code.

## 4. Shell

The integrator's shell adds `scripts/merge-train.sh` for a slice the lead marks approved. No tracker write, and no push but the script's lease push of the rebased branch.

## 5. Tests

`tests/factory/test_merge_train.sh`: the scripts seam (two slices merged in order with the second rebased on the first, the bump and changelog after the rebase, ADR renumbering, a missing changelog entry, a clash outside the shared files, a failed merge keeping the worktree, usage and approval) and the standard-text seam (ownership of the steps in the agent, the run text and the protocol).
