# Brief: docs-writer — 49
Goal: Update the user and operational docs for factory 1.1.0 (Andon) now that QA and security pass.
Inputs: docs/requirements/49-andon.md; contracts/49-*.md; reviews/qa-49.md; reviews/security-49.md; plugins/factory/ (final text); README.md; CHANGELOG.md; docs/factory/ ; docs/agents/factory.md; tracker #49
Constraints:
- Add the ownership row `| `docs/agents/factory.md` section `## Overrides` | lead |` to this repo's docs/agents/factory.md (exact wording matters: the kind 3 rule depends on the word "section"; person confirmed this on 2026-11-05). Do not create an `## Overrides` section there.
- CHANGELOG 1.1.0 entry (what the Andon adds, the known limits from security-49: S1 residual with one git identity, N1, N2; the fence stays seven items with question E; hansei schema v3; five wait kinds). README and docs/factory/reference.md rows for the new contracts.
- Do not touch plugins/, contracts/, tests/ or reviews/. Do not describe features the plugin does not have. No absolute home paths. No project data. The release-runbook entry is devops's.
- The two named QA skips (docs-factory-md-overrides-row, docs-changelog-1.1.0) must turn green: run bash tests/run.sh.
Output: edits to the paths above; result in work/49/16-result-docs-writer.md
Done: user docs, operational docs and changelog match the shipped behaviour; tests/run.sh exits 0 with those skips gone.
