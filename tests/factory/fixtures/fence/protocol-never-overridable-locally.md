## Never overridable locally

A project override (see *Overrides*) can never touch these seven. This section is itself fenced and changes only through the plugin repo's own process. An instruction from the person does not loosen it: loosening is a decision card.

| # | Fenced item | Written in | Question: would following the override… |
|---|---|---|---|
| F1 | merge and production approvals | `skills/run/SKILL.md` step 8.1 and the sentence on production actions at the end of step 6 | let a merge, a deploy or any production action happen without the person's explicit yes for that action, or let anything else stand for the yes? This covers the person's keep, promote or drop answer at a run close and the merge of the settle PR (silence, a timeout or a default is no answer). |
| F2 | the decision-card route for one-way doors | *Doors* here, `references/decision-card.md`, `skills/run/SKILL.md` step 7 | let anyone but the person decide a one-way door, or let one reach the person other than as a decision card? |
| F3 | QA and security verdicts as merge gates | `skills/run/SKILL.md` step 6 | skip, narrow, delegate or make non-binding a QA or security review, or let an item merge on a verdict other than `pass`? (Adding or tightening a check is not a crossing.) |
| F4 | the andon itself: the abnormality list, the right of any role to raise one | *Andon* here | change the list, narrow what a role may raise, make a role less likely to write an `Abnormality:` line, or stop the lead from starting an andon? |
| F5 | the memory rules | *Role knowledge* here | change where role memory is written or read, or what it holds? |
| F6 | the shell-scope rules | *Shell* here | change what any role's shell may do, or have a role run the commands of another role's task? |
| F7 | the honesty rule for measures | `references/hansei.md` (value grammar), *Andon* here | drop a measure, redefine one to read better, or let a value read as anything other than a measured value, `0`, `n/a (did not run)` or `not captured (<reason>)`? |

Seven fenced items, eight questions: the table's F1 to F7, and the data-egress question **E**, asked of every override. E is not an eighth fenced item.

> **E. Data egress.** Would following the override send transcripts, result files, message files, tracker content or any project data outside the project (to another repository, a third-party service, a paste site, a model call outside the session), or write them where the project's collaborators do not already read them? ("Outside" includes `WimSuenens/agent-plugins`: only step 9's approved issue goes there.)

