# Security review — #39 hansei record

Reviewer: security-reviewer · Branch `item/39` against `main` (diff `main...item/39`, head `4774b97`) · 2026-11-04

**Verdict: pass.** No critical, high or medium findings. Seven low findings and two informational notes below. None blocks the merge; the developer may fix them in this item or a follow-up.

## Scope

Every changed file was reviewed:

| File | Review focus |
|---|---|
| `plugins/factory/scripts/fingerprint.sh` | input/path handling, quoting, symlinks, exit codes |
| `plugins/factory/scripts/check-bump.sh` | ref/option injection, path classification, exit codes |
| `plugins/factory/scripts/token-spend.sh` | argument parsing, transcript reading under `~/.claude`, what reaches stdout/stderr |
| `plugins/factory/references/hansei.md` | data the record exposes, honesty rule, tracker writes |
| `plugins/factory/skills/run/SKILL.md` | fenced gates (ADR 0011), cross-repo writes, order of close |
| `plugins/factory/skills/setup-factory-skill/references/issue-tracker-github.factory.md` | `gh` commands, record lookup/edit, release tagging |
| `plugins/factory/.claude-plugin/plugin.json` | version field only |
| `CONTEXT.md`, `contracts/39-*.md`, `docs/requirements/39-hansei-record.md`, ADR 0012 edit | secrets and personal data in a public repo |
| `work/39/*` | removed before merge; checked for secrets only |

OWASP categories that apply to local shell tooling: A01 (broken access control: cross-repo writes, gate skipping), A03 (injection: shell and option injection), A04 (insecure design: gate and record integrity), A05 (misconfiguration: temp files), A08 (data integrity: record spoofing, fingerprint honesty), A09 (logging and sensitive data in records). A02, A07, A10 do not apply: no crypto beyond content hashing, no authentication, no network calls in the scripts.

## Dependency audit

- The diff adds or changes no dependency manifest (no `package.json`, lockfile, `requirements*.txt`, `go.mod` or project file). The only manifest in the repo, `plugins/toolkit/skills/source-to-pptx/assets/docker/requirements.txt`, is untouched and out of scope.
- Runtime tools the scripts call: `bash` 3.2.57 (`/bin/bash`), `jq` 1.8.1, `git`, `gh` 2.94.0, `shasum`/`sha256sum`, BSD `sed`/`grep`/`find`. The contract's floor is `jq` 1.6; jq 1.7.0 had CVE-2023-50246/50268 (decNumber), fixed in 1.7.1. The input is the person's own transcripts, so exposure is negligible; noted, no finding.
- No secrets in the diff (grep for token, key and private-key patterns: none).

## Probes run (throwaway copies in the scratchpad, nothing in the repo or `~/.claude` changed)

- fingerprint.sh: unreadable file under `scripts/` (exit 0, see L4); symlink from `references/` to `/etc/hosts` (followed, only its hash is printed); `$(id)` in `version` (rejected, exit 2, never evaluated); missing root (exit 2, absolute path on stderr, see L5).
- check-bump.sh: base refs `--output=/tmp/pwn-sec39` and `-p` (both stop at `rev-parse --verify`, exit 2, no file written); non-ASCII standard-work file with a patch bump (passes, see L1); prerelease version `2.0.0-rc1` (refused, exit 1).
- token-spend.sh: option-like file names (L7); missing file in a private path (stderr shows the basename only); non-JSON line (exit 3); bad `--since` with shell metacharacters (exit 2, not evaluated); bad `timestamp` and non-numeric usage in a transcript (exit 3, never a false `0`).
- Gate review of SKILL.md: QA and security verdicts still gate the merge (step 6.5 unchanged), merge stays behind the person's one approval, a bump-check exit 2 goes to the person, and the honesty rule is reinforced. No new text lets the Lead skip a fenced gate. The only `--repo WimSuenens/agent-plugins` is step 9, behind the person's per-draft approval and now with an explicit "no raw hansei records" rule.
- Data in the hansei record: release, two fingerprints, dependency versions, override names, durations, counts, token totals and Under-test line names. No transcript content, prompts, paths or session ids reach the record template; token-spend.sh prints only totals and, on error, a file's basename.

## Findings

### L1 — `plugins/factory/scripts/check-bump.sh:13` — low — quoted paths escape the standard-work classification

`git diff --name-only` quotes any path with non-ASCII or special bytes (`core.quotePath` default). `"plugins/factory/agents/d\303\251velopeur.md"` starts with `"`, matches no `case` pattern, and the change passes with a patch bump (reproduced: `pass: patch bump needed, 1.0.0 -> 1.0.1`). The poka-yoke ADR 0012 point 5 asks for can be passed by a file name; the standard fingerprint still moves, so detection remains.

Fix: read the list NUL-separated and unquoted, e.g. `git diff -z --no-renames --name-only "$base...HEAD" -- plugins/factory/` and loop with `while IFS= read -r -d '' p`; or, as a fallback, treat any path not positively classified as tooling/other as `minor` (fail closed).

