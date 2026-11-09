<!-- factory:a3 v2 -->
## A3: run #3 Export a report

- run: #3 — closed
- series and release: 2.3; factory 2.3.0; standard 683cfb53180122ef3307b5d00d04adf37c141076985d212941925d4a908429c2; tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5
- problem: the developer's brief did not name the project's test runner, so the developer came back for it
- evidence: andon A1 in #6 (https://github.com/example/shop/issues/6#issuecomment-111), 1 of 4 items; the developer's rework was 1 in #5 and #6 and 0 in #7 and #8
- waste: defects 2, waiting 1; untagged 1
- gemba (targeted): item #6 row 3 Build (developer); read transcript 18342 chars; found difference: Done item 2 has no trace of the test command in the brief, process object: the brief
- 5 whys:
  1. Why did the developer come back for the runner? — the brief named no test command — evidence: gemba Build #6 row 3
  2. Why did the brief name none? — the Constraints of a developer brief have no line for it — evidence: plugins/factory/skills/run/SKILL.md step 6, briefs
  process item to change: the developer brief template has no line for the test runner
- process item to change: the developer brief template has no line for the test runner
- countermeasure: qa-brief-names-runner (started 2026-11-09)
- measure targeted: 3 developer — direction down
- before: 1 (2 of 2; items #5, #6; factory 2.3.0)
- after: 0 (2 of 2; items #7, #8; factory 2.3.0)
- change: -1 — toward the intended direction (down)
- target: 0 — reached
- items counted: before #5, #6; during none; after #7, #8
- still uncertain: sample: before 2 of 2 items, after 2 of 2 items; other overrides in force during the after-items: none; kind of work: all four items were small shell-script slices, before and after alike; not captured in the readings: none; no significance is claimed: these are counts with item numbers, what moved and not that it is proven
- other problems seen: none seen
- other overrides: none
- standard changes proposed: plugin change: add a "test runner" line to the developer brief template
- baseline: https://github.com/example/shop/issues/4
- answer: qa-brief-names-runner (experiment): promote 2026-11-12
