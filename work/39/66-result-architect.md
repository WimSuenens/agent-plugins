# Result: architect — 39
Status: done
Progress:
  Done: ADR 0013 and the path rule (commit "#39 architect: ADR 0013 merge style; path rule"); the lead's added close-step findings in the contracts (commit "#39 architect: close step in one call, git clean, glob pathspec, I4, F5")
  Next: none; developer builds §9 of 39-standard-changes and the close-step changes, QA and security re-verify
Summary: ADR 0013 records the person's decision on #48 (option A): keep `gh pr merge --merge`; message files in work/ (briefs, results, feedback, questions, options, cards, lead state) never carry an absolute home path, only worktree-relative, ../wt/<id> or ~/ paths; the security checklist treats work/ in history as expected and checks only for a home path, secret or stray file. Rejected B (squash) and C (rebase-merge) with reasons; cites the decision comment, not work/. Locked for #39's merge, provisional as policy. Contract 39-standard-changes gains §9 (protocol.md Messages rule with worked example, run/SKILL.md pointer, security-reviewer.md checklist line with `git log -S"$HOME/"` and a worked finding, Merge PR keeps --merge with its reason), the placement table and §8 updated; 39-stage-log's intro states the rule for the lead state. Also, per the lead's addition: close step 6 runs guard + 6.1 + 6.2 as one shell call with "${w:?}" (L11/F4); `rm -rf` replaced by `git clean -fdx` plus a `[ ! -e ]` check (removal safety prompt, cannot leave the repo, does not follow symlinks; a nested repo stops the close for the person); `:(glob)` pathspec (L8a); api-error markers whitelisted to ^[a-z_]+$ else `other` (I4); F5 resolved by changing the contract: a lone Wake inside a gap counts as asleep (logically implied), so the script stays and QA's skipped test flips to expect `interrupted`.
Artifacts: docs/adr/0013-factory-items-merge-with-their-history-and-work-files-carry-no-home-paths.md; contracts/39-standard-changes.md (§9, table, §3, §8); contracts/39-stage-log.md; contracts/39-hansei-record.md §6; contracts/39-plugin-scripts.md §4
Decisions:
- Path rule also covers work/frontier-<id>/ and every message type, not only briefs/results/lead state / rejected: the three named types only / undo: narrow the protocol line.
- Slipped paths are detected by the security reviewer (`git log -S"$HOME/"` over origin/main..HEAD -- work/, severity low), no automatic rewrite at close / rejected: Lead rewrite in close commit (cosmetic, history keeps it) / undo: add a close check.
- Merge PR line carries a short reason for --merge / rejected: bare flag / undo: drop the clause.
- No new version bump: §9 rides on the 1.0.0 bump / rejected: separate minor / undo: n/a before tagging.
- `git clean -f -d -x -q -- work/<id>` plus `[ ! -e "${w:?}/work/<id>" ]` replaces `rm -rf` / rejected: rm -rf with the Lead substituting the literal path (still an rm the safety check may prompt on, and can reach outside the repo), git clean -ff (would delete a nested repo silently) / undo: one command in hansei.md §5 and SKILL.md.
- F5: contract changed to count a Sleep or Wake line inside the gap / rejected: Sleep-only filter in the script / undo: one jq condition plus the contract sentence.
- I4: non-matching error values read `other`, not dropped / rejected: `unknown` (that already means "no error field") / undo: one jq expression.
Open questions: none
Proposed for other owners:
- developer: protocol.md Messages rule; run/SKILL.md pointer; agents/security-reviewer.md checklist line; Merge PR clause in the tracker patch; hansei.md §5 and SKILL.md step 8.6 per contract 39-hansei-record §6 (one call, ${w:?}, :(glob), git clean); cut-offs.sh I4 whitelist. No change to cut-offs.sh for F5.
- qa-engineer: flip `sleep-wake-inside-alone-not-asleep` to expect `interrupted`; re-run the close commands from one call, including a nested-repo and a `03-dump/` case.
- docs-writer: docs/agents/issue-tracker.md Merge PR clause; CHANGELOG 1.0.0 names the merge-style rule.
Missing: none
