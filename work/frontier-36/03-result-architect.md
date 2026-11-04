# Result: architect — 36
Status: done
Progress:
  Done: options written (02-options-architect.md), committed as "#36 architect: options for plugin version and baseline"
  Next: none. Waiting for the person's decision; the ADR follows it.
Summary: Three coherent options, each covering both halves. A: semver in plugin.json per standard change, git tag per release, a standard fingerprint (sha256 of the standard-work files) on every record; this run is frozen and recorded as calibration (pre-baseline). B: same identity; this run frozen and counted as agent-plugins' first "before Lean" baseline. C: keep sha identity, the baseline keys on the fingerprint, this run unfrozen with per-item labels and resets. The one-way parts are the record label and the freeze. "Baseline" vs "calibration" is only a rename, provided every record carries its label. With a `version` set, the Lead can't reliably read a sha, so the fingerprint stands in for "sha alongside".
Artifacts: work/frontier-36/02-options-architect.md, work/frontier-36/03-result-architect.md
Decisions:
- First semver 1.0.0 / rejected 0.x / undo: change the string before the first release (applies if A or B)
- Bump levels major=protocol/format break, minor=standard work, patch=other; baseline resets on major/minor only / rejected: reset on any bump / undo: edit the ADR and the bump check
- Release tag `factory-v<semver>` / rejected: no tags (semver couldn't be mapped to a sha) / undo: retag
- Fingerprint scope = the four standard-work paths from map decision "Standard work" / rejected: the whole plugin directory (README edits would count) / undo: change the file list in run/SKILL.md
- Dependency versions recorded as context, not reset triggers / rejected: reset on a wayfinding change / undo: add to the reset rule; trigger: a baseline shift that coincides with a wayfinding update and no factory bump
Open questions:
- One-way door for the person (decision card): A, B or C. Leaning A. Options, undo costs and draft card lines are in 02-options-architect.md.
- For the lead: whatever is chosen, don't run `/plugin marketplace update` or `/reload-plugins` mid-run if A or B wins. The freeze is already in effect only if nothing has been updated so far. Please confirm which factory cache directory this Lead loaded (#35 saw both 9147301f75c3 and 5a136f2eaa0a in use).
Missing: none
