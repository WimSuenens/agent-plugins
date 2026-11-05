# Feedback: architect — 39
Source: docs-writer (open question 3)
Findings: docs/adr/0013-*.md cites `work/39/09-…` and `work/39/60-…`; the protocol's *Citations* rule forbids work/ paths in docs that land on main. Describe them instead as "two of item #39's message files (the QA brief and the architect's options file), in the PR's history" and cite the security review's finding (reviews/security-39.md, final round, L14) or the #39 tracker comment that reports it. Wording only. No absolute home paths.
Commit `#39 architect: ADR 0013 citations`; result `work/39/80-result-architect.md`. Devops commits in parallel; touch only your paths; retry on index.lock.
