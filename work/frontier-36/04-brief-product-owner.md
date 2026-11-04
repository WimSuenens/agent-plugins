# Brief: product-owner — 36
Goal: Write a decision card for #36 "Plugin version and this run's baseline" from the architect's three options.
Inputs: #36 (`gh issue view 36`); #35's findings (`gh issue view 35 --comments`); `work/frontier-36/02-options-architect.md` (options A/B/C, leaning A, comparison table, undo costs, draft card lines); map #34 Destination and Decisions so far; `docs/agents/factory.md` (decision-maker: technical); `${CLAUDE_PLUGIN_ROOT}/references/decision-card.md`.
Constraints:
- Grilling ticket in a frontier round: **Question me** (`/grilling`) is the first dig-deeper option.
- Note the architect's leaning (A) beside your own pick if they differ.
- Fact for the card: this Lead runs factory install `9147301f75c3`; options A and B require the person not to run `/plugin marketplace update` or `/reload-plugins` before this run's last item closes. Make that cost visible.
- Keep the architect's two-way sub-decisions (1.0.0, bump levels, tag name, fingerprint scope, dependency versions as context) out of the options; list them once as "decided inside, overturnable".
- No tracker writes.
Output: `work/frontier-36/05-decision-plugin-version-baseline.md`; result `work/frontier-36/06-result-product-owner.md` with `Status: needs-decision`. Commit: `#36 product-owner: decision card on plugin version and baseline`.
Done: the card follows the template and rules; "Undoing it later" is concrete per option.
