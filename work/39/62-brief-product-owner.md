# Brief: product-owner — 39
Goal: Write a decision card for the merge style of PR #40 and later factory items (#48), from the architect's options.
Inputs: #48 (`gh issue view 48`); `work/39/60-options-architect.md` (options A/B/C, leaning A, facts: refs/pull/40/head is already public and permanent; one home path in work/39/09-brief-qa-engineer.md; session ids accepted by security); `docs/agents/factory.md` (decision-maker: technical); `${CLAUDE_PLUGIN_ROOT}/references/decision-card.md`.
Constraints:
- Two options on the card (A keep --merge + no absolute home paths in work/; B squash + record cites the PR head sha). C (rebase-merge) appears only as rejected, one line.
- State plainly what is already public and can't be taken back whatever is chosen, and what each option makes permanent on main.
- Lead decision (two-way, put on the card as "same in all options"): the resulting standard change goes into 1.0.0 in this PR, since 1.0.0 isn't tagged yet.
- **Question me** first among the dig-deeper options. No tracker writes.
Output: `work/39/63-decision-merge-style.md`; result `work/39/64-result-product-owner.md` with `Status: needs-decision`. Commit `#39 product-owner: decision card on merge style`.
