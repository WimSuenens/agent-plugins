# Contract 116 — Improvement loop: local or fundamental

Issue [#116](https://github.com/WimSuenens/agent-plugins/issues/116) · Parent map [#108](https://github.com/WimSuenens/agent-plugins/issues/108) · Revises [ADR 0011](../docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md) and the glossary terms Override and Local countermeasure

Paths:
- plugins/factory/scripts/improvement.sh
- plugins/factory/skills/run/SKILL.md
- plugins/factory/references/protocol.md
- docs/adr/0011-local-countermeasures-stop-at-a-wide-fence-and-end-with-their-run.md
- CONTEXT.md
- tests/factory/
- contracts/116-improvement-loop.md

## 1. The test

Every finding is classified: would this hold in a project with a different stack, business and person? No: project-local. Yes: factory-fundamental. The class and its reason are posted on the finding's issue (`<!-- factory:finding v1 -->`).

## 2. `scripts/improvement.sh`

| Command | Behaviour | Exit |
|---|---|---|
| `classify <issue> <local\|fundamental> <reason-file>` | posts the finding comment; reason non-empty and scanned | 0; 2 usage; 6 scan; 4 gh |
| `trace <name> <role> <measure\|none> <before> <what> <why>` | appends a row to `docs/agents/improvements.md` (main checkout), scanned, unique name | 0; 2; 6 |
| `report <readings.json>` | one line per row: `<name>: <measure>: before <b> / after <a>`; unread or null reads `not captured` | 0; 2 |
| `check <file>` | sanitising scan: post-text scan, project name, URL, `#<n>`, code fence; prints `clean <sha256>` | 0; 6 |
| `submit <file> [--approved <sha256>]` | files the proposal in `FACTORY_MARKETPLACE_REPO` (default the marketplace) only with the sha256 of the exact text; once per text | 0; 7 no approval; 6; 4 |

## 3. Persistence and measure

A project-local improvement lives in the role files and `docs/agents/improvements.md`; nothing in them expires. The fence binds them. The next cycle's `report` is the before and after.

## 4. Unchanged

The andon, the A3, the baseline and the override settle round work as before.

## 5. Tests

`tests/factory/test_improvement.sh`: the script seam (scan, approval gate, trace, report against a stub gh) and the standard-text seam (classification test, permanence).
