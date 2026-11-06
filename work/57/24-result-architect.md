# Result: architect — 57 (feedback round 2)
Status: done
Abnormality: none
Progress:
  Done: all of items 1 to 4 in `contracts/57-baseline.md`, commit 0f1bf66.
  Next: none.
Summary:
- Item 1 (R2-1 / S4): §2.1 table row names an empty or missing body as `no-marker`; new paragraph "A failed lookup is not none found" (non-zero exit: change and create nothing, tell the person; only exit 0 with no line is the row "none at all"; the filter must be total); §2.2 *Find baseline* carries the null-safe form `((.body // "") | split("\n")[0] // "" | test(...))`.
- Item 2 (R2-3): §1 says the third place is the `plugin:` text of the calibration line (free text, no other grammar), cut at 120 with `…`, neutralised, one span; `factory `, number and link are the standard's own text. Chosen: span it (rejected: cut to semver, loses the reason a record is calibration).
- Item 3: §1 one code span per reason (R2-O1); `not captured (unreadable <key> line)` once per field, with the line's key (R2-O2); §3 item 6 a v4 record with an `active overrides` line outside the extent grammar is skipped whole and named `skipped: #<id> <url> (active overrides line not in its grammar)`, never key `none` (R2-O3). Reader's `# READING:` choices accepted as written.
- Item 4 (R2-2): §2.2 *Create baseline* wording: "Run only when *Find baseline* exited 0 and printed no `marker` line; when it printed a `no-marker` line, only after the person said `create`. Never after a non-zero exit." The template must not say "printed nothing". Also: *Edit baseline* names *Read baseline* before the marker stop.
- R2-O4 left to the product-owner.
Moved fixtures / expectations:
- Empty-body fixture: expected `10<TAB>OPEN<TAB>no-marker` (unchanged; skip becomes a plain check once the filter is fixed). Add a null-body fixture, expected `no-marker`.
- New: failed-lookup rule (non-zero exit leads to no create); text check that Create baseline no longer says "printed nothing" (QA's moved pin already passes either way, now only the new wording).
- Reader: spans per reason, per-field unreadable text, v4 bad-extent skip: expected values equal the reader's current readings, so none move. A replay that read such a record as key `none` is now wrong.
- Calibration line: the `plugin:` text is now in a code span (cut, neutralised); a fixture with `@` or `<` there expects `(at)`/`(lt)` inside backticks.
Artifacts: contracts/57-baseline.md
Decisions:
- Calibration `plugin:` text is code-spanned / rejected: cut to semver, or drop from the list / undo: edit one clause in §1.
- Failed lookup changes nothing, tells the person / rejected: retry silently, treat as none found / undo: edit one paragraph.
- Accept reader's READING choices / rejected: one span for whole list, per-line unreadable text / undo: one clause each.
Open questions: none
