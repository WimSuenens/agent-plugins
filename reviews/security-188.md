# Security review: 188 (wiki shell)

Verdict: pass

Scope: every changed file of origin/main...item/188 (61 files; apps/site code, content, a11y script, tests, contracts, requirement, role notes). The workflow .github/workflows/site.yml is unchanged.

## Findings

1. apps/site/src/lib/langScript.mjs (unchanged this slice, now reached from Base.astro for every page) - low (informational) - `JSON.stringify(base)` is written into an inline script with `set:html`; JSON does not escape `</script>`. `base` comes from the build-time `SITE_BASE` env var (validated only for leading and trailing slash), set by the workflow, not by a visitor. Not exploitable from the deployed page. Optional fix: also replace `<` with `<` in the serialised value.

No critical, high or medium findings.

## Checks

- Markdown injection: the two content files (en and nl getting-started.md) hold no raw HTML, no `javascript:` or `data:` links. Content is repository-authored and trusted; `layoutFaults` is a layout guard, not a security control, and is not relied on as one. The hast plugin (`rehypePage.mjs`) only sets `tabIndex` on `pre` and prefixes the base path on site-root hrefs; it rejects `//` protocol-relative links and builds no HTML from input. Link targets in bodies are validated against the page tree at build time.
- Language switcher: the stored value is only compared with `"nl"`; it is never written into the DOM or a URL. `setItem` takes values from fixed `data-lang` attributes; `location.replace` goes to `base + "/nl/"`. Storage errors are caught. Switcher hrefs come from the page tree model, not from user input.
- Components: values are rendered through Astro's escaping; no new `set:html` or `innerHTML` besides the existing langScript; the a11y script's `page.evaluate` only reads the DOM.
- Dependencies: one declared dependency added, `@astrojs/markdown-satteri` 0.4.9 (exact pin). The lockfile change is one line; the package was already resolved in the lockfile as a transitive dependency of astro (registry URL, integrity hash, MIT). `npm audit --omit=dev` in apps/site: found 0 vulnerabilities.
- Secrets and logs: grep for secret, token, password and key found none in src, scripts or the workflow; the build prints only the list of Dutch draft routes.
- Build and deploy: the astro.config.mjs hook runs only `loadPages` (reads local files, no network, no child process). No workflow change.
- work/ history: `git log -S"$HOME/"` over work/ returned no line; every file under work/ is named `NN-<type>-<role>.md` or the lead state.
- Off-path check: `paths.sh check` listed only the three contracts/188-*.md files and the developer and qa-engineer role notes as off-list; the lead named all of them as known and accepted, so none is a finding.
