# Brief: product-owner — 49
Goal: Turn slice #49 (Andon) into a requirement with testable Given/When/Then criteria, one per Under-test line that would show a contradiction.
Inputs: tracker issues #49 (slice frame), #34 (map: Destination, Decisions so far, Deferred, Not yet specified), #37 (fence, ADR 0011), #35 (pause/resume findings), #39 (hansei slice, for the stage-log and hansei record this slice extends); docs/requirements/39-hansei-record.md; docs/adr/0011, 0012, 0013; docs/agents/factory.md
Constraints:
- Pre-release factory 9147301f75c3 is installed and frozen; the slice changes plugins/factory/ in the worktree and is demoed with `claude --plugin-dir`, not an install.
- Fix contract text before code: criteria must let QA validate any detection rule on the data that showed the defect (the five "same finding twice" abnormalities of #39), run by QA or the developer, not the architect.
- "Blame the process first": a criterion must show the 5 Whys cannot end in swapping a model or role before the process is examined.
- An override that crosses the ADR 0011 fence is itself an abnormality; the Lead checks it before writing it to docs/agents/factory.md.
- The 2x-usual-time test has no baseline yet: decide in-slice (item's own earlier stage rows, or leave out until a baseline exists); a two-way door, list it in Decisions.
- No absolute home paths in work/ or docs. Nothing from the sandbox repo lands here. No project data.
- Out of scope: everything under "Deliberately faked" in #49.
Output: docs/requirements/49-andon.md; result in work/49/02-result-product-owner.md
Done: every criterion can be turned into a test by QA without a clarifying question; every Under-test line of #49 maps to a criterion.
