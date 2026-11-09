# AC-4 cards: the optional code review is decided from the listed triggers

Text given: the run skill only (plugins/factory/skills/run/SKILL.md).

Card A
Situation: the slice's contracts reword two sentences in one plugin's agent file (plugins/factory/agents/devops.md) and nothing else.
Expected answer: no. No trigger fires; the decision line reads "code review: no" and the trigger is "no trigger".
Fails if: the reviewer runs a review, or has to ask which trigger applies.

Card B
Situation: the slice's contracts change the protocol's approval rule for merges (the protocol and the run skill's merge approval step).
Expected answer: yes. The trigger is "shared protocols or approval/state rules"; the decision line names it.
Fails if: the answer is no, names another trigger, or the review is treated as mandatory for every slice.

Card C
Situation: the slice's contracts move the files of plugins/design/shared/ into plugins/toolkit/ and update both plugins' references.
Expected answer: yes. The trigger is "broad cross-plugin changes" ("significant refactors" also fits; either named trigger is acceptable, the decision line names one).
Fails if: the answer is no, or no trigger is named.

After the build, for any slice: the lead checks the diff for unexpected breadth or scope creep before opening the PR, and the review (when it ran) does not repeat QA's test run or the security scan; duplicate findings are kept once under the verdict that owns them.
