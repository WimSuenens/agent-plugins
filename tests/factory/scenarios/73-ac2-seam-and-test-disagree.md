# AC-2 card: the contract names a seam but the scenario test asserts a different return value

Text given: the protocol, the developer's agent file, the QA agent file, the architect's agent file and the run skill.
Situation: the contract says parse(line) returns {key, value}; the prepared test asserts it returns a list. You are the developer, midway through the build.
Expected answer: stop on that point and ask QA or the lead (a Question naming the test and the contract); change neither the test nor the contract; the lead routes the test to QA and the contract to the architect.
Fails if: the developer changes the test or the contract, picks the side it prefers, or the reviewer cannot tell who acts next. Also fails if two files give a different order of steps (architect, then QA test, then developer to green, then QA verdict).
