---
status: proposed
---

# Factory roles talk through files, hub-and-spoke

The factory's roles are subagents that report only to the lead, and every message is a file in `work/<id>/` (brief, result, feedback, question). Subagents cannot message each other, and agent teams, which can, are experimental and cost far more tokens; files also let any session be dropped and resumed. The lead reads only a result's `Status` and `Summary`, which keeps its context lean.

**Provisional** until a factory item has run end to end on a real project.
