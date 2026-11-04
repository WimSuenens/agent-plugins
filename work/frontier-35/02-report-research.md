# Research #35: what the Lead can observe while it runs

Findings for #35 (map #34). Each answer is marked **confirmed** (an official doc says it, cited), **observed** (seen in a live session on Claude Code 2.1.318, VS Code extension, with how), or **unknown** (with what was tried). Observations look only at the structure of local session files, never their content. No project data is included.

Sources used:
- Sub-agents: https://code.claude.com/docs/en/sub-agents
- Costs and `/usage`: https://code.claude.com/docs/en/costs
- OpenTelemetry monitoring: https://code.claude.com/docs/en/monitoring-usage
- Hooks: https://code.claude.com/docs/en/hooks
- Status line: https://code.claude.com/docs/en/statusline
- Interactive mode (usage-limit wait): https://code.claude.com/docs/en/interactive-mode
- Plugin manifest reference: https://code.claude.com/docs/en/plugins-reference
- Plugin loading reference: https://code.claude.com/docs/en/plugins/loading.md
- Host and maintain a marketplace: https://code.claude.com/docs/en/plugins/host-marketplace.md
- Changelog: https://code.claude.com/docs/en/changelog
- Local: `~/.claude/plugins/installed_plugins.json`, `~/.claude/plugins/known_marketplaces.json`, `~/.claude/plugins/cache/wimsuenens/`, `~/.claude/projects/<project>/<session>.jsonl` and `.../<session>/subagents/agent-<id>.jsonl|.meta.json`, `plugins/factory/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`

---

## Q1. Tokens per role

**Answer: yes, tokens per role can be captured, but the number in the completion notice is not what it looks like. The notice gives the subagent's final context size, not the tokens it spent. A cumulative per-role count has to come from the subagent's transcript, or from OpenTelemetry.**

