#!/bin/bash
# #207 slice 6, the text seam: hansei fields, baseline per band and carry-over, the one resume question, the integrator's measures.
# Written before the text. The mechanical rules are pinned in test_slice6_scripts.sh; here what a script cannot say, and the caps.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
HA="$PLUGIN/references/hansei.md"; BA="$PLUGIN/references/baseline.md"; RT="$PLUGIN/references/run-route.md"; CI="$PLUGIN/references/run-close-item.md"
IA="$PLUGIN/agents/integrator.md"; ROUTER="$RUN_ROUTER"; ALL="$(run_all_file)"
ck router-under-cap yes "$([ "$(wc -c <"$ROUTER" | tr -d ' ')" -le 70000 ] && echo yes || echo no)"

# hansei: the plan section, one definition, and the close step that fills it by script
has hansei-plan-heading "$HA" "### Plan"
for f in "estimated points" "fired triggers" "band" "route" "role path" "test depth" "actual triggers" "actual points" "release"; do
  has "hansei-field-$f" "$HA" "- $f: "
done
has hansei-no-plan "$HA" "- plan: no plan"
has hansei-release-crossed "$HA" "release crossed"
has hansei-script-fills "$HA" 'scripts/hansei-plan.sh" fields'
has hansei-script-checks "$HA" 'scripts/hansei-plan.sh" check'
has hansei-not-by-hand "$HA" "the lead does not add"
has hansei-stays-v5 "$HA" "Release 3.8.0 keeps v5"
has hansei-after-resize "$HA" "re-size plan is the first plan"
has close-item-runs-fields "$CI" 'hansei-plan.sh" fields'
has close-item-runs-check "$CI" 'hansei-plan.sh" check'

# baseline: a section per band, the carry-over rule
has baseline-band-heading "$BA" "#### Band"
for b in Light Normal Heavy; do has "baseline-band-$b" "$BA" "$b"; done
has baseline-band-rule "$BA" "A band section is the reference section's items split by the record's band"
has baseline-band-no-plan "$BA" "not in any band section"
has baseline-carry-script "$BA" 'hansei-plan.sh" carry'
has baseline-carry-reference "$BA" "reference (standard unchanged)"
has baseline-carry-indicative "$BA" "*indicative*"
has baseline-carry-never-before "$BA" "never the \"before\" reading of an experiment"
has baseline-carry-new-minor "$BA" "A new minor starts a new series"
has baseline-crossed-outside "$BA" "release crossed"

# the resume question: one place, one question, a default
has route-resume-heading "$RT" "## Resume after a release change"
has route-resume-detect "$RT" 'plan-check.sh" release'
has route-resume-one-question "$RT" "one question"
has route-resume-default "$RT" "finish under the original plan"
has route-resume-resize "$RT" "re-size under the new table"
has route-resume-marks "$RT" "release crossed"
has route-resume-outside "$RT" "outside the baseline sections"
ck router-points-at-resume 1 "$([ "$(grep -c 'Resume after a release change' "$ROUTER")" -ge 1 ] && echo 1 || echo 0)"
ck resume-question-defined-once 1 "$(grep -l 'finish under the original plan' "$ROUTER" "$PLUGIN"/references/*.md "$PLUGIN"/agents/*.md | wc -l | tr -d ' ')"

# the integrator: per band, a separate working time, the limit warning, advisory
has integrator-band-measure "$IA" "measure band"
has integrator-agent-working "$IA" "agent working"
has integrator-role-tasks "$IA" "role-task count"
has integrator-limits-warning "$IA" "waits on usage limits"
has integrator-not-usable-alone "$IA" "is not a usable measure on its own"
has integrator-advisory "$IA" "never choose the route"

# the release
has version-3-8-0 "$PLUGIN/.claude-plugin/plugin.json" '"version": "3.8.0"'
has changelog-3-8-0 "$REPO/CHANGELOG.md" "## factory 3.8.0"
done_
