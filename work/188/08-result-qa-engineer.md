# Result: qa-engineer — 188
Status: done
Abnormality: none
Progress:
  Done: helper changed (option A), control extended, suites run; committed.
  Next: none
Summary: Option A applied in tests/site/getting-started.test.mjs. `unknownCommands` now accepts an installed plugin that is listed in `.claude-plugin/marketplace.json` (new `marketplaceNames()`, the `listed` parameter) or has a folder under `plugins/`. A plugin in neither still fails (`install nosuch`), and a wrong marketplace still fails. The control test gained two cases. `mattpocock-skills@wimsuenens` passes with the real list. It fails when the list is empty and no folder exists. Page and contract are unchanged. `node --test tests/site/getting-started.test.mjs` gives 9 pass, 0 fail. Full suite (`node --test --test-concurrency=1 tests/site/*.test.mjs`) gives 178 tests, 177 pass, 0 fail, 1 skipped (actionlint not installed).
Artifacts: tests/site/getting-started.test.mjs
Decisions: helper accepts marketplace.json names / the contract keeps the prototype's install line / cost to undo: one-line revert
Open questions: none
