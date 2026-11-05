# Contract 39 — Plugin scripts: label, bump check, token spend, cut-offs

Slice [#39](https://github.com/WimSuenens/agent-plugins/issues/39) · Requirement [39-hansei-record](../docs/requirements/39-hansei-record.md) · ADR [0012](../docs/adr/0012-factory-releases-carry-a-semver-and-this-run-is-calibration.md) · Record: [39-hansei-record](39-hansei-record.md)

Four scripts under `plugins/factory/scripts/`. They are **tooling**: covered by the tooling fingerprint, and a change to one alone is a patch release.

Common rules for all four:

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

On branch `item/39` after the build, the release reads `1.0.0`, `standard` differs (new `references/hansei.md`, changed `skills/run/SKILL.md`), and `tooling` differs (four new scripts).

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
- **`--require-end`** (for role-agent transcripts; the Lead never passes it for its own session, which is still running when the script reads it). Each file, read whole regardless of `--since`/`--until`, must show a run that ended by itself and was never cut on the way:
  1. **no cut-off**: `bash "<dir>/cut-offs.sh" -- <file>` (§4; `<dir>` is `token-spend.sh`'s own directory, so the two scripts share one marker test) prints no line whose kind is `stalled` or `interrupted` with a marker other than `silent-gap`. A `limits` line does not count (a refused request spends nothing; a run stopped by a limit and never resumed fails rule 2), nor does a `silent-gap` line (the reply did arrive, and its usage with it). Rule 1 of v2, "no `[Request interrupted` user entry", is one case of this rule (marker `request-interrupted`). When `cut-offs.sh` exits 3 or 4, `token-spend.sh` exits with the same code and the same stderr line: a transcript the marker test cannot read is never passed as complete. And
  2. **a final reply at the end**: among the entries with `type` `assistant` or `user`, the last one is either an `assistant` entry with no `tool_use` content block, or the `user` entry holding the `tool_result` of the agent's hand-back tool call (`tool_use` named `SubagentHandback`), with nothing after it but entries of other types.

  A file that fails either is **truncated**: exit 6, stdout empty, stderr `token-spend: transcript <basename> truncated`. Exit 3 (unreadable) is checked first, then 6, then 5. Without the option the script never checks endings or cut-offs, so the Lead's own window still sums.

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

At close the Lead passes `--require-end` for every role transcript. A role whose transcript was cut by a stall (here the docs-writer of item #12, which stalled after writing its `done` result; the stream watchdog wrote a `[Request interrupted by user]` user entry at the moment of its notice, and the file ends on it):

```
$ bash "$ROOT/scripts/token-spend.sh" --require-end -- agent-e90b55.jsonl; echo "exit $?"
token-spend: transcript agent-e90b55.jsonl truncated
exit 6
```

The Lead finds W4 (`stalled`, agent `e90b55`) in `## Waits` and writes `spend not captured (transcript truncated by stalled)`. A stalled wait alone already decides it (signal a); the exit 6 catches the truncation nobody logged.

The same exit 6 comes for a transcript that **ended normally** on its hand-back but holds a cut-off the agent recovered from (rule 1): the QA agent `d21f77` of item #12 had one mid-stream cut-off at 15:03Z–15:07Z and handed back at 15:10Z. Its `## Waits` entry W6 comes from the close scan ([39-stage-log](39-stage-log.md) §3, *Cut-offs at close*), so its spend reads `not captured (transcript truncated by stalled)`.

## 4. `scripts/cut-offs.sh` — the cut-offs a transcript shows

```
bash <root>/scripts/cut-offs.sh [--since <UTC time>] [--until <UTC time>] [--sleep-log <file> | --sleep-log -] [--] <transcript.jsonl>...
```

Options, times and `--` as `token-spend.sh` (§3); an unknown option is exit 2. Needs `jq`. Reads every file whole; `--since`/`--until` keep only gaps whose **first marker's** `timestamp` lies inside the window (the Lead passes the item's window for its own session, which also holds other work).

**Why a script.** A cut-off, whether the agent recovered from it or not, is visible only in the transcript, and the Lead needs the same answer at a notice, at close, and in QA's replay. One script gives one marker test, shared with `token-spend.sh --require-end`, and a fixture-tested output instead of a jq line in prose. No timestamp the Lead reads by eye.

### Entries and markers

The script reads the entries with `type` `user`, `assistant` or `system`, in file order. A `user` or `assistant` entry without a string `timestamp` makes the file unreadable (exit 3): the rules cannot place it, and the script does not guess.

An entry is a **marker** when the first matching row holds (text = a string `message.content`, or the `text` blocks of an array `message.content` joined):

| # | Entry | Marker name | Kind |
|---|---|---|---|
| 1 | `user` whose text contains `cut off mid-stream` | `cut-mid-stream` | `stalled` |
| 2 | `user` whose text starts with `[Request interrupted` | `request-interrupted` | `stalled` |
| 3 | `assistant` with `isApiErrorMessage == true`, **or** a string `error` field, **or** text matching `^(API Error\|You.ve hit your)` | `api-error:<error, or unknown>` | `limits` when `error == "rate_limit"` or the text starts `You've hit your`; else `interrupted` |
| 4 | `system` with a non-null `error` field (Claude Code's own retry after a dropped connection, `subtype: api_error`) | `api-retry` | `interrupted` |

The test in jq, normative (the developer copies it):

```jq
def txt: if (.message.content | type) == "string" then .message.content
         else ([.message.content[]? | select(.type == "text") | .text] | join("")) end;
def mark:
  if .type == "user" and (txt | test("cut off mid-stream")) then ["stalled", "cut-mid-stream"]
  elif .type == "user" and (txt | startswith("[Request interrupted")) then ["stalled", "request-interrupted"]
  elif .type == "assistant" and (.isApiErrorMessage == true or ((.error // null) | type) == "string"
                                 or (txt | test("^(API Error|You.ve hit your)")))
    then [ (if (.error // "") == "rate_limit" or (txt | test("^You.ve hit your")) then "limits" else "interrupted" end),
           ("api-error:" + ((.error // "unknown") | tostring)) ]
  elif .type == "system" and (.error // null) != null then ["interrupted", "api-retry"]
  else null end;
```

### Gaps

- **Start** of a marker's gap: the `timestamp` of the last `user` or `assistant` entry **before** the marker that is not itself a marker. This is the moment the agent last showed progress, never the notice: the watchdog writes its `[Request interrupted by user]` entry at the notice (QA-39 v2 F1), so the file's last line is the wrong one. When there is no such entry, the marker's own `timestamp`.
- **End**: the `timestamp` of the first `assistant` entry **after** the marker that is not itself a marker (the agent producing output again, whether it recovered by itself or the Lead resumed it). `open` when there is none: the run stopped there, and the Lead's own action ends the wait ([39-stage-log](39-stage-log.md) §3).
- **One gap per start.** Markers whose start is the same entry form one gap (a sleep error, then a retry, then a cut-off). Its kind is the strongest of theirs, in the order `limits`, `interrupted`, `stalled`; its markers are listed, sorted and comma-separated.
- **Silent gap** (the fail-closed net, below): a `user` entry carrying a `tool_result` block, followed by an `assistant` entry as the next `user`/`assistant` entry, 600 s or more later, with no marker between. After a tool result the model must answer; ten minutes of nothing is the watchdog's own window. Kind `stalled`, marker `silent-gap`, start the tool result, end the assistant entry. A gap after an assistant's end-of-turn text or after a new prompt is idle time, not a silent gap, and is never reported.
- **Sleep.** With `--sleep-log`, a `stalled` gap whose machine was asleep at any moment of [start, end] (end = the last marker's time when `open`) is reported as `interrupted`: a `Sleep` line inside the gap, or the last `Sleep`/`Wake` line before the start is `Sleep`. The log is the output of the exact filter `pmset -g log | awk -F'\t' '$1 ~ /^[0-9-]+ [0-9:]+ [+-][0-9]+ (Sleep|Wake) *$/ {print $1}'` (only `<local date> <local time> <offset> Sleep|Wake`; `DarkWake` and every other pmset line are left out), piped in with `--sleep-log -`. Each line's offset is applied, so the comparison is in UTC. Lines that don't match `YYYY-MM-DD HH:MM:SS ±HHMM Sleep|Wake` are skipped and never echoed. An unreadable `--sleep-log` file is exit 3. `limits` and `interrupted` gaps keep their kind. Without the option, no gap changes kind (the rule in [39-stage-log](39-stage-log.md) §3 then says the notice alone decides).

### Output

One line per gap, sorted by start, tab-separated, no header:

```
<transcript basename>	<kind>	<start YYYY-MM-DDTHH:MM:SSZ>	<end YYYY-MM-DDTHH:MM:SSZ | open>	<markers>
```

Fractions of seconds are dropped. No message text, no path, no pmset line reaches stdout or stderr (common rules; L10). No line at all is a valid result: the transcript shows no cut-off.

| Exit | When | The Lead does |
|---|---|---|
| 0 | ok, zero or more lines | logs or reconciles each line ([39-stage-log](39-stage-log.md) §3) |
| 2 | bad usage | fixes the call |
| 3 | a transcript missing, unreadable, not JSON, or with a `user`/`assistant` entry lacking a `timestamp`; or the sleep log unreadable; stderr names the file by basename | writes in that wait's `What`, or in the cross-check, `cut-offs not captured (transcript <basename> unreadable)`; the role's spend then fails `--require-end` with exit 3, so it reads `not captured (…)` |
| 4 | `jq` missing | as 3, `jq missing` |

### Undocumented fields, and failing closed

Every signal here (`isApiErrorMessage`, `error`, `isMeta`'s cut-off text, the `[Request interrupted` text, `system` entries' `error`, `model: "<synthetic>"`) is an undocumented Claude Code transcript detail. They were read from real transcripts written by Claude Code 2.1.287 (factory-sandbox #2's Lead session and agents `a37df3717d6edee1d`, `a85f55ebb2244ed91`) and checked against the 433 transcripts on the person's machine from the 30 days before 2026-11-05. A later Claude Code can change them without notice. The rules are built to fail towards *stalled* and *not captured*, never towards *agent working* and a number:

- **Independent signals.** A marker matches on a flag **or** a field **or** a text; renaming one leaves the others.
- **The silent-gap net.** A stall whose marker is no longer recognised still shows as a tool result followed by ten minutes of nothing, and lands in `stalled`. What it misses is a cut-off shorter than ten minutes with an unknown marker; the demo's shortest was 6m47s, which marker 1 catches.
- **Any cut marks spend truncated** (§3 rule 1), even when the run ended normally. The record then shows `not captured` for a role whose spend might have been right, rather than a number that is short.
- **Unreadable is not clean.** A file the script cannot read gives exit 3 and `not captured`, never "no cut-offs".
- **The fixture is the canary.** QA's fixtures copy the demo's real shapes. When a Claude Code upgrade changes them and the real transcripts stop matching, the replay QA runs on a release finds it.

### Worked example: the acceptance demo's transcripts (factory-sandbox #2)

The developer (`a37df…`), the first QA agent (`a85f55…`), and the Lead's session over the item's window, with the machine's sleep log:

```
$ pmset -g log | awk -F'\t' '$1 ~ /^[0-9-]+ [0-9:]+ [+-][0-9]+ (Sleep|Wake) *$/ {print $1}' \
    | bash "$ROOT/scripts/cut-offs.sh" --sleep-log - -- agent-a37df3717d6edee1d.jsonl agent-a85f55ebb2244ed91.jsonl
agent-a37df3717d6edee1d.jsonl	interrupted	2026-11-04T23:50:46Z	open	request-interrupted
agent-a85f55ebb2244ed91.jsonl	interrupted	2026-11-05T00:08:06Z	2026-11-05T00:14:53Z	cut-mid-stream
agent-a85f55ebb2244ed91.jsonl	interrupted	2026-11-05T00:14:53Z	2026-11-05T00:32:26Z	cut-mid-stream
agent-a85f55ebb2244ed91.jsonl	interrupted	2026-11-05T00:32:26Z	2026-11-05T00:48:37Z	cut-mid-stream
agent-a85f55ebb2244ed91.jsonl	interrupted	2026-11-05T00:48:37Z	2026-11-05T01:04:31Z	api-error:server_error
agent-a85f55ebb2244ed91.jsonl	interrupted	2026-11-05T01:05:29Z	2026-11-05T01:21:45Z	api-error:server_error
agent-a85f55ebb2244ed91.jsonl	interrupted	2026-11-05T01:25:07Z	open	request-interrupted
$ bash "$ROOT/scripts/cut-offs.sh" --since 2026-11-04T21:52Z --until 2026-11-05T07:08Z -- 61c45656-95a0-41df-8e1d-1d321cad55d4.jsonl
61c45656-95a0-41df-8e1d-1d321cad55d4.jsonl	limits	2026-11-04T22:02:06Z	2026-11-04T23:49:48Z	api-error:rate_limit
61c45656-95a0-41df-8e1d-1d321cad55d4.jsonl	interrupted	2026-11-05T01:43:18Z	2026-11-05T06:49:32Z	api-error:server_error
```

Without `--sleep-log` the three `cut-mid-stream` lines and both `request-interrupted` lines read `stalled` (the `api-error` lines are `interrupted` either way): the machine went to `Sleep` at 22:13Z and had only dark wakes until its `Wake` at 06:49Z, so every stall that night happened while it slept. The developer's gap starts at its last tool result (23:50:46Z), not at the watchdog's entry (00:05:54Z). The QA's five recovered cut-offs, 00:08Z–01:21Z, are 72 minutes the v2 text put in agent working. The Lead's own 5-hour gap is found from its `API Error` entry. Agent ids and session ids may appear in the output (L5): they are random and locate a file on this machine only.
