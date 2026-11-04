# Factory operations patch: GitHub

**Applies to**: `docs/agents/issue-tracker.md` whose first heading is `# Issue tracker: GitHub`.

**Change**: add (or replace) the `## Factory operations` section at the end of the file with the section below, verbatim.

---

## Factory operations

Used by `/factory:run`. Only the lead touches the tracker. A factory **run** follows one `wayfinder:map`, `<map>`; an **item** is one `wayfinder:slice` ticket the run cut, and `<id>` is its issue number. Ids for the Project, the `Factory status` field, and its options are cached in `docs/agents/factory.md`.

- **Add to board**: `gh project item-add <project-number> --owner <owner> --url <issue-url> --format json --jq .id`. The output is the item's project id, `<item>`; write it into the item's lead state.
- **Set status**: `gh project item-edit --id <item> --project-id <project-id> --field-id <field-id> --single-select-option-id <option-id>`.
- **Run state**: `gh issue view <map> --json body --jq .body`, replace the `## Factory run` section at the top, then `gh issue edit <map> --body-file <file>`.
- **Stage summary**: `gh issue comment <id> --body "<stage>: <summary>"`, at most five lines, after every stage, followed by a `Decisions:` list of the stage's two-way decisions, overturned ones marked `[overturned: <reason>]`.
- **Find hansei**: `gh api "repos/{owner}/{repo}/issues/<id>/comments" --paginate --jq '.[] | select(.body | startswith("<!-- factory:hansei v")) | .id'`. Prints the hansei comment's id, or nothing.
- **Post hansei**: run *Find hansei* first. When it prints nothing: `gh issue comment <id> --body-file <record>.md`; the command prints the comment URL, ending `#issuecomment-<comment-id>`. When it prints an id, the record exists already (a resumed close): update it with *Edit hansei* instead. Never post a second record. No command here names `--repo`, so the record lands in the project's own tracker.
- **Edit hansei**: `gh api "repos/{owner}/{repo}/issues/comments/<comment-id>" --jq .body > <record>.md`, change only the measure 7 block, then `gh api --method PATCH "repos/{owner}/{repo}/issues/comments/<comment-id>" -F body=@<record>.md`. `<record>.md` is a scratch file outside the repo, never committed.
- **Decision card**: `gh issue comment <ticket> --body-file <card>.md` on the ticket the door belongs to (the slice, or the map's `prototype` or `grilling` ticket). Record the person's choice as a reply comment: `Decision: <option>. Reason: <their words>.`
- **Task request**: `gh issue comment <ticket> --body "Task for you: <what, and why it blocks>"` on the map's `task` ticket. Record what was done as its resolution comment.
- **Open PR**: `gh pr create --head item/<id> --title "<slice title>" --body "Closes #<id>"`. Merging it closes the slice ticket, which is the moment `/wayfinding:wayfinder` resurveys.
- **Merge PR**: only after the person approved *merge and clean up?*. `<branch>` is `item/<id>` or `frontier/<map>`. `gh pr merge <branch> --merge`; once it succeeds:
  1. When the merged branch changed the `version` in `plugins/factory/.claude-plugin/plugin.json` (only in the repo that hosts the factory): `git fetch origin main`, then `git tag factory-v<version> "$(gh pr view <branch> --json mergeCommit --jq .mergeCommit.oid)"` and `git push origin factory-v<version>`. Skip when that tag exists already (`git ls-remote --tags origin factory-v<version>` prints a line).
  2. `git worktree remove <worktree>`, `git branch -D <branch>`, and `git push origin --delete <branch>`.
- **Commit reference**: every commit message on `item/<id>` starts with `#<id>`.
