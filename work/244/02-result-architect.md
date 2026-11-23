# Result: architect — 244
Status: done
Abnormality: none
Progress:
  Done: contract contracts/244-inline-names-check.md written; both open questions decided.
  Next: none
Summary: Contract 244 defines the seams in tests/site/names.mjs (backtickedTokens, inlineSpans, fencedBlocks, agentPathsIn, skillText, unknownAgentPaths, unknownNames, handWrittenPages, pageFaults) and the tests in tests/site/names.test.mjs. Q1: tokens come from the raw Markdown (CommonMark span rules; edge cases tabulated), not rendered HTML. Q2: own test file; the three AC-19 helpers move byte-identical to names.mjs and getting-started.test.mjs re-exports them, so its assertions stay unchanged. I searched both pages: no drift, so no page edit is expected. No ADR, no one-way door.
Artifacts: contracts/244-inline-names-check.md
Decisions: token source raw Markdown / rejected rendered HTML / cost to undo: swap tokenizer, ~1h; check in names.test.mjs with rules in names.mjs / rejected beside AC-19 (it builds the site and starts a browser) / cost to undo: move three functions back; path regex single-segment `docs/agents/<name>.md` with a left boundary / rejected nested paths / one pattern.
Open questions: none
Missing: none
