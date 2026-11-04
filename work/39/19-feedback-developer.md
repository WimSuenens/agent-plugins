# Feedback: developer — 39
Source: lead (architect contracts round 1, ed0e627)
Findings:
1. plugins/factory/scripts/check-bump.sh — minor — a base (origin/main) version that isn't a strict semver exits 2 (goes to the person); a branch version like 1.08.0 is still refused with exit 1. [overturns your leading-zero-base decision]
2. plugins/factory/references/hansei.md lines ~9, 22, 31 — minor — write `<plugin root>` instead of the literal `${CLAUDE_PLUGIN_ROOT}`, with the existing note that the Lead fills it from the `Plugin root:` line of run/SKILL.md. [overturns your keep-the-literal decision; QA updates its text test]
3. plugins/factory/references/hansei.md Label example (~l.251) — minor — `/Users/p/...` → `~/...` (contract stage-log §1).
4. Check the rest of the build against contracts/39-*.md as of ed0e627 (exit codes and messages in contracts/39-plugin-scripts.md §1–3, common rules: basename-only error messages) and fix any other gap.
Re-verify: tests/run.sh; list any test that now asserts the old text, for QA. Commits `#39 developer: <what>`; result `work/39/20-result-developer.md`.
