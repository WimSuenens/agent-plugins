# AC-6 card: the slice's deliverable is a test harness

Text given: the developer's agent file and the factory.md template (plugins/factory/skills/setup-factory-skill/assets/factory.md).
Situation: the slice's deliverable is a new test harness for the repo. The lead has to say who writes what.
Expected answer: QA writes the harness and its first cases in tests/; the developer builds what the harness runs; the lead makes no ad-hoc ownership decision. The developer's own unit tests beside the code stay developer-owned and are not the acceptance suite.
Fails if: the developer is told to put harness files under tests/, the lead has to decide ownership on the spot, or the two files disagree.
