# Result: architect — 60
Status: done
Progress:
  Done: contracts written and committed (769e942, 88274bf); CONTEXT.md *Gemba* added
  Next: none
Summary: Four contracts: 60-gemba-sample (rule, worked example), 60-gemba-walk (evidence, cap commands, comparison, 5 Whys path), 60-gemba-line (v5 grammar, baseline reading), 60-standard-changes (files, release, QA test list T1-T13, AC map, decisions). Walk = step 8.3a / hansei.md 5 item 3a, procedure once in new hansei.md section 6. 5 Whys = kind 7 andon, no paused agent, no wait (lead time ended at approval), no override. Bounded read = text, no script; only the standard fingerprint moves. Baseline reads v3, v4, v5; v5 without exactly one gemba line is skipped. No ADR: no one-way door. Release 1.3.0: plugin.json is the only file the bump check needs to move; check-bump.sh must pass.
Artifacts: contracts/60-gemba-sample.md, contracts/60-gemba-walk.md, contracts/60-gemba-line.md, contracts/60-standard-changes.md, CONTEXT.md
Decisions:
  D1 walk numbered 8.3a / rejected renumbering 8.4 to 8.12 (about twenty citations) / undo: renumber at next close rewrite
  D2 eligibility by lowercased prefix, `paused by A<digit>`, log listing order / rejected sort by `#`, exact match / one rule
  D3 walk's 5 Whys = kind 7 andon, no wait, no override / rejected own comment, andon wait, override after approval / one sentence
  D4 cap counts the brief too; m = brief + whole view / rejected cap on evidence only / one number
  D5 filter keeps final reply as a claim (1500 chars), calls (300), results first line (200) / rejected dropping it, treating it as evidence / edit filter
  D6 transcript or commits per row, never mixed / one rule
  D7 brief and result file found by ordinal, commits by role + subject + window to the role's next row / rejected timestamp match / one rule
  D8 first difference by brief order in the line, rest in the chain / one rule
  D9 `changes`: `process item:` outside the plugin root, `none: needs a plugin change` inside; plugin case has no link / one rule
  D10 baseline presence check of the gemba line (not a field read) / rejected no check, parsing / drop one item
  D11 `records:` line names every schema held / one line
  D12 `partial (cap)` only reason / one grammar line
Open questions:
  - The reference jq filter (contracts/60-gemba-walk.md section 3) is written from the transcript shape the scripts already read; I could not run it. The developer should run it once on a real transcript and say so in the result (unverified item 3 stays).
  - QA/test-replay: baseline_replay.py reads only the presence of a gemba line, never content (contract 60-gemba-line section 4.3).
  - Proposal to docs-writer for docs/factory/reference.md, CHANGELOG.md, README.md: contracts/60-standard-changes.md section 9.
Missing: none
