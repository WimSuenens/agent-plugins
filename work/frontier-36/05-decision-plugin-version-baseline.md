## Decision: How do we label factory versions on every measurement, and do this run's numbers count as agent-plugins' starting baseline?

**Why now:** every item's measurement (its hansei record, a fixed-format comment posted on the slice ticket when the item closes) carries a version label from the first item on. The baseline (the project's reference numbers that later changes are compared with) resets when that label changes. Every slice on map #34 waits for this answer. And a label that is too coarse or wrong can't be fixed afterwards: the standard text an item ran on is gone, and the item can't be re-run on it.

**Two facts behind all three options:**
- This session's Lead runs factory install `9147301f75c3`. Today the factory has no version number, so its "version" is the agent-plugins commit id at fetch time. Every push, even a docs-only one, counts as a new factory version.
- This run changes the factory it runs on. Its slices write the very standard (the plugin text the roles follow) that the measurements are about.

**Same in all options:** every record also carries a **standard fingerprint** (a checksum over the four standard-work files: `skills/run/SKILL.md`, `references/protocol.md`, `agents/*.md`, `references/decision-card.md`), which the Lead computes at run start. It shows whether two items really ran on the same text.

### Option A: Give the factory release numbers; this run is a trial measurement that doesn't count
- **For users:** you read versions like "1.2.0 → 1.3.0" on every record and card, and each improvement is one visible release. Other projects using the factory get changes only when you release, never from an unrelated push. This run's numbers appear under "Calibration (pre-baseline)": they show what the numbers look like and how long capturing them takes, but they are never used as a "before". The real baseline starts with the first item run on release 1.0.0, the first one with the hansei standard in it.
- **Cost and time:** about half a day to a day of build work inside the slices: the version line, a git tag per release, a bump check in the developer's Done plus a qa line, and the fingerprint step in `run/SKILL.md` (estimate, see open question). After that, about a minute per standard change to bump the version. **The cost you carry during this run:** you must not run `/plugin marketplace update` or `/reload-plugins` until this run's last item closes. So you can't try out what each slice merged until the run ends.
- **Undoing it later:** counting this run as the baseline after all (switching to B) means renaming one section of the baseline issue, a few minutes, because the data is identical. Dropping release numbers (switching to C) means deleting one line in `plugin.json`, under an hour, and old records stay valid because each release tag points to an exact commit. The freeze can't be undone afterwards, but all it costs is that you try the new standard one run later. No data is lost.
- *Technical:* `"version"` goes in `plugins/factory/.claude-plugin/plugin.json` only, not in the marketplace entry. Major = message formats or protocol break; minor = any change to standard work; patch = everything else under `plugins/factory/`. The baseline resets on major or minor. If the fingerprint changes under the same version, a bump was forgotten. The Lead raises that as an abnormality and never starts a new baseline silently. Repair: one patch release plus re-labelling the affected records, about an hour.

### Option B: Same release numbers; this run counts as the "before Lean" baseline
- **For users:** the same as A, plus a before/after for the Lean change itself. This run is the only chance to measure the factory before Lean replaces it. But this run's numbers come from the Lead's hand-kept stage log, and later numbers come from hansei records. Some measures will read "not comparable" instead of showing a difference: tokens (peak context against total spend) and the person's touches (counted by hand). And this baseline holds for one run only.
- **Cost and time:** the same as A, including the freeze: no `/plugin marketplace update` or `/reload-plugins` until this run's last item closes.
- **Undoing it later:** switching to A means renaming the section, a few minutes. Switching to C is the same as from A, under an hour. The freeze is as in A.
- *Technical:* this run's items are labelled `factory 9147301f75c3` (commit id only, before release numbers) plus the fingerprint. The baseline resets at the first release and is kept as history.

### Option C: Keep today's automatic commit ids, with no release step; this run isn't frozen
- **For users:** labels stay 12- and 64-character codes ("9147301f75c3 vs 5a136f2eaa0a"), which you can't read on a card. There's nothing to remember at release time. You may update and reload between items to try out what each slice merged. But almost every item in this run changes the standard, so most "baselines" hold one item, and later experiments have hardly anything to compare against. Other projects pull whatever agent-plugins holds at the time, including a half-finished series of standard changes.
- **Cost and time:** a few hours of build work (the fingerprint step only). No release practice and no freeze.
- **Undoing it later:** adding release numbers later (switching to A) takes under an hour: one line plus tagging from then on. Old records stay valid. **What can't be undone:** this run's items ran on a mix of standards, and their numbers can never be re-collected on one frozen version. A clean first baseline then waits for the next run.
- *Technical:* records carry `plugin: factory <sha>` (the last segment of `${CLAUDE_PLUGIN_ROOT}`) plus the fingerprint. The baseline resets when the fingerprint changes, not the sha, so docs-only or `toolkit` pushes don't reset it.

**Recommendation:** A, because it is the only option that keeps both doors open. You get readable versions and a clean, frozen run, and turning the calibration into a "before" later (B) takes one rename. The freeze is the part you can't get back, and C gives it up for good. The architect leans the same way.

**If we're wrong:** if you do want the Lean before/after, rename the section and mark the incomparable measures, a few minutes. If the bump discipline turns out to be a burden, delete the version line, under an hour. If waiting until the run ends to try the new standard turns out to cost too much, the next run can run unfrozen, but this run's items stay frozen.

**Decided inside, overturnable** (the architect's two-way doors; not part of the choice above):
- The first release is `1.0.0`, not `0.x`, because the factory is already in use.
- Bump levels as in A, and the baseline resets on major or minor only.
- Tag format `factory-v<semver>`.
- The fingerprint covers the four standard-work paths from map decision "Standard work" (sha256 over the files in sorted order) and moves with that decision.
- Dependency versions (`wayfinding`) are recorded as context, not as reset triggers. Trigger to revisit: a baseline shift that coincides with a wayfinding update and no factory bump.

**Want to dig deeper?** Reply with a number:
1. **Question me** — `/grilling` asks you questions until your own answer is clear.
2. **Ask me** — I explain with an example or comparison until it is clear.
3. **Look it up** — `/research` writes a sourced report on the options. (#35 already covers how versions and updates work.)
4. **Show me** — `/prototype` builds a throwaway version you can look at or click through.
