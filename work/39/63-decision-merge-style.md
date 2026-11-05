## Decision: When a factory item's pull request (PR) is merged, should main keep every step the roles took, or only one combined commit?

**Why now:** PR #40 (release 1.0.0) is waiting to merge, and the factory's *Merge PR* step reads `gh pr merge --merge`. Whichever style #40 merges with stays on main for good. Issue #48 asks for a deliberate choice so the per-item security finding about local paths and the merge-time question to you both stop.

### Already public, whatever you choose

- **Everything on branch item/39 is already public and cannot be withdrawn.** The repo is public, and GitHub keeps `refs/pull/40/head` (GitHub's permanent copy of the PR's last commit and its history) even after the branch is deleted. Only GitHub support can remove it. That copy holds all 77 commits, including `work/39/`, the one absolute home path (`work/39/09-brief-qa-engineer.md`, line 7, a path with your username, which is also your public GitHub login), and the session ids in the lead state (security accepted these: random, and they only locate a transcript on this machine).
- This card decides only whether those commits **also** land on main, and so in every clone of main.
- The record's stage-log cross-check (the hansei record's check of each stage's time against the commit history) is computed and posted **before** the merge, so its value is the same under both options. What differs is where someone can re-check it later.

### Same in all options

- The chosen merge style is written into the factory standard (the *Merge PR* step in the tracker template, copied into `docs/agents/issue-tracker.md`) **in this PR, as part of 1.0.0**, since 1.0.0 is not tagged yet. No separate minor release.
- The security reviewer's checklist learns that `work/` in history is expected (under A) or no longer reaches main (under B), so the per-item finding is judged on the real risk.
- Tagging the release (AC-7) works under both: the tag goes on the commit GitHub reports as the PR's merge commit.

### Option A: Keep every step on main, and stop writing home paths into `work/`
- **For users:** Nothing changes at merge time, and you get no merge-time question. Main keeps each role's commits for an item, so anyone with a clone can see who did what and when with plain `git log`. The one home path and the session ids from #39 become part of main's history.
- **Cost and time:** about half a day in this PR: one rule in the standard ("briefs, results and the lead state use worktree-relative or `~/` paths, never an absolute home path") and one line in the security checklist.
- **Undoing it later:** switching later items to squash is a one-line template change, under an hour, from the next item on. **Removing #39's commits (and the home path) from main later is not practical:** it means rewriting public main, which breaks every clone and the `factory-v1.0.0` tag; count on about a day of work plus every clone having to re-fetch.

Technical detail: `gh pr merge --merge` stays. The cross-check and AC-18 stay re-checkable from main alone, e.g. `git log <merge>^1..<merge>^2 --format='%cI %s'`, and the `remove work/` commit's time is on main. Commit shas cited in result **Progress** keep resolving. The runbook's `git revert -m 1 <merge>` rollback is correct as written. The added exposure over what is already public is zero text, only extra copies (in clones of main). Editing the path out of `work/39/09-brief-qa-engineer.md` in the close commit would be cosmetic: the 70 earlier commits still hold it, and removing it from those would rewrite item/39 and break every sha cited in reviews and results. Not proposed.

### Option B: Squash each item into one commit on main
- **For users:** Main gets one tidy commit per item, and `work/` (with the home path) never appears in main's history. The per-role steps stay visible only on the PR page on GitHub. Re-checking the record later needs GitHub's PR copy, not main: a mirror, a move to another host, or an offline clone usually loses it.
- **Cost and time:** about one day across roles in this PR: the merge line becomes `--squash` with subject `#<id> <slice title>` (developer), the hansei record and contract §6 gain a "PR head commit at close" field (architect, developer), the runbook's rollback line changes (devops), and QA re-verifies.
- **Undoing it later:** switching back to `--merge` for later items is a one-line template change, under an hour. **#39's history on main stays one commit for good:** the 77 role commits can never be placed on main without rewriting it, and the home path stays public on the PR copy regardless.

Technical detail: `gh pr view <n> --json mergeCommit` returns the squash commit, so the tag step works unchanged. Rollback becomes `git revert <squash commit>`. The squash commit's time is the merge time; role commit times and the `remove work/` commit exist only on `refs/pull/<n>/head`, so AC-12 ("checkable by QA from the posted record") and AC-18 (comment time vs `remove work/` commit time) depend on GitHub keeping PR refs. Result **Progress** shas no longer resolve on main.

Rejected: **rebase-merge** (`--rebase`) puts the home path on main like A and rewrites every commit's time to the merge time, which destroys the cross-check evidence on main like B. It has the downsides of both.

**Recommendation:** A, because the thing squash would hide is already public and stays public, while what squash gives up (being able to re-check the record from main with plain git) can never be recovered on main. The architect leans A as well.
**If we're wrong:** if keeping role history on main turns out to be noise, or a later item carries something sensitive, later items switch to squash with a one-line change (under an hour). #39's commits stay on main either way; taking them out would mean rewriting public main (about a day, and every clone and the 1.0.0 tag break).

**Want to dig deeper?** Reply with a number:
1. **Question me** — `/grilling` asks you questions until your own answer is clear.
2. **Ask me** — I explain with an example or comparison until it is clear.
3. **Look it up** — `/research` writes a sourced report on the options.
4. **Show me** — `/prototype` builds a throwaway version you can look at or click through.
