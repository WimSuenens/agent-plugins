---
status: accepted
---

# The Obeya discipline has its own opt-in line; run timing is always on

Decided on [Obeya discipline: the opt-in setting](https://github.com/WimSuenens/agent-plugins/issues/279) and corrected after [Obeya discipline: can the before-reading be reconstructed from past runs?](https://github.com/WimSuenens/agent-plugins/issues/280), part of [Map: the Obeya discipline for the factory](https://github.com/WimSuenens/agent-plugins/issues/278) (from [#66](https://github.com/WimSuenens/agent-plugins/issues/66)).

The Obeya discipline preview (the discovery-readiness checkpoint) is switched by its own line, `obeya-discipline: on|off`, in the `## Obeya` section of `docs/agents/factory.md`, not by the room's `obeya: on|off`. A project that already runs the room must not get the discipline silently, because #66 requires each project's own before-reading to be captured *before* it opts in. A missing line means off, and setup does not ask while the discipline is a preview. The discipline works with `obeya: off`: it lives in the run and needs no container.

The run-level timing (run start and close, waits outside any item, whole-run blocks, raw and adjusted run duration) is **not** behind the switch: it is captured on every run, like the ledger and the hansei record. A before-reading has to come from a run *without* the discipline, and #280 found that past runs cannot supply one (no run in the current series, waits outside items never captured); timing behind the switch would make a before-reading impossible.

## Considered options

- **Reuse `obeya: on`**: rejected. Every project that opted in to the room, this repository included, would start the discipline with no before-reading.
- **More values on one line** (`obeya: off|room|discipline|both`): rejected. `obeya-optin.sh` and older installs read anything other than `on|off` as `unanswered`, so setup would ask again and the room would stop.
- **Run timing behind `obeya-discipline: on`**, or behind a switch of its own: rejected. A project would need a measured run with the discipline off, which the first form forbids and the second leaves to chance.
