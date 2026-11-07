# Feedback: architect — 60
Source: qa, security
Findings:
1. contracts/60-gemba-walk.md — low (QA F7) — the example `read transcript 30000 chars, partial (cap)` / `30000 chars of 201240` must follow the built text: the budget is 29,900 minus what was read, so n is at most 29,900 (see plugins/factory/references/hansei.md section 6 and work/60/12-result-developer.md). Also state in the contract that the extra bounded read takes only a worktree-relative path with no `..` and no leading `-`, or a hex sha, quoted and after `--`, else no extra read (security N1). Keep the contract and the 10 ACs consistent; no new AC.
Re-verify: grep the contracts for 30000 and fix every stale example. Commit "#60 architect:". Result: work/60/18-result-architect.md.
