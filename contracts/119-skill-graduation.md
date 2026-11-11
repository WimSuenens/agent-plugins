# Contract 119 — Skill graduation into domain plugins

Issue [#119](https://github.com/WimSuenens/agent-plugins/issues/119) · Parent map [#108](https://github.com/WimSuenens/agent-plugins/issues/108) · Builds on [116](116-improvement-loop.md)

Paths:
- plugins/factory/scripts/skill-graduation.sh
- plugins/factory/skills/run/SKILL.md
- plugins/factory/references/protocol.md
- plugins/*/.claude-plugin/plugin.json
- CONTEXT.md
- tests/factory/test_skill_graduation.sh
- contracts/119-skill-graduation.md

## 1. Plugin domain

Every plugin manifest has `"domain"`: one sentence ending in a full stop. Claude Code ignores the field at load time (`claude plugin validate` warns of an unknown field); the factory reads it.

## 2. `scripts/skill-graduation.sh`

| Command | Behaviour | Exit |
|---|---|---|
| `record <skill> <origin>` | appends to `docs/agents/skill-uses.md` (main checkout), once per pair | 0; 2 |
| `eligible <skill> <file>` | at least two distinct origins, then `improvement.sh check`; prints `eligible <sha256>` | 0; 5 threshold; 6 scan |
| `match <domain-text> <plugins-dir>` | the plugin whose domain shares most words (4+ letters, at least two): `match <plugin>: <domain>` or `none` | 0; 2 |
| `draft <skill> <file> <domain-text> <plugins-dir> <out>` | eligible, match, then writes the proposal; nothing written when not offered | 0; 5; 6; 2 |
| `check-proposal`, `submit` | `improvement.sh check` and `submit`: the approval gate | as improvement.sh |

The script never files without `--approved <sha256 of the exact file>`.

## 3. Standard text

Run skill *Skill graduation*; protocol *Role knowledge*: plugin skills are an optional reference in a role file and a missing plugin leaves the factory working.
