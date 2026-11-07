| # | Stage              | Role          | Agents | Result   | Notes          |
|---|--------------------|---------------|--------|----------|----------------|
| 1 | Start item         | lead          | -      | done     |                |
| 2 | Requirement        | product-owner | a1c9e2 | done     |                |
| 3 | Contracts and ADRs | architect     | b7d031 | done     |                |
| 4 | Build              | developer     | c44a10 | done     |                |
| 5 | QA                 | qa-engineer   | d21f77 | findings |                |
| 6 | Andon A1           | lead          | c44a10 | done     | kind 2 …       |
| 7 | Build (round 2)    | developer     | c44a10 | done     | paused by A1   |
| 8 | QA (round 2)       | qa-engineer   | d21f77 | pass     |                |
| 9 | Merge approval     | person        | -      | approved |                |
