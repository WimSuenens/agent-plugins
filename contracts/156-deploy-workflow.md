# Contract 156 — Deploy workflow: build, check, publish to Pages

Issue [#156](https://github.com/WimSuenens/agent-plugins/issues/156) · Requirement AC-26, AC-27 · Pages source is "GitHub Actions" (ticket [#148](https://github.com/WimSuenens/agent-plugins/issues/148))

## Paths

Paths:
- .github/workflows/site.yml
- tests/site/
shared: none

Owner: devops (pipeline). The site's own commands are in the [site skeleton](156-site-skeleton.md) section 1.

## 1. Seams of `.github/workflows/site.yml`

Workflow `name: site`.

Triggers:

| Event | Filter | Effect |
|---|---|---|
| `push` | branch `main`; paths `apps/site/**`, `plugins/**`, `.github/workflows/site.yml` | build and deploy |
| `pull_request` | the same paths | build only, no deploy |
| `workflow_dispatch` | none | build and deploy (on the branch chosen; the deploy job runs only when `github.ref` is `refs/heads/main`) |

The `plugins/**` path is what makes a changed SKILL.md redeploy the generated Reference.

Permissions: top level `contents: read`. The `build` job adds nothing. The `deploy` job adds exactly `pages: write` and `id-token: write`. No other permission anywhere.

Jobs:

1. `build` (`ubuntu-24.04`), working directory `apps/site` for the steps below:
   1. `actions/checkout` (full `plugins/` is in the checkout; no worktrees exist in CI).
   2. `actions/setup-node`, Node 22, npm cache keyed on `apps/site/package-lock.json`.
   3. `npm ci`.
   4. `npx playwright install --with-deps chromium`.
   5. `npm test` (unit tests).
   6. `npm run build` with `env: SITE_BASE: /agent-plugins`. This runs `astro build` then the accessibility check; a failed check fails the step and the job.
   7. Only when `github.event_name != 'pull_request'`: `actions/upload-pages-artifact` with `path: apps/site/dist`.
2. `deploy`: `needs: build`; `if: github.event_name != 'pull_request' && github.ref == 'refs/heads/main'`; `environment: { name: github-pages, url: ${{ steps.deployment.outputs.page_url }} }`; one step `actions/deploy-pages` with `id: deployment`.

Because `deploy` needs `build`, and the check runs inside `build` step 6, a failing check stops the deploy (AC-26).

Concurrency: `group: site-${{ github.ref }}`, `cancel-in-progress: false` for pushes to `main` (a deploy in flight finishes), and a pull-request build may be cancelled by a newer one. Devops may express this as one `cancel-in-progress` expression.

Action versions are pinned by commit sha with the version in a trailing comment, as `.github/workflows/obeya-image.yml` does. `actionlint` passes with no error.

## 2. Worked example

A push to `main` that edits `plugins/wayfinding/skills/ask-me/SKILL.md`: the `site` workflow starts (path match), `build` runs steps 1 to 7, the Reference page now carries the new description, the check reports `a11y: 3 pages checked, 0 violations`, the artifact uploads, `deploy` publishes it, and `https://wimsuenens.github.io/agent-plugins/reference/` shows the new text. A pull request touching only `README.md` does not start the workflow.

## 3. Behaviour QA can test (workflow file, no run needed)

- `actionlint` on the file: exit 0.
- Parsed YAML: triggers, path filters and the `workflow_dispatch` entry as in section 1; `pull_request` has no deploy path (`deploy` is guarded as above).
- Permissions: the union of declared permissions equals `contents: read`, `pages: write`, `id-token: write`, and `pages` and `id-token` appear only on the `deploy` job.
- Order: the `npm run build` step precedes the upload step in `build`; `deploy.needs` contains `build`; the upload and deploy use `actions/upload-pages-artifact` and `actions/deploy-pages`.
- `SITE_BASE` is set to `/agent-plugins` on the build step.

## 4. Needs real infrastructure (post-merge, AC-27)

The deploy itself needs GitHub Actions and Pages on the real repository: the workflow can only be proven by its first run on `main`. Pages is already enabled with the Actions source (ticket #148), and the `github-pages` environment exists once Pages is enabled; if its branch rule rejects `main`, devops fixes that, not the contract. The decision for the lead: **devops is needed** for the workflow file and for watching the first run on `main`. After the merge, the proof is: both Home URLs and the Reference URL return 200, the Reference lists as many skills as `plugins/*/skills/*/SKILL.md`, and the stylesheet loads with 200 under the base (there is no font file).

## 5. Acceptance criteria map

AC-26 (sections 1, 3), AC-27 (sections 2, 4).
