factory-state: 2

# Factory

## Flow table

The points table.

table: provisional
bands: Light 0 to 3, Normal 4 to 5, Heavy 6 or more
floor: never removed by the table: the independent QA verdict, runtime proof and the person's merge approval for protected areas stay.

| Trigger | Points | Adds | Reason | Status |
|---|---|---|---|---|
| Open one-way door | 3 | decision card, ADR (prototype if visual), stays with the person | costs most to undo | provisional |
| Unresolved research question | 3 | research before slicing, map | an unknown fact | provisional |
| More than 3 expected slices, or dependencies between them | 2 | map, frontier round | needs an order | provisional |
| Protected area touched | 3 | security review, test depth at least targeted, the person's merge approval | scan | provisional |
| Contract or interface used by others | 2 | architect, contract file | scan | provisional |
| New logic or data behaviour in a code project | 2 | tests-first (targeted) | code | provisional |
| Visual result | 1 | demo | scan | provisional |
| Deploy, pipeline or production config (project row) | 3 | devops role, environment stage | scan | provisional |

## Run budget

run-budget: none
