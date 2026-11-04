# Feedback: architect — 39
Source: qa
Findings:
1. contracts/39-plugin-scripts.md §2 — minor — write down the fail-closed rule the build and tests now hold: any path whose name contains a newline counts as standard work (minor bump), wherever it sits under plugins/factory/, including scripts/ and hooks/.
Re-verify: nothing else in §2 changes. Touch only contracts/ — the acceptance demo is running on this worktree's plugins/. Commit `#39 architect: newline names fail closed`; result `work/39/34-result-architect.md`.
