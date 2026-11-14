<!-- factory:hansei v5 -->
## Hansei: #168 Quote two factory skill descriptions so frontmatter parses as strict YAML

- series: release
- plugin: factory 2.12.2
- standard: 14cb8e842c591bfd3cea6c914b228ef4280389b4f0a8d31d787910e535152f1a
- tooling: bb3846aba3d5a84eb0993c5888e697b0e1ac16b241822902dba7b7426327eaaf
- context: wayfinding bb9268f0245b; mattpocock-skills 1.3.1
- active overrides: none
- abnormalities: none
- stage-log cross-check: largest gap 14m (Contracts and ADRs: architect correction commit 22:07Z after logged end 21:53Z)
- gemba: row 1 Contracts and ADRs (architect); read transcript 3731 chars; found nothing (3 Done items and 4 constraints checked); changes nothing

### Measures

1. lead time: total 48m; agent working 38m; waiting for the person 10m; waiting on limits 0m; stalled 0m; interrupted 0m; andon 0m
   - flow efficiency: 79%
   - per stage: Contracts and ADRs 1m / 0m; Tests 5m / 0m; Build 20m / 0m; Documentation 4m / 0m; QA 6m / 0m; Security 2m / 0m; Merge approval 0m / 10m
2. first-pass yield: qa pass first time (2 low); security pass first time; acceptance demo n/a (did not run)
3. rework: feedback briefs product-owner 0, architect 0, developer 1, qa-engineer 0, security-reviewer 0, devops 0, docs-writer 0; overturned two-way decisions 1
4. escaped defects: not captured (tracing deferred until the first defect found in a merged item)
5. tokens:
   - lead: spend not captured (the lead session also worked another item in this window); peak context not captured (the lead session also worked another item in this window)
   - product-owner: spend n/a (did not run); peak context n/a (did not run)
   - architect: spend 464870 (input 30, cache write 79497, cache read 377159, output 8184); peak context 42322
   - developer: spend 575914 (input 56, cache write 70528, cache read 497855, output 7475); peak context 29436
   - qa-engineer: spend 813885 (input 52, cache write 76930, cache read 720703, output 16200); peak context 43712
   - security-reviewer: spend 103928 (input 10, cache write 30222, cache read 71040, output 2656); peak context 30750
   - devops: spend n/a (did not run); peak context n/a (did not run)
   - docs-writer: spend 827174 (input 42, cache write 53778, cache read 758190, output 15164); peak context 54850
6. person's touches: decision cards 0; demos 0; approvals 1; overturns 0; other 1
7. doors:
   - What the plugin files give the reference generator: contradicted


