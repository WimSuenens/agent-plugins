---
status: proposed, amended by 0017
---

# Slices run in parallel when their path lists do not overlap

Amends [0007](0007-factory-owns-destination-and-slicing.md): its closing rule "Slices run one at a time" and its rejected option "Parallel slices" no longer stand. It also changes the text of the wayfinding plugin's `beachhead` and resurvey, which the factory calls.

Issue [#55](https://github.com/WimSuenens/agent-plugins/issues/55) asked whether slices may run side by side. The person decided it on the same combined card as 0014 and 0015: [decision on #55](https://github.com/WimSuenens/agent-plugins/issues/55#issuecomment-6706121063), option C1, from [the card](https://github.com/WimSuenens/agent-plugins/issues/53#issuecomment-6706052982) on 2026-11-07. The release default of 2 is the Destination's default; the person did not choose it, the lead kept it.

## Context

- 0007 rejected parallel slices because a slice cut before the previous resurvey is cut on stale knowledge, and every merge needs the person's approval, so a second ready slice waits.
- Targets served: **performance** (less waiting for the person when independent slices exist), **maintainability** (one list per slice; no lock registry and no hook, and a script that compares two path lists is the one comparison), **security** (an off-list write is a finding).
- The architect's options note: the limit setting is a free retreat, so this is nearly a two-way door; it goes on a card because the person asked for it and 0007 states the opposite.

## Decision

1. **A contract carries a path list** (`Paths:`): files and directory prefixes, one per line, directory prefixes ending in `/`, every role's paths included, plus a `shared:` line.
2. **Two slices overlap** when a path is equal to, or a directory prefix of, a path in the other, or both name a shared path.
3. **The lead starts another slice only if its list does not overlap a running slice's**, up to `parallel-limit` in `docs/agents/factory.md`. **The default at release is 2.** Setting 1 is one-at-a-time.
4. **The list exists only after the architect stage**, so a slice is cut first and, if it overlaps, waits as Ready. That answers 0007's objection with a check, not with a ban: after each merge the resurvey compares every running slice with what the merge taught, and a questioned slice moves to Waiting on you ([0015](0015-factory-status-has-six-values-plus-kind-and-role.md)); its roles finish the step in hand and start no more.
5. **QA and security check** `git diff --name-only main...item/<id>` against the list. A path outside it is a finding.

## Considered options

- **C2: file-level locks enforced while the work runs.** Rejected. 5 to 8 days to build, a registry both worktrees can see, and locks held by an interrupted role are freed by hand. ADR 0010 gives roles a full shell, so a hook is a guard, not a boundary.
- **C3: no parallelism, keep 0007 as written.** Rejected. The person asked for it; getting to C1 later is about 3 days and a minor release.
- **Default limit of 1 until parallel running has been seen to work.** The architect's own counter-leaning, because this run cannot exercise parallel running. Rejected for the default by the person's choice of the Destination's default 2; the setting stays the free retreat.

## Consequences

- **Unverified at release.** This run cannot run two slices, so 2.0.0 ships the feature untested; the first real use is its test.
- A wrong list is caught late, at QA, and costs the later slice a merge conflict, not lost data.
- Shared ports and test environments are deferred until two slices run at once.
- **Undo cost.** Setting `parallel-limit: 1` takes minutes with no code change. Removing the `Paths:` field, the resurvey text and the setting is about 2 days and a minor release (estimates). Old path lists are harmless. Undoing this is not a 3.0.0 release.
- Depends on 0015 for Waiting on you and Blocked.

## Decided inside, overturnable

- **Shared paths always overlap**: the plugin version, `CHANGELOG.md`, `CONTEXT.md` and the next ADR number. The lead assigns the ADR number at slice start and applies the version bump and changelog line at merge, after rebasing. Rejected: glob matching (harder to test). Undo: under a day.

**Provisional** until two slices have run side by side.
