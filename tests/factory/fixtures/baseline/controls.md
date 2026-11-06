# Controls for the #57 baseline and A3 replay (written before any fixture or replay)

Rules under test: `plugins/factory/references/baseline.md` sections 3 to 8 (AC-2 to AC-6) and `plugins/factory/references/a3.md` sections 4, 6, 7 (AC-11, AC-14, AC-15).
Everything here is synthetic: invented titles, values, hashes, ids and URLs on the `example.invalid` host. The real records S2 and S5 are replayed
by hand from a scratch file outside the repository; their expected values are the ones the contract and the requirement already print (`expected-real.tsv`).

## The synthetic stand-in of S5 and its controls

`X5` (item #101, hansei v3, `series: release`, `plugin: factory 1.1.0`, `active overrides: none`): lead time total 47m, agent working 30m, waiting for the person 9m,
limits 0m, stalled 0m, interrupted 0m, andon 8m; first-pass yield qa and security `pass first time`, acceptance demo `not captured (no demo held; approval without outcome noted)`;
rework qa-engineer 2, security-reviewer 1, the rest 0, overturned 0; tokens: lead 5000100 / 150000, product-owner 100000 / 20000, architect 120000 / 30000, developer 90000 / 26000,
qa-engineer 400000 / 45000, security-reviewer 200000 / 28000, devops `n/a (did not run)`, docs-writer 700000 / 41000; touches approvals 1, other 4, the rest 0; doors two lines, both `confirmed`.

| Control | Item | Change from X5 | Must do, and why |
|---|---|---|---|
| X5b | #102 | developer spend `not captured (transcript truncated by stalled)`; total 60m, agent working 43m; qa `failed first time`; security `pass first time (2 low)`; security-reviewer rework 2; docs-writer spend 700001; doors `not captured (run stopped before the resurvey)` | n = 2: medians of an even count (54m from 53.5 rounded half up, 37m from 36.5; counts and tokens keep `.5`), a not-captured token field with `k of n`, outcome counts, a doors entry that is not an item |
| X5c | #103 | `plugin: factory 1.2.0` | series `1.2`, the session's own series |
| X5d | #104 | `plugin: factory 1.1.1`, same `standard` | patch release, joins series `1.1` with X5 |
| X5e | #105 | `plugin: factory 1.1.1`, a different `standard` | excluded and named, in no section, no figure |
| X5f | #106 | `series: calibration (pre-baseline)`, `plugin: factory 9147301f75c3 (pre-release install, no semver)` | no series, listed under Calibration only |
| X2 | #107 | marker `v1` | skipped and named (`schema v1`) |
| C39, C49 | none | manual comments with no marker (ids 9110, 9111) | never returned by Find records; no figure enters any section |
| C39t | #108 | measure 1: total 22h18m, six parts `not captured (manual log, split not kept)`; the other measures `not captured (manual log)` or `n/a`-free; once `series: calibration (pre-baseline)`, once `series: release` plus `plugin: factory 1.1.0` | calibration: only in the Calibration list; release: parts read `not captured`, never `0`; total `22h18m` |

Timestamps (created_at): X2 2026-10-20, C39 2026-10-25, C49 2026-10-26, X5 2026-11-01, X5d 2026-11-02, X5e 2026-11-03, X5f 2026-11-04, X5c 2026-11-05 (all 10:00:00Z), C39t 2026-11-06.
Comment URL of item #N: `https://example.invalid/shop/issues/N#issuecomment-9N`.

## Scenarios and expectations (machine form in `expected.tsv`)

- A (AC-2, AC-5): comments X2, C39, C49, X5, X5d, X5e, X5f, X5c; the session runs 1.2.0. Current series 1.2 holds #103. History 1.1 holds #101, #104, replaced 2026-11-05 by 1.2. Calibration lists #106. Skipped #107. Excluded #105. Nothing of C39, C49.
- B (AC-2): X2 and X5; session 1.2.0. Current 1.2 reads `0 items` and every figure `not captured (no items in series)`; history 1.1 `replaced by 1.2 (first item pending)`.
- C (AC-3, n = 1): X5 alone. D (AC-3, n = 2): X5 and X5b.
- E (AC-4): the series 1.1 block written from X5 alone, and from X5 + X5f + C39t as calibration, is identical; the calibration list differs.
- F (AC-5, order of events): X5, X5d with the session on 1.1.1, then X5c arrives and the session runs 1.2.0. The figures of series 1.1 do not change; its heading moves from current to history.
- G (AC-3): C39t as `series: release`, alone, session 1.1.0.
- I, J, K, L (AC-6): series 1.2 with v4 records #11, #12 (key none), #13 (override `runner-line` from 09:00Z, a during-item), #14, #15 (`runner-line`, whole item). Overrides file on main: I `active`; J `kept 2026-11-12 for next run`; L `promote chosen 2026-11-12`; K entry removed and an A3 whose answer line reads `runner-line (experiment): drop 2026-11-12`.
- P (AC-14), Q (AC-15), R (AC-11): the A3 rules on small ledgers, in `a3-*.tsv`.

## Round 3 additions (written before the reader and the tests ran)

- S3cal (baseline.md section 1, calibration `plugin:` text): #124 `plugin: factory 91@47<b> x` + backtick + `y` and #125 `plugin: factory ` + 130 `z`, both `series: calibration (pre-baseline)`, session 1.3.0. Expected: `factory ` outside the span, the text in one code span, `@` as `(at)`, `<` as `(lt)`, backtick as `'`; #125 cut to 120 `z` then `…` inside the span. The earlier calibration expectation (X5f, scenario A) moves to the code-span form.
- Null body (Find baseline): `body: null` for an own exact-title issue reads `no-marker`, no jq error, and a later issue in the list is still printed.
- Failed lookup: a non-zero exit of Find baseline never leads to Create baseline or Edit baseline (text pins on the rule in both files).
