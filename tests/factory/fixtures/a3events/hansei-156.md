<!-- factory:hansei v5 -->
## Hansei: #156 Live skeleton: bilingual home and generated skills index on GitHub Pages

- series: release
- plugin: factory 2.12.2
- standard: 14cb8e842c591bfd3cea6c914b228ef4280389b4f0a8d31d787910e535152f1a
- tooling: bb3846aba3d5a84eb0993c5888e697b0e1ac16b241822902dba7b7426327eaaf
- context: wayfinding bb9268f0245b; mattpocock-skills 1.3.1
- active overrides: none
- abnormalities: none
- stage-log cross-check: largest gap 27m (Tests: last qa-engineer commit 21:54Z after logged end 21:27Z)
- gemba: row 6 Build (round 2) (developer); read transcript 4046 chars; found nothing (4 Done items and 3 constraints checked); changes nothing

### Measures

1. lead time: total 1h54m; agent working 1h48m; waiting for the person 6m; waiting on limits 0m; stalled 0m; interrupted 0m; andon 0m
   - flow efficiency: 95%
   - per stage: Requirement 2m / 0m; Contracts and ADRs 4m / 0m; Tests 7m / 0m; Build 69m / 0m; Environment 2m / 0m; Documentation 21m / 0m; QA 3m / 0m; Security 0m / 0m; Merge approval 0m / 6m
2. first-pass yield: qa pass first time (2 low); security pass first time (2 low); acceptance demo pass first time
3. rework: feedback briefs product-owner 0, architect 0, developer 1, qa-engineer 0, security-reviewer 0, devops 0, docs-writer 0; overturned two-way decisions 1
4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)
5. tokens:
   - lead: spend not captured (the lead session also worked another item in this window); peak context not captured (the lead session also worked another item in this window)
   - product-owner: spend 213840 (input 14, cache write 44576, cache read 157501, output 11749); peak context 45417
   - architect: spend 927119 (input 32, cache write 77166, cache read 822837, output 27084); peak context 80640
   - developer: spend 2945793 (input 102, cache write 121488, cache read 2793270, output 30933); peak context 94594
   - qa-engineer: spend 2064571 (input 78, cache write 305056, cache read 1702496, output 56941); peak context 93845
   - security-reviewer: spend 165397 (input 14, cache write 32827, cache read 127040, output 5516); peak context 33771
   - devops: spend 190196 (input 16, cache write 29019, cache read 156277, output 4884); peak context 30224
   - docs-writer: spend 1665264 (input 54, cache write 87582, cache read 1546260, output 31368); peak context 89259
6. person's touches: decision cards 0; demos 1; approvals 1; overturns 0; other 1
7. doors:
   - Astro in `apps/site/` is the stack: confirmed
   - GitHub Pages at the default URL, site served under `/agent-plugins/`: confirmed
   - English at the root, Dutch at `/nl/`, remembered switcher: confirmed
   - What the plugin files give the reference generator: contradicted
   - Generated reference content is the source of truth: confirmed
   - The editorial wiki look with the switcher in the top bar (ADR 0022): confirmed



