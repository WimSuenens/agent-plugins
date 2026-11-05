# Result: qa-engineer — 39
Status: done
Progress:
  Done: F5 flip + I4 tests (79e191c); close-* moved to the one-call close, dump-dir/nested-repo/split-call cases (dac4bc2); section 9 tests and docs F1 skips (d93c152); home-style path dropped from the I4 fixture (95bbf40); final verdict (2a820d4)
  Next: none
Summary: Verdict pass on the final build (plugin files as of 0762ef2; unchanged at HEAD). Suite 616 passed, 2 skipped (F1), 0 failed; same in a clean git-archive export (fingerprint skips worked-example-84f282e there). check-bump exit 0.
  Close commands are extracted from hansei.md and run verbatim as ONE bash -c in scratch repos: the 03-dump/ dir is not staged and is removed; a nested repo stops the chain (rc 1, HEAD unchanged, git rm staged, nested repo kept); step 6.2 run alone with w unset stops on ${w:?} and touches nothing.
  F5 flipped to interrupted (plus rotated-head and after-gap cases). I4: non-matching error values (uppercase, digits, space, tab/newline, path+token, empty, object) read api-error:other.
  Section 9: path-rule text and placement in protocol.md, SKILL step-4 pointer, security-reviewer checklist line (its git log -S command run verbatim with a fake HOME), --merge reason clause.
  Mutation-checked every new rule on plugin copies; all went red.
  AC-17: pass, re-confirmed on the real demo transcripts (demo-replay-* and require-end-demo-* run, not skipped). No re-run demanded.
  New finding F1 (low, docs-writer): docs/agents/issue-tracker.md Merge PR lacks the --merge reason clause, and CHANGELOG.md line 71 still says "The merge style is open (#48)" (contract 39-standard-changes section 8). Does not block; fix before merge.
  L13: reviews/qa-39.md lines 199/205 rewritten with ../wt/39/plugins/factory and ~/; the I4 fixture no longer holds a home-style absolute path; no QA file at HEAD holds one (earlier review versions in history still do).
Fingerprint at HEAD: release 1.0.0; standard 4ca583cdaaea68bc93fecce4d6a2c07800829c2d858e03e9dd87756dbe2652fc; tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5
Artifacts: reviews/qa-39.md, tests/factory/test_standard_text.sh, tests/factory/test_cut_offs.sh
Decisions:
- F1 (docs) as low / non-blocking with named skips / rejected: block the release on docs outside plugins/ / undo: flip the verdict in reviews/qa-39.md.
- Round-5 detail in reviews/qa-39.md condensed to a pointer (git show bf41112) / rejected: keep the full round-5 suite log / undo: restore from bf41112.
- Human-only plugin-dir path written as ../wt/39/plugins/factory with the ~/ form / rejected: $HOME form / undo: reword.
Open questions: none
