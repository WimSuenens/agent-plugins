# Options: architect — 36 "Plugin version and this run's baseline"

Two linked one-way doors are combined into one card here, because the answer to one limits the answer to the other:

1. **Version identity.** What label every baseline and hansei record carries, and so when a baseline resets.
2. **This run's baseline.** How the items of this run count for agent-plugins. This run changes the factory standard it runs on.

Only coherent combinations are offered. Facts come from #35's findings comment (Q4, Q5).

## What is one-way here, and what is not

- **One-way: the label on the records.** Every hansei record and baseline written from the first item on carries it. A record with a coarse or wrong label can't be split again later. The text it ran on is gone, and the item can't be re-run on it.
- **One-way: freezing (or not) the installed version during this run.** Time passes. Items run on a mix of standards stay mixed.
- **Two-way: the `version` field itself.** Adding or removing it is one line in `plugin.json`. Its *release practice* consequence affects every project, though (see A/B).
- **Two-way: what this run's numbers are called** ("baseline" or "calibration"). The data is the same in both cases. The name can be changed later by editing the baseline issue, *as long as every record carries its version label*.

## Facts that shape the options

- No `version` today (`plugins/factory/.claude-plugin/plugin.json` and the `factory` entry in `.claude-plugin/marketplace.json` both lack one). So the factory's version = the agent-plugins HEAD sha at fetch time. Every push to the repo is a new factory "version", even a docs-only push or a change to `toolkit`. The local cache already holds four factory versions (`275b635d726c`, `5a136f2eaa0a`, `9147301f75c3`, `c2d23e2b65a8`), and the two newest have identical contents.
- With a `version` in `plugin.json`, the cache directory and `${CLAUDE_PLUGIN_ROOT}` end in that string. The Lead then reads the semver, **not a sha**. The record of the sha in `installed_plugins.json` can be stale mid-session (Q4). So "semver plus the sha in each record" is not reliably observable by the Lead. A **standard fingerprint** is: a sha256 over the standard-work files under the plugin root it was given (`skills/run/SKILL.md`, `references/protocol.md`, `agents/*.md`, `references/decision-card.md`). The Lead computes it with its shell at run start.
- With a `version`, installs stay put until the string changes. A forgotten bump means a standard change never ships to installed projects. A *fresh* install after an un-bumped change gets the new text under the old label.
- A running session keeps the version it loaded until `/reload-plugins` or a restart. Updates are manual for this marketplace (no `autoUpdate`). Freezing for a whole run therefore takes no mechanism, only a rule: don't update or reload mid-run.
- This run's items are measured by the Lead's manual stage log. The hansei mechanism is built *by* this run. Map decision "Baseline": the first instrumented items measure but don't improve.

## Options

### A — Semver per standard change, fingerprint alongside; this run is calibration *(leaning)*

