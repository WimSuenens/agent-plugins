# Result: developer — 64
Status: done
Abnormality: none
Progress:
  Done: F7 fixed (Overlap paragraph); restatement search run for every rule of build rounds 1 and 2; two further stale statements updated
  Next: none
Summary: The Overlap paragraph of the run skill now states rule 3 and ASCII case folding (r2-run-text-states-folding-and-rule-3 passes). Restatement searches, all `grep -rn` over `plugins/`:
  case: `grep -rniE "case.?(insensitive|sensitive|fold)|exact string|character for character" .` found only paths.sh comments and the Overlap paragraph (now updated).
  overlap/shared: `grep -rnE "shared:|overlap" .` : run SKILL lines 292, 386, 392, 394 and the board.sh/template text say "path overlap" generally and stay (no rule listed). architect.md:25 and SKILL:388 restated the path grammar without the empty/./.. rule and the slash warning: both updated.
  diff command: `grep -rnE "git (-c [a-zA-Z.=]+ )?diff " .` : four places carry the two-option form; check-bump.sh uses -z and stays (NUL output is not quoted).
  body: `grep -rnE -- "--body[ =]|--body\b" . | grep -v body-file` found only the wayfinding tracker doc's Resolve bullet (wayfinding, not a factory posting; stays).
  brief check: `grep -rnE "json body|--jq \.body|brief from that issue|read(s)? (your|the) brief" .` : the remaining `--json body` hits are the lead's own reads (hansei gemba walk lines 488 and 499, Run state, Read baseline) and protocol.md:46 (the lead creating a task); they stay because the check binds roles only.
  budget: `grep -rnE "29,?900|29,?800|30,000|100 characters" .` : only 29,800 and 30,000 remain.
  scan scope: `grep -rniE "scan" . | grep -v ...` : run SKILL 320 and 382, protocol.md:42, decision-card.md and the tracker doc state the full scope; hansei close-scan hits are the cut-off scan, unrelated.
  rule 5.6: `grep -rnE "5\.6|rules-touched|parallel-limit:|factory-state:" .` : SKILL 435 updated in round 2; the rest are config scripts and templates.
  secrets: `grep -rniE "ghp|gh\[|secret pattern|awk interval|intervals|AKIA|xox" . | grep -v scripts/post-text.sh` : no other statement of the patterns.
Artifacts: plugins/factory/skills/run/SKILL.md, plugins/factory/agents/architect.md
Decisions: restated the path grammar in SKILL.md and architect.md, one clause each / left them / one clause to undo.
Open questions: none
