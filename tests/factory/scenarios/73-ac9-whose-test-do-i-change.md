# AC-9 card: whose test do I change, asked in four roles

Text given: protocol, developer, QA and architect agent files, the run skill and the factory.md template, read as each role in turn.
Situation: a test under tests/ looks wrong. Ask it as the lead, the developer, QA and the architect.
Expected answer: the same answer from every file: QA owns tests/ and is the only role that changes them; the developer and the lead ask QA instead (the developer through the lead); the architect fixes a contract, not a test.
Fails if: two files give different answers, a role has to ask to find out, or any file keeps wording that gives the developer the suite ("test first with /tdd" as the way the developer writes the acceptance tests; "has a passing test" as the developer's Done).
