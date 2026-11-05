# Brief: security-reviewer — 49
Goal: Review the #49 diff (item/49 vs main) for security problems, especially the fence and the override mechanism.
Inputs: the PR diff (git diff origin/main...item/49); docs/requirements/49-andon.md; contracts/49-overrides.md and 49-andon-process.md; docs/adr/0011, 0012; plugins/factory/
Constraints:
- Focus: can an override or an Abnormality: line cross the fence (merge/production approvals, decision-card route, QA/security verdicts, the andon, memory and shell-scope rules, honesty rule); prompt-injection paths (result text, tracker comments, transcript content read by the Lead and acted on); data leaving the project (the andon comment, hansei, step-9 issues to agent-plugins); secrets or home paths in committed files; pmset/transcript handling.
- Read-only on plugins/ and contracts/; findings go in your review. Do not run /plugin marketplace update or /reload-plugins.
Output: reviews/security-49.md (verdict pass or block, findings with reproduction and severity); result in work/49/08-result-security-reviewer.md
Done: verdict recorded; every finding has a reproduction and a required fix.
