# Feedback: architect — 39
Source: lead
Findings:
1. contracts/39-plugin-scripts.md example 2 — minor — conflicts with "one line per changed path"; align with the developer's resolution (plugin.json listed in a refusal only when it is the sole changed path) or say why not.
2. contracts/39-hansei-record.md grammar table — minor — allows `n/a` in measures 2, 3 and 5 while measure 3's definition says roles that never ran read `0`; align with the developer's resolution (n/a only in 2 and 5).
3. contracts/39-hansei-record.md security-reviewer token example — minor — keep the `spend` key ("spend not captured (...); peak context …").
Re-verify: the worked examples still add up. Commit `#39 architect: align contracts with build`; result `work/39/14-result-architect.md`. Touch only your paths.
