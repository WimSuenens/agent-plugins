# Security review: 244 (inline names check)

Verdict: pass. No findings.

Changed files reviewed: tests/site/names.mjs, tests/site/names.test.mjs, tests/site/getting-started.test.mjs, docs/requirements/188-wiki-shell.md, docs/requirements/244-inline-names-check.md, contracts/244-inline-names-check.md, work/244/ messages.

Checks
- Regex denial of service: the regexes are anchored or bounded (`^\s*(`{3,}|~{3,})(.*)$`, `docs/agents/<class>+.md` with a fixed lookbehind); none has nested quantifiers. The span scanner is hand-written. Probes: 100k unmatched single backticks took 8 ms; 3000 unmatched runs of mixed length took 1 ms; 50k repeats of `docs/agents/` took 0 ms. Worst case for unmatched backtick runs is quadratic, but input is repo-authored page text, so there is no attacker-controlled input. Informational only.
- Path handling: `skillText` and `handWrittenPages` walk with `readdirSync({withFileTypes})`; `Dirent.isDirectory()` is false for symlinks, so symlinks are not followed and there is no traversal out of PLUGINS or CONTENT. Paths come from directory entries, never from page text. Page-derived strings (`docs/agents/x.md`) are only compared with `includes` against SKILL text, never used as a filesystem path.
- Execution of page content: none. No eval, child_process, dynamic import or fetch in the new code. The only file writes in the tests go to scratch copies (`scratch()` temp dirs); the real plugins tree is copied before it is edited.
- Dependencies: no manifest or lockfile changed (npm audit has nothing new to audit); only node:fs and node:path are imported.
- Secrets and sensitive data: none in the diff. Home path check (`git log -S"$HOME/"` over work/ and `git grep "$HOME/" HEAD` over tests, docs/requirements, contracts, work): no hits. work/ files are named NN-result-<role>.md or 00-lead-state.md.
- Changed paths against the item's list (paths.sh check with the contract): no off-list lines.
