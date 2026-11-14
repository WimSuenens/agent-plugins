#!/bin/bash
# The run as a cycle. Issue #111, ADR 0017.
# Two seams: the scripts (factory-config.sh budget and reached, paths.sh overlap) and the standard text.
. "$(dirname "$0")/lib.sh"
FC="$PLUGIN/scripts/factory-config.sh"; PS="$PLUGIN/scripts/paths.sh"
RUN="$(run_all_file)"
SU="$PLUGIN/skills/setup-factory-skill/SKILL.md"
TPL="$PLUGIN/skills/setup-factory-skill/assets/factory.md"
f() { printf '%b' "$2" >"$T/$1"; }

# --- scripts seam: no slice maximum is read
f lim 'factory-state: 2\nparallel-limit: 1\n'; flow_table_text >>"$T/lim"
bash "$FC" state "$T/lim" >/dev/null 2>"$T/e"; ck old-limit-state-exit-0 0 "$?"
ck old-limit-note "yes" "$(grep -q 'parallel-limit line; it is ignored' "$T/e" && echo yes || echo no)"
f nolim 'factory-state: 2\n'; flow_table_text >>"$T/nolim"
ck no-limit-no-note "" "$(bash "$FC" state "$T/nolim" 2>&1)"
bash "$FC" limit "$T/lim" >/dev/null 2>&1; ck limit-command-gone 2 "$?"
f bad 'factory-state: 2\nparallel-limit: zero\n'; flow_table_text >>"$T/bad"
bash "$FC" state "$T/bad" >/dev/null 2>&1; ck bad-old-limit-still-ignored 0 "$?"
ck old-limit-does-not-change-budget "none" "$(bash "$FC" budget "$T/lim")"

# --- scripts seam: reading the budget
ck budget-absent "none" "$(bash "$FC" budget "$T/nolim")"
f b1 'run-budget: none\n';          ck budget-none "none" "$(bash "$FC" budget "$T/b1")"
f b2 'run-budget: 500000 tokens\n'; ck budget-tokens "500000 tokens" "$(bash "$FC" budget "$T/b2")"
f b3 'run-budget: 8 hours  \n';     ck budget-hours-trailing-space "8 hours" "$(bash "$FC" budget "$T/b3")"
for bad in "0 hours" "-1 hours" "5 minutes" "5" "hours" "" "1.5 hours" "05 hours" " 5 hours"; do
  f bb "run-budget: $bad\n"
  bash "$FC" budget "$T/bb" >/dev/null 2>"$T/e"; ck "budget-bad-[$bad]-exit-5" 5 "$?"
done
ck budget-bad-names-line 'factory.md line "run-budget: 5 minutes": run-budget must be none, or a whole number of 1 or more followed by tokens or hours' "$(f bb 'run-budget: 5 minutes\n'; bash "$FC" budget "$T/bb" 2>&1)"
f b4 'run-budget: 1 hours\nrun-budget: 2 hours\n'; bash "$FC" budget "$T/b4" >/dev/null 2>&1; ck budget-doubled-exit-5 5 "$?"
f b5 '  run-budget: 9 hours\nNote: run-budget: 9 hours\n'; ck budget-indented-and-quoted-not-matched "none" "$(bash "$FC" budget "$T/b5")"
bash "$FC" budget "$T/none-such" >/dev/null 2>&1; ck budget-missing-file-exit-2 2 "$?"
ck budget-env-var-ignored "none" "$(RUN_BUDGET=3 FACTORY_RUN_BUDGET=3 bash "$FC" budget "$T/nolim")"

# --- scripts seam: reaching it
bash "$FC" reached 10 "$T/nolim"; ck reached-no-budget-never 0 "$?"
bash "$FC" reached 99999999 "$T/b1"; ck reached-none-never 0 "$?"
bash "$FC" reached 499999 "$T/b2"; ck reached-below 0 "$?"
bash "$FC" reached 500000 "$T/b2"; ck reached-at 1 "$?"
bash "$FC" reached 600000 "$T/b2"; ck reached-above 1 "$?"
bash "$FC" reached 7 "$T/b3"; ck reached-hours-below 0 "$?"
bash "$FC" reached 8 "$T/b3"; ck reached-hours-at 1 "$?"
bash "$FC" reached 0 "$T/b3"; ck reached-zero-spent 0 "$?"
bash "$FC" reached x "$T/b3" >/dev/null 2>&1; ck reached-bad-spent-exit-2 2 "$?"
bash "$FC" reached "" "$T/b3" >/dev/null 2>&1; ck reached-empty-spent-exit-2 2 "$?"
bash "$FC" reached 3 "$T/bb" >/dev/null 2>&1; ck reached-bad-budget-exit-5 5 "$?"

