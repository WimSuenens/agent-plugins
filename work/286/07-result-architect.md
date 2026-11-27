# Result: architect — 286
Status: done
Abnormality: none
Progress:
  Done: brief checked (author WimSuenens, marker architect 2); Q1 and Q2 in 286-a3-v4-and-runs (02c7e51); 286-release pins and re-search (907fabb); role file
  Next: none (lead writes the Build brief; QA replaces the named skip at tests/factory/test_a3_v4_286.sh:154 and moves the soft pin)
Summary:
- Q1: option B. `a3-check.sh` checks order in two tracks: v1 to v3 keys exactly as on `main` (v4 keys never move the previous position); the four v4 keys from the v3 track's position after `calibration experiments`, bounded above by the first present key after them. AC-C2 holds as written: no requirement change, nothing to route to the product-owner.
- Worked example (§3): the out-of-order fixture as v4 gives `refused: run timing (out of order)` and `refused: still uncertain (out of order)`, exit 1; `guardrails` moved after `answer` gives `refused: guardrails (out of order)` only. Traced by hand against `main`'s order rule and QA's existing order checks (swapped, guardrails first, calibration after the four): their expected outputs are unchanged. The developer's build confirms it (I run no scripts).
- Q2 (§4.2): `<reasons>` are separated by `; `, each distinct reason once, first-appearance order over runs in `created_at` order; `m` counts runs. Worked example with two lite runs: `adjusted not captured (2 of 2 runs: lite)`. This matches QA's replay reading.
- 286-release §3: added `test_slice2_loop.sh:195` (now `when its marker is v2, v3 or v4`) and `test_lean_rules.sh:179` `ac17-docs-say-v2`. That one is a soft pin: it turns into a skip if the docs drop `factory:a3 v2`, so QA should re-point it to v4. `:185` was added to the pins that do not move. `v2 or v3` is in the search terms, and the per-sentence re-search over `tests/` is recorded with its terms.
Artifacts: contracts/286-a3-v4-and-runs.md, contracts/286-release.md, docs/agents/roles/architect.md
Decisions:
- AC-C2 versus the order rule: two order tracks in `a3-check.sh` (v3 keys apart from the four v4 keys) / rejected: narrowing AC-C2 to refusals not about order (needs a requirement change by the product-owner, and the v4 output would name `run timing` instead of the key the v3 check names for the same misplacement) / cost to undo: about 15 lines of awk in one script, a paragraph of §3, and then the AC-C2 narrowing.
- Runs `<reasons>`: `; ` separator, each reason once in first-appearance order / rejected: `, ` (already the slot separator in `blocked:`), and listing a reason once per run (repeats `lite` j times) / cost to undo: one sentence of baseline.md section 9 and the replay tool.
- `test_lean_rules.sh:179` listed as a soft pin for QA to re-point / rejected: leaving it out (it would go quiet as a skip) / cost to undo: one table row.
Open questions: none
Missing: none
