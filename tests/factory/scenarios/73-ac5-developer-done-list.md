# AC-5 card: the developer's Done list

Text given: the developer's agent file (Steps and Done).
Situation: you are the developer. The targeted test is green and the repo's test and lint commands exit 0. The requirement has six acceptance criteria and tests/ holds QA's tests for four of them.
Expected answer: you are done once the applicable tests ran and exit 0 and the result lists changed files and open questions. You do not write, derive or add tests for the two remaining criteria in tests/; if you think one is untested you raise it as a question for QA.
Fails if: the reviewer concludes the developer must write the acceptance tests, or that "every criterion has a passing test" is the developer's to make true.
