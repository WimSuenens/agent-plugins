# Contract 110 — Inbox, idea command and triaged intake

Issue [#110](https://github.com/WimSuenens/agent-plugins/issues/110) · Parent map [#108](https://github.com/WimSuenens/agent-plugins/issues/108) · Revises [ADR 0015](../docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md) (the `Kind` vocabulary)

Paths:
- plugins/factory/scripts/intake.sh
- plugins/factory/scripts/board.sh
- plugins/factory/skills/idea/SKILL.md
- plugins/factory/skills/run/SKILL.md
- plugins/factory/skills/setup-factory-skill/
- plugins/factory/.claude-plugin/plugin.json
- docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md
- CONTEXT.md
- tests/factory/
- contracts/110-idea-intake.md
- CHANGELOG.md
- README.md

## 1. What an idea is

A tracker issue with the label `idea`. Filed with `/factory:idea`, with a plain tracker issue carrying the label (no factory needed), or from the inbox. The kind `idea` joins `Kind` (map, slice, role task, frontier ticket, idea).

## 2. `scripts/intake.sh`

| Command | Behaviour | Exit |
|---|---|---|
| `dir` | prints `.claude/factory-inbox` | 0 |
| `init` | creates the folder and adds `/.claude/factory-inbox/` to the main checkout's `.gitignore`; `created` or `already present`; idempotent | 0 |
| `file <title> [<body-file>]` | scans, then creates one issue with label `idea` (body marker `<!-- factory:idea -->`); prints the URL | 0; 2 usage; 4 gh failed; 6 scan refused |
| `drop` | each regular, non-dot text file of the folder (no NUL, at most 60000 bytes) becomes one `idea` issue and is then removed; a file of one URL becomes `Reference: <url>`; the body carries `<!-- factory:inbox <sha256> -->` and an existing issue with that marker is reused, so a retry or a second run creates nothing new. A file that cannot be carried (binary, too large, symlink) or that the scan refuses is **kept** and reported; nothing is removed that did not reach the tracker | 0; 4 gh failed; 5 some file kept |
| `untriaged` | open `idea` issues with no outcome comment of the lead, `<n>\t<title>\t<new\|waiting>`; `waiting` = an open needs-you comment | 0 |
| `triage <n> <outcome> <reason-file>` | posts `<!-- factory:triage v1 -->` with the outcome and reason; outcome is one of `direction`, `slice-candidate`, `research-ticket`, `parked`, `rejected`; `rejected` also closes the issue as not planned; the text is scanned first | 0; 2 usage, bad outcome, empty reason; 4 gh failed; 6 scan refused |

Only the lead's own comments count as an outcome (a forged marker from another login does not). Attachments are not uploaded: a file the body cannot carry stays and the person hosts it and drops a link.

## 3. Standard text

`skills/run/SKILL.md`, `## Idea intake`: drop, list, triage by the upstream triage skill read by hand, the five outcomes each with a reason, the one-way-door rule (decision card, not decided by the lead), record, and the run-start rule (step 0: items not triaged are handled at the next run start). The `Kind` table and rule and the status table name `idea`. `skills/idea/SKILL.md` is the command. `setup-factory-skill` step 8b asks before it runs `init`; step 7 point 8 covers the board option.

## 4. Board

`board.sh` creates `Kind` with `idea` on a new board; the template Kind table has an `idea` row. An existing board gets the option by hand (setup step 7); until then ideas stay off the board.

## 5. Release

Standard work: a minor release, `2.4.0` to `2.5.0`. No `factory-state` change.

## 6. Tests

`tests/factory/test_idea_intake.sh`: the scripts seam against `tests/factory/stub-gh` (every command, idempotence, removal, kept files, retry after a failure, forged markers) and the standard-text seam (outcomes, the one-way-door rule, run start, kind vocabulary, glossary, setup).
