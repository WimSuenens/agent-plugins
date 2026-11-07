# Brief: product-owner — 57 (requirement amendment 2)

Goal: One wording fix so the requirement and the contract say the same.

Inputs: `docs/requirements/57-per-run-a3-and-baseline.md` AC-14; `reviews/qa-57.md` observation R2-O4; `contracts/57-a3.md` §6 rule 3 (after-items: a run-list record carrying the experiment for the whole item is an after-item whatever its series; the series test is for before-items only).

Required: AC-14 says an item of another series is in neither reading. Change it to say what §6 says: another series' item is a before-item never, and an after-item when it is in the run list and carries X for the whole item. Touch nothing else; keep the Under test table and the demo script consistent. No home path. Commit `#57 product-owner: ...`. Result `work/57/25-result-product-owner.md` (start with `Status: working`).

Done: AC-14 aligned with the contract; the changed line named in the result.
