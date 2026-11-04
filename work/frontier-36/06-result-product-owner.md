# Result: product-owner — 36
Status: needs-decision
Progress:
  Done: inputs read; card written at work/frontier-36/05-decision-plugin-version-baseline.md; committed "#36 product-owner: decision card on plugin version and baseline"
  Next: none. Waiting on the person's choice; after it, the architect writes the ADR from the lead's ticket comment.
Summary:
  Decision card for #36 at the technical level, with the architect's three options A/B/C.
  A: release numbers (semver) plus fingerprint; this run is frozen and recorded as "Calibration (pre-baseline)".
  B: same as A, but this run counts as the "before Lean" baseline (some measures read "not comparable").
  C: commit ids stay the identity; no freeze; every standard change resets the baseline.
  The freeze cost is spelled out in A and B: the person must not run `/plugin marketplace update` or `/reload-plugins` until this run's last item closes (install 9147301f75c3).
  Recommendation is A. It matches the architect's leaning, because the freeze is the only part that can't be recovered and A→B is a rename.
  "Question me" (/grilling) is listed first under dig deeper, as the brief asked. The architect's sub-decisions are listed once, as "decided inside, overturnable".
Artifacts: work/frontier-36/05-decision-plugin-version-baseline.md
Decisions:
  - Card leads with "Question me" and reorders the remaining dig-deeper options / rejected template order / undo: reorder lines, minutes.
  - "Same in all options" block for the fingerprint, above the options / rejected repeating it per option / undo: minutes.
Open questions:
  - architect: confirm the day estimates on the card (A/B build about half a day to a day; C a few hours; undo A→C under an hour; forgotten-bump repair about an hour). I converted these from the options file's qualitative undo costs.
  - architect: does a Claude Code restart without an update keep the Lead on 9147301f75c3? #35 left unexplained why a second cache dir (5a136f2eaa0a) appeared mid-session. If a restart can switch versions, the freeze rule should also name restarts. The card currently names only update and reload.
Missing: none
Decision card: work/frontier-36/05-decision-plugin-version-baseline.md