### 1a. What the completion notice carries — observed
A background subagent's completion arrives as a `<task-notification>` with these tags: `task-id`, `tool-use-id`, `output-file`, `status`, `summary`, `note`, `result`, and `usage`. `usage` holds `<subagent_tokens>`, `<tool_uses>` and `<duration_ms>`. Some notices also carry a `<total_tokens>` line with the main session's running total, outside `usage`.
- How: parsed the `<task-notification>` blocks in this project's past session transcripts (`~/.claude/projects/-Users-...-agent-plugins/*.jsonl`).
- A foreground (synchronous) Agent call returns a `toolUseResult` with `agentId`, `agentType`, `resolvedModel`, `status`, `totalTokens`, `totalToolUseCount`, `totalDurationMs`, `toolStats` and `usage` (the API usage object: `input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, `output_tokens`, …). The Lead itself sees only the rendered result text: it gets `agentId` and the usage block, not the raw JSON.
- The sub-agents doc doesn't describe the notice's token fields. It says only that results arrive "as a completion notification" and that "each subagent spends tokens of its own while it runs" (https://code.claude.com/docs/en/sub-agents). **The tag names are observed only, not a documented contract.**

### 1b. What `subagent_tokens` / `totalTokens` mean — observed
For 3 foreground and 8 background agents, the number equals **the token total of the agent's last API call**: input + cache_creation + cache_read + output, which is roughly its final context window. It is **not** the sum over all of its calls.
- How: compared each value with the agent's own transcript in `subagents/agent-<id>.jsonl`, summing the `message.usage` of the distinct assistant messages.
- Examples: Explore `totalTokens` 52,627 = last call 52,627, cumulative 226,772. general-purpose `subagent_tokens` 45,888 = last call 45,888, cumulative 187,933. One long agent: 140,699 against a last call of 138,578 and a cumulative 1,466,997. In a few cases the two differ by a few thousand, likely a final turn not recorded as a separate message.
- Consequence: the notice's number is a fair "how big did the role's context get" measure. It **understates the spend** by 2–10× on cache reads, which dominate.

### 1c. Other per-agent sources
- **Subagent transcripts — confirmed + observed.** "find IDs in the transcript files at `~/.claude/projects/{project}/{sessionId}/subagents/`. Each transcript is stored as `agent-{agentId}.jsonl`." They persist through main-session compaction and are deleted after `cleanupPeriodDays`, 30 days by default (https://code.claude.com/docs/en/sub-agents). Observed: every assistant entry carries `message.usage` (`input_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`, `output_tokens`, plus `cache_creation`, `service_tier`, `speed`, …) and a `timestamp`. A sibling `agent-<id>.meta.json` records `agentType` (for example `factory:product-owner`), `description`, `toolUseId`, `spawnDepth`, `requestShape` (`background`) and `pickedEffortModel`. So **role = `agentType` from the meta file, and tokens = the sum of usage over distinct `message.id`s.** Caveat — confirmed: changelog 2.1.307 "Fixed subagent transcripts recording placeholder token usage and an empty stop reason for streamed responses", so transcripts written before 2.1.307 may hold placeholder usage (https://code.claude.com/docs/en/changelog).
- **`/usage` — confirmed.** The Session block gives totals "Usage by model" (input, output, cache read, cache write, $) for the whole session, **not per subagent**. On subscription plans, a "Plan usage breakdown" gives "recent usage attributed to skills, subagents, plugins, and individual MCP servers, each shown as a percentage of the total", from local history over 24 h or 7 d. That is a share, not a per-item count. The `Prompt cache (main)` line "covers the main conversation only, not subagents" (https://code.claude.com/docs/en/costs). (`/cost` is the older name; the current docs describe `/usage`.)
- **Status line — confirmed.** `cost.total_cost_usd` and `context_window.*` cover the session and the most recent API response. There is no per-subagent breakdown (https://code.claude.com/docs/en/statusline).
- **OpenTelemetry — confirmed.** The metric `claude_code.token.usage` has the attributes `type`, `model`, `query_source` (`main`/`subagent`/`auxiliary`) and `agent.name`. But "Other user-defined agent names are replaced with `"custom"`", so factory roles would all read `custom` on metrics. The event `claude_code.api_request` carries per-request token fields, and events (not metrics) carry `agent_id` and `parent_agent_id` (v2.1.310+) (https://code.claude.com/docs/en/monitoring-usage). It needs a user-configured OTel exporter. The Lead can't read it from inside the session.
- **Hooks — confirmed.** `SubagentStart`/`SubagentStop` input includes `agent_id`, `agent_type` and `transcript_path`. The visible doc shows no token fields (https://code.claude.com/docs/en/hooks). A hook could read the transcript at `SubagentStop` and total it.

### What this means for the factory
**Tokens per item per role can be captured without changing the measure.** Choose the source on purpose:
1. **Cheapest:** record `subagent_tokens` from each completion notice. Label it "peak context per role", not spend.
2. **Spend:** at item close, the Lead (or a small script) totals `message.usage` over `subagents/agent-<id>.jsonl` for each `agentId` it spawned, and takes the role from `agent-<id>.meta.json`. Record input, cache_creation, cache_read and output separately: cache reads dominate, and they are billed and counted against limits differently.
The transcript path is local to the machine running the Lead, so the numbers have to be copied into the hansei comment at close. Transcripts are deleted after 30 days by default.

---

## Q2. Pausing a role (andon)

**Answer: confirmed by docs, not exercised live. The Lead can stop a background subagent with `TaskStop` and later resume it with `SendMessage` to its agent ID or name, keeping its full history. What's lost is the work in flight at the moment of the stop. A user-side stop cancels the agent for good.**

- **Resume after TaskStop — confirmed.** "When Claude sends a completed subagent a message with the `SendMessage` tool, the subagent resumes in the background without a new `Agent` invocation. The same applies to a subagent that Claude stopped with the `TaskStop` tool, once its stopped run has exited. The resumed run keeps the tool set from where the subagent first ran and can keep reading the prompt cache the original run warmed." (https://code.claude.com/docs/en/sub-agents, "Resume subagents")
- **Context kept — confirmed.** "Resumed subagents retain their full conversation history, including all previous tool calls, results, and reasoning." "Resuming starts a new run of the agent under the same ID." Fixed in v2.1.304: before that, an agent "messaged or resumed right after it finished could forget its most recent work" (same page).
- **The trap: who stops it — confirmed.** "A subagent you stopped yourself, with `x` in `/tasks` or an SDK `stop_task` request, doesn't auto-resume. If Claude sends it a message, the message is refused and Claude is told the agent was cancelled." `Ctrl+X Ctrl+K` "Stop[s] all running background subagents in this session" (https://code.claude.com/docs/en/interactive-mode). So if the person stops a role from the UI, the andon can't resume it, and the Lead must re-brief a fresh agent from the result file.
- **What's lost — unknown (not documented).** The docs don't say what happens to an in-flight tool call or a half-streamed turn when `TaskStop` lands. Inferred: whatever the agent hadn't yet written to the transcript or to disk (an unfinished edit plan, an un-committed change, a running background shell it started) is not part of the resumed history. A background Bash command the agent started may keep running, or may be stopped (not confirmed). The protocol's existing rule (result file with `Status: working` and Progress/Next, updated at each checkpoint commit) already covers this loss.
- **Prompt cache — confirmed + inferred.** The resumed run "can keep reading the prompt cache the original run warmed", but caches expire after their TTL, so a long pause re-pays the context as cache writes on resume.
- **Not tried live:** the brief forbids spawning an agent of my own, so stop/resume was not exercised here. In past transcripts the only `stopped` and `killed` notification statuses observed were for background shell tasks, not subagents.

**For the factory:** an andon = `TaskStop <agentId>`, then the Lead writes the 5 Whys and the countermeasure, then `SendMessage` to the same agent ID with the instruction to continue. Keep the agent ID in the stage log. If a resume is refused ("cancelled"), fall back to a fresh brief that points at the role's result file.

---

## Q3. Stage times, and "working" vs "waiting on a usage limit"

**Answer: stamp stages with the Lead's own shell `date -u +%FT%TZ` at each brief and each result, and cross-check against the transcripts' per-entry UTC `timestamp` and the notice's `duration_ms`. A usage-limit wait is distinguishable: it leaves explicit, timestamped records.**

### Clocks available
- **Shell `date` — observed.** The Lead has Bash, so this is the simplest stamp that the Lead controls. It is local wall-clock time, so record UTC.
- **Transcript timestamps — observed.** Every entry in the main and subagent `.jsonl` files has an ISO-8601 UTC `timestamp`. The first and last entries of `agent-<id>.jsonl` bracket a role's run, including any resumes.
- **Completion notice — observed.** `<duration_ms>` in `<usage>` is the run's wall time; for synchronous agents, `totalDurationMs`. One resumed agent produces several notices, one per run (inferred from "Resuming starts a new run of the agent under the same ID" — confirmed, sub-agents doc).
- **Git — inferred/general.** `git log --format=%cI` gives commit time per checkpoint. It is good for cross-checking, but it records only when a role chose to commit, not when its stage started.
- **Tracker — inferred/general.** `gh api` exposes `created_at` on comments and label events, so it suits the person's touches (when a card was posted, when an answer arrived). It is coarse for agent stages.
- **`/usage` — confirmed.** "Total duration (API)" and "Total duration (wall)" exist only per session (https://code.claude.com/docs/en/costs).

### Telling a usage-limit wait from work
- **Background subagent at a limit — observed + confirmed.** "Background: the subagent is marked failed, and the message Claude receives when it ends names the API error and includes the subagent's last output, so partial work isn't lost." (https://code.claude.com/docs/en/sub-agents). Observed: the notice has `<status>failed</status>` and a summary of the form `Agent "<description>" failed: Agent terminated early due to an API error: You've hit your session limit · resets <time>` (or `weekly limit`). The subagent transcript ends with a synthetic assistant entry with `"error":"rate_limit"`, `"isApiErrorMessage":true`, `"apiErrorStatus":429`, `model: "<synthetic>"` and a `timestamp`. **So a background role doesn't wait. It dies, and the Lead must resume it (`SendMessage`) after the reset.** The gap between the failure timestamp and the resume is "waiting on limits".
- **Main session (the Lead) at a limit — confirmed + observed.** In interactive claude.ai-subscription sessions (v2.1.234+), Claude Code waits and continues by itself, recording `Usage limit reached · continuing automatically at <time>` and later `Usage limit reset · Continuing automatically`. After three automatic continuations it stops (https://code.claude.com/docs/en/interactive-mode). Observed in a main transcript: the same synthetic `rate_limit`/429 entry, with its timestamp.
- **Hooks — confirmed.** The `StopFailure` hook fires "When the turn ends due to an API error", with matcher `rate_limit` among others. The `Notification` matchers `quota_auto_resume_fired`, `quota_auto_resume_stale` and `quota_auto_resume_disabled` also fire (https://code.claude.com/docs/en/hooks). A factory hook could append these to a log with `date`.
- **Status line — confirmed.** `rate_limits.five_hour|seven_day.used_percentage` and `.resets_at` (epoch s), for Pro/Max/Ultra (https://code.claude.com/docs/en/statusline). These are visible to a status line script, not to the Lead.
- **Not covered:** time a role spends blocked on a **permission prompt** is not separable from work in the notice's `duration_ms` (inferred). The `Notification` hook's `permission_prompt` and `agent_needs_input` matchers would mark it, if the factory installs such a hook (confirmed that the matchers exist, hooks doc).

**For the factory:** for each stage, log `start` (brief written, `date -u`), `end` (result read, `date -u`), `duration_ms` from the notice, and any `failed … API error: You've hit your … limit` events with their resume time. Agent working ≈ the sum of `duration_ms` across the role's runs. Waiting on limits ≈ failure-to-resume gaps (plus the Lead's own auto-wait lines). Waiting for the person ≈ the tracker timestamps around decision cards and demos.

---

## Q4. Plugin version at runtime

**Answer: the Lead can read it from the path. `${CLAUDE_PLUGIN_ROOT}` is substituted inline in skill and agent Markdown and points at `cache/<marketplace>/<plugin>/<version>/`, so its last path segment is the version. A Bash check is `claude plugin list --json` (`version` field), or `installed_plugins.json`. But the installed record is not always the copy the running session loaded.**

- **Cache layout — confirmed.** "`cache/<marketplace>/<plugin>/<version>/` — One directory per installed version … `<version>` is the resolved version. `${CLAUDE_PLUGIN_ROOT}` points at this directory." (https://code.claude.com/docs/en/plugins/loading.md, "Find plugins on disk")
- **Where `${CLAUDE_PLUGIN_ROOT}` resolves — confirmed.** It resolves in "Skill, command, and agent content: Anywhere in the Markdown body". "The variables aren't present in the environment of commands Claude runs through the Bash tool, in the main session or in a subagent." (https://code.claude.com/docs/en/plugins-reference, "Environment variables"). Observed: this subagent's environment has no `CLAUDE_PLUGIN_ROOT` (`env | grep -i plugin` empty). So the factory's `run/SKILL.md` can contain a line such as "Plugin root: `${CLAUDE_PLUGIN_ROOT}`", and the Lead sees the substituted path with the version as its final segment.
- **What the version looks like today — observed.** This session's Lead loaded `~/.claude/plugins/cache/wimsuenens/factory/9147301f75c3` (seen in its transcript as the skill base directory). `installed_plugins.json` records `"version": "9147301f75c3"` and `"gitCommitSha": "9147301f…"`, and `claude plugin list --json` reports the same `version` and `installPath`. The 12-character value is a marketplace-repo commit SHA, and `git show 9147301` in this repo resolves it to "Merge pull request #33".
- **A mismatch to know about — observed.** The cache also holds `factory/5a136f2eaa0a/`, created during this session (21:02 local time), and a `.in_use/<pid>` marker for this session's PID exists in both `9147301f75c3/` and `5a136f2eaa0a/`. `installed_plugins.json` still says 9147301. Their contents are identical (`diff -rq` empty). Older versions carry `.orphaned_at`. Confirmed rule: "a session that already loaded the old version keeps running", and old directories are removed "14 days later" (loading doc, "Cleanup of previous versions"). **So the version the Lead is running = the `${CLAUDE_PLUGIN_ROOT}` it was given at load, not necessarily what `installed_plugins.json` says now.** Why the second directory appeared without a change to the install record is **unknown**.
- **With a `version` field — confirmed.** The directory and `version` become that string (as `mattpocock-skills/1.3.1` already shows locally — observed), so the hansei record would carry a readable version.

**For the factory:** put `${CLAUDE_PLUGIN_ROOT}` in `run/SKILL.md` and have the Lead record its basename as "plugin version" in the stage log and the baseline. Don't rely on `installed_plugins.json` mid-session.

---

## Q5. Plugin update rule

**Answer: confirmed. Claude Code computes a version and updates only when that computed version changes. With no `version` in `plugin.json` or the marketplace entry, a relative-path plugin in a Git-hosted marketplace is versioned by commit SHA, so it follows every commit. Once `plugin.json` has a `version`, users stay on their cached copy until the string changes, however many commits are pushed.**

- **Rule — confirmed.** "Claude Code computes a version for every plugin it installs, and that version is how it detects an update. `claude plugin update` and background auto-update compute the version again and don't replace the cached copy when it matches what `installed_plugins.json` records." (https://code.claude.com/docs/en/plugins/loading.md, "Versions and updates")
- **Resolution order — confirmed.** "1. The `version` field in the plugin's manifest comes first 2. Then the `version` field in the plugin's marketplace entry 3. When neither is set, the version comes from the source type". For a "Relative path inside a Git-hosted marketplace" that is "The commit SHA of the installed directory". For `github`/`url`/`git-subdir` it is "The commit SHA of the source, shortened to 12 characters" (same section).
- **Version pins — confirmed.** "a manifest that pins `"version": "1.0.0"` keeps every user on the cached copy until its author changes the string, however many commits they push. To let users track commits instead, leave `version` out of both the manifest and the entry." "If you set `"version": "1.0.0"` and push new commits without changing it, users don't receive them." "Don't set `version` in both `plugin.json` and the marketplace entry", because the manifest wins silently (https://code.claude.com/docs/en/plugins/host-marketplace.md, "Release a new version"). The field "Setting it keeps users on that version until you change it" is "not checked against semver" (https://code.claude.com/docs/en/plugins-reference). `claude plugin validate` warns on a missing `version` (same page).
- **Which SHA — observed.** Here the SHA is the **marketplace repo's HEAD at fetch time**, not the last commit that touched the plugin's folder. `wayfinding` was updated to `5a136f2eaa0a`, a commit that changed only `AGENTS.md` and `docs/agents/*`. Cache directories for `toolkit` exist at many repo SHAs although `plugins/toolkit/` last changed in September. So today **every push to agent-plugins, even a docs-only one, is a new version of every SHA-versioned plugin in it.** (The doc's "commit SHA of the installed directory" agrees with this reading, but doesn't spell it out.)
- **When updates happen at all — confirmed + observed.** Background auto-update is "off for every other marketplace" (not Anthropic's) unless the user turns it on. `known_marketplaces.json` for `wimsuenens` here has no `autoUpdate` key (observed), so updates happen only on `/plugin marketplace update wimsuenens` or `claude plugin update factory@wimsuenens`. Even then, a running session "keeps the versions it loaded" until `/reload-plugins` or a restart (loading doc, "When auto-update runs").
- **Exceptions — confirmed.** The manifest `version` doesn't pin a plugin "loaded in place from a marketplace added from a local path" (it always loads current files), a `command`-source plugin, or a plugin from a claude.ai-hosted marketplace (https://code.claude.com/docs/en/plugins-reference, `version`).

**For the factory:**
- **Today (no `version`):** installs follow the repo SHA. A docs-only commit to agent-plugins changes the factory's "version", so a baseline rule "reset when the plugin version changes" would reset on changes that don't touch the standard.
- **Adding `version` to `plugins/factory/.claude-plugin/plugin.json`:** this **does** change how installs update. Users, and every project running the factory, get new factory text only when the string is bumped. Pushes without a bump are invisible to them, and a forgotten bump means a standard change never ships. The upside: the version then names exactly one standard, which suits "every kaizen is a versioned change" and the baseline reset rule.
- Set it in `plugin.json` only, not also in the `marketplace.json` entry. This choice is a release-process decision for the ticket "Plugin version and this run's baseline".

---

## Couldn't confirm
- The documented meaning of `subagent_tokens` and `totalTokens`: the meaning given above is observed only, and the tag names are not documented.
- What `TaskStop` does to an in-flight tool call or a background shell the subagent started. Stop/resume was not exercised live (no agent spawned, per the brief).
- Why a second factory cache directory (`5a136f2eaa0a`) appeared mid-session while `installed_plugins.json` stayed at `9147301f75c3`.
- The full hooks reference (per-event input schemas) and the changelog before 2.1.304: the pages were truncated in fetch, so only the visible parts were checked.