- **Identity.** `plugin.json` gets `"version"` (first release `1.0.0`; marketplace entry stays without one). Bump rule: **major** when message formats or the protocol break; **minor** for any change to standard work; **patch** for anything else under `plugins/factory/` (README, setup assets, scripts). Each release commit gets a git tag `factory-v<semver>`, so a semver always maps back to an exact sha in the repo. Every record carries `plugin: factory <semver>`, `standard: <fingerprint>`, and the dependency versions as context (`wayfinding <ver>`).
- **Reset rule.** A baseline resets on a major or minor change. It does not reset on a patch, or on any commit that doesn't bump. A different fingerprint under the same semver is an **abnormality** (a forgotten bump). The Lead raises it; it is never silently a new baseline.
- **This run.** Freeze the installed factory for the whole run (`9147301f75c3` as loaded; no update or reload until the run's last item closes). Its items are recorded with the full label, in a section titled **"Calibration (pre-baseline)"** of the baseline issue. They show what the numbers look like and how long capture takes. They are not used as a "before". agent-plugins' baseline opens with the first item run on the first semver release, the first one with the hansei standard.
- **For the person.** Readable versions ("1.2.0 → 1.3.0") on every record and card. Each kaizen is visibly one release. You must bump on every standard change; a check in the developer's Done (and a qa line) catches a diff under the standard-work paths without a bump. Other projects get factory changes only when you release, never from an unrelated push.
- **For every project using the plugin.** Updates arrive per release, not per commit. A project's baseline resets only on real standard changes.
- **Undo cost.** To sha tracking (C): delete one line in `plugin.json`. Old records stay valid, because tags map each semver to a sha. To counting this run as the baseline (B): rename one section of the baseline issue. A forgotten bump caught by the fingerprint costs one patch release plus a re-label of the affected records. No data is lost, because the fingerprint tells the two texts apart.

### B — Semver as in A; this run is agent-plugins' first baseline, the "before" of the Lean change

- **Identity and reset rule.** As in A.
- **This run.** Freeze as in A. This run's items **are** agent-plugins' first baseline, labelled `factory 9147301f75c3` (pre-semver, sha only) and the fingerprint. It is the only chance to put numbers on the factory *before* Lean, since the run itself replaces that standard. The baseline resets at the first semver release and is kept as history. That release's items are compared against it.
- **For the person.** You get a "did the Lean standard help?" comparison. The cost is that it compares a manual stage log (this run) with hansei records (later). The two capture methods differ, so some measures aren't comparable: tokens may be peak context in one and spend in the other, and touches may be counted by hand. Each such measure has to read "not comparable", not a delta. The baseline also lives for one run only.
- **For every project.** As A.
- **Undo cost.** To A: rename the section. The data is identical. To C: as A.

### C — No `version`, sha stays the identity, the baseline keys on the fingerprint; this run labels each item and accepts resets

- **Identity.** No change to `plugin.json` or release practice. Every record carries `plugin: factory <sha>` (basename of `${CLAUDE_PLUGIN_ROOT}`) and `standard: <fingerprint>`.
- **Reset rule.** A baseline resets when the **fingerprint** changes, not the sha. So a docs-only push or a `toolkit` change doesn't reset it.
- **This run.** No freeze. The person may update and reload between items to dogfood what each slice merged. Each item records its own sha and fingerprint. Every item that lands a standard change starts a new baseline. In this run that is likely every item, so most of these "baselines" will hold one item.
- **For the person.** Nothing new to remember at release time, and nothing to forget. Labels are 12-hex and 64-hex strings, unreadable on cards ("9147301f75c3 vs 5a136f2eaa0a"). "Every kaizen is a versioned change" holds only implicitly. Countermeasure experiments have tiny baselines to compare with.
- **For every project.** Each `/plugin marketplace update` pulls whatever HEAD is, including a half-finished series of standard changes. Projects can't name or wait for "a release".
- **Undo cost.** To A or B later: add the `version` line and start tagging. Old records stay valid, because a sha is exact. Not undoable: items this run ran on mixed standards. Their numbers can't be re-collected on one frozen version.

## Comparison

| | A | B | C |
|---|---|---|---|
| Label on records | semver + fingerprint | semver + fingerprint | sha + fingerprint |
| Release practice | bump per change, tag | bump per change, tag | unchanged |
| Other projects update | per release | per release | per push |
| Baseline resets on | major/minor bump | major/minor bump | fingerprint change |
| This run | frozen, calibration | frozen, first baseline | unfrozen, per-item labels |
| Readable by the person | yes | yes | no |
| Forgotten bump | caught by fingerprint (abnormality) | same | can't happen |
| One-way part in this option | freeze, labels | freeze, labels | no freeze (mixed standards, permanent) |

## Leaning: A

The reason is asymmetric undo. A and B record exactly the same data: the full label, a frozen version, this run kept separate. They differ only in a name that one edit changes later. C gives up the freeze, which can't be recovered: a run on mixed standards can't be re-measured. A is preferred over B because B's "before" compares two capture methods that measure differently. Calling it a baseline invites a delta that the map's honesty rule and "not captured, never zero" would have to undo measure by measure. Calibration says what it is. If the person wants the Lean comparison anyway, A→B is one rename, with the incomparable measures marked.

Semver over sha (A over C) because the baseline and every card are read by the person. Releases also protect other projects from unrelated pushes. The bump discipline is the price. The fingerprint turns a forgotten bump from silent mislabelling into a visible abnormality.

## Draft card lines (technical decision-maker)

- **A:** "Version the factory like a product (1.0.0, 1.1.0 …). This run is a trial measurement that doesn't count. The real baseline starts with the first release. You bump the version on every standard change, and a check catches it when you forget."
- **B:** "Same versioning. This run counts as the 'before Lean' baseline. You get a before/after for the Lean change, but some numbers were captured by hand and won't be comparable."
- **C:** "Keep today's automatic commit-ids, with no release step. Baselines reset only when the standard text changes. This run may update the factory between items, so its items each run on a different version."

## Two-way doors inside A/B (decided by the architect; listed for the lead)

- First semver `1.0.0`, not `0.x`. The factory is already in use. Undo: change the string before the first release.
- Bump levels as above, with baseline reset on major/minor only. Undo: edit the ADR and the bump check.
- Tag format `factory-v<semver>`. Undo: retag.
- Fingerprint scope = the four standard-work paths from map decision "Standard work". The scope moves with that decision. The Lead computes it as sha256 over the files in sorted order, under the substituted `${CLAUDE_PLUGIN_ROOT}`. Undo: change the file list in `run/SKILL.md`.
- Dependency versions (`wayfinding`) recorded as context, not as reset triggers. Trigger to revisit: a baseline shift that coincides with a wayfinding update and no factory bump.
