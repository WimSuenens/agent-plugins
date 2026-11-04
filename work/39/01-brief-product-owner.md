# Brief: product-owner — 39
Goal: Turn slice #39 into a requirement with testable acceptance criteria.
Inputs: slice #39 (`gh issue view 39`) with its frame; map #34 (`gh issue view 34`): Destination and Decisions so far (Measures, Capture, Honesty rule, What reaches agent-plugins, Bounds of a local countermeasure, Plugin version and this run's baseline) and Notes; `docs/adr/0011-*.md`, `docs/adr/0012-*.md`; `CONTEXT.md`; existing `docs/requirements/`.
Constraints:
- One acceptance criterion per **Under test** line, worded so it shows the contradiction.
- The "user" is the person running the factory; the observable outputs are the hansei comment on the slice ticket, the lead state's stage log, and the Lead's refusal to open an unbumped PR.
- Out of scope includes everything under **Deliberately faked**.
- Name criteria that only a person can judge in a real session (e.g. running the new standard via `claude --plugin-dir`) so QA can list them as human-only.
Output: `docs/requirements/39-hansei-record.md`; result `work/39/02-result-product-owner.md`. Commit: `#39 product-owner: requirement for the hansei record`.
Done: your role's Done list.
