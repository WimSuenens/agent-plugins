<!-- factory:hansei v5 -->
## Hansei: #188 Wiki shell: navigation tree, contents and the first hand-written page, in English and Dutch

- series: release
- plugin: factory 2.12.2
- standard: 14cb8e842c591bfd3cea6c914b228ef4280389b4f0a8d31d787910e535152f1a
- tooling: bb3846aba3d5a84eb0993c5888e697b0e1ac16b241822902dba7b7426327eaaf
- context: wayfinding bb9268f0245b; mattpocock-skills 1.3.1
- active overrides: none
- abnormalities: none
- stage-log cross-check: largest gap 6m (Requirement: last product-owner commit 23:28Z after logged end 23:22Z)
- gemba: row 2 Contracts and ADRs (architect); read transcript 9414 chars; found nothing (4 Done items and 3 constraints checked); changes nothing

### Measures

1. lead time: total 23h34m; agent working 59m; waiting for the person 22h35m; waiting on limits 0m; stalled 0m; interrupted 0m; andon 0m
   - flow efficiency: 4%
   - per stage: Requirement 2m / 0m; Contracts and ADRs 6m / 1349m; Tests 24m / 0m; Build 13m / 0m; QA 6m / 0m; Security 0m / 0m; Documentation 6m / 0m; Merge approval 2m / 6m
2. first-pass yield: qa pass first time; security pass first time (1 low); acceptance demo pass first time
3. rework: feedback briefs product-owner 0, architect 2, developer 1, qa-engineer 1, security-reviewer 0, devops 0, docs-writer 0; overturned two-way decisions 0
4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)
5. tokens:
   - lead: spend 25489111 (input 212, cache write 201118, cache read 25228806, output 58975); peak context 508261
   - product-owner: spend 514603 (input 28, cache write 100012, cache read 399377, output 15186); peak context 54611
   - architect: spend 1447173 (input 66, cache write 151711, cache read 1248961, output 46435); peak context 89491
   - developer: spend 4690384 (input 102, cache write 169033, cache read 4471018, output 50231); peak context 152149
   - qa-engineer: spend 6511866 (input 130, cache write 268779, cache read 6135726, output 107231); peak context 197431
   - security-reviewer: spend 226922 (input 16, cache write 38186, cache read 183261, output 5459); peak context 38857
   - devops: spend n/a (did not run); peak context n/a (did not run)
   - docs-writer: spend 2099377 (input 64, cache write 94489, cache read 1971301, output 33523); peak context 95445
6. person's touches: decision cards 0; demos 1; approvals 1; overturns 0; other 2
7. doors:
   - The editorial wiki look with the switcher in the top bar (ADR 0022): confirmed
   - Page slugs and navigation structure (Deferred, fired by the first narrative page): confirmed
   - Generated reference content is the source of truth: confirmed
   - English at the root, Dutch at `/nl/`, remembered switcher: confirmed
   - Translation workflow beyond the Home page (Deferred, fired by the second Dutch page): confirmed
   - Accessibility check in the build: confirmed


