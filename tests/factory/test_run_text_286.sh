#!/bin/bash
# #286 AC-A2, AC-B1 (the text side): the sentences contract 286-run-timing section 5 fixes word for word, and the always-on rule.
# Only the quoted texts are pinned; the rest of the wording is the developer's and is read at verification (AC-A2's search for conditions).
. "$(dirname "$0")/lib.sh"
HA="$PLUGIN/references/hansei.md"; SK="$PLUGIN/skills/run/SKILL.md"; CR="$PLUGIN/references/run-close-run.md"
RR="$PLUGIN/references/run-route.md"; RO="$PLUGIN/references/run-overrides.md"; RS="$PLUGIN/scripts/run-state.sh"

# hansei.md section 8 (5.1)
has a2-hansei-section-8 "$HA" "## 8. The run's waits and run timing"
has a2-always-written "$HA" 'None of them depends on a line of docs/agents/factory.md.'
has q3-lead-gaps-outside-items "$HA" "The Lead's gaps outside every item go to the run's Run waits table (section 8)."
has a2-hansei-names-the-script "$HA" 'run-timing.sh line'
# the router (5.3)
has b1-session-line "$SK" 'Session: ${CLAUDE_SESSION_ID}'
ck b1-session-line-under-plugin-root 1 "$(grep -A1 '^Plugin root: ${CLAUDE_PLUGIN_ROOT}' "$SK" | grep -cxF 'Session: ${CLAUDE_SESSION_ID}')"
has b3-router-run-waits-sentence "$SK" 'A wait that belongs to no item goes in the Run waits table when it ends: read references/hansei.md, section 8.'
has b3-router-template-lead-sessions "$SK" '- lead sessions:'
has b3-router-template-table-header "$SK" '| # | Kind | Agent | Start | End | What |'
has b1-router-add-session "$SK" 'run-state.sh add-session'
# the run close (5.2) and the other references (5.4, 5.5)
has b5-close-runs-gaps "$CR" 'run-timing.sh gaps'
has b6-close-runs-line "$CR" 'run-timing.sh line'
has c1-close-posts-v4 "$CR" 'The A3 posted is v4'
has b1-escalation-copies-everything "$RR" '(the same `started`, `lead sessions`, `closed in this run`, `baseline` and `### Run waits` table)'
has b1-escalation-exit-4-kept "$RR" '`run-state.sh` exits 4 and names the map'
has b1-run-identity-add-session "$RO" 'run-state.sh add-session'
# run-state.sh's header lists the three additions
for u in 'add-session <' 'add-run-wait <' 'lead-sessions'; do has "b3-run-state-header-$u" "$RS" "$u"; done
# AC-A2: no line of docs/agents/factory.md is read by the two scripts that write the run's timing
ck a2-scripts-read-no-factory-md 0 "$(cat "$PLUGIN/scripts/run-timing.sh" "$RS" 2>/dev/null | grep -v '^ *#' | grep -c 'factory\.md\|obeya\|measurement:')"
done_
