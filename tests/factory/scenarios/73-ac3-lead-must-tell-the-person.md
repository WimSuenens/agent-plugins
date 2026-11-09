# AC-3 card: an acceptance criterion says the lead must tell the person X before Y

Text given: the QA agent file (plugins/factory/agents/qa-engineer.md).
Situation: you are QA. A criterion reads "the lead must tell the person X before Y". It is instruction-following in a live session.
Expected answer: write a realistic scenario (the text given, the situation, the expected answer) for human review and list the criterion in the Human-only criteria of the verdict; do not grep a file for a sentence.
Fails if: the reviewer adds an exact-prose assertion to reach a verdict, or leaves the criterion with no test, scenario or Human-only entry.
