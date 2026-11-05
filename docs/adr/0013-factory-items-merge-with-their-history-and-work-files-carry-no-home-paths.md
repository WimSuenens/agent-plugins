---
status: proposed
---

# Factory items merge with their history, and work files carry no home paths

A factory item's PR is merged with `gh pr merge --merge`, so every role commit, including the item's `work/<id>/` files, lands in main's history for good. That made two things recur: the security review raised "`work/` in merge history" on every item, and at merge time the person was asked again whether to squash. Issue [#48](https://github.com/WimSuenens/agent-plugins/issues/48) asked for a deliberate choice. Whichever style PR #40 (release 1.0.0) merges with stays on main for good, which makes this a one-way door. The person decided it: [decision on #48](https://github.com/WimSuenens/agent-plugins/issues/48#issuecomment-6666262968), option A.

## Context

- **What is already public.** agent-plugins is a public repo, and GitHub keeps `refs/pull/<n>/head` (the PR's last commit and its history) after the branch is deleted; only GitHub support can remove it. So every commit on an item's branch, `work/<id>/` included, is public as soon as the PR is opened, whatever the merge style. For #39 that is 77 commits, one absolute home path, written in a brief and quoted in the architect's options file (the username in it is the owner's public GitHub login), and the session ids in the lead state, which security accepted as harmless (random, they only locate a transcript on this machine). The merge style decides only whether those commits **also** reach main and every clone of it.
- **The record's evidence lives in the role commits.** The hansei record's stage-log cross-check reads the item branch's commit times, and AC-18 compares the record's post time with the `remove work/` commit. Both are computed and posted before the merge, so their values are the same under any style. What the style decides is where they can be re-checked later.

## Decision

1. **Keep `--merge`.** The *Merge PR* step keeps `gh pr merge <branch> --merge`. Main holds every role commit of every item, and anyone re-checks a record from a plain clone, for example `git log <merge>^1..<merge>^2 --format='%cI %s'`.
2. **No absolute home paths in `work/`.** Briefs, results, feedback, questions and the lead state write paths relative to the worktree (`plugins/factory/agents/developer.md`), relative to the repo's parent where they name another worktree (`../wt/<id>`), or with the home directory as `~` (`~/.claude/plugins/cache/...`). Never an absolute path under the home directory. The rule sits in the protocol, which every role reads, so it holds at the source: once a role commits a file, the path is in history for good.
3. **The security checklist expects `work/` in history.** `work/<id>/` in the merge history is by design and is not a finding. The finding is narrower: an absolute home path, a secret, or a file outside the protocol's `NN-<type>-<role>.md` names in a `work/` commit.
4. **In 1.0.0.** The rule, the checklist line and the unchanged `--merge` line ship in PR #40, as part of release 1.0.0 (not yet tagged), not as a separate minor release.

The placement of each line is in [39-standard-changes](../../contracts/39-standard-changes.md) §9.

## Consequences

- No merge-time question about style, and the per-item security finding drops to zero once roles follow the path rule.
- The record stays verifiable with plain git, from any clone or mirror, without depending on GitHub keeping PR refs. Commit shas cited in results keep resolving on main, and the runbook's `git revert -m 1 <merge>` rollback stays correct.
- **For #39, accepted knowingly:** its one home path, in two of item #39's message files (the QA brief, and the architect's options file, which quotes it), both in the PR's history, and its session ids enter main's history. The security review's finding L14 (`reviews/security-39.md`, final round) names the two commits that add them. They add no text beyond what `refs/pull/40/head` already shows, only more copies. Editing the path out in the close commit would be cosmetic, because the 70 earlier commits still hold it; removing it from those would rewrite item/39 and break every cited sha. Not done.
- Main's history grows by an item's role commits each time, and `work/` files appear and disappear in it.

**Undo cost.** Switching later items to squash is a one-line change to the *Merge PR* template, under an hour, effective from the next item. Taking #39's commits (or any merged item's) out of main means rewriting public main: about a day, every clone re-fetches, and the `factory-v1.0.0` tag breaks. Trigger to revisit: an item whose `work/` would carry something sensitive that its PR ref does not already expose, or the person finding the role history on main to be noise.

## Considered options

- **B: squash each item into one commit on main.** Rejected. Main would get one commit per item and `work/` would never appear in its history, but the home path stays public on the PR ref anyway, so the gain is only in clones of main. In return the role commit times and the `remove work/` commit would exist only on `refs/pull/<n>/head`: re-checking a record (AC-12, AC-18) would depend on GitHub keeping PR refs, which a mirror or a host move usually drops, and result shas would stop resolving on main. It would also need a head-sha field in the record and a new rollback line. What it gives up can never be restored on main.
- **C: rebase-merge.** Rejected. GitHub rewrites every commit with the merge time as committer date, so the home path reaches main as in A while the commit times no longer match the stage log, which destroys the cross-check evidence on main as in B. There is no merge commit for `git revert -m 1`, and the tag lands on the last rebased commit. It has the downsides of both.

## Decided inside, overturnable

The architect's two-way doors.

- The path rule also covers `work/frontier-<id>/`, since the protocol defines both folders' messages the same way. Undo: narrow the protocol line.
- Detection of a slipped path is the security reviewer's, with `git log -S` over the item's commits, as a low finding. No automatic rewrite at close, for the reason above. Undo: add a check to the close step.
- The *Merge PR* line names the reason for `--merge` in a few words, so a project's maintainer doesn't "tidy" it to squash. Undo: drop the clause.

**Locked** for #39's merge: whatever lands on main with PR #40 stays. **Provisional** as the policy for later items, a two-way door behind one template line.
