# Result: devops — 156
Status: done
Abnormality: none
Progress:
  Done: .github/workflows/site.yml written to contract 156-deploy-workflow; committed.
  Next: none for this task; after the merge, watch the first run on main (AC-27).
Summary:
  Workflow `site`: triggers push to main, pull_request, workflow_dispatch with paths apps/site/**, plugins/**, the workflow file. Top-level permissions contents: read; deploy job adds pages: write and id-token: write only. Build job (ubuntu-24.04, working dir apps/site): checkout, setup-node 22 with npm cache on the lockfile, npm ci, playwright chromium, npm test, npm run build with SITE_BASE=/agent-plugins, upload artifact (not on pull requests). Deploy: needs build, only off pull requests and on refs/heads/main, environment github-pages, actions/deploy-pages.
  Concurrency: group site-<ref>, cancel-in-progress true only for pull_request events.
  Pins (sha looked up from each action's own repo, latest release): checkout v7.0.1, setup-node v7.1.0, upload-pages-artifact v5.0.0, deploy-pages v5.0.1.
  `node --test tests/site/workflow.test.mjs`: 6 pass, 1 skipped (actionlint binary not installed here, so actionlint has NOT run on the file), 1 FAIL: "every action is pinned" asserts `uses.length >= 5`, but the contract has exactly four actions (checkout, setup-node, upload-pages-artifact, deploy-pages). Not fixable on my side without adding a needless fifth action; the test threshold looks like a QA error (should be >= 4). Needs QA to correct.
  Only the first run on main can prove (AC-27): that the github-pages environment accepts main; that Playwright install and the a11y check run on the runner; that the real plugins/ build passes (it fails today on the two invalid-YAML SKILL.md files, question 05); that the artifact deploys; that both Home URLs and the Reference URL return 200, Reference count equals plugins/*/skills/*/SKILL.md, and the stylesheet returns 200 under /agent-plugins; that actionlint is clean in a real environment.
Artifacts: .github/workflows/site.yml
Decisions: cancel-in-progress as one expression on event_name / rejected two separate concurrency groups / cost to undo: one line
  Latest action releases chosen (major versions newer than obeya-image.yml's checkout v4.2.2) / rejected matching v4 / cost to undo: change sha and comment
Open questions: QA to fix the `uses.length >= 5` threshold in tests/site/workflow.test.mjs; actionlint to be run where installed.
Missing: none
