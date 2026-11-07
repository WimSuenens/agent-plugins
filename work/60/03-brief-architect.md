# Brief: architect — 60
Goal: Define the contracts for the gemba sample so the developer can write standard text and QA can test it offline.
Inputs: docs/requirements/60-gemba-sample.md (10 ACs, open questions for the architect); tracker issue 60 and map 34; contracts/57-*.md and contracts/49-*.md (style, and the 5 Whys, andon and hansei rules to reuse); plugins/factory/references/hansei.md; plugins/factory/skills/run/SKILL.md (step 8, close); docs/factory/reference.md (contract index); CONTEXT.md; docs/adr/0011, 0012, 0013; docs/agents/factory.md.
Constraints:
- Answer the requirement's open questions for the architect: exact `gemba` line grammar (v5) and the step number for the walk in step 8; where the 5 Whys of a difference is written (leaning: kind 7 andon without a paused agent) and whether an andon raised at close fits the andon timing rules; the bounded read command as text in hansei.md, no script (so only the standard fingerprint moves); baseline skip list reads v3, v4 and v5; add *Gemba* to CONTEXT.md.
- Contract text first: the standard-change list (which files of plugins/factory change, by which sections) and the fixtures/tests QA must write. Keep to the 10 ACs; add no measure, no hoshin view, no script reading gemba lines.
- The sample rule is fixed by AC-1; if you find it ambiguous or non-replayable, write a question rather than changing it.
- ADR 0011/0012/0013 bind. Write an ADR only for a real one-way door (none expected; say so). Cite tracker comments, never paths under work/. No absolute home paths in any committed file; no project data.
- Release 1.3.0 is the docs-writer/developer's bump; state which files must move and that check-bump.sh must pass.
Output: contracts/60-*.md, CONTEXT.md and docs/factory/reference.md entries as needed (docs/factory/reference.md is docs; propose it in the result if you do not own it); result in work/60/04-result-architect.md (Status: working at start).
Done: contracts committed (commit starts "#60 architect:"); every AC covered by a contract line; open questions answered; test list for QA; two-way decisions listed in the result.
