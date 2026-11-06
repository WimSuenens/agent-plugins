# Result: devops — 49
Status: done
Progress:
  Done: runbook entry for 1.1.0; demo script; sandbox read-only check
  Next: none
Summary:
  Runbook docs/factory/release-runbook.md gains "Release 1.1.0": final fingerprints (683cfb53..., 295033f4...; re-verified with fingerprint.sh), by-hand tag steps with git ls-remote check, post-merge checks (AC-30), rollback to 1.0.0, monitoring. Cites no work/ path.
  Demo script work/49/17-demo-script.md: step 0 (start with --plugin-dir ../wt/49/plugins/factory, restart after plugin changes, verify Plugin root, release, standard) plus one step each for AC-7, 9, 10, 11, 14, 20, 25, 28 and QA's two live checks.
  Sandbox (read-only): WimSuenens/factory-sandbox private, main, holds the earlier calibration content; issues #1 (map) and #2 (slice) closed, PR #3 merged; Project #10 exists with 1 item (issue #2), has Factory status field. Nothing created or changed there.
  The PR number is a <PR> placeholder in the runbook; the Lead fills it at merge.
Artifacts: docs/factory/release-runbook.md; work/49/17-demo-script.md
Decisions: PR number left as <PR> placeholder / fixed number rejected (not known yet) / trivial to edit
Open questions: seeding the sandbox needs new issues; the person/Lead should approve that list when seeding.
