# Brief: research — 35
Goal: Answer the five fact questions in ticket #35 ("What the Lead can observe while it runs") with sourced findings.
Inputs: #35 (read it with `gh issue view 35`); map #34 Destination and Decisions so far (`gh issue view 34`); the factory plugin in this worktree (`plugins/factory/`); the live install cache at `~/.claude/plugins/cache/wimsuenens/` and `~/.claude/plugins/` metadata (read-only).
Constraints:
- Follow `/research` source rules: high-trust primary sources (official Claude Code docs at code.claude.com / docs.anthropic.com, the Claude Code changelog, plugin/marketplace reference). Cite every claim with a URL or a local file path; mark anything inferred or observed-only as such, and say what you could not confirm.
- You may observe your own session (e.g. what your own environment exposes, `${CLAUDE_PLUGIN_ROOT}`-style paths, the plugin cache layout and installed_plugins metadata). Do not change any plugin installation or setting.
- Spawn no background agent of your own. Do not create a `research/` branch.
- No project data or personal data in the findings.
Output:
- Report: `work/frontier-35/02-report-research.md` in this worktree (branch `frontier/34`), committed with message `#35 research: findings on what the Lead can observe`.
- Post the **full findings** (not a summary) as a comment on #35 with `gh issue comment 35 --body-file work/frontier-35/02-report-research.md`. Do NOT close the issue; the lead closes it.
- Result: `work/frontier-35/03-result-research.md` using the protocol's Result template (Status, Progress, Summary ≤10 lines, Artifacts, Decisions, Open questions), committed.
Done:
- Each of the five questions has an answer marked confirmed (with source), observed (with how), or unknown (with what was tried).
- For Q1 and Q5 especially, state plainly what this means for the factory: can tokens per role be captured, and does adding a `version` to plugin.json change how installs update.
- The comment on #35 holds the full findings.