### L2 — `plugins/factory/skills/run/SKILL.md` (Open PR) and tracker patch (*Merge PR*) — low — the bump check is not re-run before the merge

The check runs once, before `gh pr create`. QA, security or docs feedback rounds after that can touch `plugin.json` or standard work, and *Merge PR* then tags `factory-v<version>` from whatever `plugin.json` holds, without a re-check. A patch-level PR whose feedback round edits `agents/*.md` merges with a patch bump; a hand-edited version that is not `MAJOR.MINOR.PATCH` would become a tag name.

Fix: in *Merge PR* step 1 (or SKILL.md step 8.7), run `git fetch origin main` and `check-bump.sh` again before `gh pr merge`, and do not merge or tag on a non-zero exit; tag only when the version matches `^[0-9]+\.[0-9]+\.[0-9]+$`.

### L3 — tracker patch, *Find hansei* — low — any commenter can plant a record

The lookup selects any comment whose body starts with `<!-- factory:hansei v`, whoever wrote it. On a public project, a third party who comments first makes the Lead skip posting and try to edit that comment (a 403, or, with admin rights, an overwrite of someone else's comment), and a later reader that aggregates records ingests the spoofed one. This touches the integrity of the measures the baseline is built on.

Fix: filter on the author as well: `select(.user.login == "<gh api user --jq .login>" and (.body | startswith("<!-- factory:hansei v")))`. Readers that aggregate records apply the same filter.

### L4 — `plugins/factory/scripts/fingerprint.sh:47-50` — low — an unreadable file yields a fingerprint and exit 0

When a file in a set cannot be read, the redirection fails, `bash` prints `Permission denied`, the manifest line holds an empty hash, and the script exits 0 with a 64-hex fingerprint (reproduced). The Lead writes that as measured, which runs against the honesty rule (fenced by ADR 0011): an uncaptured value should read `not captured`.

Fix: check each file before hashing (`[ -r "$root/$rel" ] || { echo "fingerprint: cannot read $rel" >&2; exit 2; }`, propagated out of the pipeline, e.g. with a flag file or by building the manifest in the main shell), so the Lead records `not captured (...)`.

### L5 — `hansei.md` section 1 (`## Label`) and fingerprint.sh stderr; `contracts/39-plugin-scripts.md:171` — low — local paths and ids in tracker and git history

- When fingerprint.sh fails, `not captured (<script's message>)` copies `fingerprint: not a factory plugin root: /Users/<name>/…` into the label and from there into the record's `standard`/`tooling` slots on the project's tracker, which may be public.
- The label's `plugin root` and `lead sessions` lines (home directory and session ids) are committed in `work/<id>/00-lead-state.md`. `work/` is deleted in the last commit, but *Merge PR* uses `--merge`, so those commits stay in the project's history for good.
- The contract's worked example (`contracts/39-plugin-scripts.md:171`) commits this machine's project directory and a real session id to the public agent-plugins repo. The username equals the public GitHub login, so the exposure is small.

Fix: in fingerprint.sh print only `basename "$root"` in the error, or have hansei.md say to use the exit code as the reason (`not captured (fingerprint exit 2)`); in the label write the plugin root as `~/…` (`${root/#$HOME/~}`); in the contract replace the path with `~/.claude/projects/<project>/<session id>/subagents/agent-<agent id>.jsonl`.

### L6 — tracker patch, *Edit hansei* — low — scratch file location unspecified

`<record>.md` is "a scratch file outside the repo" with no location or clean-up. A fixed name in shared `/tmp` can be pre-created or read by another local user, and a leftover file holds the project's record.

Fix: `f="$(mktemp -t hansei.XXXXXX)"`, use it for the fetch and the PATCH, then `rm -f "$f"`.

### L7 — `plugins/factory/scripts/token-spend.sh:44-49,51` — low — option-like file names

A transcript path beginning with `-` (only possible with a relative path) is taken as an option by `basename` and `jq` (reproduced: `basename: illegal option -- n`, exit 3 with an empty file name in the message). Not exploitable, since the paths come from `find ~/.claude/projects`, but the error loses the file name the Lead must record.

Fix: prefix relative arguments with `./` before use (`case "$f" in -*) f="./$f";; esac`), and use `basename -- "$f"`.

## Informational

- I1 — SKILL.md, pre-1.0.0 fallback: for a project whose tracker doc lacks *Post hansei*, the Lead runs the whole item on the plugin's GitHub *Factory operations* instead of the project's own section. Any project-specific tracker rule in that section is set aside for the item. Not a fenced gate (merge still waits for the person), and the person is told; acceptable as written.
- I2 — All tracker commands rely on `gh` resolving the repo from the clone. In a fork with an `upstream` remote and no `gh repo set-default`, `gh` may resolve to the upstream repo, so records and stage summaries could land on someone else's tracker. This predates #39 (stage summaries already work this way). A later slice could have setup-factory-skill run `gh repo set-default`.

## Re-verify

To be filled in after any fixes: rerun the L1 (non-ASCII path), L4 (unreadable file) and L7 (option-like name) probes, and read the changed *Find hansei*, *Edit hansei* and *Merge PR* lines.
