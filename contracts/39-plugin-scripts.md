# Contract 39 — Plugin scripts: label, bump check, token spend

Slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39) · Requirement [39-hansei-record](../docs/requirements/39-hansei-record.md) · ADR [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) · Record: [39-hansei-record](39-hansei-record.md)

Three scripts under `plugins/factory/scripts/`. They are **tooling**: covered by the tooling fingerprint, and a change to one alone is a patch release.

Common rules for all three:

- `bash` 3.2 compatible (macOS's `/bin/bash`), no other interpreter. `jq` (1.6 or later) only where stated. sha256 via `sha256sum`, falling back to `shasum -a 256`.
- The Lead calls them with the substituted plugin root from `skills/run/SKILL.md`: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh" …`. `CLAUDE_PLUGIN_ROOT` is not in the Bash environment (#35), so no script reads it; the root is always an argument or the script's own location.
- Results on stdout, in the exact lines below. Diagnostics on stderr. Exit codes as listed; any non-zero exit means the Lead writes `not captured (<stderr line>)` for what the script would have produced (or, for the bump check, does not open the PR).
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

- **release**: the `"version"` string of `<root>/.claude-plugin/plugin.json`, read from the plugin root alone (no git, no `installed_plugins.json`). This is what gives `1.0.0` both for an install path ending `factory/1.0.0` and for a `--plugin-dir` path ending `plugins/factory` (AC-2). The version must be plain `MAJOR.MINOR.PATCH`. When `plugin.json` has no `version`, the line reads `<basename of root> (pre-release install, no semver)`.
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
- **Exit codes**: 0 ok. 2 when `<root>` has no `skills/run/SKILL.md` or no `.claude-plugin/plugin.json` (not a factory root), or `plugin.json` has a `version` that isn't `MAJOR.MINOR.PATCH`. 3 when no sha256 tool is found.

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

Run by the Lead in the item worktree, after `git fetch origin main`, before `gh pr create`:

```
bash <root>/scripts/check-bump.sh [<base-ref>]        # default base: origin/main
```

- **Changed paths**: `git diff --name-only <base>...HEAD -- plugins/factory/` (committed changes on the branch since it forked; uncommitted files don't count, since the PR carries commits).
- **Needed level**: `minor` when any changed path is standard work (`plugins/factory/skills/run/SKILL.md`, `plugins/factory/references/*.md`, `plugins/factory/agents/*.md`); else `patch` when any path changed; else nothing.
- **Versions**: old = `version` in `git show <base>:plugins/factory/.claude-plugin/plugin.json`, `0.0.0` when the file or field is absent. New = the same at `HEAD`; absent or not `MAJOR.MINOR.PATCH` is a refusal.
- **Pass**: no factory path changed; or level `minor` and (new major > old major, or equal majors and new minor > old minor); or level `patch` and new > old. A major is never required by the script: whether a change breaks message formats or the protocol is the architect's call in the item, and the developer bumps major when told to.
- **Stdout and exit**:

| Case | Exit | Stdout |
|---|---|---|
| no factory path changed | 0 | `pass: no factory paths changed` |
| bump covers the change | 0 | `pass: <minor\|patch> bump needed, <old> -> <new>` |
| bump missing or too small | 1 | `refuse: <standard work\|factory files> changed; plugin.json version <old> -> <new>; needs at least a <minor\|patch> bump (<suggested>)` then one line per changed path, indented two spaces |
| not a git repo, base ref missing | 2 | nothing; reason on stderr |

`<suggested>` is the smallest passing version: `<major>.<minor+1>.0` for minor, `<major>.<minor>.<patch+1>` for patch.

### Worked examples

AC-9, a branch that edits `agents/developer.md` and leaves `plugin.json` at `1.0.0`:

```
$ bash "$ROOT/scripts/check-bump.sh"; echo "exit $?"
refuse: standard work changed; plugin.json version 1.0.0 -> 1.0.0; needs at least a minor bump (1.1.0)
  plugins/factory/agents/developer.md
exit 1
```

The same branch with `1.0.1`:

```
refuse: standard work changed; plugin.json version 1.0.0 -> 1.0.1; needs at least a minor bump (1.1.0)
  plugins/factory/agents/developer.md
exit 1
```

A change under `scripts/` only, bumped to `1.0.1`: `pass: patch bump needed, 1.0.0 -> 1.0.1`, exit 0.

AC-10, any project without `plugins/factory/` (or a branch not touching it): `pass: no factory paths changed`, exit 0.

This item's own branch (main has no `version`): `pass: minor bump needed, 0.0.0 -> 1.0.0`, exit 0.

### What the Lead does with the result

Written into *Open PR* in `skills/run/SKILL.md` ([39-standard-changes](39-standard-changes.md) §3): exit 0 → open the PR, and log the pass line in the `Open PR` row's Notes. Exit 1 → do not open the PR; send the developer a feedback brief (`Source: lead`) quoting the refusal; log a `refused` row. Exit 2 → do not open the PR; put the stderr line to the person.

## 3. `scripts/token-spend.sh` — spend from transcripts

```
bash <root>/scripts/token-spend.sh [--since <UTC time>] [--until <UTC time>] <transcript.jsonl>...
```

Needs `jq`. Times are `YYYY-MM-DDTHH:MMZ` or `YYYY-MM-DDTHH:MM:SSZ`; the script compares on epoch seconds (fractions dropped), not as strings, because `20:44Z` sorts after `20:44:12.345Z` as text.

- Takes the entries with `type == "assistant"`, a `message.usage`, `message.model` other than `<synthetic>` (the rate-limit stand-in), and a `timestamp` inside the window when one is given.
- Counts each `message.id` once, keeping its last entry (a streamed message is written in several entries).
- Sums `input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, `output_tokens` over all files given (several transcripts of one role add up). **peak** is the largest single message's sum of the four.

Stdout, one line:

```
spend <total> (input <i>, cache write <w>, cache read <r>, output <o>); peak <p>; messages <n>
```

The `spend …` part is the record's `<tok>` slot verbatim; `peak` is the Lead's peak context.

| Exit | When | The Lead writes |
|---|---|---|
| 0 | ok | the line |
| 3 | a file is missing, unreadable, or holds a line that is not JSON | `not captured (transcript <file name> unreadable)` |
| 4 | `jq` missing | `not captured (jq missing)` |
| 5 | no assistant message in the window | `not captured (no messages in window)`, never `0` |

Locating transcripts: a role agent's is `find ~/.claude/projects -name 'agent-<agent id>.jsonl'`; the Lead's is `~/.claude/projects/<project>/<session id>.jsonl` for each id under `lead sessions` in the lead state, with `--since` the `Start item` start and `--until` the approval time. Transcripts are deleted after `cleanupPeriodDays` (30 by default), and those written before Claude Code 2.1.307 may hold placeholder usage (#35), which is why the totals are taken at close.

### Worked example

The product-owner of this item (#39), agent `aff847e3e8c7e5bfa`:

```
$ bash plugins/factory/scripts/token-spend.sh ~/.claude/projects/-Users-wimsuenens-Projects-portfolio-agent-plugins/b3146b4a-f9f3-49bc-a33a-9f3c202be9b0/subagents/agent-aff847e3e8c7e5bfa.jsonl
spend 387472 (input 22, cache write 52402, cache read 316497, output 18551); peak 53942; messages 11
```

The peak equals the `53,942` the completion notice reported, as #35 found; the spend is about 7× it.
