# 39 — Hansei record end to end, shipped as release 1.0.0

Slice: [#39](https://github.com/WimSuenens/agent-plugins/issues/39) · Map: [#34](https://github.com/WimSuenens/agent-plugins/issues/34) · ADRs: [0011](../adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md), [0012](../adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md)

## User outcome

The person running the factory runs an item on factory release **1.0.0**. While the item moves through its stages, the Lead keeps a **stage log** in the item's lead state. When the person approves the merge, the Lead posts **one hansei comment** on the slice ticket, in the project's own tracker, before `work/<id>/` is removed. The comment carries a marker with a schema version, the release and the standard fingerprint, and the seven measures, each with a value or "not captured". The Lead refuses to open a PR that changes the factory without the version bump the change needs.

This serves the map's first *Done when*: every closed item leaves a hansei record on its slice ticket, in the project where the factory runs.

## Terms used here

- **Standard work**: `skills/run/SKILL.md`, `references/*.md`, `agents/*.md` under the factory plugin root. This widens map #34's Notes (four paths) so that the new `references/hansei.md` counts as standard work (contract `39-standard-changes.md`).
- **Tooling**: `hooks/` and `scripts/` under the factory plugin root.
- **New standard**: the factory as it is on branch `item/39`, loaded with `claude --plugin-dir <worktree>/plugins/factory` in a separate session.
- **Hansei record**: the hansei comment as the new standard defines it. Its exact layout is the architect's contract; this requirement fixes what it must contain.

## Acceptance criteria

Criteria marked **[human-only]** can only be judged by the person in a real session running the new standard. QA lists them for the acceptance demo. Criteria marked **[post-merge]** can only be checked after the merge and are checked by the Lead at close or at the resurvey. All other criteria QA checks against the branch: the plugin files, any script the developer adds, and fixtures.

### A. Release and fingerprint (ADR 0012)

**AC-1 Release in plugin.json.**
Given branch `item/39`,
when `plugins/factory/.claude-plugin/plugin.json` is read,
then it holds `"version": "1.0.0"`, and the factory's entry in `.claude-plugin/marketplace.json` holds no `version`.

**AC-2 Release readable at runtime.** *(Under test: ADR 0012, releases and fingerprint)*
Given the plugin root is passed as `${CLAUDE_PLUGIN_ROOT}`, both as an install path ending in a version segment and as a `--plugin-dir` path that ends in `plugins/factory`,
when the Lead follows the new standard to read its release,
then it gets `1.0.0` in both cases, read from the plugin root alone, without the agent-plugins git history or `installed_plugins.json`.
It is contradicted if either case yields anything other than `1.0.0`.

**AC-3 Fingerprint is stable.** *(Under test: ADR 0012, releases and fingerprint)*
Given two copies of the same plugin tree at different absolute paths, with different file modification times, computed in two separate runs,
when the fingerprint is computed the way the new standard tells the Lead to,
then both results are the same sha256 (64 hex characters).
It is contradicted if the same files give two different fingerprints.

**AC-4 Fingerprint moves with the text.**
Given a copy of the plugin tree,
when one byte changes in any one standard-work file (tried once each in `skills/run/SKILL.md`, `references/protocol.md`, `references/hansei.md` and one file in `agents/`), or a file is added to or removed from `agents/` or `references/`,
then the fingerprint changes.
And when a file outside standard work and tooling changes (for example `README.md`, or `plugin.json` itself),
then the fingerprint does not change.

**AC-5 Tooling changes are told apart from standard-work changes.** *(Under test: ADR 0012, releases and fingerprint)*
Given three copies of the plugin tree: the original, one with a change under `scripts/` only, and one with a change in `references/protocol.md` only,
when a record's release-and-fingerprint fields are produced for each,
then a reader comparing the fields alone (without diffing the files) can tell that the second copy changed tooling and the third changed standard work.
It is contradicted if the two changed copies look alike against the original. How they are told apart (for example one fingerprint for standard work and one for tooling) is the architect's choice; see Open questions.

**AC-6 Dependency versions as context.**
Given the new standard,
when a hansei record is produced,
then it names the `wayfinding` version the session runs with, labelled as context. A dependency whose version can't be read shows "not captured".

**AC-7 Release tag.** **[post-merge]**
Given the PR for #39 is merged,
when the tags are listed,
then `factory-v1.0.0` exists and points at the merge commit on `main`.

### B. Bump poka-yoke (ADR 0012)

**AC-8 The standard tells the Lead to refuse an unbumped PR.** *(Under test: ADR 0012, bump poka-yoke)*
Given the new standard's text at the step where the Lead opens a PR (*Open PR*),
when it is read,
then it tells the Lead, before running `gh pr create`, to compare the branch with `main` and to stop when:
- a standard-work path changed and the `version` in `plugin.json` did not go up by at least a minor;
- any other path under `plugins/factory/` changed and the `version` did not go up at all.
On a stop, the Lead does not open the PR; it sends the developer a feedback brief (`Source: lead`) asking for the bump, and records the refusal in the stage log.
It is contradicted if any instruction in the standard opens a PR without passing this check first.

**AC-9 The refusal holds in a real session.** **[human-only]** *(Under test: ADR 0012, bump poka-yoke)*
Given a session running the new standard and a throwaway branch that edits `plugins/factory/agents/developer.md` and leaves `plugin.json` unchanged,
when the Lead reaches *Open PR*,
then no PR is opened, and the Lead names the missing bump.
And given the same branch with a patch bump only, the Lead still refuses, naming the minor bump the change needs.

**AC-10 Changes outside the factory pass.**
Given a branch whose diff touches nothing under `plugins/factory/` (the usual case in any other project),
when the Lead follows *Open PR*,
then the check passes without asking for a bump.

### C. Capture: the stage log (Capture decision)

**AC-11 The standard tells the Lead to keep a stage log.**
Given the new standard,
when it is read,
then it tells the Lead to keep a stage log in `work/<id>/00-lead-state.md` with one row per stage (including feedback rounds and the acceptance demo), each with a start and end time in UTC taken from `date -u`, the time spent waiting for the person, the time spent waiting on limits, the time lost to stalls and interruptions (each logged as its own wait kind, naming the agent it hit), and the role's token figures. It also keeps a list of the person's touches with times.

**AC-12 Stage-log times agree with git and the tracker.** **[human-only]** *(Under test: Capture)*
Given the item run in the demo session with the new standard,
when each stage's logged start and end are compared with the commits made in that stage (first and last commit times of the stage's role, messages starting `#<id> <role>:`) and with that stage's stage summary comment creation time on the slice ticket,
then no logged time is further from its git or tracker evidence than that stage's own logged duration.
`Factory status` change times are not evidence: `gh` does not expose their history (contract `39-stage-log.md`, section 4).
The person (or QA, from the posted record) writes down the largest gap found in minutes. It is contradicted if any gap is larger than the stage's duration.

