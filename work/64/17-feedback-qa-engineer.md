# Feedback: qa-engineer — 64
Source: lead (re-verify round 2)
Findings: the developer built the architect's checklist (`work/64/16-result-developer.md`, `work/64/14-result-architect.md`, `contracts/`). `bash tests/run.sh` fails only on pins the new contract text overturned, which are yours to update:
1. `ac28-q14`, `ac28-q16`, `ac28-q17` (case folding and overlap rule 3; rule 3 prints `overlap: yes <path> <shared entry>`).
2. `ac32` qa-engineer and security-reviewer diff-command pins (the two-option form).
3. `ac3-op-[Read role brief]`: `T-brief` is the same command as `T-view` for the harness; map it.
4. `ac9-run-spawn-prompt-number` (the spawn prompt now carries the lead's login).
5. The seven `ac16-agent-*-reads-brief-from-issue` pins (brief read with `--json author,body`, author and marker check, `blocked` with `Abnormality: 7 other` on a mismatch).
6. `ac7-stage-log-gone`.
7. `t8-text-29900-reserve`, `t8-text-n-is-the-sum-at-most-29900`, `f7-contrast-reads-29900` become 29,800 with the 200 reserve; the four `t8-*-printed-at-most-30000` skips should now pass at 29,800.
8. `ac45-no-home-path-or-token-in-changed-files` reports a hit at `tests/factory/test_gemba.sh:434`, a whole `ghp_` sample: your file; build the sample from halves, or exempt it in the scan with a reason.
Then, for each named skip of your first round that the build now meets (F1 `sk-` boundary and the ADR 0014 file name, F2 split cut reported on stderr, F3 `--needs-you` paths, F4 gemba budget, F5 baseline line), turn the skip into a test. Add rows for the new contract text: path grammar (empty, `.`, `..`), case folding, rule 3, the review diff command with a moved file and a non-ASCII name, rule 5.6 on `parallel-limit:` and `factory-state:`, scan scope (everything the lead posts), canary exit 2, the extended `--needs-you` paths, `T-brief` and the brief check, exit 6 rows (a) and (b) of AC-39, and a search showing only the two intended `--name-only` forms remain outside the two-option form (`check-bump.sh` and the rule 5.3 `diff-tree -z` line). Run the mutation checks on the new rows. Check that security's S1 to S8 each have a test or a stated reason.
Re-verify: the full suite, the quoted result, the verdict in `reviews/qa-64.md` (round 2; the remaining skips with reasons). Findings go to the developer as feedback. Update `work/64/11-result-qa-engineer.md` (Status, Progress, Summary, Decisions) and commit with subject `#64 qa-engineer: `.
