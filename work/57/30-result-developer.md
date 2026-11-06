# Result: developer — 57
Status: done
Abnormality: none
Progress:
  Done: round 2 edits to the Find/Create/Edit baseline bullets and baseline.md sections 1, 2, 3 (commit 37d475f)
  Next: none
Summary:
- Reproduced first: the old Find filter exits non-zero (jq error) on an empty and on a null body. The contract's total form `((.body // "") | split("\n")[0] // "" | test(...))` prints `no-marker` for both.
- Template: Find baseline uses the total filter and states the failed-lookup rule (non-zero exit: change and create nothing, tell the person). Create baseline uses the contract wording (exit 0 and no `marker` line; `no-marker` only after `create`; never after non-zero). Edit baseline names Read baseline before the marker stop; "and only when they differ" kept.
- baseline.md: section 1 gains once-per-field `unreadable <key>` text, the `…` after a 120-character cut, one code span per reason, and the calibration `plugin:` text cut/neutralised/in one span (skeleton line now `factory `<text>``); section 2 gains the failed-lookup rule and the empty/missing body = `no-marker`; section 3 item 4 points to the span rule and item 6 adds the v4 skip `(active overrides line not in its grammar)`, never key `none`.
- `bash tests/run.sh`: all pass except one pin (below). `ac1-find-baseline-empty-body-is-no-marker` is now a plain `ok`; 0 skips anywhere.
Artifacts: plugins/factory/references/baseline.md, plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md
Decisions: kept the old pinned sentences verbatim and added the new rules as extra sentences next to them (two-way, cheap to undo)
Open questions:
- A pin must move (QA's, not edited by me): `ac1-create-exception-no-marker-needs-create` in tests/factory/test_baseline_a3.sh pins the literal `create only when the person said `create`.)`, which the contract's Create wording (R2-2) replaces. New text to pin: `Run only when *Find baseline* exited 0 and printed no `marker` line; when it printed a `no-marker` line, only after the person said `create`. Never after a non-zero exit.`
- No pin yet for: null-body fixture, failed-lookup sentence, calibration `plugin:` span with `(at)` and `(lt)`, once-per-field unreadable text, v4 skip line. The text is in place for QA to pin.
- No lint command found in the repo beyond tests/run.sh. Fingerprints not computed (Lead's job).
