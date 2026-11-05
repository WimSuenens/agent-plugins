# Feedback: qa-engineer — 39
Source: lead (final round)
Findings: verify the final build (57b7592 + 'basename -- in all scripts') against contracts dbfc448/ce920d4 and ADR 0013.
1. Move the close-* assertions listed in work/39/68-result-developer.md to the new wording ("${w:?}", ':(glob)', git clean -f -d -x -q + `[ ! -e`); keep extracting and running the commands from hansei.md as ONE shell call, adding a nested-repo case (stops, nothing committed) and a `03-dump/` case (not staged, removed).
2. Flip `sleep-wake-inside-alone-not-asleep` to expect `interrupted` (F5 settled in the contract).
3. Tests for the I4 whitelist (`other` for a non-matching code) and the protocol path rule's text; a check that the security-reviewer agent carries the checklist line.
4. Re-confirm AC-17 still passes on the demo replay.
Re-verify: full suite; final verdict in reviews/qa-39.md with the fingerprint at HEAD. Commits `#39 qa-engineer: <what>`; result `work/39/70-result-qa-engineer.md`. Security commits in parallel: touch only tests/ and reviews/qa-*; retry on index.lock.
