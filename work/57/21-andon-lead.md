<!-- factory:andon v1 -->
## Andon A1: same finding twice (#57)

- kind: 2 same-finding-twice
- raised by: lead
- raised at: 2026-11-06T19:17Z
- seen: same-finding-twice: security-reviewer r1 S2 = security-reviewer r2 S4: the baseline lookup in the tracker template must test the marker line on every body, empty or missing included, and treat a body without the marker as no-marker
- where to look: reviews/security-57.md (round 1 S2, round 2 S4, commit abcc859), plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md (Find baseline)
- fit: n/a
- paused: no agent paused (the security reviewer had handed back; QA round 2 carries on, its brief already holds the empty-body fixture, a stop would lose its fixtures in flight)
- 5 Whys:
  1. Why did Find baseline stop on an empty body after S2 was closed? — the jq test splits `.body` without a default for a missing body, and the contract states the empty-body case in prose only — evidence: reviews/security-57.md round 2 S4; contracts/57-baseline.md section 2
  2. Why does the contract give the case in prose only? — its worked outputs for Find baseline list the marker and no-marker bodies, with no row for an empty or missing body, so the standard text had no expected output to build against — evidence: contracts/57-baseline.md section 2 table; plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md
  3. Why did no test show it before round 2? — the fixtures for the empty-body, CRLF and v2-marker cases were listed in the architect's round-1 result for QA and reached the tests only in QA's round 2 brief, after the build — evidence: work/57/14-result-architect.md; work/57/17-brief-qa-engineer.md item 1
  4. Why did the fixtures come after the build? — the stage order of a feedback round is contract text, then build, then test changes, and tests/ is not editable by the build stage, so the build runs against the old pins — evidence: work/57/16-result-developer.md (one failing check and one skip needing tests/ edits); open issue 42; skills/run/SKILL.md step 6 item 5
  5. Why does the order allow a rule change to reach the build without its fixtures? — the standard's feedback round has no step that sends the fixtures for a changed rule to QA at the same time as the contract text — evidence: skills/run/SKILL.md step 6 items 1 to 5
  process item to change: a feedback round that changes a rule sends that rule's fixtures and expected values to QA together with the contract text, before the build, so the build runs against them
- fence check: not run: no override proposed
- countermeasure: none: needs a plugin change
- supersedes: none
- standard change proposed: in the feedback round of step 6, brief QA for the changed rule's fixtures and expected values in parallel with the contract text, before the developer builds
- carried on: 2026-11-06T19:18Z
