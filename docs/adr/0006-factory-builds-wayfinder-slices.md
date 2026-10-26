---
status: superseded by 0007
---

# The factory builds wayfinder slices, and wayfinder and beachhead became model-invoked

A factory item is one `wayfinder:slice` ticket with a `/beachhead` frame: wayfinding decides *what* to build, the factory decides *who builds it how*. For the lead to chart a map, frame a slice, and resurvey after a merge on its own, `/wayfinding:wayfinder` and `/wayfinding:beachhead` dropped `disable-model-invocation`. Both stay interactive, so they run in the lead's main session, never inside a role subagent.

## Consequences

Both descriptions now sit in every session's context where the wayfinding plugin is enabled, including repos that never run the factory.