**AC-13 Cross-check written into the standard.**
Given the new standard,
when it is read,
then it tells the Lead, before posting the hansei comment, to compare the stage log with git commit times and stage summary comment times and to note in the record the largest gap found.

### D. The hansei record: content and honesty rule

**AC-14 Fixed format with a marker.**
Given the new standard (the record template it gives the Lead),
when it is read,
then the record:
- starts with a marker that carries a schema version (`hansei v2`; v1 appeared only in the acceptance demo's record and is not what release 1.0.0 writes), which a script can find in the slice ticket's comments without reading the rest;
- carries `plugin: factory <semver>`, the fingerprint field(s) from AC-5, and the dependency versions from AC-6;
- carries the seven measures as named fields in a fixed order, each always present;
- carries an "Active overrides" field (ADR 0011), which reads "none" when the project's `docs/agents/factory.md` lists none;
- carries the stage-log cross-check gap from AC-13.

**AC-15 The seven measures, each defined.** *(Under test: Measures)*
Given the record template,
when it is read,
then each of the seven measures says what is counted and where the Lead reads it:

| # | Measure | Fields | Source the Lead reads |
|---|---|---|---|
| 1 | Lead time | total, from the first stage's start to the person's merge approval, split into agent working / waiting for the person / waiting on limits / stalled / interrupted, the five parts adding up to the total | stage log |
| 2 | First-pass yield | QA, security, acceptance demo, judged on the stage's first run: "pass first time" when the first verdict is pass and that run lists no finding at or above minor (a finding without a severity counts as at or above), written "pass first time (<n> low)" when it lists <n> ≥ 1 findings below minor (low, info, trivial or note); "failed first time" otherwise; "n/a" when the stage did not run | results and feedback briefs in `work/<id>/` |
| 3 | Rework loops and overturned two-way decisions | count of feedback briefs per role; count of two-way decisions overturned by a `Source: lead` feedback | `work/<id>/` |
| 4 | Escaped defects | "not captured" until its deferral fires | (deferred) |
| 5 | Tokens per role | per role, the Lead included: spend summed from transcript `message.usage`, and peak context from the completion notice, each labelled; spend reads "not captured (transcript truncated by <kind>)" when a stall or interruption cut one of the role's transcripts | transcripts, completion notices |
| 6 | The person's touches | counts of decision cards, demos, approvals, overturns | stage log's touches list |
| 7 | Doors confirmed or contradicted | per **Under test** line of the frame: confirmed / contradicted / not exercised | the resurvey (see AC-19) |

**AC-16 Honesty rule: "not captured", never 0, never left out.** *(Under test: Honesty rule)*
Given a record in which a measure, or one part of a measure, could not be captured (always escaped defects; in a fixture also one role's token spend because its transcript is unreadable),
when the record is produced,
then that field reads `not captured`, with a short reason where there is one, and is present in its usual place.
And given a measure whose true value is zero (for example no rework loops),
then it reads `0`.
It is contradicted if any field that wasn't captured shows `0`, is blank, or is missing from the record. "n/a" is allowed only for a stage that did not run (AC-15, measure 2) and never stands in for "not captured".

**AC-17 Seven measures filled for a real item.** **[human-only]** *(Under test: Measures)*
Given the item run in the demo session with the new standard,
when the person reads its hansei comment,
then every measure except escaped defects holds a value (or "n/a" where the stage did not run) that the person agrees with from what they saw in the session.
The person notes each field the Lead had to mark "not captured" and why. It is contradicted if any measure other than escaped defects reads "not captured" because the Lead had no way to observe it.
*Status:* failed at the acceptance demo (record on factory-sandbox #2, schema v1): measure 1 hid stalls and interruptions inside agent working, and token spend from a cut transcript could read as a number (issues #44–#47). The fix is schema v2. By the person's rule, AC-17 is re-judged on QA's word after the fix, against the v2 template and fixtures, unless QA demands a demo re-run.

**AC-18 Posted before work/ is removed.** *(Under test: Capture)*
Given the new standard's step 8 (close the item),
when it is read,
then posting the hansei comment comes after the person's merge approval and before the commit that removes `work/<id>/`.
And **[human-only]** in the demo session, the hansei comment's creation time is earlier than the time of the commit that removes `work/<id>/`.
It is contradicted if the comment can't be posted before that removal.

**AC-19 Doors measure filled after the resurvey.**
Given the new standard,
when it is read,
then it tells the Lead to post the record at approval with measure 7 reading `pending resurvey`, and after the resurvey (step 8.5) to edit **the same comment** so measure 7 holds the outcome per **Under test** line. When the resurvey does not happen (the run is stopped), measure 7 reads `not captured`.
**[human-only]** In the demo session, after the resurvey, the slice ticket holds one hansei comment (not two), and measure 7 no longer reads `pending resurvey`.

### E. What reaches agent-plugins

**AC-20 Measurements stay in the project.** *(Under test: What reaches agent-plugins)*
Given every file of the new standard,
when it is searched for instructions that write a hansei record, a stage log, or any measure,
then each one targets the project's own tracker or files (no `--repo WimSuenens/agent-plugins`, no path in the plugin repo).
And step 9's factory feedback issue keeps to the map's rule: the problem in factory terms, the standard change, before/after numbers against the baseline with item count and release, no code, names, business content, or raw hansei records.
It is contradicted if any instruction tells the Lead to write a measurement into the plugin repo.

**AC-21 Measurements stay in the project, in a real session.** **[human-only]**
Given the demo session,
when the item closes,
then the Lead posted or pushed nothing to `WimSuenens/agent-plugins`, and the hansei comment is on the demo project's slice ticket.

### F. Calibration record for this item (resurvey input)

**AC-22 #39's own manual record.** **[post-merge]** *(Under test: Measures, Capture)*
Given this item (#39) runs on the frozen install `9147301f75c3` with the Lead's manual stage log,
when the Lead posts #39's record at close under "Calibration (pre-baseline)",
then each of the seven measures is filled or reads "not captured", and the resurvey notes which ones the Lead could not fill and why. This record is never used as a "before" (ADR 0012).

## Out of scope

From the frame's **Deliberately faked**:
- Tracing escaped defects to their item: the measure reads "not captured" (Deferred "How an escaped defect is traced back to its item").
- A baseline issue and any aggregation of hansei records (the baseline slice; script vs reading is Deferred "A metrics store outside the tracker").
- Gemba sample, A3 and andon fields in the record (later slices; the schema version leaves room).
- A CI check for the version bump: the Lead's check only.
- Hansei records for frontier rounds (Deferred "Hansei records for frontier rounds").
- Running the new standard on this run's own items: this run stays frozen on `9147301f75c3`; the demo loads the item branch with `claude --plugin-dir` in a separate session, without touching the install.

Also out of scope for this slice:
- Whether a tooling-only change resets the baseline (ADR 0012, "Left to the slice"): this slice only makes such a change visible in the record (AC-5); the reset rule belongs to the baseline slice.
- Raising an andon when the fingerprint changes under the same release (ADR 0012, point 4) and the item-start freeze check (point 7): the andon is a later slice. This slice puts the fingerprint on every record so the check can be built on it.
- Writing or checking overrides (ADR 0011): only the "Active overrides" field is shown.
- A dashboard, composite scores, comparing projects (map: Out of scope).

## Decisions

Two-way doors decided here (chosen / rejected / cost to undo):

1. **Measure 7 is filled by editing the same comment after the resurvey.** Rejected: running the resurvey before the merge (changes step order in step 8), or a second comment (two records per item). Undo: about an hour of text in step 8; records already posted stay readable.
2. **"n/a" allowed only for a stage that did not run**, next to "not captured". Rejected: "not captured" for skipped stages, which would mix "didn't happen" with "didn't measure". Undo: a template change and a schema version bump.
3. **The poka-yoke covers all of `plugins/factory/`, and checks the level**: at least minor for standard work, at least patch for the rest. Rejected: standard-work paths only (ADR 0012's wording), which lets an unbumped tooling change move the fingerprint under the same release. Undo: narrow one rule in *Open PR*, minutes.
4. **"Active overrides" field included now** (ADR 0011 asks for it on every record), reading "none" until overrides exist. Rejected: adding it with the overrides slice, which would need a schema bump. Undo: drop one field before records are aggregated.
5. **Lead time runs from the first stage's start to the person's merge approval.** Rejected: ending at the merge itself, which happens after the record is posted. Undo: a definition change in the template; old records note the definition through the schema version.
6. **Token spend includes the Lead**, summed from the main transcript between item start and close. Undo: drop a row.

## Open questions

- **Architect**: how a tooling change is told apart from a standard-work change in the record (AC-5): two fingerprints, or one plus a per-part one, or another way. Also where the fingerprint computation lives (a script under `scripts/` would itself be tooling), and the record's exact layout and marker (contract).
- **Architect**: where the "post hansei comment" and "edit hansei comment" tracker operations live. Today tracker commands sit in each project's `docs/agents/issue-tracker.md`, written by `/factory:setup-factory-skill`; projects set up before 1.0.0 lack the new operations unless the run skill carries them itself.
- **Architect**: add *Hansei record* and *Stage log* to `CONTEXT.md`.
- **Lead (with the person)**: which scratch project and slice host the demo item for the human-only criteria (AC-9, AC-12, AC-17, AC-18, AC-19, AC-21). It needs its own GitHub issues and a map, and must not be agent-plugins' real tracker, so no measurement lands in agent-plugins. For AC-9, the throwaway branch must never be pushed to `WimSuenens/agent-plugins`.
- **Lead**: who creates the `factory-v1.0.0` tag at close (AC-7): the Lead in *Merge PR*, or devops in Delivery.
