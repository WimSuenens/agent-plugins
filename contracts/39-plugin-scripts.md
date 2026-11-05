# Contract 39 — Plugin scripts: label, bump check, token spend

Slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39) · Requirement [39-hansei-record](../docs/requirements/39-hansei-record.md) · ADR [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) · Record: [39-hansei-record](39-hansei-record.md)

Three scripts under `plugins/factory/scripts/`. They are **tooling**: covered by the tooling fingerprint, and a change to one alone is a patch release.

Common rules for all three:

- `bash` 3.2 compatible (macOS's `/bin/bash`), no other interpreter. `jq` (1.6 or later) only where stated. sha256 via `sha256sum`, falling back to `shasum -a 256`.
- The Lead calls them with the plugin root that `skills/run/SKILL.md` shows on its `Plugin root:` line, where Claude Code substitutes `${CLAUDE_PLUGIN_ROOT}`: `bash "<plugin root>/scripts/<name>.sh" …`. Only a skill file gets that substitution; a reference file such as `references/hansei.md` writes `<plugin root>` and says it is the path from that line, never a literal `${CLAUDE_PLUGIN_ROOT}`. `CLAUDE_PLUGIN_ROOT` is not in the Bash environment either (#35), so no script reads it; the root is always an argument or the script's own location.
- Results on stdout, in the exact lines below. Diagnostics on stderr. Exit codes as listed; any non-zero exit means the Lead writes `not captured (<stderr line>)` for what the script would have produced (or, for the bump check, does not open or merge the PR).
- **No absolute paths in output.** A stderr line can be copied into a record on a public tracker, so it names a directory or file by its basename only (`fingerprint: not a factory plugin root: 9147301f75c3`), never a path under the home directory.
- **A semver** is `MAJOR.MINOR.PATCH`, each part `0` or a number without leading zeros (`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$`, as semver.org). `1.08.0`, `1.0`, `v1.0.0` and `2.0.0-rc1` are not semvers.
- No network, no writes outside stdout and stderr.

## 1. `scripts/fingerprint.sh` — the label

```
bash <root>/scripts/fingerprint.sh <root>
```

Stdout, exactly three lines:

```
release: <semver | <basename of root> (pre-release install, no semver)>
standard: <64 lowercase hex>
tooling: <64 lowercase hex>
```

- **release**: the `"version"` string of `<root>/.claude-plugin/plugin.json`, read from the plugin root alone (no git, no `installed_plugins.json`). This is what gives `1.0.0` both for an install path ending `factory/1.0.0` and for a `--plugin-dir` path ending `plugins/factory` (AC-2). The version must be a semver (common rules). Only when `plugin.json` has **no** `version` key does the line read `<basename of root> (pre-release install, no semver)`; a `version` key that is present but empty (`""`) or not a semver is an error (exit 2), never the pre-release label.
- **Two fingerprints** (AC-5). A reader compares the two lines with another record's: a different `standard` means standard work changed; a different `tooling` with the same `standard` means only tooling changed.
  - **standard** covers standard work: `skills/run/SKILL.md`, every `references/*.md`, every `agents/*.md` (top level of each folder only).
  - **tooling** covers every regular file under `hooks/` and `scripts/`, recursively.
  - Both skip any path with a component that starts with `.` (`.DS_Store`, editor swap files). Nothing else under the root counts: `README.md`, `.claude-plugin/plugin.json`, `skills/setup-factory-skill/**`, `.in_use/`, `.orphaned_at` change neither (AC-4).
- **Algorithm**, the same for both sets:
  1. List the set's files as paths relative to `<root>`, `/`-separated, no leading `./`.
  2. Sort them bytewise (`LC_ALL=C sort`).
  3. For each file write one manifest line: `<sha256 hex of the file's bytes>␠␠<relative path>\n` (two spaces, the `sha256sum` format).
  4. The fingerprint is the sha256 hex of the whole manifest's bytes.

  File contents and relative paths only: not the absolute root, not mtimes, not modes (AC-3). Adding, removing or renaming a file in a set changes its manifest and so its fingerprint (AC-4). An empty tooling set hashes the empty manifest (`e3b0c442…b855`).
- **All or nothing.** When any file of either set cannot be read, the script prints nothing on stdout and exits 2, naming the file by its path relative to `<root>` on stderr (`fingerprint: cannot read scripts/x.sh`). A fingerprint that silently skipped a file, or hashed an error, would be a wrong label that looks right.
- **Exit codes**: 0 ok. 2 when `<root>` has no `skills/run/SKILL.md` or no `.claude-plugin/plugin.json` (not a factory root), `plugin.json` has a `version` that is empty or not a semver, or a file in a set is unreadable. 3 when no sha256 tool is found. On any non-zero exit stdout is empty.

### Worked example

The frozen install of this run, and main at `84f282e`, hold the same files, so they give the same lines from two different paths:

```
$ bash plugins/factory/scripts/fingerprint.sh ~/.claude/plugins/cache/wimsuenens/factory/9147301f75c3
release: 9147301f75c3 (pre-release install, no semver)
standard: 48f28915d19a3b1261c98220136dcab0098061d0c62c0d1ee7a290d8ea6d1c20
tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652

$ git -C ../agent-plugins worktree add /tmp/fp-main 84f282e && bash plugins/factory/scripts/fingerprint.sh /tmp/fp-main/plugins/factory
release: factory (pre-release install, no semver)
standard: 48f28915d19a3b1261c98220136dcab0098061d0c62c0d1ee7a290d8ea6d1c20
tooling: d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652
```

(The two `standard`/`tooling` pairs were computed with the algorithm above on 2026-11-04.) The tooling manifest at that commit has two lines:

```
<sha256 of hooks/hooks.json>  hooks/hooks.json
<sha256 of scripts/guard-memory.sh>  scripts/guard-memory.sh
```

On branch `item/39` after the build, the release reads `1.0.0`, `standard` differs (new `references/hansei.md`, changed `skills/run/SKILL.md`), and `tooling` differs (three new scripts).

### Why two fingerprints settle ADR 0012's open point

ADR 0012 left open how a `hooks/`/`scripts/` change, a patch release, interacts with a fingerprint that moves. With two fingerprints:

- a patch release that touched only tooling keeps `standard` equal, so the records show the same standard work and the baseline holds, as ADR 0012 point 3 says for a patch;
- a moved `standard` or `tooling` under the **same** release is the forgotten bump ADR 0012 point 4 names (the andon on it is a later slice);
- a moved `standard` under a release that went up by a patch only is a wrong bump level, also visible.

Whether a tooling change should still reset a baseline stays with the baseline slice; the two fields make every such change visible on the records, so that slice can decide it on the data.

## 2. `scripts/check-bump.sh` — the bump poka-yoke

Run by the Lead after `git fetch origin main`, in the branch's worktree, at three points: before `gh pr create` for an item, before `gh pr create` for a frontier round (its PR should carry only ADRs and glossary changes, so the check normally passes with `no factory paths changed`; it is there for the round that touched `plugins/factory/` anyway), and again before `gh pr merge` (*Merge PR*), because commits can land on the branch, or on main, after the PR was opened:

```
bash <root>/scripts/check-bump.sh [<base-ref>]        # default base: origin/main
```

- **Changed paths**: `git diff -z --name-only <base>...HEAD -- plugins/factory/` (committed changes on the branch since it forked; uncommitted files don't count, since the PR carries commits). Paths are read by their real names, NUL-separated (`-z`), never in git's quoted form: a quoted non-ASCII name (`"plugins/factory/references/caf\303\251.md"`) would miss the standard-work rule and pass with a patch.
- **Needed level**: `minor` when any changed path is standard work (`plugins/factory/skills/run/SKILL.md`, `plugins/factory/references/*.md`, `plugins/factory/agents/*.md`); else `patch` when any path changed; else nothing.
- **Newline names fail closed**: a changed path whose name contains a newline counts as standard work (`minor`), wherever it sits under `plugins/factory/`, `scripts/` and `hooks/` included. Such a name cannot be told apart from two shorter paths when it is displayed or classified line by line, so the check takes the stricter level rather than guess; a standard-work rename can never slip through as a patch this way. In a refusal the path is printed as is, so it spans two (or more) lines.
- **Versions**: old = `version` in `git show <base>:plugins/factory/.claude-plugin/plugin.json`, `0.0.0` when the file or field is absent; present but not a semver (empty, `1.08.0`, …) is exit 2, because no suggestion can be computed from it and main should never hold one. New = the same at `HEAD`; absent, empty or not a semver (`1.08.0` included) is a refusal (exit 1), with `<new>` printed as found (`(absent)` when there is none).
- **Pass**: no factory path changed; or level `minor` and (new major > old major, or equal majors and new minor > old minor); or level `patch` and new > old. A major is never required by the script: whether a change breaks message formats or the protocol is the architect's call in the item, and the developer bumps major when told to.
- **Stdout and exit**:

| Case | Exit | Stdout |
|---|---|---|
| no factory path changed | 0 | `pass: no factory paths changed` |
| bump covers the change | 0 | `pass: <minor\|patch> bump needed, <old> -> <new>` |
| bump missing or too small | 1 | `refuse: <standard work\|factory files> changed; plugin.json version <old> -> <new>; needs at least a <minor\|patch> bump (<suggested>)` then one line per changed path other than `plugins/factory/.claude-plugin/plugin.json`, indented two spaces; `plugin.json` itself is listed only when it is the sole changed path |
| not a git repo, base ref missing, base version not a semver | 2 | nothing; reason on stderr |

`<suggested>` is the smallest passing version: `<major>.<minor+1>.0` for minor, `<major>.<minor>.<patch+1>` for patch.

### Worked examples

AC-9, a branch that edits `agents/developer.md` and leaves `plugin.json` at `1.0.0`:

```
$ bash "$ROOT/scripts/check-bump.sh"; echo "exit $?"
refuse: standard work changed; plugin.json version 1.0.0 -> 1.0.0; needs at least a minor bump (1.1.0)
  plugins/factory/agents/developer.md
exit 1
```

The same branch with `1.0.1` (the branch now also changes `plugin.json`, which the path lines leave out because the first line already reports its version):

```
refuse: standard work changed; plugin.json version 1.0.0 -> 1.0.1; needs at least a minor bump (1.1.0)
  plugins/factory/agents/developer.md
exit 1
```

A change under `scripts/` only, bumped to `1.0.1`: `pass: patch bump needed, 1.0.0 -> 1.0.1`, exit 0.

A new standard-work file with a non-ASCII name, `references/café.md`, bumped to `1.0.1`: classified by its real name, so it is standard work and the patch falls short:

```
refuse: standard work changed; plugin.json version 1.0.0 -> 1.0.1; needs at least a minor bump (1.1.0)
  plugins/factory/references/café.md
exit 1
```

A branch that sets the version to `1.08.0` over main's `1.0.0`, with a `scripts/` change: not a semver, so refused with the smallest valid suggestion:

```
refuse: factory files changed; plugin.json version 1.0.0 -> 1.08.0; needs at least a patch bump (1.0.1)
  plugins/factory/scripts/fingerprint.sh
exit 1
```

A file under `scripts/` whose name holds a newline (`scripts/a⏎b.sh`), bumped to `1.0.1`: fails closed as standard work, though a plain `scripts/` change would need only a patch:

```
refuse: standard work changed; plugin.json version 1.0.0 -> 1.0.1; needs at least a minor bump (1.1.0)
  plugins/factory/scripts/a
b.sh
exit 1
```

A change to `plugin.json` alone (say its `description`) with the version left at `1.0.0`: it still counts as a factory change, so a patch is needed, and being the sole path it is listed:

```
refuse: factory files changed; plugin.json version 1.0.0 -> 1.0.0; needs at least a patch bump (1.0.1)
  plugins/factory/.claude-plugin/plugin.json
exit 1
```

AC-10, any project without `plugins/factory/` (or a branch not touching it): `pass: no factory paths changed`, exit 0.

This item's own branch (main has no `version`): `pass: minor bump needed, 0.0.0 -> 1.0.0`, exit 0.

### What the Lead does with the result

Written into *Open PR* in `skills/run/SKILL.md`, and into step 3 for the frontier round's PR and *Merge PR* ([39-standard-changes](39-standard-changes.md) §3, §5): exit 0 → open (or merge) the PR, and log the pass line in the `Open PR` (or `Merge approval`) row's Notes. Exit 1 → do not open or merge; in an item, send the developer a feedback brief (`Source: lead`) quoting the refusal and log a `refused` row; in a frontier round, put the refusal to the person (the round's PR is not meant to touch `plugins/factory/`) and note it in the map's Factory run section, which stands in for the stage log there. Exit 2 → do not open or merge; put the stderr line to the person.

## 3. `scripts/token-spend.sh` — spend from transcripts

```
bash <root>/scripts/token-spend.sh [--since <UTC time>] [--until <UTC time>] [--require-end] [--] <transcript.jsonl>...
```

`--` ends the options; every argument after it is a transcript, so a file named `-x.jsonl` or `--since` is read as a file. An unknown option before `--` is exit 2 (usage on stderr).

Needs `jq`. Times are `YYYY-MM-DDTHH:MMZ` or `YYYY-MM-DDTHH:MM:SSZ`; the script compares on epoch seconds (fractions dropped), not as strings, because `20:44Z` sorts after `20:44:12.345Z` as text.

- Takes the entries with `type == "assistant"`, a `message.usage`, `message.model` other than `<synthetic>` (the rate-limit stand-in), and a `timestamp` inside the window when one is given.
- Counts each `message.id` once, keeping its last entry (a streamed message is written in several entries).
- Sums `input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, `output_tokens` over all files given (several transcripts of one role add up). **peak** is the largest single message's sum of the four.
- **`--require-end`** (for role-agent transcripts; the Lead never passes it for its own session, which is still running when the script reads it). Each file, read whole regardless of `--since`/`--until`, must show a run that ended by itself:
  1. no entry with `type == "user"` whose message text starts with `[Request interrupted` (what a run cut off and later resumed leaves behind), and
  2. a final reply at the end: among the entries with `type` `assistant` or `user`, the last one is either an `assistant` entry with no `tool_use` content block, or the `user` entry holding the `tool_result` of the agent's hand-back tool call (`tool_use` named `SubagentHandback`), with nothing after it but entries of other types.

  A file that fails either is **truncated**: exit 6, stdout empty, stderr `token-spend: transcript <basename> truncated`. Exit 3 (unreadable) is checked first, then 6, then 5. Without the option the script never checks endings, so the Lead's own window still sums.

Stdout, one line:

```
spend <total> (input <i>, cache write <w>, cache read <r>, output <o>); peak <p>; messages <n>
```

The `spend …` part is the record's `<tok>` slot verbatim; `peak` is the Lead's peak context.

| Exit | When | The Lead writes |
|---|---|---|
| 0 | ok | the line |
| 2 | bad usage: unknown option, a time not in the formats above | `not captured (<stderr line>)` |
| 3 | a file is missing, unreadable, or holds a line that is not JSON; stderr names that file by basename (`token-spend: transcript agent-a41f09.jsonl unreadable`) | `not captured (transcript <basename> unreadable)` |
| 4 | `jq` missing | `not captured (jq missing)` |
| 5 | no assistant message in the window | `not captured (no messages in window)`, never `0` |
| 6 | with `--require-end`, a transcript is truncated (stderr names it by basename) | `not captured (transcript truncated by <kind>)`, `<kind>` from the `stalled` or `interrupted` wait naming that agent, else `unlogged` ([39-hansei-record](39-hansei-record.md) §4, measure 5) |

Locating transcripts: a role agent's is `~/.claude/projects/<project>/<session id>/subagents/agent-<agent id>.jsonl`, found with `find ~/.claude/projects -name 'agent-<agent id>.jsonl'`; the Lead's is `~/.claude/projects/<project>/<session id>.jsonl` for each id under `lead sessions` in the lead state, with `--since` the `Start item` start and `--until` the approval time. Transcripts are deleted after `cleanupPeriodDays` (30 by default), and those written before Claude Code 2.1.307 may hold placeholder usage (#35), which is why the totals are taken at close.

### Worked example

The product-owner of this item (#39), agent `aff847e3e8c7e5bfa`:

```
$ bash plugins/factory/scripts/token-spend.sh -- ~/.claude/projects/<project>/<session id>/subagents/agent-aff847e3e8c7e5bfa.jsonl
spend 387472 (input 22, cache write 52402, cache read 316497, output 18551); peak 53942; messages 11
```

The peak equals the `53,942` the completion notice reported, as #35 found; the spend is about 7× it.

At close the Lead passes `--require-end` for every role transcript. A role whose transcript was cut by a stall (here the docs-writer of item #12, which stalled after writing its `done` result, so its file ends on an `assistant` tool call that never got its result):

```
$ bash "$ROOT/scripts/token-spend.sh" --require-end -- agent-e90b55.jsonl; echo "exit $?"
token-spend: transcript agent-e90b55.jsonl truncated
exit 6
```

The Lead finds W4 (`stalled`, agent `e90b55`) in `## Waits` and writes `spend not captured (transcript truncated by stalled)`. A stalled wait alone already decides it (signal a); the exit 6 catches the truncation nobody logged.
