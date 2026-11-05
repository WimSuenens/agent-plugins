# Options: merge style for PR #40 and factory items (#48)

Architect, item 39, 2026-11-05. Input to the product-owner's decision card. No ADR yet: the ADR follows the person's choice.

## Facts the options rest on (checked, not assumed)

1. **The branch is already public.** `WimSuenens/agent-plugins` is public. `refs/heads/item/39` and `refs/pull/40/head` both point at `29e030a`, 77 commits. GitHub keeps `refs/pull/40/head` after the branch is deleted, and the owner cannot delete it (only GitHub support can). So every commit on item/39, including `work/39/`, is already readable by anyone, whatever the merge style. The merge style decides only whether those commits also enter **main**, and so every clone of main.
2. **What is in those commits.** One absolute local path: `work/39/09-brief-qa-engineer.md:7` (`/Users/wimsuenens/Projects/portfolio/wt/39/plugins/factory`), present in 70 commits. The lead state holds session ids, which security accepted (review L5: random, locate a transcript on this machine only, no access). Main's history already holds `work/frontier-*` files from #38 (merged with `--merge`), with no `/Users/` path in them.
3. **The cross-check runs before the merge.** Contract 39-hansei-record §6: the stage-log cross-check (step 2) reads `git log item/<id>` and the record is posted (step 4) before `work/` is removed (step 6) and before *Merge PR* (step 7). So the record's `stage-log cross-check` value is computed identically under every style. What differs is where the evidence can be **re-checked later** (AC-12 is human-only and may be checked "by QA, from the posted record"; AC-18 compares the comment time with the `remove work/` commit time).
4. **The AC-12/AC-18 demo ran in `WimSuenens/factory-sandbox`**, not here. Its merge followed the standard text it ran on. For PR #40 the choice affects agent-plugins' own history and every later item.
5. **The merge style is standard work.** `--merge` is written in `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` (*Merge PR*), copied into `docs/agents/issue-tracker.md`. Changing it for "factory items generally" is a standard change: a minor bump, or part of 1.0.0 if decided before #40 merges (the developer edits the template in this PR).
6. **Tag (AC-7).** `gh pr view <n> --json mergeCommit --jq .mergeCommit.oid` returns the merge commit for `--merge` and the squash commit for squash; both are on main, so the *Merge PR* tag step and the runbook's post-merge checks work unchanged. For rebase-merge it returns the last rebased commit.

## Option A: keep `--merge`, stop paths at the source (issue #48's first branch)

`gh pr merge --merge` stays. The standard adds one rule: briefs, results and the lead state use worktree-relative or `~/` paths, never an absolute home path. The security reviewer's checklist says `work/` in merge history is expected; the finding becomes "a home path in `work/`", not "work/ in history".

- **For the person:** no change at merge time. Main's history keeps every role commit of an item, readable with plain `git log` from any clone; `work/` shows up in history between the item's first and last commit. The merge-time question in #48 goes away.
- **Cross-check (AC-12) and AC-18:** evidence lives on main for good. Anyone re-checks the record from the merge's second parent, e.g. `git log <merge>^1..<merge>^2 --format='%cI %s'`, and the `remove work/` commit's time is on main. Commit shas named in result **Progress** stay valid.
- **Tag (AC-7):** unchanged; the tag is on a real merge commit, and the runbook's `git revert -m 1` rollback is correct as written.
- **Cannot be taken back once #40 lands:** the one home path and the session ids enter main's history; removing them later means rewriting public main (force push, every clone and the `factory-v1.0.0` tag break). Marginal exposure is small: the same text is already public on `refs/pull/40/head`, and the username equals the public GitHub login.
- **Cost:** one rule in the standard (minor), one line in the security checklist. Briefs written by the Lead today already mostly use `~`.

## Option B: squash-merge (issue #48's second branch)

`gh pr merge --squash`, subject `#<id> <slice title>`. The record cites the PR's head commit for the `work/` removal.

- **For the person:** main gets one commit per item, and `work/` never appears in main's history. Per-role history stays on the PR (Commits tab, `git fetch origin pull/<n>/head`).
- **Cross-check (AC-12) and AC-18:** the record's value is unaffected (fact 3). Re-checking later needs the PR ref, not main: the squash commit's time is the merge time, and the role commits and the `remove work/` commit exist only on `refs/pull/<n>/head`. That evidence then depends on GitHub keeping PR refs; a move to another host, or a mirror, usually drops `refs/pull/*`. Result **Progress** shas no longer resolve on main. The hansei template and contract §6 need one added field: the PR head sha at close.
- **Tag (AC-7):** works as is (fact 6). The runbook's rollback changes from `git revert -m 1 <merge>` to `git revert <squash commit>`, and the AC-7 wording "the merge commit" means GitHub's merge commit of the PR, which is the squash commit.
- **Cannot be taken back once #40 lands:** main's history of #39 is one commit for good; the 77 commits can never be placed on main without rewriting it. The home path is **not** removed from public view: it stays on `refs/pull/40/head` (fact 1), so the privacy gain for #40 is clones of main only.
- **Cost:** template change to `--squash` plus the head-sha field (minor), runbook rollback line (devops), contract §6 edit (architect). Security L8 (stray files) loses most of its weight, since nothing in `work/` reaches main.

## Option C: rebase-merge (listed, not recommended)

`gh pr merge --rebase`. It differs from A in the wrong direction: GitHub's rebase-merge always writes new commits with new shas and the **merge time as committer date**. `work/` and the home path still enter main (as in A), but the committer times on main no longer match the stage log, so a later cross-check from main reads the merge time for every stage (AC-12 evidence destroyed on main), and result **Progress** shas don't resolve (as in B). The tag lands on the last rebased commit, and there is no merge commit to `revert -m 1`. It combines A's exposure with B's loss of evidence. Rejected.

## Undo cost, side by side

| | A `--merge` + path rule | B squash | C rebase |
|---|---|---|---|
| Home path / session ids on public main | yes, one path, for good | no (still on PR ref) | yes, for good |
| Cross-check re-checkable from main | yes | no, PR ref only | no (times rewritten) |
| Progress shas valid on main | yes | no | no |
| Tag + runbook unchanged | yes | tag yes, rollback line changes | no |
| Switch policy later | one-line template change, next item | same | same |
| What #40's merge fixes for good | path in main history | #39 as one commit on main | both |

The policy is a two-way door (one line in the template, next item onward). The **merge of #40 itself** is the one-way part: whichever style it uses is permanent for main.

## Leaning: A

The exposure squash would avoid is already public on `refs/pull/40/head` and cannot be withdrawn, and it is one path whose username is the public login. What squash gives up is not recoverable on main: the record's evidence (role commit times, the `remove work/` commit) moves to a GitHub-only ref, which a later QA check, a mirror or a host move does not see. A keeps the measurement verifiable with plain git, which is what the hansei standard is for, and its source fix (no home paths in `work/`) brings the per-item finding to 0, the #48 target, without a merge-time question.

Variant worth offering if the person cares about the one path: **A now, with the path edited out of `work/39/09-brief-qa-engineer.md` in the close commit**. It does not remove the path from earlier commits (that needs a history rewrite of item/39, which breaks every sha cited in reviews and results), so it is cosmetic; I would not do it.

## Two-way doors decided here

- Rebase-merge dropped from the card as a live option; kept as a listed, rejected alternative. Undo: put it back on the card.
- If B is chosen: squash subject `#<id> <slice title>` (keeps the commit-reference rule), and the record gains the PR head sha. Undo: change the template line.
