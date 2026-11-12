#!/bin/bash
# #143 Setup asks about the Obeya and writes the `## Obeya` section from the answer, never silently.
# Seams: scripts/obeya-optin.sh (status | set) and the setup skill text that tells the agent to ask first.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
OP="$PLUGIN/scripts/obeya-optin.sh"
SU="$PLUGIN/skills/setup-factory-skill/SKILL.md"
TPL="$PLUGIN/skills/setup-factory-skill/assets/factory.md"
OB="$PLUGIN/scripts/obeya.sh"

mkproj() { mkdir -p "$T/$1/docs/agents" && git -C "$T/$1" init -q && printf '%s' "$2" >"$T/$1/docs/agents/factory.md"; echo "$T/$1"; }
op() { ( cd "$1" && shift && bash "$OP" "$@" 2>&1; echo "rc=$?" ); }
F() { echo "$1/docs/agents/factory.md"; }
OLD=$'factory-state: 2\n\n# Factory\n\n## Run budget\n\nrun-budget: none\n\n## Tracker\n\nrows\n'

# existing repo (factory-state: 2) without the section: status says unanswered, status writes nothing
P="$(mkproj old "$OLD")"; before="$(cat "$(F "$P")")"
ck status-unanswered $'unanswered\nrc=0' "$(op "$P" status)"
ck status-writes-nothing "$before" "$(cat "$(F "$P")")"
# no answer, no write: set with no or a bad value changes nothing
ck set-no-value-rc $'rc=2' "$(op "$P" set | tail -n1)"
ck set-bad-value-rc $'rc=2' "$(op "$P" set maybe | tail -n1)"
ck no-answer-no-write "$before" "$(cat "$(F "$P")")"
# yes: adds the section once, line 1 and the rest untouched
ck set-on $'added obeya: on\nrc=0' "$(op "$P" set on)"
ck on-line "1" "$(grep -c '^obeya: on$' "$(F "$P")")"
ck on-section "1" "$(grep -c '^## Obeya$' "$(F "$P")")"
ck on-line1 "factory-state: 2" "$(head -n1 "$(F "$P")")"
ck on-keeps-other-sections "2" "$(grep -c -e '^## Run budget$' -e '^## Tracker$' "$(F "$P")")"
ck status-answered-on $'on\nrc=0' "$(op "$P" status)"
ck obeya-sh-accepts-it "0" "$(grep -q '^obeya: on[[:space:]]*$' "$(F "$P")"; echo $?)"
# idempotent re-run: reports no change, even with the other answer
snap="$(cat "$(F "$P")")"
ck rerun-same $'already answered: on\nrc=0' "$(op "$P" set on)"
ck rerun-other $'already answered: on\nrc=0' "$(op "$P" set off)"
ck rerun-unchanged "$snap" "$(cat "$(F "$P")")"
# no: writes off
P="$(mkproj old2 "$OLD")"
ck set-off $'added obeya: off\nrc=0' "$(op "$P" set off)"
ck status-answered-off $'off\nrc=0' "$(op "$P" status)"
# section placed before ## Tracker when there is one; appended when not
ck before-tracker "yes" "$(awk '/^## Obeya$/{o=NR} /^## Tracker$/{t=NR} END{print (o && o<t) ? "yes" : "no"}' "$(F "$P")")"
P="$(mkproj bare $'factory-state: 2\n\n# Factory\n')"; op "$P" set on >/dev/null
ck append-without-tracker "1" "$(grep -c '^## Obeya$' "$(F "$P")")"
# new repo: the copied template already carries "obeya: off"; the answer replaces it, only with --replace
P="$(mkproj new "$(cat "$TPL")")"
ck template-status $'off\nrc=0' "$(op "$P" status)"
ck template-set-keeps $'already answered: off\nrc=0' "$(op "$P" set on)"
ck template-set-replace $'replaced obeya: on\nrc=0' "$(op "$P" set on --replace)"
ck template-replaced "1" "$(grep -c '^obeya: on$' "$(F "$P")")"
ck template-no-dup-section "1" "$(grep -c '^## Obeya$' "$(F "$P")")"
# no factory.md: refuse
ck no-file-rc $'rc=2' "$(op "$T" set on | tail -n1)"
# the refusal of /factory:obeya points at setup too
P="$(mkproj refuse "$OLD")"
out="$( cd "$P" && PATH="$REPO/tests/factory/stub-docker:$PATH" bash "$OB" start 2>&1 )"
has refusal-names-setup <(echo "$out") "/factory:setup"
# the setup skill asks first, and runs on an already migrated repo too
has skill-calls-script "$SU" "obeya-optin.sh"
has skill-asks "$SU" "Enable the Obeya?"
has skill-only-yes-no "$SU" "no answer, no write"
has skill-already-migrated "$SU" "On \`already migrated\`, say so, skip the rest of this step"
done_
