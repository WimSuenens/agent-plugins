## Overrides

An override is a local countermeasure the lead wrote under `## Overrides` in `docs/agents/factory.md`. Every role that reads that file for the ownership table reads `## Overrides` too.

- Apply every in-force override that concerns your role or stage as if it were part of this protocol. In force: status `active`, `kept` bound to the current run (or `kept … for next run`), or `promote chosen`; never `superseded`, and never one whose `fence check` is not `pass`.
- Outside the fence, the override wins over the plugin's text where they disagree. The fence wins over any override.
- The lead puts each in-force override's rule, in its own words, in the Constraints of your brief (`Override <name>: <rule>`).
- When you read an override that touches a fenced item, do not apply it and raise kind 5 on your `Abnormality:` line.

