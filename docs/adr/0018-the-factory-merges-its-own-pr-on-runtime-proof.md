---
status: proposed
---

# The factory merges its own PR when the gates and the runtime proof are met

Amends the merge-approval rule of `/factory:run` step 8.1 ("Merging is never automatic"). Issue [#114](https://github.com/WimSuenens/agent-plugins/issues/114), under [#108](https://github.com/WimSuenens/agent-plugins/issues/108).

## Decision

- Before it merges, the factory runs the application and attaches proof to the PR description under `## Proof`: browser screenshots for a web application, a run log for a command-line tool or a library.
- `scripts/merge-gate.sh` decides. It merges without the person when QA and security pass, CI is green, proof is attached and no one-way door is open. No proof means no auto-merge.
- Always human: contracts, authentication, secrets, data migrations and anything involving a one-way door. The slice pauses, carries a plain-language validation script and shows `Waiting on you` (`Cause: validation`).
- The fence F1 stays: no override widens this, and the person's earlier approvals (a production action, a run-close answer) are not covered by the gate.

## Consequences

- The hansei record's approval time is the gate time on an auto-merge, with no person touch.
