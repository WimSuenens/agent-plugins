#!/bin/bash
# #230: three lead gaps found in the first run on factory 3.2.0. Written before the scripts and the text it tests.
#  1. flow-size.sh --paths derives "Protected area touched" through protected-areas.sh.
#  2. run-state.sh start replaces a closed run's Factory run section; a3-events.sh and intake.sh filed-since anchor on the new `started:`.
#  3. stage-report.sh prints the fixed lines of the stage summary; the router names it and carries no prose for those lines.
# Fixtures: tests/factory/fixtures/lead230 (the real expected paths of #225 = the changed paths of PR #232; the ledger of #225; the Factory run
# section of the map #146 as read on 2026-11-14, and the stale shape the issue describes). The sizing rows come from the slice 4 table fixture.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
FS="$PLUGIN/scripts/flow-size.sh"; RS="$PLUGIN/scripts/run-state.sh"; AE="$PLUGIN/scripts/a3-events.sh"
IN="$PLUGIN/scripts/intake.sh"; SR="$PLUGIN/scripts/stage-report.sh"
FX="$REPO/tests/factory/fixtures/lead230"; TBL="$REPO/tests/factory/fixtures/slice4/factory.md"
cd "$T" || exit 1
val() { printf '%s\n' "$out" | sed -n "s/^$1: //p" | head -1; }
NEWLOGIC="New logic or data behaviour in a code project"; VISUAL="Visual result"; CONTRACT="Contract or interface used by others"; PROT="Protected area touched"

