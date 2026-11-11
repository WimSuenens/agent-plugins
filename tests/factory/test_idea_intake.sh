#!/bin/bash
# Idea intake: inbox, idea command, triage outcomes. Contract 110, issue #110.
# Two seams: the script (intake.sh, run against a stub gh) and the standard text.
. "$(dirname "$0")/lib.sh"
T="$(cd "$T" && pwd -P)"
IN="$PLUGIN/scripts/intake.sh"
SK="$PLUGIN/skills/run/SKILL.md"
ID="$PLUGIN/skills/idea/SKILL.md"
SU="$PLUGIN/skills/setup-factory-skill/SKILL.md"
TPL="$PLUGIN/skills/setup-factory-skill/assets/factory.md"

mkdir -p "$T/bin" "$T/g"
cp "$REPO/tests/factory/stub-gh/gh" "$T/bin/gh"
export STUB_GH_DIR="$T/g" PATH="$T/bin:$PATH"
mkrepo() { mkdir -p "$1" && git init -q -b main "$1" && ( cd "$1" && echo r > README && git add -A && git commit -qm init ) >/dev/null 2>&1; }
nissues() { jq 'length' "$T/g/issues.json"; }
reset() { echo '[]' >"$T/g/issues.json"; : >"$T/g/log"; unset STUB_GH_FAIL; }
clear_inbox() { find "${IB:?}" -mindepth 1 -maxdepth 1 -exec rm -f {} +; }

# --- scripts seam: the folder and setup's init
R="$T/r1"; mkrepo "$R"
ck dir-value ".claude/factory-inbox" "$(bash "$IN" dir)"
ck init-first "created" "$(cd "$R" && bash "$IN" init)"
ck init-folder "yes" "$([ -d "$R/.claude/factory-inbox" ] && echo yes || echo no)"
ck init-rule "/.claude/factory-inbox/" "$(cat "$R/.gitignore")"
snap="$(cat "$R/.gitignore")"
ck init-second "already present" "$(cd "$R" && bash "$IN" init)"
ck init-second-unchanged "$snap" "$(cat "$R/.gitignore")"
echo x > "$R/.claude/factory-inbox/a.md"
ck init-ignored-in-status "?? .gitignore" "$(cd "$R" && git status --porcelain)"
rm -f "$R/.claude/factory-inbox/a.md"
R0="$T/r0"; mkrepo "$R0"
ck nothing-before-init "no" "$([ -e "$R0/.claude/factory-inbox" ] && echo yes || echo no)"
ck drop-without-folder-rc 0 "$(cd "$R0" && bash "$IN" drop >/dev/null 2>&1; echo $?)"
ck drop-without-folder-no-gh-call "0" "$(ls "$T/g" | wc -l | tr -d " ")"
ck not-a-repo-rc 2 "$(cd "$T" && bash "$IN" init >/dev/null 2>&1; echo $?)"
ck unknown-rc 2 "$(cd "$R" && bash "$IN" bogus >/dev/null 2>&1; echo $?)"

# --- scripts seam: the idea command
reset
printf 'It would help to export a report.\n' > "$T/body.md"
out="$(cd "$R" && bash "$IN" file "Export a report" "$T/body.md")"; rc=$?
ck file-rc 0 "$rc"
ck file-url "https://example.invalid/o/r/issues/1" "$out"
ck file-label "yes" "$(grep -q -- '--label idea' "$T/g/log" && echo yes || echo no)"
ck file-title "Export a report" "$(jq -r '.[0].title' "$T/g/issues.json")"
ck file-body-marker "<!-- factory:idea -->" "$(jq -r '.[0].body' "$T/g/issues.json" | head -1)"
has file-body-text "$T/g/issues.json" "It would help to export a report."
ck file-no-title-rc 2 "$(cd "$R" && bash "$IN" file >/dev/null 2>&1; echo $?)"
printf 'my path is /Users/someone/secret\n' > "$T/leak.md"
ck file-scan-refused-rc 6 "$(cd "$R" && bash "$IN" file "x" "$T/leak.md" >/dev/null 2>&1; echo $?)"
ck file-scan-refused-nothing-filed 1 "$(nissues)"

