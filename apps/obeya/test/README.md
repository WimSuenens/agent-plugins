# Obeya test harness

`harness.mjs` is what every Obeya test builds on.

- `makeFixtureProject(name)` makes a throwaway git repository in the OS temp folder with one commit and a real worktree at `.claude/worktrees/item-1` (branch `item/1`).
- `startServer({ projects, host })` runs `bin/start.mjs` against the built app (`npm run build` first) on a free port. The stub `gh` from `tests/factory/stub-gh` is first on `PATH`, with its own `STUB_GH_DIR`. It resolves to `{ base, stop }` once the server answers, or to `{ exit: { code, output } }` if the server stops first (for example when it refuses a non-loopback address).
- Tests assert on HTTP responses only: `fetch(base + '/api/projects/<id>')` and `fetch(base + '/')`.

Run: `npm ci && npm run build && npm test` in `apps/obeya`. `bash tests/run.sh` runs the same suite through `tests/factory/test_obeya_app.sh`.

Server configuration: `OBEYA_PROJECTS` (JSON list of `{id, path}`), `OBEYA_HOST` (loopback only, default `127.0.0.1`), `OBEYA_PORT`. The container sets `OBEYA_IN_CONTAINER=1` and binds `0.0.0.0` inside; the host must publish the port on `127.0.0.1` only.

Theme tests (`themes.test.mjs`) build a temporary copy of the app with one trivial extra theme dropped in; `OBEYA_REFRESH_SECONDS` tunes the page refresh (default 15).
