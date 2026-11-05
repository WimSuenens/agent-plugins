# Brief: architect — 39
Goal: Record the person's merge-style decision (#48: option A) as an ADR and put its rule into the contracts, before the developer builds it.
Inputs: #48 with the card and the decision comment (`gh issue view 48 --comments`; cite the decision comment URL from `gh api repos/WimSuenens/agent-plugins/issues/48/comments --jq '.[-1].html_url'`); work/39/60-options-architect.md; contracts/39-*.md; ADR 0012.
Constraints:
- ADR `docs/adr/0013-<slug>.md`: keep `--merge`; no absolute home paths in work/ (worktree-relative or `~/`); the security checklist expects work/ in merge history; what's already public on refs/pull/<n>/head; rejected B (squash) and C (rebase-merge). Cite the decision comment, never work/.
- Contracts: add the path rule where briefs, results and the lead state are defined for this item's standard changes (contracts/39-standard-changes.md and, if the label or stage log carries paths, 39-stage-log.md), and note the security-checklist line for the security-reviewer agent file (developer's path) in the placement contract.
- Touch only your paths. QA may still be committing: retry on index.lock.
Output: ADR, contract edits; result `work/39/66-result-architect.md`. Commit `#39 architect: ADR 0013 merge style; path rule`.
