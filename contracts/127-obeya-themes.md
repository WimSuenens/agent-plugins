# Contract 127 — Obeya themes

Issue [#127](https://github.com/WimSuenens/agent-plugins/issues/127) · Spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121) · [ADR 0019](../docs/adr/0019-the-obeya-is-a-lens-and-holds-no-truth.md)

Paths:
- apps/obeya/app/
- apps/obeya/shared/view.ts
- apps/obeya/test/themes.test.mjs

The page is a layer over the read model ([contract 126](126-obeya-read-model.md)). The API seam is unchanged by this slice.

## 1. A theme only presents

A theme is a folder `app/themes/<id>/` with an `index.vue` (plus any styles). It receives one prop, `view` (the `PageView` in `shared/view.ts`), and renders it. A theme **may not fetch, compute or reshape data**: no `useFetch`, `useAsyncData`, `$fetch` or `fetch` in a theme folder. The test scans every theme for these. Shared components (for example `ParseFailureCard`) are auto-imported and take read-model objects.

Adding a theme is dropping in a folder. The data layer, the switcher and the registry do not change.

## 2. Choosing a theme

- The choice is kept in the cookie `obeya-theme` (one year, `SameSite=Lax`). The server reads it and renders that theme, so a reload shows no flash of another theme.
- A missing or unknown value falls back to `DEFAULT_THEME` in `app/themes/config.ts` (one line to change), and then to `base`.
- The switcher is a group of buttons with `aria-pressed`, reachable and operable by keyboard, with a polite live region announcing `Theme: <name>`.

## 3. Shared page behaviour

- The page re-reads the read model every `OBEYA_REFRESH_SECONDS` seconds (default 15) and shows the time of the last good refresh (UTC).
- A failed read shows an `role="alert"` banner with the error and the last good time; the last good data stays on screen.
- The base theme shows the project header, the read-only lens badge with the bind address, the "needs you" slot first, and the parse-failure card (path, reason, provenance chip).
