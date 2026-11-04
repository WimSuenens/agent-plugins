# Brief: architect — 37
Goal: Record the person's decision on #37 "Bounds of a local countermeasure" as an ADR, and add the Lean terms it settles to CONTEXT.md.
Inputs: #37 with its comments (`gh issue view 37 --comments`): the card and the decision comment https://github.com/WimSuenens/agent-plugins/issues/37#issuecomment-6641342929; map #34 Decisions so far; existing `docs/adr/` (next number after 0010) and `CONTEXT.md`.
Constraints:
- The ADR cites the decision comment URL, never a path under `work/`.
- Content: option C — the wide fence list; visibility (hansei + hoshin, with start date); expiry at the close of the run the override started in, where the person keeps / promotes / drops it next to the A3; poka-yoke (the Lead checks a new override against the fence before writing it and refuses fenced items); an override that crosses the fence is an andon abnormality any role can raise. Note what stays two-way (override format and precedence, decided in a slice) and what stays deferred (experiment length).
- CONTEXT.md: add only terms this decision crystallises (e.g. local countermeasure / override, fence, yokoten), in the existing style with `_Avoid_` lines where useful.
- No tracker writes.
Output: `docs/adr/0011-<slug>.md`, `CONTEXT.md` edit; result `work/frontier-37/05-result-architect.md`. Commit: `#37 architect: ADR for the bounds of a local countermeasure`.
Done: the ADR states context, decision, consequences, and cites the decision comment; glossary entries added.
