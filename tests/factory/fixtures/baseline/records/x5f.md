<!-- factory:hansei v3 -->
## Hansei: #106 Synthetic slice 106

- series: calibration (pre-baseline)
- plugin: factory 9147301f75c3 (pre-release install, no semver)
- standard: 3c1f5a7e9b2d4f6a8c0e1b3d5f7a9c2e4b6d8f0a1c3e5b7d9f2a4c6e8b0d1f3a
- tooling: b4d6f8a0c2e4b6d8f0a2c4e6b8d0f2a4c6e8b0d2f4a6c8e0b2d4f6a8c0e2b4d
- context: wayfinding 0000000000aa; mattpocock-skills 0.0.0
- active overrides: none
- abnormalities: none
- stage-log cross-check: largest gap 2m (Build: synthetic)

### Measures

1. lead time: total 47m; agent working 30m; waiting for the person 9m; waiting on limits 0m; stalled 0m; interrupted 0m; andon 8m
2. first-pass yield: qa pass first time; security pass first time; acceptance demo not captured (no demo held; approval without outcome noted)
3. rework: feedback briefs product-owner 0, architect 0, developer 0, qa-engineer 2, security-reviewer 1, devops 0, docs-writer 0; overturned two-way decisions 0
4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)
5. tokens:
   - lead: spend 5000100 (input 100, cache write 50000, cache read 4900000, output 50000); peak context 150000
   - product-owner: spend 100000 (input 10, cache write 20000, cache read 70000, output 9990); peak context 20000
   - architect: spend 120000 (input 10, cache write 30000, cache read 80000, output 9990); peak context 30000
   - developer: spend 90000 (input 10, cache write 25000, cache read 55000, output 9990); peak context 26000
   - qa-engineer: spend 400000 (input 30, cache write 70000, cache read 320000, output 9970); peak context 45000
   - security-reviewer: spend 200000 (input 20, cache write 40000, cache read 150000, output 9980); peak context 28000
   - devops: spend n/a (did not run); peak context n/a (did not run)
   - docs-writer: spend 700000 (input 200, cache write 40000, cache read 650000, output 9800); peak context 41000
6. person's touches: decision cards 0; demos 0; approvals 1; overturns 0; other 4
7. doors:
   - Synthetic constraint one: confirmed
   - Synthetic constraint two: confirmed
