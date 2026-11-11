---
status: proposed
---

# The Obeya stays read-only until write-back and its auth model are decided

Issue [#122](https://github.com/WimSuenens/agent-plugins/issues/122), under spec [#121](https://github.com/WimSuenens/agent-plugins/issues/121).

## Context

Answering a decision card from the Obeya is a wanted later feature. It needs a write path and an authentication model, and both involve secrets and exposure, which are one-way doors that are not decided yet. v1 must not drift into them.

## Decision

- v1 is **read-only**: the project folder is mounted read-only, and the app never writes to the repo or the tracker.
- The documented token path is a **read-only token** from an untracked environment file. The user's own login token is allowed with a printed warning. The token is passed through the environment and is never written to disk by the start command.
- The app is **loopback-only** with no authentication, and it refuses to start on a non-loopback address.
- Write-back, a write-capable token and the auth model are **deferred to a decision card**; none is built until the person answers it.

## Consequences

- A misconfiguration cannot change the project or expose it on the network.
- Interactive decisions, intake adapters that write, and any multi-user use wait for the decision card.
- Slices that follow must not add a write path; one that needs it amends this ADR in the same PR.

## Way back

Supersede this ADR with the ADR that records the write-back and auth decision. The read-only mount, loopback rule and token modes are start-script and server settings, so lifting them is a contained change.
