# Role file: developer

Project rules, checks and knowledge for the developer role, kept under version control. Only the developer role reads this file and its skills folder, `docs/agents/skills/developer/`.
It may add rules, checks and knowledge. It never lifts a protocol guard, an ownership rule or a one-way-door rule; such a line has no effect and the lead reports it.

## Rules and checks

## Knowledge

- apps/site (Astro 7): when `outDir` lies outside the cwd, Astro writes its prerender temp files to `apps/site/.astro/`, so two builds at once clobber each other; run the site tests with `--test-concurrency=1`. Inline scripts need `is:inline`; `build.inlineStylesheets: "never"` keeps a real `.css` reference. Real `SKILL.md` frontmatter can be invalid YAML (unquoted `: ` in a description); the generator fails on it by contract.

## Skills used

## Migrated memory

<!-- migrated: factory-developer/factory-plugin-gotchas.md -->
---
name: factory-plugin-gotchas
description: Gotchas when editing the factory plugin text (check-bump reads commits, tests pin literal strings)
metadata:
  type: feedback
---

check-bump.sh compares committed state: commit plugin edits before running it, or it reports no bump.
tests/factory/test_standard_text.sh pins literal strings of plugin text (versions, "four" wait kinds, a grep for the repo flag in all plugin files): a standard change breaks QA-owned tests on purpose; list the failing names for QA, do not edit tests/.
**How to apply:** after plugin text edits run `bash tests/run.sh`, report each FAIL as QA's to update.

<!-- migrated: factory-developer/jq-bash-script-gotchas.md -->
---
name: jq-bash-script-gotchas
description: jq `E as $x | body` rebinds the input of body; bash scripts must not write temp files when a contract says stdout/stderr only
metadata:
  type: feedback
---

In jq, `[...] | sort_by(.t) as $ev | body` parses as `[...] | (sort_by(.t) as $ev | body)`, so body's `.` is the sorted array, not the original input. Wrap the source in parentheses: `( [...] | sort_by(.t) ) as $ev | body`. Symptom: the program yields no output and no error.

**Why:** hit building cut-offs.sh (#39): empty output for every transcript until parenthesised.

**How to apply:** any jq program that derives a helper from a side input (`--rawfile`, `--argjson`) before processing the slurped file. Also: to pass big text into jq without ARG_MAX issues use `--rawfile x <(printf ...)`; to capture a child's stdout and stderr without a temp file, `2>&1` and split by line shape.

<!-- migrated: factory-developer/mac-shell-editing-gotchas.md -->
---
name: mac-shell-editing-gotchas
description: macOS/zsh tool quirks when editing big text files and building throwaway fakes for shell scripts (python heredocs, sed -i, call counters)
metadata:
  type: feedback
---

- The Bash tool evals in zsh: a `python3 - <<'EOF'` heredoc holding triple quotes or odd quoting failed with `unmatched '`. Write the python to a file in the scratchpad (Write tool), then run `python3 -I file.py`. Use `rep(old, new)` helpers that `assert old in s` so a drifted anchor fails loudly.
- macOS `sed -i` needs a suffix argument (`sed -i.bak ... && rm file.bak`); a bare `sed -i 's/..'` treats the script as the backup suffix. For multi-line changes use the Edit tool or python.
- A fake `gh` that serves `<op>.<k>.out` by call count keeps `.count.<op>` files: delete them before every run (and after `cp -r` of a fixture dir), or the fixtures drift by one.
- Large contract/standard rewrites: slice by headings with python (`s.index("## N.")`), keep unchanged subsections byte for byte, and grep the result for the retired words afterwards.

**Why:** each cost a failed call or a silently shifted test run in the factory item 64 build.
**How to apply:** any task that edits long markdown standards or tests shell scripts against a fake CLI.

<!-- migrated: factory-developer/ts-test-runners-skip-typecheck.md -->
---
name: ts-test-runners-skip-typecheck
description: vitest (and other esbuild/strip-types runners) do not type-check; tsc --noEmit must run alongside tests
metadata:
  type: feedback
---

vitest strips types and runs: a type error shows up only as a failing (or silently passing) test. Always pair `vitest run` with `tsc --noEmit` in the repo's test/lint command.

**Why:** observed in the #8 stack prototype (2026-10-27): a region passed as brand was caught by tsc but vitest just reported 1 of 5 tests failing.

**How to apply:** when setting up or verifying a TS project, check that CI/test scripts include a typecheck step. Same holds for Python: pytest does not run mypy.