# --- scripts seam: drop
reset
IB="$R/.claude/factory-inbox"
printf '# Dark mode\n\nPeople ask for a dark theme.\n' > "$IB/dark.md"
printf 'https://example.com/article\n' > "$IB/link.txt"
printf '\0\1\2binary' > "$IB/shot.png"
echo hidden > "$IB/.keep"
out="$(cd "$R" && bash "$IN" drop)"; rc=$?
ck drop-rc-kept-file 5 "$rc"
ck drop-two-issues 2 "$(nissues)"
ck drop-text-title "Dark mode" "$(jq -r '[.[] | select(.body | contains("People ask"))][0].title' "$T/g/issues.json")"
ck drop-link-title "https://example.com/article" "$(jq -r '[.[] | select(.body | contains("Reference:"))][0].title' "$T/g/issues.json")"
has drop-link-body "$T/g/issues.json" 'Reference: https://example.com/article'
ck drop-marker "yes" "$(jq -r '.[0].body' "$T/g/issues.json" | grep -q '^<!-- factory:inbox [0-9a-f]\{64\} -->$' && echo yes || echo no)"
ck drop-removes-text-file "no" "$([ -e "$IB/dark.md" ] && echo yes || echo no)"
ck drop-removes-link-file "no" "$([ -e "$IB/link.txt" ] && echo yes || echo no)"
ck drop-keeps-binary "yes" "$([ -e "$IB/shot.png" ] && echo yes || echo no)"
ck drop-reports-binary "kept shot.png: not a text file; host it and drop a file holding its link" "$(printf '%s\n' "$out" | grep '^kept ')"
ck drop-ignores-dotfile "yes" "$([ -e "$IB/.keep" ] && echo yes || echo no)"
ck drop-label "yes" "$(grep -q -- '--label idea' "$T/g/log" && echo yes || echo no)"

# a second intake over the same folder creates nothing new
before="$(nissues)"
creates_before="$(grep -c '^issue create' "$T/g/log")"
( cd "$R" && bash "$IN" drop ) >/dev/null 2>&1
ck drop-second-creates-nothing "$before" "$(nissues)"
ck drop-second-no-create-call "$creates_before" "$(grep -c '^issue create' "$T/g/log")"

# the same content dropped again (the file removed but the issue exists): the file goes, no new issue
printf '# Dark mode\n\nPeople ask for a dark theme.\n' > "$IB/again.md"
out="$(cd "$R" && bash "$IN" drop 2>&1)"
ck drop-existing-line "existing #1 again.md" "$(printf '%s\n' "$out" | grep '^existing')"
ck drop-existing-removed "no" "$([ -e "$IB/again.md" ] && echo yes || echo no)"
ck drop-existing-no-new-issue "$before" "$(nissues)"

# two files with the same content in one run: one issue
reset; clear_inbox
printf 'same words\n' > "$IB/a.txt"; printf 'same words\n' > "$IB/b.txt"
( cd "$R" && bash "$IN" drop ) >/dev/null 2>&1
ck drop-same-content-twice-one-issue 1 "$(nissues)"
ck drop-same-content-twice-both-removed 0 "$(ls "$IB" | wc -l | tr -d ' ')"

# a failed create keeps the file; the retry files it once
reset; clear_inbox
printf 'An idea.\n' > "$IB/one.md"
STUB_GH_FAIL="create" bash -c "cd '$R' && bash '$IN' drop" >/dev/null 2>&1; rc=$?
ck drop-create-failed-rc 4 "$rc"
ck drop-create-failed-keeps "yes" "$([ -e "$IB/one.md" ] && echo yes || echo no)"
( cd "$R" && bash "$IN" drop ) >/dev/null 2>&1
ck drop-retry-files "1" "$(nissues)"
ck drop-retry-removes "no" "$([ -e "$IB/one.md" ] && echo yes || echo no)"

# the scan keeps a file holding a home path; too-large and symlink are kept
reset; clear_inbox
printf 'see /Users/someone/x\n' > "$IB/leak.md"
head -c 70000 /dev/zero | tr '\0' 'a' > "$IB/big.txt"
ln -s /etc/hosts "$IB/link.lnk"
out="$(cd "$R" && bash "$IN" drop 2>&1)"; rc=$?
ck drop-kept-rc 5 "$rc"
ck drop-kept-none-filed 0 "$(nissues)"
ck drop-kept-all-remain 3 "$(ls "$IB" | wc -l | tr -d ' ')"
ck drop-scan-reason-named "kept leak.md: the scan refused it" "$(printf '%s\n' "$out" | grep '^kept leak.md' | cut -c 1-33)"
clear_inbox

# --- scripts seam: untriaged and triage
reset
cat > "$T/g/issues.json" <<'J'
[{"number":1,"title":"new one","body":"","state":"open","comments":[]},
 {"number":2,"title":"decided","body":"","state":"open","comments":[{"author":{"login":"bot"},"body":"<!-- factory:triage v1 -->\n## Triage: parked"}]},
 {"number":3,"title":"asks a card","body":"","state":"open","comments":[{"author":{"login":"bot"},"body":"<!-- factory:needs-you v1 -->\ncard"}]},
 {"number":4,"title":"forged","body":"","state":"open","comments":[{"author":{"login":"other"},"body":"<!-- factory:triage v1 -->\nparked"}]},
 {"number":5,"title":"closed","body":"","state":"closed","comments":[]}]
