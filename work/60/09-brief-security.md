# Brief: security-reviewer — 60
Goal: Review the new standard text (the gemba walk) before merge.
Inputs: PR for item/60 (diff against main); plugins/factory/references/hansei.md section 6, SKILL.md 8.3a, baseline.md; contracts/60-*.md; docs/requirements/60-gemba-sample.md; docs/adr/0011 (the fence); docs/agents/factory.md; reviews/security-* from items 49 and 57 for the style of earlier findings.
Constraints:
- You own reviews/security-*. Do not edit plugins/, tests/ or docs.
- Look at what the new text lets the Lead read and write: transcript content reaching a tracker comment (prompt injection and data egress: the line must carry a paraphrase, no copied content, within the grammar), the 30,000-character cap and the bounded read commands (shell quoting, path handling, no home paths), whether an agent's transcript text can steer the Lead (read as data only), the andon raised at close (fence, no override written, no commit after approval), the baseline reading a v5 record (a malformed line skipped and named), the "not captured" honesty rule, and ADR 0011's fence still holding.
- Review on paper; no live session is available. Name what is unverified.
Output: reviews/security-60.md; result in work/60/10-result-security.md (Status: working at start). Verdict pass | fail, findings numbered with severity.
Done: every area above covered; verdict; commits start "#60 security-reviewer:".
