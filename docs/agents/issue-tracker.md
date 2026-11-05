# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v` — `gh` does this automatically when run inside a clone.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

When set to `yes`, PRs run through the same labels and states as issues, using the `gh pr` equivalents:

- **Read a PR**: `gh pr view <number> --comments` and `gh pr diff <number>` for the diff.
- **List external PRs for triage**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments` then keep only `authorAssociation` of `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, or `NONE` (drop `OWNER`/`MEMBER`/`COLLABORATOR`).
- **Comment / label / close**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be either — resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

Used by `/wayfinding:wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Destination / Notes / Beachhead / Decisions-so-far / Deferred / Fog / Out-of-scope body. `gh issue create --label wayfinder:map`.
- **Child ticket**: an issue linked to the map as a GitHub sub-issue (`gh api` on the sub-issues endpoint). Where sub-issues aren't enabled, add the child to a task list in the map body and put `Part of #<map>` at the top of the child body. Labels: `wayfinder:<type>` — one of `research`, `slice`, `prototype`, `grilling`, `task`. Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: GitHub's **native issue dependencies** — the canonical, UI-visible representation. Add an edge with `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, _not_ the `#number` or `node_id`). GitHub reports `issue_dependencies_summary.blocked_by` (open blockers only — the live gate). Where dependencies aren't available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Frontier query**: list the map's open children (`gh issue list --state open`, scoped to the map's sub-issues / task list), drop any with an open blocker (`issue_dependencies_summary.blocked_by > 0`) or an assignee; first in map order wins.
- **Claim**: `gh issue edit <n> --add-assignee @me` — the session's first write.
- **Resolve**: `gh issue comment <n> --body "<answer>"`, then `gh issue close <n>`, then append a context pointer to the map's Decisions-so-far in the form `- [<title>](<url>) — [locked|provisional] <gist>`. A one-way door also gets an ADR under `docs/adr/` via `/domain-modeling`.
- **Slice ticket**: label `wayfinder:slice`. Its body is the `/beachhead` frame (Question / Behaviour / Under test / Deliberately faked). It stays open across the whole build and closes when the implementation PR merges; its resolution comment records what the build taught and any decision it contradicted. Link the implementation tickets `/to-tickets` produced back to it so the build is reachable from the map.
- **Deferred**: plain lines in the map body under `## Deferred`, each ending in `— **trigger:** <condition>`. Deferred items are deliberately **not** issues: giving them ids invites them onto the frontier, which is the weight this layer exists to avoid.

## Factory operations

Used by `/factory:run`. Only the lead touches the tracker. A factory **run** follows one `wayfinder:map`, `<map>`; an **item** is one `wayfinder:slice` ticket the run cut, and `<id>` is its issue number. Ids for the Project, the `Factory status` field, and its options are cached in `docs/agents/factory.md`.

- **Add to board**: `gh project item-add <project-number> --owner <owner> --url <issue-url> --format json --jq .id`. The output is the item's project id, `<item>`; write it into the item's lead state.
- **Set status**: `gh project item-edit --id <item> --project-id <project-id> --field-id <field-id> --single-select-option-id <option-id>`.
- **Run state**: `gh issue view <map> --json body --jq .body`, replace the `## Factory run` section at the top, then `gh issue edit <map> --body-file <file>`.
- **Stage summary**: `gh issue comment <id> --body "<stage>: <summary>"`, at most five lines, after every stage, followed by a `Decisions:` list of the stage's two-way decisions, overturned ones marked `[overturned: <reason>]`.
- **Find hansei**: `me="$(gh api user --jq .login)"`, then `gh api "repos/{owner}/{repo}/issues/<id>/comments" --paginate --jq '.[] | select(.user.login == "'"$me"'") | select(.body | startswith("<!-- factory:hansei v")) | .id'`. Only comments written by the Lead's own `gh` user count. Prints the hansei comment's id, or nothing.
- **Post hansei**: run *Find hansei* first. When it prints nothing: `rec="$(mktemp)"`, write the record to `$rec`, `gh issue comment <id> --body-file "$rec"`, then `rm -f "$rec"`; the command prints the comment URL, ending `#issuecomment-<comment-id>`. When it prints an id, the record exists already (a resumed close): update it with *Edit hansei* instead. Never post a second record. No command here names `--repo`, so the record lands in the project's own tracker.
- **Edit hansei**: `gh api "repos/{owner}/{repo}/issues/comments/<comment-id>" --jq .body > <record>.md`, change only the measure 7 block, then `gh api --method PATCH "repos/{owner}/{repo}/issues/comments/<comment-id>" -F body=@<record>.md`. `<record>.md` is a scratch file made with `mktemp` (`rec="$(mktemp)"`, its path wherever `<record>.md` stands), outside the repo, never committed, and removed with `rm -f "$rec"` afterwards.
- **Decision card**: `gh issue comment <ticket> --body-file <card>.md` on the ticket the door belongs to (the slice, or the map's `prototype` or `grilling` ticket). Record the person's choice as a reply comment: `Decision: <option>. Reason: <their words>.`
- **Task request**: `gh issue comment <ticket> --body "Task for you: <what, and why it blocks>"` on the map's `task` ticket. Record what was done as its resolution comment.
- **Open PR**: `gh pr create --head item/<id> --title "<slice title>" --body "Closes #<id>"`. Merging it closes the slice ticket, which is the moment `/wayfinding:wayfinder` resurveys.
- **Merge PR**: only after the person approved *merge and clean up?*. `<branch>` is `item/<id>` or `frontier/<map>`. First re-run the bump check: `git fetch origin main`, then `bash "<plugin root>/scripts/check-bump.sh"` in the branch's worktree (`<plugin root>` is the lead's `Plugin root:` path). Exit 1 or 2: do not merge; handle it as in *Open PR*. Exit 0: `gh pr merge <branch> --merge` (`--merge`, never squash or rebase: the role commits are the evidence the hansei record is re-checked against); once it succeeds:
  1. When the merged branch changed the `version` in `plugins/factory/.claude-plugin/plugin.json` (only in the repo that hosts the factory): read it from the merge commit and tag only when it is MAJOR.MINOR.PATCH (digits and two dots, e.g. `printf '%s' "<version>" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'`); otherwise skip the tag and tell the person. `git fetch origin main`, then `git tag factory-v<version> "$(gh pr view <branch> --json mergeCommit --jq .mergeCommit.oid)"` and `git push origin factory-v<version>`. Skip when that tag exists already (`git ls-remote --tags origin factory-v<version>` prints a line).
  2. `git worktree remove <worktree>`, `git branch -D <branch>`, and `git push origin --delete <branch>`.
- **Commit reference**: every commit message on `item/<id>` starts with `#<id>`.