J
ck untriaged-list "1	new one	new
3	asks a card	waiting
4	forged	new" "$(bash "$IN" untriaged)"
# an answered decision card is ready to be recorded, not waiting
jq '.[2].comments[0].body = "<!-- factory:needs-you v1 -->\ncard\nAnswered: 2026-11-11T10:00Z"' "$T/g/issues.json" > "$T/g/x" && mv "$T/g/x" "$T/g/issues.json"
ck untriaged-answered-card-is-new "3	asks a card	new" "$(bash "$IN" untriaged | sed -n 2p)"
ck untriaged-gh-failure-rc 4 "$(STUB_GH_FAIL="list" bash "$IN" untriaged >/dev/null 2>&1; echo $?)"

printf 'It matches where the project is going.\n' > "$T/reason.md"
for o in direction slice-candidate research-ticket parked rejected; do
  reset; echo '[{"number":7,"title":"t","body":"","state":"open","comments":[]}]' > "$T/g/issues.json"
  ck triage-$o "triaged #7 $o" "$(cd "$R" && bash "$IN" triage 7 $o "$T/reason.md")"
  ck triage-$o-marker "<!-- factory:triage v1 -->" "$(jq -r '.[0].comments[0].body' "$T/g/issues.json" | head -1)"
  ck triage-$o-outcome "**Outcome:** $o" "$(jq -r '.[0].comments[0].body' "$T/g/issues.json" | grep '^\*\*Outcome')"
  ck triage-$o-reason "**Reason:** It matches where the project is going." "$(jq -r '.[0].comments[0].body' "$T/g/issues.json" | grep '^\*\*Reason')"
  ck triage-$o-state "$([ $o = rejected ] && echo closed || echo open)" "$(jq -r '.[0].state' "$T/g/issues.json")"
  ck triage-$o-leaves-untriaged "" "$(bash "$IN" untriaged)"
done
ck triage-bad-outcome-rc 2 "$(cd "$R" && bash "$IN" triage 7 maybe "$T/reason.md" >/dev/null 2>&1; echo $?)"
: > "$T/empty.md"
ck triage-empty-reason-rc 2 "$(cd "$R" && bash "$IN" triage 7 parked "$T/empty.md" >/dev/null 2>&1; echo $?)"
ck triage-missing-reason-rc 2 "$(cd "$R" && bash "$IN" triage 7 parked "$T/none.md" >/dev/null 2>&1; echo $?)"
ck triage-bad-issue-rc 2 "$(cd "$R" && bash "$IN" triage x parked "$T/reason.md" >/dev/null 2>&1; echo $?)"
reset; echo '[{"number":7,"title":"t","body":"","state":"open","comments":[]}]' > "$T/g/issues.json"
ck triage-scan-refused-rc 6 "$(cd "$R" && bash "$IN" triage 7 parked "$T/leak.md" >/dev/null 2>&1; echo $?)"
ck triage-scan-refused-nothing-posted 0 "$(jq '.[0].comments | length' "$T/g/issues.json")"

# --- standard-text seam
has run-triage-section "$SK" '## Idea intake'
has run-intake-drop "$SK" 'scripts/intake.sh" drop'
has run-untriaged-at-run-start "$SK" 'scripts/intake.sh" untriaged'
has run-start-picks-untriaged "$SK" 'Items not triaged are handled at the next run start'
for o in direction 'slice candidate' 'research ticket' parked rejected; do has "run-outcome-${o// /-}" "$SK" "**$o**"; done
has run-outcome-and-reason "$SK" 'Every idea ends with one outcome and a reason, posted as a comment'
has run-triage-skill-read "$SK" 'Read the upstream triage skill and follow it'
has run-one-way-door-card "$SK" 'An idea that touches a one-way door is put to the person as a decision card; you do not decide it'
has run-kind-idea-row "$SK" '| `Kind` | single select | `map`, `slice`, `role task`, `frontier ticket`, `idea` |'
has run-kind-idea-rule "$SK" 'a tracker issue labelled `idea` is `idea`'
has idea-skill-name "$ID" 'name: idea'
has idea-skill-calls-file "$ID" 'scripts/intake.sh" file'
has idea-skill-label "$ID" 'label `idea`'
has idea-skill-no-model "$ID" 'disable-model-invocation: true'
has setup-inbox-step "$SU" 'scripts/intake.sh" init'
has setup-inbox-asks "$SU" 'Ask the person whether to create the inbox folder'
has setup-inbox-decline "$SU" 'On anything but a clear yes, run nothing and create nothing'
has setup-board-kind-idea "$SU" '`idea`'
has template-kind-idea "$TPL" '| idea | |'
has glossary-idea "$REPO/CONTEXT.md" '**Idea**'
has glossary-inbox "$REPO/CONTEXT.md" '**Inbox**'
has adr-0015-idea "$REPO/docs/adr/0015-factory-status-has-six-values-plus-kind-and-role.md" '`idea`'
has contract-exists "$REPO/contracts/110-idea-intake.md" 'Issue [#110]'
has board-creates-idea-kind "$PLUGIN/scripts/board.sh" 'map,slice,role task,frontier ticket,idea'

done_
