# Security review: 156 (live skeleton, apps/site)

Verdict: **pass**. No critical, high or medium findings. Two info notes.

## Scope

Every changed file outside `work/156/` was reviewed: the workflow, the generator, the language script, the a11y script, the Astro sources, the manifests and the ignore file. `tests/site/*` was read for what it executes only.

## Checks

| Area | Result |
|---|---|
| `.github/workflows/site.yml` permissions | Top level `contents: read`. `pages: write` and `id-token: write` only on the `deploy` job. |
| Deploy gate | `deploy` has `if: github.event_name != 'pull_request' && github.ref == 'refs/heads/main'`. The Pages artifact upload is also skipped on pull requests. |
| Action pinning | All four actions use full 40-hex shas. Each sha exists in its repository and is the commit of the tag in its comment: checkout v7.0.1, setup-node v7.1.0, upload-pages-artifact v5.0.0, deploy-pages v5.0.1 (checked with the GitHub API). |
| Untrusted input in `run` | None. No `github.event.*`, PR title, branch name or issue text is used. `github.ref` appears only in `concurrency.group` and the `if`. The `SITE_BASE` env value is a literal. |
| Secrets | None used or referenced. No `pull_request_target`. |
| Language script (`langScript.mjs`) | Reads `localStorage["site-lang"]` and `location.pathname`; writes only that localStorage key (the value comes from a `data-lang` attribute that the site sets itself) and the `data-lang-pending` attribute. No eval, no HTML injection. `location.replace` goes only to `base + "/nl/"`, a same-site path. Storage errors are caught. |
| Generator (`skills.mjs`) | Reads only `<plugins>/<p>/skills/<s>/SKILL.md`, built from `readdir` names (dot-entries skipped), no user-supplied path. Frontmatter goes through the `yaml` parser (data only, no code), with type checks. The text is rendered as an Astro text child (`{s.description.trim()}`), which Astro escapes, so a SKILL.md text cannot add markup or script. The only `set:html` is the inline script, which is built from `base`. |
| a11y script | No outbound network. The server binds `127.0.0.1` on port 0, serves only below the dist root (decoded path, resolved, prefix-checked, 404 otherwise). The server and browser are closed in `finally`. |
| Dependencies | `npm audit` in `apps/site`: found 0 vulnerabilities (none high or critical). Direct set is astro, yaml, @axe-core/playwright, playwright. Lockfile is committed and CI uses `npm ci`. |
| `apps/site/.gitignore` | Ignores `dist/`, `.astro/`, `node_modules/`. |
| Secrets and home paths in the item | None in the added tree. No `$HOME/` hit in `work/` history (`git log -S`). Every `work/` file in the item is named `NN-<type>-<role>.md` or `00-lead-state.md`. Existing `/Users/` hits on HEAD are in older reviews and contracts, not in this item. |

## Paths check

`paths.sh check` against `contracts/156-*.md` reports off-list: `README.md` (docs-writer), `contracts/156-*.md` (architect), `docs/requirements/156-live-skeleton.md` (product-owner), `docs/agents/factory.md` (lead rows), `docs/agents/roles/developer.md` and `docs/agents/roles/docs-writer.md` (own-role knowledge files). All are protocol-allowed own-role files: info, no finding.

## Findings

None at low or above.

Info notes (no action needed):

- I1. `langScript(base)` embeds `JSON.stringify(base)` in an inline script, and `JSON.stringify` does not escape `</script>`. `base` comes from the build-time env `SITE_BASE`, which the maintainer sets, and `astro.config.mjs` checks the leading `/`. Not exploitable. A hardening would be to replace `<` with `<` and to reject `//` as a base.
- I2. The generator follows a symlinked `skills/` directory (`existsSync` follows links). The plugin tree is committed and reviewed, so this is not exploitable.

## Re-verify

Not needed: no finding to fix.
