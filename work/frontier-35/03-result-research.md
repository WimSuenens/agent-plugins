# Result: research — 35
Status: done
Progress:
  Done: brief read; sources gathered (docs + live-session observation); report written and committed (d244262); full findings posted on #35 (https://github.com/WimSuenens/agent-plugins/issues/35#issuecomment-6641160572)
  Next: none — lead closes #35
Summary:
  Q1 tokens per role: capturable. The completion notice's <subagent_tokens> (and sync totalTokens) equals the agent's LAST API call total (≈ final context), not its spend (observed; cumulative is 2–10× higher). Real per-role spend = sum of message.usage in subagents/agent-<id>.jsonl, role from agent-<id>.meta.json agentType (confirmed path + observed fields). /usage and the status line are per session only; OTel labels plugin agents "custom" on metrics.
  Q2 andon: confirmed by docs — TaskStop then SendMessage to the agent ID resumes with full history and the same tool set; a user stop (x in /tasks, Ctrl+X Ctrl+K) cancels for good. In-flight work at the stop is undocumented (not exercised live).
  Q3 stage times: shell `date -u` at brief and result, cross-checked against transcript UTC timestamps and the notice's duration_ms. Usage limits are distinguishable: a background subagent FAILS ("Agent terminated early due to an API error: You've hit your … limit · resets …", synthetic rate_limit/429 entry); the Lead's own session auto-waits and logs "Usage limit reached · continuing automatically at …". StopFailure(rate_limit) and Notification(quota_auto_resume_*) hooks exist.
  Q4 version at runtime: ${CLAUDE_PLUGIN_ROOT} substitutes in skill/agent Markdown (not in Bash env); its basename is the version (today a 12-char repo SHA, e.g. 9147301f75c3). installed_plugins.json / `claude plugin list --json` can lag what the session loaded (observed).
  Q5 update rule: confirmed — updates only when the computed version changes; manifest version > entry version > SHA. Without version, the factory follows the marketplace repo HEAD SHA (observed: even docs-only commits create a new version). With a version in plugin.json, installs stay put until the string is bumped. Auto-update is off for this marketplace by default.
Artifacts: work/frontier-35/02-report-research.md; comment https://github.com/WimSuenens/agent-plugins/issues/35#issuecomment-6641160572
Decisions: none
Open questions:
  - Should the measure "tokens per item per role" be defined as summed transcript usage (spend) rather than the notice's subagent_tokens (peak context)? Report recommends recording both, labelled.
  - Baseline reset on "plugin version change" fires on every repo commit while plugin.json has no version — feeds the ticket "Plugin version and this run's baseline".
  - Unconfirmed: TaskStop's effect on in-flight tool calls/background shells; why a second factory cache dir appeared mid-session.
