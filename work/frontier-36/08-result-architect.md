# Result: architect — 36
Status: done
Progress:
  Done: result started (3928a27); ADR 0012 and CONTEXT.md terms (1601c99)
  Next: none
Summary:
ADR 0012 records the person's decision on #36 (option A plus the three additions), citing
https://github.com/WimSuenens/agent-plugins/issues/36#issuecomment-6641533963 and the #35 findings.
It covers: semver in plugins/factory/.claude-plugin/plugin.json only, first 1.0.0, bump levels, factory-v<semver> tags,
baseline reset on major/minor; the standard fingerprint over the four standard-work paths plus hooks/ and scripts/;
the poka-yoke on PRs without a bump; this run frozen on 9147301f75c3 as "Calibration (pre-baseline)", its
machine-wide reach, the item-start sha check with an andon, and an urgent fix ending the calibration.
Rejected B, C and "semver plus sha in each record" (not observable). Provisional until the first item on 1.0.0;
the freeze is locked.
CONTEXT.md gains Release, Standard fingerprint, Baseline, Calibration.
Artifacts:
  docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md
  CONTEXT.md
Decisions:
  - ADR slug "factory-releases-carry-a-semver-and-this-run-is-calibration" / rejected a shorter "plugin-version-and-baseline" / rename, minutes
  - Glossary adds "Release" besides the three named terms, since the ADR leans on it / rejected leaving "version" ambiguous between sha and semver / drop the entry, minutes
  - Freeze tagged locked, the rest provisional / rejected all-provisional (the freeze can't be undone once the run has run) / retag, minutes
  - The decided-inside two-way doors from the card carried into the ADR unchanged, as overturnable
Open questions:
  - For the slice (not a door for the person): a hooks/ or scripts/ change is a patch release yet moves the fingerprint. The slice decides whether that resets the baseline, is reclassified as minor, or is told apart (e.g. two fingerprints). Recorded in ADR 0012 under "Left to the slice"; worth attaching to the slice that builds the fingerprint step.
