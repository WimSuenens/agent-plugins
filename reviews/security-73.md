# Security review: 73 (test ownership and the TDD loop, factory 2.1.0)

Verdict: pass. No critical, high or medium finding.

## Scope

All 34 changed files reviewed (diff of origin/main...item/73): three contracts, one requirement, plugin.json (version 2.0.0 to 2.1.0), the architect, developer and qa-engineer agent files, hansei.md, protocol.md, the run skill, the setup skill and its factory.md template, seven scenario cards plus README, six shell tests, and seven files in work/73/.

## Path check

`git diff --no-renames --name-only origin/main...item/73 | paths.sh check --ignore work/73/ contracts/73-*.md` printed no `off-list:` line. No finding.

## Instruction text: does any control weaken?

- Fenced section (Never overridable locally, F1 to F7 and E) in protocol.md: byte-identical to origin/main (extracted and diffed). The only protocol.md change is a new `## Tests` section outside the fence.
- Merge and production approval (F1): no change in who approves. The run skill's approval and merge steps are untouched in this diff.
- QA and security gates (F3): the new text says "The security review stays mandatory" and the optional code review "cannot replace the QA or the security stage, cannot make either verdict optional or non-binding, and its absence never blocks a merge". Its findings are not a verdict and do not gate; QA and security verdicts remain the gates. Duplicate findings are kept once under the owning verdict, so a security finding is not dropped (the reviewer's copy is). Not a weakening.
- The new diff-breadth check is mandatory on every slice and adds a check; it replaces none.
- Shell scope, memory rules, memory guard: no change. QA's new Tests task writes only under `tests/` and its result, which it already owns.
- Data egress: no new posting or sending. The brief for the developer names the targeted test by reference; no tracker content is copied.
- Ownership: the new rules strengthen it. The developer must not write under `tests/` and a commit that does is a kind-3 hit. The lead routes a test question to QA and a contract question to the architect and edits neither. No instruction tells a role to write under a path it does not own. The setup template tells repos to keep developer unit tests out of the `tests/` row.

## Shell tests (tests/factory/)

- test_ownership_tdd.sh: works in a `mktemp -d` directory from lib.sh (line 42). Reads only repo files and `git show`/`git archive` of the baseline commit and origin/main. No network call, no write outside the temp dir, no eval, no read outside the repo. Variables are quoted. The `$HOME` use (line 271) is a read-only grep for a leaked home path.
- The edits to the five older tests are version-string updates and `skip` retirements with a stated reason; `sed -i ''` acts on temp copies. Retiring the ac44/ac45 checks narrows old assertions about a release that is now superseded; the replacements are the rel-* checks. Not a security control.
- Limitation, informational: the test BASE sha `4086c9c` must exist in the clone, otherwise the file skips itself. A skip is not a failure, so a shallow clone passes silently. Not a finding for security; QA may note it.

## Dependency audit

The slice adds or changes no manifest. The repo has one manifest, plugins/toolkit/skills/source-to-pptx/assets/docker/requirements.txt, unchanged by this item (`git diff --stat` for plugins/toolkit is empty). `pip-audit` is not installed here, so no audit ran against it. Result: no dependency change in scope; nothing audited. Recommendation for a later item: audit that file.

## work/73/

`git log -S"$HOME/" --format='%h %s' origin/main..HEAD -- work/` returned nothing. Every file in work/73/ is named `00-lead-state.md` or `NN-result-<role>.md`. Secret-pattern grep over the item's files found no hit (the only matches are the existing scanner patterns in plugins/factory/scripts/post-text.sh, not changed here).

## Findings

None.