# ---------- 1. sizing derives the protected paths ----------
PATHS225="$(cat "$FX/paths-225.txt")"
out="$(bash "$FS" --table "$TBL" "$NEWLOGIC" "$VISUAL" 2>/dev/null)"
ck old-call-two-triggers-is-3 "3 Normal" "$(val points) $(val band)"
out="$(bash "$FS" --table "$TBL" --paths "$PATHS225" "$NEWLOGIC" "$VISUAL" "$CONTRACT" 2>"$T/err")"; code=$?
ck new-call-exit 0 "$code"
ck new-call-225-is-8-heavy "8 Heavy" "$(val points) $(val band)"
ck new-call-fires-protected-area "1" "$(printf '%s\n' "$out" | grep -c "^trigger: $PROT +3 -- ")"
ck new-call-names-the-derived-path "protected: contract contracts/188-page-tree.md" "$(printf '%s\n' "$out" | grep '^protected: ' | head -1)"
has new-call-asks-in-heavy-band <(printf '%s\n' "$out") "person: Heavy band: ask before running"
out="$(bash "$FS" --table "$TBL" --paths "$PATHS225" "$NEWLOGIC" "$VISUAL" 2>/dev/null)"
ck derived-trigger-alone-adds-3 "6 Normal" "$(val points) $(val band)"
out="$(bash "$FS" --table "$TBL" --paths "$PATHS225" "$PROT" "$NEWLOGIC" 2>/dev/null)"
ck derived-and-named-trigger-count-once "5 Normal" "$(val points) $(val band)"
out="$(bash "$FS" --table "$TBL" --paths "$(printf 'apps/site/src/lib/agents.mjs\nREADME.md\ntests/site/a11y.test.mjs')" "$NEWLOGIC" 2>/dev/null)"
ck unprotected-paths-fire-nothing "2 Light 0" "$(val points) $(val band) $(printf '%s\n' "$out" | grep -c '^protected: ')"
out="$(bash "$FS" --table "$TBL" --paths "src/auth/session.ts" 2>/dev/null)"
ck authentication-path-fires "3 Normal" "$(val points) $(val band)"
out="$(bash "$FS" --table "$TBL" --paths "contracts/" 2>/dev/null)"; ck directory-path-fires "3" "$(val points)"
# no --paths: today's output, byte for byte (the script as of origin/main is the reference)
mkdir -p "$T/oldscripts"; cp "$PLUGIN"/scripts/*.sh "$T/oldscripts/"
git -C "$REPO" show origin/main:plugins/factory/scripts/flow-size.sh >"$T/oldscripts/flow-size.sh" 2>/dev/null
for args in "" "$VISUAL" "$NEWLOGIC|$VISUAL" "$PROT|$CONTRACT|$NEWLOGIC"; do
  set --; oldifs="$IFS"; IFS='|'; for a in $args; do set -- "$@" "$a"; done; IFS="$oldifs"
  [ -n "$args" ] || set --
  ck "no-paths-same-output-[$args]" "$(bash "$T/oldscripts/flow-size.sh" --table "$TBL" "$@" 2>&1)" "$(bash "$FS" --table "$TBL" "$@" 2>&1)"
done
# the list is refused, not ignored, when it is empty or only blanks; a missing value is a usage error. Nothing on stdout.
for bad in "" "   "; do
  bash "$FS" --table "$TBL" --paths "$bad" "$VISUAL" >"$T/o" 2>"$T/e"; code=$?
  ck "empty-paths-refused-[$bad]-exit" 2 "$code"; ck "empty-paths-refused-[$bad]-stdout-empty" "" "$(cat "$T/o")"
  has "empty-paths-refused-[$bad]-says-why" "$T/e" "--paths"
done
bash "$FS" --table "$TBL" "$VISUAL" --paths >"$T/o" 2>/dev/null; ck paths-without-value-exit-2 2 $?
# the project's own extension is read the way the gate reads it (protected-paths: at column 0 of docs/agents/factory.md)
P="$T/ext"; mkdir -p "$P/docs/agents"; printf '%s\n' 'protected-paths: deploy/*, infra/**' >"$P/docs/agents/factory.md"
out="$(cd "$P" && bash "$FS" --table "$TBL" --paths "deploy/prod.yml" 2>/dev/null)"
ck project-extension-fires "3 $(printf 'protected: project deploy/prod.yml')" "$(val points) $(printf '%s\n' "$out" | grep '^protected: ')"
out="$(cd "$P" && bash "$FS" --table "$TBL" --paths "docs/readme.md" 2>/dev/null)"; ck project-extension-other-path-nothing "0" "$(val points)"
# a table without the row cannot derive it (the table check already refuses an incomplete table: exit 6)
grep -v "^| $PROT " "$TBL" >"$T/norow.md"
bash "$FS" --table "$T/norow.md" --paths "contracts/x.md" >"$T/o" 2>"$T/e"; code=$?
ck table-without-the-row-refused-exit 6 "$code"; ck table-without-the-row-refused-stdout-empty "" "$(cat "$T/o")"; has table-without-the-row-says-why "$T/e" "no complete flow table"
# the sizing text: expected paths include the contract files the architect stage will write
ROUTE="$PLUGIN/references/run-route.md"
has text-route-names-paths-option "$ROUTE" '--paths'
has text-route-contract-files-of-the-architect "$ROUTE" 'contract files the architect stage will write'
has text-route-lead-still-lists-other-triggers "$ROUTE" 'still name the other rows'

# ---------- 2. a new run replaces the old run's state ----------
CLOSED="$FX/run-body-146-closed.md"; STALE="$FX/run-body-146-stale.md"; OPEN="$REPO/tests/factory/fixtures/slice4/run-body-destination.md"
NOW=2026-11-14T20:00:00Z; A3URL="https://example.invalid/issues/146#issuecomment-1"
sec() { awk '/^## /{ on = ($0 ~ /^## Factory run[ \t]*$/); next } on { print }' "$1"; }
ck status-real-146-body-closed "closed" "$(bash "$RS" status "$CLOSED")"
ck status-open-run-open "open" "$(bash "$RS" status "$OPEN")"
ck status-stale-without-pointer-open "open" "$(bash "$RS" status "$STALE")"
bash "$RS" start "$CLOSED" --now "$NOW" >"$T/new1.md" 2>"$T/e"; ck start-closed-exit 0 $?
ck start-writes-started "$NOW" "$(bash "$RS" started "$T/new1.md")"
ck start-closed-none "none" "$(bash "$RS" closed "$T/new1.md")"
ck start-items-empty "" "$(bash "$RS" items "$T/new1.md")"
ck start-no-stale-in-flight "none" "$(bash "$RS" in-flight "$T/new1.md")"
ck start-step-is-zero "0" "$(bash "$RS" step "$T/new1.md")"
ck start-freeze-reset "none yet" "$(bash "$RS" freeze "$T/new1.md")"
ck start-no-old-item-left "0" "$(sec "$T/new1.md" | grep -c '#168\|#156\|#188\|#225')"
ck start-no-old-baseline-left "0" "$(sec "$T/new1.md" | grep -c '^- baseline: #62')"
ck start-pointer-without-link "- previous run: A3 posted (link not recorded)" "$(sec "$T/new1.md" | grep '^- previous run:')"
ck start-one-section "1" "$(grep -c '^## Factory run' "$T/new1.md")"
ck start-keeps-the-rest "$(grep -v '^## Factory run' "$CLOSED" | sed -n '1,/^## Factory run/p' | head -5)" "$(head -5 "$T/new1.md")"
has start-keeps-decisions-section "$T/new1.md" "## Decisions so far"
ck start-new-section-is-open "open" "$(bash "$RS" status "$T/new1.md")"
bash "$RS" start "$T/new1.md" --now "$NOW" >"$T/o" 2>"$T/e"; ck start-on-its-own-output-refused-exit 8 $?; ck start-on-open-run-stdout-empty "" "$(cat "$T/o")"
# the lead found the A3 of the run (Find A3): the stale shape of #146 (step 5, in flight, FREEZE none yet, no started:) is replaced too
bash "$RS" start "$STALE" --a3 "$A3URL" --now "$NOW" >"$T/new2.md"; ck start-stale-with-a3-exit 0 $?
ck start-pointer-with-link "- previous run: $A3URL" "$(sec "$T/new2.md" | grep '^- previous run:')"
ck start-stale-no-in-flight-225 "none" "$(bash "$RS" in-flight "$T/new2.md")"
ck start-stale-closed-none "none" "$(bash "$RS" closed "$T/new2.md")"
# an open run's section is untouched: exit 8, nothing on stdout
for f in "$STALE" "$OPEN"; do
  b="$(basename "$f")"; cp "$f" "$T/before-$b"
  bash "$RS" start "$f" --now "$NOW" >"$T/o" 2>"$T/e"; ck "start-open-run-refused-$b" 8 $?
  ck "start-open-run-stdout-empty-$b" "" "$(cat "$T/o")"; has "start-open-run-says-why-$b" "$T/e" "open run"
  ck "start-open-run-file-untouched-$b" "$(cat "$T/before-$b")" "$(cat "$f")"
done
# a section that records its A3 pointer is closed, with that link carried over
{ cat "$OPEN" | sed 's/^- closed in this run: none/- closed in this run: none\n- A3: https:\/\/example.invalid\/issues\/9#issuecomment-9/'; } >"$T/withA3.md"
ck status-a3-line-closed "closed" "$(bash "$RS" status "$T/withA3.md")"
bash "$RS" start "$T/withA3.md" --now "$NOW" >"$T/new3.md"; ck start-a3-line-carried "- previous run: https://example.invalid/issues/9#issuecomment-9" "$(sec "$T/new3.md" | grep '^- previous run:' | sed 's/A3 //')"
# usage: no section, a missing file, a moved run, a bad time
printf '# t\n\nno section\n' >"$T/nosec.md"; bash "$RS" start "$T/nosec.md" >/dev/null 2>&1; ck start-no-section-exit-1 1 $?
bash "$RS" start "$T/missing.md" >/dev/null 2>&1; ck start-missing-file-exit-2 2 $?
bash "$RS" start "$CLOSED" --now "yesterday" >/dev/null 2>&1; ck start-bad-time-exit-2 2 $?
printf '# t\n\nFactory run: moved to #77\n' >"$T/moved.md"; bash "$RS" start "$T/moved.md" >/dev/null 2>&1; ck start-moved-exit-4 4 $?
# a3-events.sh: the run list is read only from an open run's section; a closed run's items are never read
bash "$AE" --run-body "$CLOSED" >"$T/o" 2>"$T/e"; ck a3-events-closed-run-refused-exit 2 $?; ck a3-events-closed-run-stdout-empty "" "$(cat "$T/o")"; has a3-events-closed-run-says-why "$T/e" "closed run"
bash "$AE" --run-body "$STALE" >"$T/o" 2>"$T/e"; ck a3-events-no-started-refused-exit 2 $?; has a3-events-no-started-says-start "$T/e" "run-state.sh"
ck a3-events-new-section-none "- items closed in this run: none" "$(bash "$AE" --run-body "$T/new1.md" | grep '^- items closed')"
printf '%s' "$(cat "$T/new1.md")" | sed 's/^- closed in this run: none/- closed in this run: #300 https:\/\/example.invalid\/c/' >"$T/new1b.md"
ck a3-events-new-run-reads-its-own-items "- items closed in this run: #300" "$(bash "$AE" --run-body "$T/new1b.md" | grep '^- items closed')"
# intake.sh filed-since --run-body: the start is the new `started:`; a closed run's section is refused
mkdir -p "$T/bin"; cat >"$T/bin/gh" <<'SH'
#!/bin/bash
[ "$1 $2" = "issue list" ] && { echo "$*" >>"$STUB_LOG"; cat "$STUB_ISSUES"; exit 0; }
exit 99
SH
chmod +x "$T/bin/gh"; export PATH="$T/bin:$PATH" STUB_LOG="$T/gh.log" STUB_ISSUES="$T/issues.json"
cat >"$T/issues.json" <<'JSON'
[{"number":240,"title":"factory: a filed one","createdAt":"2026-11-14T20:30:00Z","state":"OPEN","labels":[{"name":"needs-triage"}],"body":"x"},
 {"number":239,"title":"factory: before the new run","createdAt":"2026-11-14T19:00:00Z","state":"OPEN","labels":[{"name":"needs-triage"}],"body":"x"},
 {"number":238,"title":"unlabelled","createdAt":"2026-11-14T20:40:00Z","state":"OPEN","labels":[],"body":"x"}]
JSON
R="$T/proj"; mkdir -p "$R/docs/agents"; git init -q -b main "$R"
printf '%s\n' '| Label in mattpocock/skills | Label in our tracker | Meaning |' '|---|---|---|' '| `needs-triage` | `needs-triage` | evaluate |' > "$R/docs/agents/triage-labels.md"
( cd "$R" && echo r >README && git add -A && git commit -qm init ) >/dev/null
cd "$R" || exit 1
bash "$IN" filed-since --run-body "$CLOSED" >"$T/o" 2>"$T/e"; ck filed-since-closed-run-refused-exit 2 $?; ck filed-since-closed-run-stdout-empty "" "$(cat "$T/o")"; has filed-since-closed-run-says-why "$T/e" "closed run"
bash "$IN" filed-since --run-body "$STALE" >/dev/null 2>&1; ck filed-since-no-started-refused 2 $?
ck filed-since-anchors-on-the-new-start "240" "$(bash "$IN" filed-since --run-body "$T/new1.md" 2>/dev/null | cut -f1 | tr '\n' ' ' | sed 's/ $//')"
has filed-since-new-start-in-the-line <(bash "$IN" filed-since --run-body "$T/new1.md" --line 2>/dev/null) "new issues since $NOW: 1 open: #240"
has filed-since-new-start-in-the-query "$T/gh.log" "created:>=2026-11-14"

# ---------- 3. the stage-boundary report comes from a script ----------
cd "$R" || exit 1
bash "$RS" start "$CLOSED" --now 2026-11-14T18:50:00Z >"$T/new225.md"
LED="$FX/ledger-225.md"
out="$(bash "$SR" --run-body "$T/new225.md" --ledger "$LED" 2>"$T/e")"; code=$?
ck report-exit 0 "$code"
ck report-line-1-new-issues "new issues since 2026-11-14T18:50:00Z: 2 open: #239 factory: before the new run; #240 factory: a filed one (sources: label needs-triage, marker factory:improvement)" "$(printf '%s\n' "$out" | sed -n 1p)"
ck report-waits-line "waits so far: 2 (andon 1: 0 min; person 1: 2 min)" "$(printf '%s\n' "$out" | grep '^waits so far')"
ck report-no-direction-line-without-the-file "0" "$(printf '%s\n' "$out" | grep -c '^direction')"
ck report-is-exactly-two-lines "2" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
# the same line as intake.sh itself prints for the same run body: nothing reworded
ck report-new-issues-line-is-intakes "$(bash "$IN" filed-since --run-body "$T/new225.md" --line 2>/dev/null)" "$(printf '%s\n' "$out" | sed -n 1p)"
# docs/direction.md created since the last boundary (default: the run start); the date is the commit that added it
mkdir -p "$R/docs"; echo "goal: x" >"$R/docs/direction.md"
( cd "$R" && git add -A && TZ=UTC GIT_AUTHOR_DATE=2026-11-14T19:20:00Z GIT_COMMITTER_DATE=2026-11-14T19:20:00Z git commit -qm "#226 product-owner: direction" ) >/dev/null
sha="$(git -C "$R" rev-parse --short HEAD)"
out="$(bash "$SR" --run-body "$T/new225.md" --ledger "$LED" 2>/dev/null)"
ck report-direction-line "direction: docs/direction.md created 2026-11-14T19:20:00Z ($sha)" "$(printf '%s\n' "$out" | grep '^direction')"
ck report-direction-line-is-second "direction" "$(printf '%s\n' "$out" | sed -n 2p | cut -c1-9)"
out="$(bash "$SR" --run-body "$T/new225.md" --ledger "$LED" --since 2026-11-14T19:30:00Z 2>/dev/null)"
ck report-direction-before-the-last-boundary-no-line "0" "$(printf '%s\n' "$out" | grep -c '^direction')"
out="$(bash "$SR" --run-body "$T/new225.md" --since 2026-11-14T19:00:00Z --ledger "$LED" 2>/dev/null)"
ck report-direction-after-the-last-boundary-line "1" "$(printf '%s\n' "$out" | grep -c '^direction')"
# no ledger: said so; a ledger with no waits rows: zero
out="$(bash "$SR" --run-body "$T/new225.md" 2>/dev/null)"; ck report-no-ledger-line "waits so far: none (no ledger given)" "$(printf '%s\n' "$out" | grep '^waits so far')"
printf '<!-- factory:ledger v1 -->\n## Ledger: #1 x\n\n### Waits\n\n| Id | Kind | Agent | Start (UTC) | End (UTC) | Held item | What |\n|---|---|---|---|---|---|---|\n' >"$T/led0.md"
out="$(bash "$SR" --run-body "$T/new225.md" --ledger "$T/led0.md" 2>/dev/null)"; ck report-ledger-without-waits "waits so far: 0" "$(printf '%s\n' "$out" | grep '^waits so far')"
# two ledgers add up
out="$(bash "$SR" --run-body "$T/new225.md" --ledger "$LED" --ledger "$LED" 2>/dev/null)"; ck report-two-ledgers-add "waits so far: 4 (andon 2: 0 min; person 2: 4 min)" "$(printf '%s\n' "$out" | grep '^waits so far')"
# refusals: a closed run's section, a missing file, no run body
bash "$SR" --run-body "$CLOSED" --ledger "$LED" >"$T/o" 2>/dev/null; ck report-closed-run-refused-exit 2 $?; ck report-closed-run-stdout-empty "" "$(cat "$T/o")"
bash "$SR" --run-body "$T/new225.md" --ledger "$T/missing.md" >"$T/o" 2>/dev/null; ck report-missing-ledger-exit-2 2 $?
bash "$SR" >"$T/o" 2>/dev/null; ck report-no-args-exit-2 2 $?
bash "$SR" --run-body "$T/new225.md" --since yesterday >"$T/o" 2>/dev/null; ck report-bad-since-exit-2 2 $?
cd "$T" || exit 1
# the router names the script and no longer describes the lines in prose
ROUTER="$PLUGIN/skills/run/SKILL.md"
sect="$(run_section "Report at each stage boundary")"; printf '%s\n' "$sect" >"$T/sect.md"
has router-names-stage-report "$T/sect.md" 'stage-report.sh'
has router-says-paste-unchanged "$T/sect.md" 'unchanged'
hasnt router-no-filed-since-prose "$T/sect.md" 'filed-since'
hasnt router-no-two-sources-prose "$T/sect.md" 'two sources'
hasnt router-no-label-marker-prose "$T/sect.md" 'factory:improvement'
hasnt router-no-direction-prose "$T/sect.md" 'created or updated `docs/direction.md`'
hasnt router-no-two-lines-prose "$T/sect.md" 'Two lines join the stage summary'
rb="$(wc -c <"$ROUTER" | tr -d ' ')"; ck router-at-most-70000 yes "$([ "$rb" -le 70000 ] && echo yes || echo no)"
# step 0 and the run start name the start subcommand; the template records the A3 pointer
ALL="$(run_all_file)"
has text-names-run-state-start "$ALL" 'run-state.sh" start'
has text-template-has-a3-line "$ALL" '- A3: <comment URL of the posted A3>'
done_
