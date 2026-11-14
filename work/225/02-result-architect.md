# Result: architect — 225
Status: done
Abnormality: none
Progress:
  Done: contracts 225-agents-loader.md and 225-reference-section.md written; ADR decision: no ADR
  Next: none
Summary:
  Two contracts. Loader: lib/agents.mjs beside skills.mjs, loadAgents(pluginsDir) with PLUGINS_DIR override, strict YAML, name/description required, model and tools optional (tools string or list), zero agent files fails the build, a missing agents/ folder is skipped; faults named "reference: <plugin>/agents/<file>.md: <fault>".
  Section: three page-tree entries (reference gains title.nl and loses alsoListedIn; skills and agents with parent reference), registry keys reference/skills/agents, markup hooks (data-agent-entry, data-count, data-field, lang="en" on English plugin text in Dutch), UI keys, frozen file list for AC-9.
  Counts come from one function in registry.mjs; no typed number anywhere.
  No ADR: every decision is a two-way door (flat slugs, loader placement, duplicated frontmatter reader, error prefix, generated body counts as page content).
  Stale text listed in section 8 of the section contract: QA tests, developer tests, README lines 225/235/277/296 (outside Paths, for docs-writer via the lead), 188 contracts (architect note after build).
  Known limitation accepted: Contents.astro (frozen) shows names without lang="en" in Dutch.
Artifacts: contracts/225-agents-loader.md, contracts/225-reference-section.md
Decisions:
  - own loader module lib/agents.mjs / one generic loader / merge later, an hour
  - frontmatter reader duplicated, skills.mjs untouched / extract shared module / extract when hooks arrive
  - error prefix "reference:" for both loaders / "agents:" / one-line rename
  - counts via data-count spans filled at render, UI strings carry no number / typed templates / n/a
  - Skills at /skills/, ReferenceBody renamed SkillsBody, new ReferenceOverview / keep name / rename
  - Dutch labels Naslag, Vaardigheden, Agenten (drafts) / English / one-word edits
  - accepted the product-owner reading that generated bodies are page content (AC-9 guards shell only); no stricter seam needed
Open questions: none
