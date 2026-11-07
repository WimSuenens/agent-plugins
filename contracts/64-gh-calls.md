# Contract 64 — The closed list of tracker calls, and the fake `gh` that answers them

Slice [#64](https://github.com/WimSuenens/agent-plugins/issues/64) · Requirement [64-board-as-run-state](../docs/requirements/64-board-as-run-state.md) · ADRs [0014](../docs/adr/0014-each-role-task-is-a-sub-issue-with-its-brief-as-body-and-its-result-as-closing-comment.md), [0015](../docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md)

Serves AC-3, AC-9 to AC-12, AC-19, AC-35 to AC-42. The other 64 contracts say **when** a call is made; this one says **which calls exist**. It is the list the `## Factory operations` section of `references/issue-tracker-github.factory.md` carries (and `docs/agents/issue-tracker.md` after the migration), and the list a test checks a call log against.

## Paths

Paths:
- plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md
- plugins/factory/skills/run/SKILL.md
- tests/factory/
shared: none

## 1. The rule

Every `gh` call the lead, a factory script (`scripts/board.sh`) or a test-driven step makes matches **exactly one** operation below. A call that matches none is a defect (AC-3: "each call is one the standard names"). A role makes none of the **mutation** operations (AC-16); the architect and product-owner may make the read operations `T-view` and `T-comments`, and a developer, QA, security, devops or docs-writer role may make any read operation its task needs.

**Mutation call** is the requirement's term: `gh issue create|edit|comment|close`, `gh project item-add|item-edit|field-create|item-create`, `gh api` with `--method` other than GET, and `gh api graphql` whose query text starts with `mutation`. A read is any other call.

Placeholders: `<O>` owner, `<R>` repo, `<N>` project number, `<P>` project id, `<item>` project item id, `<F>` field id, `<opt>` option id, `<n>` issue number, `<parent>` the parent issue's number, `<db>` an issue's numeric database id (not its number), `<cid>` a comment id, `<file>` a scratch file made with `mktemp` and removed after use (never a path in the repo).

## 2. The operations

Existing operations that 2.0.0 keeps unchanged keep their 1.3.0 text: **Run state**, **Stage summary**, **Find hansei**, **Post hansei**, **Edit hansei**, **Find/Create/Pin/Read/Edit baseline**, **Find records**, **Find A3s**, **Find/Post/Edit A3**, **Decision card**, **Task request**, **Open PR**, **Merge PR**, **Commit reference**. The ones below are new, or replace a 1.3.0 operation of the same family.

### Reads

| Id | Call | Answer the fake must give (fixture key) |
|---|---|---|
| `B-fields` | `gh project field-list <N> --owner <O> --format json --limit 100` | `{"fields":[{"id","name","type","options":[{"id","name"}]}]}`; `options` only on single-select fields |
| `B-options` | `gh api graphql -f query='query($f: ID!) { node(id: $f) { ... on ProjectV2SingleSelectField { options { id name color description } } } }' -f f=<F>` | `{"data":{"node":{"options":[{"id","name","color","description"}]}}}` (colour and description are required to send an option back, which `B-fields` does not give) |
| `B-items` | `gh project item-list <N> --owner <O> --format json --limit 1000` | `{"items":[{"id","title","content":{"type","number","title"}, "<field name, lower case>": <value>}]}`; a single-select value is the option **name**; a number or text value is the plain value; an item with no value in a field has no such key |
| `B-views` | `gh api graphql -f query='query($p: ID!) { node(id: $p) { ... on ProjectV2 { views(first: 50) { nodes { id name filter layout } } } } }' -f p=<P>` | `{"data":{"node":{"views":{"nodes":[{"id","name","filter","layout"}]}}}}` |
| `T-view` | `gh issue view <n> --json id,number,title,body,state,createdAt,closedAt` (any subset of the fields) | one issue |
| `T-subissues` | `gh api "repos/{owner}/{repo}/issues/<parent>/sub_issues" --paginate` | JSON array of issues: `number`, `id`, `title`, `body`, `state`, `created_at`, `closed_at`, `user.login`. Only those whose `user.login` is the lead's own login count (as *Find hansei*: a public repo can hold a forged marker). Used to **find** a role task by marker and to read the times of the Tasks table |
| `T-comments` | `me="$(gh api user --jq .login)"`, then `gh api "repos/{owner}/{repo}/issues/<n>/comments" --paginate --jq '.[] | select(.user.login == "'"$me"'") | {id, created_at, body}'` | the lead's own comments; **find by the first line** of `body`, never by position or time |
| `T-recent` | `me="$(gh api user --jq .login)"`, then `gh issue list --state all --author "$me" --limit 100 --json number,title,body,createdAt` | the lead's 100 newest issues; used only to find a role task that was created but never linked (AC-19) |
| `T-dbid` | `gh api "repos/{owner}/{repo}/issues/<n>" --jq .id` | the numeric database id |

### Mutations

| Id | Call | Notes |
|---|---|---|
| `B-add` | `gh project item-add <N> --owner <O> --url <issue-url> --format json --jq .id` | prints `<item>`; adding twice returns the existing item |
| `B-set` | `gh project item-edit --id <item> --project-id <P> --field-id <F> --single-select-option-id <opt>` | one field per call |
| `B-text` | `gh project item-edit --id <item> --project-id <P> --field-id <F> --text <value>` | the only way a number-like field is set (contract [64-ledger-and-fields](64-ledger-and-fields.md) §5: the fields are text) |
| `B-fcreate` | `gh project field-create <N> --owner <O> --name <name> --data-type TEXT` or `--data-type SINGLE_SELECT --single-select-options "<a>,<b>"` | `board.sh` only |
| `B-foptions` | `gh api graphql --input -` with a JSON body holding the `updateProjectV2Field` mutation and `singleSelectOptions` (each with `id` when it exists, `name`, `color`, `description`) | `board.sh` only. The only call that may add or drop an option. The fake **logs the stdin body** |
| `B-vcreate` | `gh api graphql --input -` with a JSON body holding the `createProjectV2View` mutation (`name`, `layout`, `filter`) | `board.sh` only; may be refused (AC-6) |
| `T-create` | `gh issue create --title <title> --body-file <file>` | prints the issue URL. **Content-creating** (counts toward the 80 a minute) |
| `T-link` | `gh api --method POST "repos/{owner}/{repo}/issues/<parent>/sub_issues" -F sub_issue_id=<db>` | the REST form of `addSubIssue` (decision 1 of [64-release](64-release.md) §6) |
| `T-comment` | `gh issue comment <n> --body-file <file>` | prints the comment URL. **Content-creating** |
| `T-edit-comment` | `gh api --method PATCH "repos/{owner}/{repo}/issues/comments/<cid>" -F body=@<file>` | the ledger and the hansei record |
| `T-close` | `gh issue close <n>` | after the closing comment, never before (AC-11) |

### What each rule of the requirement maps to

| Rule | Operations |
|---|---|
| AC-3 add a card with its fields | `B-add`, then `B-set` for `Factory status`, `Kind` (and `Role` for a role task) |
| AC-9 create a role task | `T-subissues` (find by marker), `T-create`, `T-dbid`, `T-link`, `B-add`, `B-set` ×3 |
| AC-10, AC-12 find again after a resume | `T-subissues`, `T-comments` |
| AC-11 post the result | `T-comment`, `T-close`, `B-set` |
| AC-5 needs-you | `T-comment`, then `B-set` (never the reverse) |
| AC-22 fields | `B-text` (text fields), `B-set` is not used for them |
| AC-35 to AC-41 migration | `B-fields`, `B-options`, `B-items`, `B-views`, `B-foptions`, `B-set`, `B-fcreate`, `B-vcreate` |

## 3. The fake `gh` (what QA builds, and what the contract gives it)

A script named `gh` placed first on `PATH`; no test in 64 calls the real tracker (AC-42). Interface, so that a test and a fixture agree:

- **Log.** Every call appends one JSON line to `$FAKE_GH_LOG`: `{"argv":[...],"stdin":"<text or empty>","op":"<operation id or unknown>"}`. The `op` is found by matching `argv` against the table above; a call that matches none gets `"op":"unknown"` and the fake exits 99 (a test fails on any `unknown`).
- **Answers.** For operation `<op>` the fake prints the content of `$FAKE_GH_DIR/<op>.out`; when `<op>.<k>.out` exists it serves them in call order (`k` = 1, 2, …; the last one repeats). A fixture sets an operation's exit code with `<op>.exit` and its stderr with `<op>.err`.
- **Fail switch.** `FAKE_GH_FAIL=<op>[:<k>]` makes the `k`-th call of `<op>` (default: every call) exit 1 with stderr read from `$FAKE_GH_DIR/<op>.err` (a limit message, for AC-19: `You have exceeded a secondary rate limit` plus a `Retry-After` line; for the link: `Sub-issue nesting too deep` or `Too many sub-issues`).
- **No network.** The fake never execs the real `gh`. A test run with `gh` removed from `PATH` must fail with `gh: not found` (a clear message) and make no connection (AC-42).
- **Stateful fixtures.** A test that needs a call to change a later answer (create a role task, then find it) swaps the `.k.out` files; the fake keeps no state of its own.

### Worked example

Creating the first developer task of item 12, with nothing yet under the slice:

```
$ gh api "repos/{owner}/{repo}/issues/12/sub_issues" --paginate        # op T-subissues -> []
$ gh issue create --title "Build: developer on #12" --body-file /tmp/x  # op T-create   -> https://github.com/example/shop/issues/31
$ gh api "repos/{owner}/{repo}/issues/31" --jq .id                       # op T-dbid     -> 2850001
$ gh api --method POST "repos/{owner}/{repo}/issues/12/sub_issues" -F sub_issue_id=2850001   # op T-link
$ gh project item-add 9 --owner example --url https://github.com/example/shop/issues/31 --format json --jq .id   # op B-add -> PVTI_abc
$ gh project item-edit --id PVTI_abc --project-id PVT_xyz --field-id PVTSSF_status --single-select-option-id 5f1c0000  # op B-set (Running)
$ gh project item-edit ... --field-id PVTSSF_kind --single-select-option-id 77aa0001                                    # op B-set (role task)
$ gh project item-edit ... --field-id PVTSSF_role --single-select-option-id 88bb0004                                    # op B-set (developer)
```
