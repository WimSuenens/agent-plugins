# Result: qa-engineer — 39
Status: done
Progress:
  Done: script tests (9f5622f); standard text tests and runner (476f62a); verdict and contract-example test (818e300); result (this commit)
  Next: re-verify F1 once the developer fixes it (the ac8-no-pr-without-check skip becomes a pass), then re-run the suite
Summary:
  Verdict: block, on F1 (AC-8). The frontier round's "Open one PR from frontier/<map>" (run/SKILL.md step 3) opens a PR without the bump check, which AC-8 names as its contradiction. Fix is one line.
  All other branch-checkable ACs pass (AC-1–6, 8 script side, 10, 11, 13–16, 18–20 text). The contract worked examples reproduce, and the hansei example adds up.
  Suite: bash tests/run.sh, 248 passed, 3 skipped (F1, F2, F3 as named skips), 0 failed, in a clean worktree on /bin/bash 3.2. The developer's three fixture tests are adopted and extended into tests/factory/.
  F2 (minor): fingerprint.sh exits 0 with an empty-content hash when a standard file is unreadable. F3 (minor): "version": "" gives a pre-release label, not exit 2. Neither blocks.
Artifacts:
  reviews/qa-39.md
  tests/run.sh, tests/factory/lib.sh, test_fingerprint.sh, test_check_bump.sh, test_token_spend.sh, test_standard_text.sh
Decisions:
  - F1 rated major/blocking because AC-8 says literally that any PR-opening instruction without the check contradicts it / rejected: non-blocking because frontier PRs carry only ADRs / cost to undo: lead can overturn; the fix is one line either way.
  - Known defects kept as named skips so the suite stays green while the verdict blocks / rejected: red tests / cost: none.
  - Text criteria tested by grepping fixed phrases of the current wording; a rewording of those lines needs the test updated / rejected: free-text judgement only / cost: minutes per rewording.
  - Human-only list run after F1 is fixed, since the fix moves the standard fingerprint the demo checks.
Open questions: none