# --- scripts seam: overlap has no count limit (three disjoint lists, no ceiling)
lf() { local n="$1"; shift; { echo "# t"; echo; echo "Paths:"; for p in "$@"; do echo "- $p"; done; echo "shared: none"; } >"$T/$n"; }
lf s1.md a/; lf s2.md b/; lf s3.md c/; lf s4.md d/; lf s5.md a/x.md
bash "$PS" overlap "$T/s4.md" -- "$T/s1.md" "$T/s2.md" "$T/s3.md" >/dev/null; ck four-disjoint-slices-side-by-side 0 "$?"
bash "$PS" overlap "$T/s5.md" -- "$T/s1.md" "$T/s2.md" "$T/s3.md" >/dev/null; ck overlapping-one-waits 1 "$?"

# --- setup writes the budget, not the limit
ck template-run-budget "none" "$(bash "$FC" budget "$TPL")"
has template-budget-section "$TPL" '## Run budget'
ck template-no-limit 0 "$(grep -c 'parallel-limit' "$TPL")"
ck own-factory-md-no-limit 0 "$(grep -c '^parallel-limit' "$REPO/docs/agents/factory.md")"
has setup-removes-old-section "$SU" 'drops a `## Parallel slices` section left by 2.0.0 to 2.5.x'
has setup-adds-budget "$SU" '`## Run budget` with `run-budget: none`'

# --- standard text seam: end conditions, map persistence, budget, parallelism
has text-cycle-section "$RUN" '## The run cycle'
has text-run-is-a-cycle "$RUN" 'A run is one cycle over the standing backlog.'
has text-restarts-every-mechanism "$RUN" '**Each run restarts every mechanism**, in this order: intake'
has text-starts-with-intake "$RUN" '**Intake at every run start.**'
has text-three-end-conditions "$RUN" 'when the backlog is empty (after intake and after the last merge), when the budget is reached, or when the person stops it'
has text-map-never-dissolved "$RUN" 'it is never dissolved by the factory'
has text-map-waits "$RUN" 'The map stays: it waits for new ideas'
has text-map-card-backlog "$RUN" 'set the map card `Backlog` (the map waits for new ideas; it is not finished)'
has text-step-9-entry "$RUN" 'Entered when the backlog is empty, the budget is reached (step 8.11) or the person stops the run.'
has text-closes-with-a3 "$RUN" 'It closes at step 9 with the A3 and the baseline.'
has text-budget-resumable "$RUN" 'every slice in flight stays resumable with `/factory:run #<slice>`'
has text-budget-no-new-start "$RUN" 'start nothing new, let each role in hand finish its step'
has text-no-maximum "$RUN" 'There is no maximum of slices in flight.'   # the run cycle's copy of this was removed as a duplicate (slice 0 of #207)
has text-old-line-ignored "$RUN" 'A leftover `parallel-limit` line is ignored'
has text-budget-read-at-start "$RUN" 'factory-config.sh budget'
ck text-no-dissolve-step "0" "$(grep -c 'The map dissolves' "$RUN")"
ck text-no-limit-read "0" "$(grep -c 'factory-config.sh limit' "$RUN")"

# --- the records
for a in 0007 0016; do
  has "adr-$a-amended-by-0017" "$(ls "$REPO"/docs/adr/$a-*.md)" 'amended by'
done
has adr-0017-exists "$(ls "$REPO"/docs/adr/0017-*.md)" 'no slice maximum'
has glossary-run "$REPO/CONTEXT.md" '**Run** — one cycle over a map'"'"'s standing backlog'
has glossary-run-budget "$REPO/CONTEXT.md" '**Run budget**'
ck glossary-no-parallel-limit-term 0 "$(grep -c '^\*\*Parallel limit\*\*' "$REPO/CONTEXT.md")"

done_
