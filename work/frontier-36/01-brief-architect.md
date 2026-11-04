# Brief: architect — 36
Goal: Give two or three options, with a leaning, for #36 "Plugin version and this run's baseline": what identifies a plugin version for the baseline and every hansei record, and how this run (which changes the factory plugin it runs on) counts toward agent-plugins' baseline.
Inputs: #36 (`gh issue view 36`); #35's findings comment (`gh issue view 35 --comments`, especially Q4 and Q5); map #34 Decisions so far ("Standard work", "Baseline", "Changing the standard", "What reaches agent-plugins"); `plugins/factory/.claude-plugin/plugin.json`; `.claude-plugin/marketplace.json`; existing ADRs in `docs/adr/`.
Constraints:
- Facts from #35: the computed version is plugin.json `version` > marketplace entry `version` > commit sha; with no `version`, every repo commit (even docs-only) is a new version; with a `version`, installs stay put until it is bumped; the Lead reads its version as the last segment of `${CLAUDE_PLUGIN_ROOT}`.
- Cover both halves: (1) the version identity (e.g. semver in plugin.json bumped per standard change; the sha; semver plus the sha recorded alongside), and what each means for release practice and for when baselines reset; (2) this run's baseline (e.g. freeze the installed version for the whole run; or label each item with its version and accept resets; or treat this run as pre-baseline calibration).
- Options are about consequences for the person and for every project using the plugin; note undo cost concretely.
- No tracker writes. Do not write an ADR yet — that follows the person's decision.
Output: `work/frontier-36/02-options-architect.md` and result `work/frontier-36/03-result-architect.md`; commit both as `#36 architect: options for plugin version and baseline`.
Done: two or three coherent options covering both halves, a leaning with its reason, and the concrete undo cost per option.
