# Brief: devops — 39
Goal: Prepare delivery of factory release 1.0.0: release readiness, the tag step, and a rollback runbook — without changing any installed plugin.
Inputs: slice #39 (`gh issue view 39 --comments`); PR for item/39 (`gh pr view item/39`); `docs/adr/0012-*.md`; `contracts/39-standard-changes.md` (*Merge PR* and tag); `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` (*Merge PR*); `.claude-plugin/marketplace.json`; `CHANGELOG.md`, `README.md`.
Constraints:
- The machine is frozen on factory install 9147301f75c3 until this run's last item closes: never run `/plugin` commands, `claude plugin install|update|marketplace update`, or `/reload-plugins`. Read-only `claude plugin validate` and `claude plugin list --json` are fine.
- Do not tag, merge or push; the Lead tags at merge on the person's approval. Do not touch `plugins/` or this repo's tracker. The acceptance demo is running on this worktree's `plugins/` right now.
- Rollback runbook: how a project goes back from 1.0.0 to the pre-release factory (what to pin or revert, what happens to hansei records already posted, what the freeze means here), and how to roll forward after a bad patch release.
Output: runbook at `docs/factory/release-runbook.md` (yours as a runbook), a delivery checklist in your result `work/39/36-result-devops.md` (validate results, the exact tag commands the Lead runs after merge, the post-merge checks for AC-7). Commit `#39 devops: release runbook for factory 1.0.0`.
Done: your role's Done list.
