# Contract 168 — Strictly valid SKILL.md frontmatter

Issue [#168](https://github.com/WimSuenens/agent-plugins/issues/168) · Found by the build of [#156](https://github.com/WimSuenens/agent-plugins/issues/156); input to the reference generator ([#149](https://github.com/WimSuenens/agent-plugins/issues/149))

## Paths

Paths:
- plugins/factory/skills/obeya/SKILL.md
- plugins/factory/skills/run/SKILL.md
- tests/factory/
shared: plugins/factory/.claude-plugin/plugin.json, CHANGELOG.md

## 1. Decision: quote the two descriptions, change nothing else

Two factory skill files carry an unquoted `description` that contains `: ` (colon, space), which a strict YAML parser reads as a second mapping key and rejects ("mapping values are not allowed in this context"). Fix: wrap each of the two `description` values in double quotes, character for character. Both values contain an apostrophe, so single quotes are not used; neither contains a double quote or a backslash, so no escaping is needed.

Rejected:

- **Block scalar (`description: >-`)**: moves the text to a new line and changes the shape the other 18 files have (one line, key and value together), so a line-based reader (`sed -n 3p`) would break.
- **Rewording to drop the `: `**: changes the description text, which the slice must not do.
- **Fix the generator to tolerate invalid YAML**: the generator should trust a standard parser; a tolerant reader hides the next such fault.

Two-way door: one line per file. Cost to undo: one edit.

## 2. Seam: the frontmatter of every `plugins/*/skills/*/SKILL.md`

The frontmatter is the text between the first line `---` and the next line `---`. After this slice, for every such file:

1. a strict YAML parser reads it without error and returns a mapping;
2. the mapping has a `description` whose value is a string;
3. `name` is a string equal to the skill's directory name;
4. for the two fixed files, the parsed `description` is byte-equal to the text that stood after `description: ` on line 3 before this slice (quotes are syntax, not text);
5. line 3 of each of the two files still starts with `description: ` (key and value on one line), and every other line of both files, including `argument-hint`, `disable-model-invocation` and the body, is unchanged.

Today 18 of 20 files pass; the two failing ones are `plugins/factory/skills/obeya/SKILL.md` (column 133) and `plugins/factory/skills/run/SKILL.md` (column 86).

## 3. Seam QA tests: a script that parses every frontmatter

QA adds a script under `tests/factory/` (name left to QA; `tests/factory/` is the path in the block above) that:

- finds every `plugins/*/skills/*/SKILL.md` (glob, not a fixed list, so a new skill is covered and a moved test dir finds zero files and fails);
- parses each frontmatter with a real YAML parser and checks points 1 to 3 of section 2;
- on a failure prints one line `frontmatter: FAIL <path> <parser message>` (the repo-relative path) and exits 1; on success prints `frontmatter: ok <n> files` and exits 0; finding zero files is exit 1.

Parser: Ruby's `Psych` is on stock macOS (`ruby -ryaml -e 'YAML.safe_load(text)'`) and needs no install; a Python with PyYAML or Node with `yaml` is equally acceptable. The tool is QA's choice (two-way door). Do not hand-roll a check for `: ` in a line: the parser is the test. For point 4, QA compares the parsed `description` of the two files with the pre-slice text read from git (`git show main:<path>`, line 3 after `description: `) or from a fixture copy of those two lines.

Worked example (before the fix, `plugins/factory/skills/obeya/SKILL.md` line 3):

```
description: Start or stop the Obeya, the read-only browser view of this project's factory, in a container on loopback. Needs `obeya: on` in docs/agents/factory.md.
```

fails with `mapping values are not allowed in this context at line 2 column 133` (the `: ` after `obeya`). After the fix:

```
description: "Start or stop the Obeya, the read-only browser view of this project's factory, in a container on loopback. Needs `obeya: on` in docs/agents/factory.md."
```

parses, and the parsed value equals the text between the quotes. Expected run before the fix: two lines `frontmatter: FAIL plugins/factory/skills/obeya/SKILL.md ...` and `... run/SKILL.md ...`, exit 1. After: `frontmatter: ok 20 files`, exit 0.

## 4. Release

The fix is a factory patch release: `plugins/factory/.claude-plugin/plugin.json` `version` from `2.12.2` to `2.12.3`, and a `CHANGELOG.md` entry `## factory 2.12.3` (the lead applies both at merge; the developer does not). The SKILL.md edits are standard work, so the fingerprint moves with a patch as the existing rule allows. No other plugin changes, so no other version moves.

## 5. Other texts that state the version (searched with `grep -rn "2\.12\.2" tests plugins docs CHANGELOG.md`)

The bump makes these pins fail. They are QA's, under `tests/`; QA updates them in the same slice, and the lead applies the bump only with them green:

- `tests/factory/test_gemba.sh:560`, `tests/factory/test_integrator.sh:161`, `tests/factory/test_andon_text.sh:421`, `tests/factory/test_standard_text.sh:20-21`, `tests/factory/test_ownership_tdd.sh:235-236`: hard-coded `2.12.2` against `plugin.json`.
- `tests/factory/test_fingerprint.sh:29-36`: copies the plugin into a directory named `2.12.2` and expects `release: 2.12.2`; the expected release must follow `plugin.json` (the directory name is a fixture and may stay).
- `tests/factory/test_lean_rules.sh:168-169`: reads the newest `## factory 2.12.2` entry of `CHANGELOG.md` for the fingerprints; with a new newest entry it must read the entry that holds them or the new entry's own lines, QA's call.

No text under `plugins/` or `docs/` states `2.12.2` other than `plugin.json`. No test pins the `description` line of the two SKILL.md files (searched `tests/`).

## 6. Acceptance mapping

| Slice behaviour | Where |
|---|---|
| every frontmatter parses with a strict YAML parser | section 2 points 1-3, section 3 |
| descriptions read the same as before | section 2 points 4-5, section 3 |
| shipped as a factory patch release | section 4, section 5 |
