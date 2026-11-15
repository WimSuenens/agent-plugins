# Run skill: a stage's content on the tracker while the item runs

Read this when a role task is `done`, before its stage summary (step 6). It is part of the run skill; the router names the moment. Here `${CLAUDE_PLUGIN_ROOT}` is not substituted (only the router is): read it as the path on the `Plugin root:` line of `skills/run/SKILL.md`, and write that path in every shell command. The roles' files stay in `work/<id>/` and `work/` is still removed before the merge; this makes their content readable on the tracker meanwhile. Only the lead runs these scripts. A role writes no tracker text and is never told to run them.

## After the role's `done`, in this order

1. **Push the stage.** In the item worktree: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/stage-publish.sh" push` (the item branch; upstream is set on the first push). The push first scans the files it would publish (home path, secret): exit 5 pushes nothing and prints the file and line (never the text); exit 4 prints `stage-publish: push failed (...)`. Either way say so in the stage summary, skip the permalink block of step 2 for this stage, and go on. A failed or refused push never blocks the item and is never hidden.
2. **Permalinks in the closing comment.** After *The closing comment* step (1), before eliding and splitting: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/stage-publish.sh" append <rendered comment> <rev>`, where `<rev>` is the role's commit, or `<commit before its first>..<its last commit>` when it made several (`git log --grep '^#<id> <role>:'` finds them). The script reads the files of those commits and inserts `Files of this stage (permalinks)` before the comment's `<details>`: one `blob/<sha>/<path>` link per file, on the full sha of the stage's last commit. A sha permalink does not name a branch, so it still resolves when `work/` is removed again and when the branch is deleted: the commit stays reachable through the pull request. Running it again replaces the block.
3. **Inline, for what the person decides or checks.** After the closing comment is posted: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/post-file.sh" <role-task ticket> <file>`. The script reads the file, scans it, cuts it into numbered comments below the tracker's 65,536-character limit, marks each `<!-- factory:artifact v1 -->` with the file name, and on a re-run replaces its own comments instead of adding copies. Do not read the file into your context. The list is fixed:
   - the product-owner's requirement (`work/<id>/NN-requirement.md`, or the file its result names);
   - the architect's contracts (each file under `contracts/` its result lists);
   - the QA verdict (the `reviews/qa-*` file its result names, else its result draft);
   - the security verdict (the `reviews/security-*` file its result names, else its result draft).

   Every other artifact stays a permalink; never widen the list without the person. Run it again after a rework round, on the same ticket. Exit 1 is a scan hit: post nothing, tell the person the file and line (never the text) and keep the task `Running`, as for any scan. Exit 3 names the failed part: report it and go on; the closing comment is already posted.
4. **One line on the slice ticket.** Pass `--task <n>` (once per role task of the stage) to `stage-report.sh`; the stage summary then starts with `role task: #<n>`, which the tracker links to the role-task ticket. Do not write it yourself.

## Rules that stay

- The protocol's rules about `work/` paths do not change: ADRs, requirements and docs that land on main never cite a path under `work/`; decision cards and needs-you comments name no `work/` path or branch. A closing comment may name a `work/` file, so a permalink to one is allowed there. A permalink never goes into a decision card, a needs-you comment, an ADR or a doc.
- **Data egress** (question E): tracker content stays in the project's own tracker. The item branch is pushed after each stage, earlier than today (at the pull request), so the item's files appear on the project's remote, public or not, sooner. The PR text says so.
- The fence and the ownership rules are unchanged.
