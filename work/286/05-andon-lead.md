---
andon: A2
item: 286
owner: architect
status: resolved
reason: contract 286-a3-v4-and-runs section 3 asserts an AC-C2 equality the existing out-of-order fixture breaks
since: 2026-11-27T23:50Z
countermeasure: none; contract question routed to the architect (role task) before the Build brief
---

<!-- factory:andon v1 -->
## Andon A2: blocked-input (#286)

- kind: 1 blocked-input
- raised by: qa-engineer
- raised at: 2026-11-27T23:50Z
- seen: the contract says every v3 refusal fixture, turned v4, gives the same refused lines for the v3 keys; the suite's out-of-order fixture gives a different first out-of-order key as v4, because the four new lines sit inside the order the check walks
- where to look: contracts/286-a3-v4-and-runs.md line 94; docs/requirements/286-run-level-timing.md AC-C2; tests/factory/test_a3_v4_286.sh line 154 (named skip); the QA result on #292
- fit: n/a
- paused: qa-engineer had handed back; no agent paused
- 5 Whys:
  1. Why did the v4 fixture refuse with other lines? — the order check reports the first key out of template order over all keys, and the v4 template inserts four keys before `still uncertain` — evidence: contracts/286-a3-v4-and-runs.md line 33 (placement) and line 94 (order rule kept)
  2. Why did the contract claim equality anyway? — the equality was written from the requirement's AC-C2 sentence, which states it for every v3 refusal fixture, without the fixtures being run against the claimed rule — evidence: docs/requirements/286-run-level-timing.md line 103
  3. Why was it not run before hand-back? — the architect's Done list asks for a worked example per contract, not for a claim about every existing fixture to be checked against those fixtures — evidence: agents/architect.md, *Done*
  process item to change: a contract claim quantified over existing fixtures has no step that checks it against them before the contract is handed back
- fence check: not run: no override proposed
- countermeasure: none
- supersedes: none
- standard change proposed: the architect's Done list checks a claim over "every fixture" against the suite's fixtures (or names it unverified) before hand-back
- carried on: 2026-11-27T23:51Z
- waste: defects

## Refused drafts

none
