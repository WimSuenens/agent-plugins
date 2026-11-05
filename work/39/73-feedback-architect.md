# Feedback: architect — 39
Source: security (final round, L14)
Findings: docs/adr/0013-*.md — low — it says #39 carries "one home path"; the checklist line finds it in two work/ files: work/39/09-brief-qa-engineer.md (line 7) and work/39/60-options-architect.md (line 8, quoting it). Name both in *Consequences*. Wording only; no history rewrite (the ADR rules it out). Also make sure no file you commit holds an absolute home path.
Commit `#39 architect: ADR 0013 names both paths`; result `work/39/74-result-architect.md`. QA commits in parallel: touch only your paths; retry on index.lock.
