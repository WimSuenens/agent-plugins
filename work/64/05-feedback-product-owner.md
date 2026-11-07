# Feedback: product-owner — 64
Source: architect
Findings:
1. docs/requirements/64-board-as-run-state.md, AC-6 (and the matching wording around line 94) — low — The filter `status:"Waiting on you"` names the project's unused built-in `Status` field and would match nothing. The contract (contracts/64-board-status.md and 64-board-script.md) uses `factory-status:"Waiting on you"`. Amend AC-6 and any other place in the requirement that quotes the filter to the contract's token. Change nothing else.
Re-verify: grep the requirement for `status:"Waiting on you"` and confirm only the `factory-status:` form remains. Write `work/64/06-result-product-owner.md` (Status, Summary, Decisions) and commit with subject starting `#64 product-owner: `.
