# Scenario cards for slice 73 (human review)

Instruction-following cannot be decided by a script. Each card gives the text a reader sees, a situation, and the answer the reader should reach. A reviewer (a person, or an agent that reads only the named files) plays the situation against the text and compares the answer.

Card format: `Text given:` (the only files the reviewer may read), `Situation:`, `Expected answer:`, and `Fails if:` (what counts as a wrong answer). The cards are written from the acceptance criteria and the contracts, not from the finished text.

Cards: 73-ac1, 73-ac2, 73-ac3, 73-ac4 (three cards), 73-ac5, 73-ac6, 73-ac9. They are listed as Human-only criteria in QA's verdict. `tests/factory/test_ownership_tdd.sh` checks only that each card exists and has its parts.
