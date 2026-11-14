# Result: security-reviewer — 225
Status: done
Abnormality: none
Progress:
  Done: every file under apps/site/src/ read (diff and full files); dependency audit run; paths check run.
  Next: none
Summary:
  Verdict: pass (no finding above medium; nothing blocks the merge).
  Trust boundary: the loader trusts the repo's own plugins/*/agents/*.md frontmatter (committed, reviewed content), reads only direct children of plugins/<dir>/agents, and every value reaches HTML through Astro's escaped expressions.
  - No set:html, no new client script, no new dependency (yaml ^2.9.1 already used by skills.mjs; package.json and lock untouched). The only set:html is in Base.astro (langScript), pre-existing and not in the diff.
  - Path traversal: file names come from readdir withFileTypes, isFile() only (symlinked files skipped), names starting with "." skipped; no user input in paths. The PLUGINS_DIR env override is build-time only.
  - YAML: yaml v2 parse, strict type checks on name, description, model and tools; alias bombs capped by the library default.
  - lang="en" is set on nl pages for English entries; no links are built from frontmatter (hrefs come from the page model).
  - Workflow files not touched (no .github path in the diff).
  - npm audit --omit=dev in apps/site: 0 vulnerabilities.
  - work/225/ names all follow NN-<type>-<role>.md; no home path or secret in any commit touching work/ (git log -S and git grep on HEAD both empty).
Findings:
  1. apps/site/src/lib/agents.mjs, the error "reference: no agent files found under ${pluginsDir}" — low — prints the absolute plugins path in a build error (CI log). Fix: print a repo-relative path, e.g. "under plugins/".
  2. docs/direction.md (created by the product-owner) — medium per the paths rule (off-list) — not in the item's path list; the product-owner's result flags it as a deliberate two-way step. Fix: the lead confirms it belongs to the item, or adds it to the list.
  3. One role-knowledge file of the QA role's (named in the off-list output) — medium per the paths rule (off-list) — edited under the protocol's Role knowledge rule; I did not read its content (another role's file is private). Fix: the lead confirms it is expected, or adds it to the list.
  Note: paths.sh also printed off-list for contracts/225-*.md because I passed them as the list file; they are the item's own architect contracts and the lead's usual ignore pattern covers them.
Artifacts: work/225/05-result-security-reviewer.md
Decisions: none
Open questions: none
