# Result: qa-engineer — 60
Status: done
Progress:
  Done: pins moved to v5 and 1.3.0 with v4 fixtures kept; v5 baseline fixtures and replay; hand-derived sample rows committed before the readers; tests T1 to T13 in tests/factory/test_gemba.sh; mutation check; verdict in reviews/qa-60.md (commits "#60 qa-engineer: ...").
  Next: none (a re-run only if the lead has the developer change the text for F1 to F4; the fingerprints then move)
Summary: Verdict pass. tests/run.sh ALL PASSED, 1809 checks, 6 skips (each names a finding or the missing changelog entry). Every AC has a test; no human-only criterion.
  Independent sample rows: W12 row 2, C49 row 8 (both equal the PO's cross-check), L57 row 10 (13 eligible, 57 mod 13 = 5).
  Fingerprints at the tested text: standard fa204f845da2d8e6e7dddbfa85c5fcdd3165b9f143b5ef74cf742dc45744648c, tooling 295033f4e6c6fcc69a2ceb6caf71968c5cc3fb233a92f6bd074fffaff2423ff5 (tooling equal to 1.2.0). check-bump passes (minor, 1.2.0 -> 1.3.0).
  Findings, all low or info: F1 garbled sentence in hansei.md "Which versions"; F2 commands print 30027 bytes and glue m to a cut line; F3 git log format has no committer time for the window; F4 unreadable transcript invisible in the view; F5 no records: form for v3 with v5; F6 ordinal brief rule shifts after a row with no brief (L57 rows 17, 19).
  Unverified list for the docs-writer's 1.3.0 entry: reviews/qa-60.md, last section (the requirement's five, plus a fresh-reader run, a live close at 8.3a, tuning of the numbers, the first mixed v4/v5 baseline).
Artifacts: reviews/qa-60.md; tests/factory/test_gemba.sh, gemba_pick.py, gemba_pick.awk, gemba_line.py, gemba_transcript.py, fixtures/gemba/, baseline_replay.py, fixtures/baseline/ (v5 records and scenarios P Q R R2 R3 S T), test_baseline_replay.sh, and the moved pins in test_standard_text.sh, test_andon_text.sh, test_baseline_a3.sh, test_fingerprint.sh
Decisions:
  - ac26-the-one-exception renamed ac26-no-path-outside-the-list and expects an empty list (the #57 setup template exception is merged) / rejected keeping the old expectation / one line
  - records: line replay writes every schema the series holds in ascending order (v3 and v5 gets its own form) / rejected leaving v3 and v5 unhandled / one line
  - home-path search needs a name segment after the home prefix, so a sentence that names the bare prefix is info, not a failure / rejected a bare-prefix search (it flags reviews/security-60.md) / one pattern
  - fresh-reader check 1 is two programmatic readers (Python and awk), check 2 permuted columns; no language-model reader was available / rejected claiming a fresh-agent run / n/a
Open questions: none
