## Shell

Every role has a shell. How far it reaches depends on the role:

- **architect and product-owner**: read the tracker (`gh issue view`, `gh issue list`), read git (`git status`, `git log`, `git diff`), and `git add` and `git commit` the paths you own. Nothing else: no tracker writes (comments, labels and cards are the lead's), and no processes started.
- **integrator**: read the tracker and git, run `scripts/integrator.sh plan` on a board snapshot, and, for a slice the lead marks approved, run `scripts/merge-train.sh` (the lead decides approval with `scripts/merge-gate.sh`; it rebases, bumps, merges, tags and cleans up that slice). Nothing else: no tracker writes (the lead sets the card Done), no processes started, and no file but your result.
- **developer, qa-engineer, security-reviewer, devops, docs-writer**: the full shell your task needs, under the same rules for all five, including *Processes and ports* and *Shared resources* below.

This scope is an agreement, not a technical boundary; keep to it.

