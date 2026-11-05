---
status: proposed
---

# Factory releases carry a semver, and this run is calibration

Every item's measurement (its hansei record) and every baseline carries a label saying which factory it ran on. A baseline resets when that label changes. Until now the factory had no version: its version was the agent-plugins commit at fetch time, so every push, even docs-only or another plugin's, counted as a new factory. A label that is too coarse can't be split afterwards, because the text an item ran on is gone and the item can't be re-run. This run also changes the standard it runs on, so whether it is frozen can't be decided after the fact either. Both doors were settled together by the person: [decision on #36](https://github.com/WimSuenens/agent-plugins/issues/36#issuecomment-6641533963), option A plus three additions. The facts on how plugin versions and updates behave come from the findings on #35.

## Decision

1. **The factory gets a semver.** `"version"` goes in `plugins/factory/.claude-plugin/plugin.json` only, not in the marketplace entry. The first release is `1.0.0`.
2. **Bump levels.** **Major** when message formats or the protocol break. **Minor** for any change to standard work. **Patch** for everything else under `plugins/factory/`. Each release commit gets a git tag `factory-v<semver>`, so every semver maps back to an exact commit.
3. **Baseline reset.** A baseline resets on a major or minor release only.
4. **Standard fingerprint on every record.** At run start the Lead computes a sha256 over the standard-work files under the plugin root it was given (`skills/run/SKILL.md`, `references/protocol.md`, `agents/*.md`, `references/decision-card.md`), plus `hooks/` and `scripts/`, in sorted order. Every record carries `plugin: factory <semver>`, the fingerprint, and the dependency versions (`wayfinding`) as context. A fingerprint that changes under the same semver means someone forgot to bump. The Lead raises that as an **andon abnormality** and never starts a new baseline silently.
5. **Poka-yoke on the bump.** The Lead refuses to open a PR that touches the factory's standard-work paths without a version bump in `plugin.json`. A CI check may follow later.
6. **This run is calibration.** This run stays frozen on install `9147301f75c3` from start to finish: no `/plugin marketplace update` and no `/reload-plugins` until its last item closes. Its items are recorded with their full label in a section titled **"Calibration (pre-baseline)"**. They show what the numbers look like and how long capturing them takes, and they are never used as a "before". agent-plugins' baseline opens with the first item run on `1.0.0`, the first release with the hansei standard in it.
7. **The freeze is checked.** The frozen sha is written into the map's Factory run section. At every item start the Lead compares the installed sha (the last segment of `${CLAUDE_PLUGIN_ROOT}`) with it and raises an andon on a mismatch.
8. **The freeze's reach is accepted knowingly.** The factory is installed at user scope, so the freeze holds for every project on this machine. Holding back `/plugin marketplace update` also holds back `wayfinding` and the other plugins from this marketplace. An urgent mid-run fix ends the calibration: the items after it are recorded as such, not mixed in silently.

## Consequences

- The person reads versions like "1.2.0 → 1.3.0" on every record and card, and each kaizen is one visible release. Other projects get factory changes only on a release, never from an unrelated push or a half-finished series of standard changes.
- Each standard change costs about a minute to bump. A forgotten bump can't slip through unnoticed: the poka-yoke stops the PR, and the fingerprint catches whatever gets past it. Repairing one costs a patch release plus re-labelling the affected records, about an hour. No data is lost, because the fingerprint tells the two texts apart.
- For the length of this run the person can't try out what each slice merged, here or in any other project on this machine. The new standard is tried one run later.
- **Left to the slice:** how the fingerprint's `hooks/` and `scripts/` coverage interacts with patch bumps. A change there is a patch release under the bump levels, yet it moves the fingerprint, so the slice works out whether such a change resets the baseline, is reclassified as minor, or is told apart some other way. The exact wording of the poka-yoke and of the item-start check are also the slice's.
  Settled by slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39) as a two-way door ([contract](../../contracts/39-plugin-scripts.md)): the record carries two fingerprints, **standard** (standard work) and **tooling** (`hooks/`, `scripts/`). A tooling-only patch leaves `standard` unchanged, so it does not reset the baseline; either fingerprint moving under the same release is the forgotten bump of point 4. The bump check also asks a patch for any other change under `plugins/factory/`.
- **Undo cost.** Counting this run as the baseline after all (B) means renaming one section of the baseline issue, a few minutes, with the incomparable measures marked "not comparable". Dropping the semver (C) means deleting one line in `plugin.json`, under an hour, and old records stay valid because each tag points to a commit. The freeze itself can't be undone afterwards, but it costs only time: no data is lost.

## Decided inside, overturnable

The architect's two-way doors. The lead or the person can overturn each one with an ordinary change.

- First release `1.0.0`, not `0.x`, because the factory is already in use. Undo: change the string before the first release.
- Bump levels as above, with the baseline resetting on major or minor only. Undo: edit this ADR and the bump check.
- Tag format `factory-v<semver>`. Undo: retag.
- The fingerprint's file list moves with the map's decision on what counts as standard work. Undo: change the list in `run/SKILL.md`.
- Dependency versions are recorded as context, not as reset triggers. Trigger to revisit: a baseline shift that coincides with a `wayfinding` update and no factory bump.

## Considered options

- **B: same semver, but this run counts as the "before Lean" baseline.** Rejected. It records exactly the same data as A, but it compares the Lead's hand-kept stage log with later hansei records. Tokens (peak context against total spend) and the person's touches (counted by hand) would read "not comparable" rather than show a difference, and the baseline would hold for one run only. Switching to it later stays a rename.
- **C: no semver; the commit sha stays the identity, the baseline keys on the fingerprint, and this run isn't frozen.** Rejected. The labels are 12- and 64-character codes the person can't read on a card. Other projects would pull whatever agent-plugins holds at the time. Most of all, it gives up the freeze, which can't be recovered: this run's items would run on a mix of standards, so most "baselines" would hold a single item, and the numbers could never be collected again on one frozen version.
- **Semver plus the commit sha in each record** (the original framing of the question). Rejected because it can't be observed. With a `version` set, the plugin root ends in the semver, not the sha, and `installed_plugins.json` can be stale mid-session (#35). The fingerprint plus a tag per release gives the same precision.

Complements [0011](0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md): an override is measured against the baseline this ADR defines.

**Provisional** until the first item has run on `1.0.0` with a fingerprint on its hansei record. The freeze of this run is **locked**: it is deliberate and can't be undone afterwards.
