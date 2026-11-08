# Result: architect — 64
Status: done
Abnormality: none
Progress:
  Done: findings 1 to 11 settled in contracts; commits "#64 architect: ..." (path grammar, scan, gemba, release decisions)
  Next: none
Summary: Contract text now names every change with a QA-checkable row. Build checklist below (file, place) for the developer's brief; QA's test pins move with item 10.
Artifacts: contracts/64-parallel-slices.md, contracts/64-role-tasks.md, contracts/64-gh-calls.md, contracts/64-ledger-and-fields.md, contracts/64-board-script.md, contracts/64-release.md
Decisions: see release contract section 6 items 23 to 30 (all two-way): review diff command with --no-renames and quotePath=false / ASCII case folding, malformed empty and dot components, directory-without-slash warns / path vs other list's shared entry overlaps (rule 3) / scan covers everything the lead posts, --body-file / grep -E patterns with boundary, canary, extra tokens / cut adds a newline, reported on stderr / rule 5.6 covers parallel-limit and factory-state, role checks brief author and marker / gemba reserve 200, n at most 29,800
Open questions: none

## Contracts changed
parallel-slices (1, 2, 7, 8), role-tasks (3, 4b, 5, 6), gh-calls (3, 4), ledger-and-fields (10, 11), board-script (9), release (decisions).

## Build checklist (developer)
1. Review diff command (parallel-slices §6): `plugins/factory/agents/qa-engineer.md` line 39, `agents/security-reviewer.md` line 39, `skills/run/SKILL.md` line 390, `plugins/wayfinding/skills/wayfinder/SKILL.md` line 159 (Resurvey step 6, `<merge>^1 <merge>` form). Search `plugins/` for `--name-only`: only the two-option form remains.
2. `scripts/paths.sh` (parallel-slices §1, §2): `valid_path` rejects empty, `.`, `..` components (exit 3); fold ASCII case in `covers`/overlap/`check` and `--ignore`; warn on stderr for a slash-less entry naming an existing directory; add overlap rule 3 (path vs other list's shared entry, `adr-number` excluded), order rule 1, 3, 2.
3. Scan everything (role-tasks §9, gh-calls §2): `skills/run/SKILL.md` gets one section *Scan before posting* and each posting step points to it (T-create titles, ledger post/edit, stage summary, hansei post/edit, andon comment, task request, cards, A3, baseline); `references/protocol.md` and `references/decision-card.md` where they name the scan.
4. `skills/setup-factory-skill/references/issue-tracker-github.factory.md` line 32 (Stage summary) and line 47 (Task request): `--body-file` from a scanned scratch file; `T-subissues` command with the `--jq` author filter; add `T-brief`; no `--body "` anywhere.
5. Brief check (role-tasks §3 step 5, §11): spawn prompt carries the lead's login; all seven `agents/*.md` read the brief with `gh issue view <n> --json author,body`, refuse a mismatched author or marker, write `blocked` with `Abnormality: 7 other`.
6. `scripts/post-text.sh scan`: `grep -E` patterns per the table, left boundary on every prefix, new shapes (Google, npm, GitLab, JWT, ghu/ghr), canary self-check exit 2, `--needs-you` also `work/frontier-N/`, `work/settle-N/`, `frontier/N`, `settle/N`; `split` prints `split: details line <n> cut into <k> pieces` on stderr.
7. Rule 5.6 in `skills/run/SKILL.md` line 429: add changes to lines starting `parallel-limit:` or `factory-state:` in `docs/agents/factory.md`, same lead exemption.
8. `plugins/factory/references/hansei.md` line 492 (budget 29,800, 200 kept back), line 532 (`n` at most 29,800), line 595 (contrast example 29800). QA updates `tests/factory/test_gemba.sh` pins of 29900.
9. `plugins/factory/references/baseline.md` line 216: replace "The stage log is gone by then (step 8.6), so the map's section is where this note lives." with the sentence in ledger-and-fields §4 (Baseline update note row).
10. Board exit 6 text (board-script §3 phase 3, exit table, QA row 39): contract only; the build already behaves so; QA row 39 gains case (a) and (b).
