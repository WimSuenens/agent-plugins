#!/bin/bash
# #286 AC-B2, AC-B5, AC-B6, AC-B7: scripts/run-timing.sh (`gaps`, the run-close scan; `line`, the run's timing). Written before the script.
# Contract 286-run-timing sections 3 and 4 fix the output lines, the reasons and the exits; the worked examples there are the fixtures
# (tests/factory/fixtures/run286: run.md, l41.md, l42.md, lead.tsv). AC-B5's chain runs the real cut-offs.sh on a transcript fixture
# (lead-b5.jsonl, three Lead gaps after the only item) into `gaps` and `run-state.sh add-run-wait`.
# AC-B7: generated runs, compared with QA's own minute-by-minute replay (run_timing_oracle.py, no shared code), and the invariants.
. "$(dirname "$0")/lib.sh"
RT="$PLUGIN/scripts/run-timing.sh"; RS="$PLUGIN/scripts/run-state.sh"
FX="$REPO/tests/factory/fixtures/run286"; OR="$REPO/tests/factory/run_timing_oracle.py"
CLOSE=2026-12-01T14:00:27Z
SID=0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c

ck rt-script-exists 1 "$([ -f "$RT" ] && echo 1 || echo 0)"
ck rt-bash-3.2-shebang '#!/bin/bash' "$(head -1 "$RT" 2>/dev/null)"
ck rt-no-bash4-features 0 "$(grep -v '^ *#' "$RT" 2>/dev/null | grep -cE 'mapfile|readarray|declare -A|\$\{[a-zA-Z_]+(,,|\^\^)\}|&>>|;&')"
ck rt-no-network-no-gh-no-jq 0 "$(grep -v '^ *#' "$RT" 2>/dev/null | grep -cE '(^|[^a-z_-])(gh|curl|wget|nc|jq) ')"
ck rt-no-date-arithmetic 0 "$(grep -v '^ *#' "$RT" 2>/dev/null | grep -cE 'date +-[dj]|date +-v')"

# rt <args...>: runs under /bin/bash (3.2 on macOS); sets OUT, ERR, RC
rt() { OUT="$(/bin/bash "$RT" "$@" 2>"$T/err")"; RC=$?; ERR="$(cat "$T/err")"; }
WANT='- run timing: raw 4h00m; adjusted 2h40m; blocked: person 1h05m, limits 15m, stalled 0m, interrupted 0m'

# ---------- AC-B6: the worked example of section 4.6, byte for byte ----------
rt line --run-body "$FX/run.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$FX/l42.md"
ck b6-line-exit 0 "$RC"; ck b6-line "$WANT" "$OUT"
# the ledger order on the command line does not matter
rt line --run-body "$FX/run.md" --close "$CLOSE" --ledger "$FX/l42.md" --ledger "$FX/l41.md"; ck b6-ledger-order-free "$WANT" "$OUT"
# control (a): B W1 is limits
sed 's/^| W1 | person | - | 2026-12-01T11:30Z/| W1 | limits | - | 2026-12-01T11:30Z/' "$FX/l42.md" > "$T/l42a.md"
rt line --run-body "$FX/run.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$T/l42a.md"
ck b6-control-a "0 - run timing: raw 4h00m; adjusted 2h40m; blocked: person 35m, limits 45m, stalled 0m, interrupted 0m" "$RC $OUT"
# control (b): R2 from 13:00, while B is in flight and not held
sed 's/^| R2 | limits | lead | 2026-12-01T13:40Z/| R2 | limits | lead | 2026-12-01T13:00Z/' "$FX/run.md" > "$T/runb.md"
rt line --run-body "$T/runb.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$FX/l42.md"; ck b6-control-b "0 $WANT" "$RC $OUT"
# control (c): --lite
rt line --run-body "$FX/run.md" --close "$CLOSE" --lite --ledger "$FX/l41.md" --ledger "$FX/l42.md"
ck b6-control-c-lite "0 - run timing: raw 4h00m; adjusted not captured (lite); blocked: person 1h05m, limits 15m, stalled not captured (lite), interrupted not captured (lite)" "$RC $OUT"
# a leading ~ on a ledger time is dropped, the time is used
sed 's/^- started: 2026-12-01T10:10Z/- started: ~2026-12-01T10:10Z/' "$FX/l41.md" > "$T/l41t.md"
rt line --run-body "$FX/run.md" --close "$CLOSE" --ledger "$T/l41t.md" --ledger "$FX/l42.md"; ck b6-tilde-time-used "0 $WANT" "$RC $OUT"
# a pure function: the same inputs give the same bytes, and no file is changed
before="$(cat "$FX/run.md" "$FX/l41.md" "$FX/l42.md" | shasum | cut -d' ' -f1)"
rt line --run-body "$FX/run.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$FX/l42.md"; o1="$OUT"
rt line --run-body "$FX/run.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$FX/l42.md"; ck b6-same-bytes-twice "$o1" "$OUT"
ck b6-inputs-unchanged "$before" "$(cat "$FX/run.md" "$FX/l41.md" "$FX/l42.md" | shasum | cut -d' ' -f1)"

# ---------- AC-B2 and section 4.4: not captured, all or nothing (stdout one line, exit 5) ----------
ncap() { # ncap <name> <want reason> <run body> [ledgers...]
  local n="$1" why="$2" b="$3" l; shift 3; set --; for l in $LEDGERS; do set -- "$@" --ledger "$l"; done
  rt line --run-body "$b" --close "$CLOSE" "$@"
  ck "$n" "5 - run timing: not captured ($why)" "$RC $OUT"
}
grep -v '^- started: ' "$FX/run.md" > "$T/nostart.md"
LEDGERS="$FX/l41.md $FX/l42.md"; ncap b2-control-d-no-started-line 'run section has no started: line' "$T/nostart.md"
LEDGERS="$FX/l41.md"; ncap b2-control-e-ledger-missing 'ledger of #42 missing' "$FX/run.md"
awk '/^### Run waits/ {skip=1} /^## Destination/ {skip=0} !skip' "$FX/run.md" > "$T/notable.md"
LEDGERS="$FX/l41.md $FX/l42.md"; ncap nc-no-run-waits-table 'run section has no Run waits table' "$T/notable.md"
sed 's/^| # | Kind | Agent | Start | End | What |$/| # | Kind | Agent | Start | End | Held item | What |/' "$FX/run.md" > "$T/badhead.md"
ncap nc-run-waits-header-not-exact 'run section has no Run waits table' "$T/badhead.md"
grep -v '^- started: ' "$FX/l42.md" > "$T/l42ns.md"
LEDGERS="$FX/l41.md $T/l42ns.md"; ncap nc-ledger-no-started 'ledger of #42 has no started: line' "$FX/run.md"
awk '/^### Waits/ {skip=1} /^### Person/ {skip=0} !skip' "$FX/l42.md" > "$T/l42nw.md"
LEDGERS="$FX/l41.md $T/l42nw.md"; ncap nc-ledger-no-waits-table 'ledger of #42 not in its grammar' "$FX/run.md"
sed 's/| 2026-12-01T12:30Z | 2026-12-01T12:40Z |/| soon | 2026-12-01T12:40Z |/' "$FX/l42.md" > "$T/l42bt.md"
LEDGERS="$FX/l41.md $T/l42bt.md"; ncap nc-ledger-row-time-not-a-time 'ledger of #42 not in its grammar' "$FX/run.md"
sed 's/^| R2 | limits |/| R2 | andon |/' "$FX/run.md" > "$T/r2andon.md"
LEDGERS="$FX/l41.md $FX/l42.md"; ncap nc-run-waits-row-kind-andon 'Run waits row R2 not in its grammar' "$T/r2andon.md"
sed 's/^| R1 | person | lead | 2026-12-01T13:30Z | 2026-12-01T13:45Z/| R1 | person | lead | 2026-12-01T13:45Z | 2026-12-01T13:30Z/' "$FX/run.md" > "$T/r1back.md"
ncap nc-run-waits-row-end-before-start 'Run waits row R1 not in its grammar' "$T/r1back.md"
# checked in the table's order: no started: line wins over a missing ledger
LEDGERS="$FX/l41.md"; ncap nc-order-started-first 'run section has no started: line' "$T/nostart.md"
# usage: a ledger of an item not in the run, a close before started, no close
sed 's/^## Ledger: #42 Item B/## Ledger: #43 Item C/' "$FX/l42.md" > "$T/l43.md"
rt line --run-body "$FX/run.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$FX/l42.md" --ledger "$T/l43.md"; ck line-ledger-not-of-the-run-exit-2 2 "$RC"
rt line --run-body "$FX/run.md" --close 2026-12-01T09:59:00Z --ledger "$FX/l41.md" --ledger "$FX/l42.md"; ck line-close-before-started-exit-2 2 "$RC"
rt line --run-body "$FX/run.md" --ledger "$FX/l41.md" --ledger "$FX/l42.md"; ck line-no-close-exit-2 2 "$RC"
rt line --run-body "$FX/run.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$T/does-not-exist.md"; ck line-unreadable-ledger-exit-2 2 "$RC"

# ---------- section 3: gaps, the worked example (S3a) ----------
rt gaps --run-body "$FX/run.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$FX/l42.md" -- "$FX/lead.tsv"
ck s3a-gaps-exit 0 "$RC"
ck s3a-gaps-stdout "$(printf 'stalled\t2026-12-01T10:00Z\t2026-12-01T10:10Z\tfound at close: silent-gap\nlimits\t2026-12-01T13:40Z\t2026-12-01T14:00Z\tfound at close: api-error:rate_limit')" "$OUT"
ck s3a-gaps-stderr-inside-items 1 "$(printf '%s\n' "$ERR" | grep -cxF "inside items: $SID.jsonl interrupted 2026-12-01T10:35:00.000Z")"
# the cut-offs output on stdin
OUT="$(/bin/bash "$RT" gaps --run-body "$FX/run.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$FX/l42.md" -- - < "$FX/lead.tsv" 2>/dev/null)"
ck s3a-gaps-stdin "$(printf 'stalled\t2026-12-01T10:00Z\t2026-12-01T10:10Z\tfound at close: silent-gap\nlimits\t2026-12-01T13:40Z\t2026-12-01T14:00Z\tfound at close: api-error:rate_limit')" "$OUT"
# a gap across an item's whole window is cut into the parts outside it, in order of start
printf '%s.jsonl\tstalled\t2026-12-01T10:05:00Z\t2026-12-01T12:10:00Z\tcut-mid-stream\n' "$SID" > "$T/cross.tsv"
rt gaps --run-body "$FX/b5.md" --close "$CLOSE" --ledger "$FX/l41.md" -- "$T/cross.tsv"
ck gaps-crossing-window-two-stretches "$(printf 'stalled\t2026-12-01T10:05Z\t2026-12-01T10:10Z\tfound at close: cut-mid-stream\nstalled\t2026-12-01T12:00Z\t2026-12-01T12:10Z\tfound at close: cut-mid-stream')" "$OUT"
# a gap wholly before started: nothing on stdout, named on stderr
printf '%s.jsonl\tlimits\t2026-12-01T09:00:00Z\t2026-12-01T09:30:00Z\tapi-error:rate_limit\n' "$SID" > "$T/before.tsv"
rt gaps --run-body "$FX/b5.md" --close "$CLOSE" --ledger "$FX/l41.md" -- "$T/before.tsv"
ck gaps-outside-the-run "0||1" "$RC|$OUT|$(printf '%s\n' "$ERR" | grep -cxF "outside the run: $SID.jsonl limits 2026-12-01T09:00:00Z")"
# exits
printf 'not a cut-offs line\n' > "$T/bad.tsv"
rt gaps --run-body "$FX/b5.md" --close "$CLOSE" --ledger "$FX/l41.md" -- "$T/bad.tsv"; ck gaps-bad-line-exit-2 "2|" "$RC|$OUT"
rt gaps --run-body "$FX/b5.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$FX/l42.md" -- "$FX/lead.tsv"; ck gaps-ledger-not-of-the-run-exit-2 2 "$RC"
rt gaps --run-body "$T/nostart.md" --close "$CLOSE" --ledger "$FX/l41.md" --ledger "$FX/l42.md" -- "$FX/lead.tsv"
ck gaps-no-started-exit-5 "5|" "$RC|$OUT"; ck gaps-no-started-reason-on-stderr 1 "$(printf '%s\n' "$ERR" | grep -cF 'not captured (run section has no started: line)')"

# ---------- AC-B5: transcript -> cut-offs.sh -> gaps -> add-run-wait, three rows, and a second close adds none ----------
chain() { # chain <body in> <body out>
  bash "$CO" --until 2026-12-01T14:00:00Z -- "$FX/lead-b5.jsonl" > "$T/co.tsv" || return 1
  /bin/bash "$RT" gaps --run-body "$1" --close 2026-12-01T14:00:00Z --ledger "$FX/l41.md" -- "$T/co.tsv" > "$T/gaps.tsv" 2>/dev/null || return 1
  cp "$1" "$T/cur.md"
  while IFS="$(printf '\t')" read -r k s e w; do
    /bin/bash "$RS" add-run-wait "$T/cur.md" --kind "$k" --start "$s" --end "$e" --what "$w" > "$T/next.md" || return 1
    mv "$T/next.md" "$T/cur.md"
  done < "$T/gaps.tsv"
  cp "$T/cur.md" "$2"
}
chain "$FX/b5.md" "$T/b5-1.md"; ck b5-chain-exit 0 $?
ck b5-three-rows "$(printf '%s\n' \
  '| R1 | limits | lead | 2026-12-01T12:05Z | 2026-12-01T12:20Z | found at close: api-error:rate_limit |' \
  '| R2 | stalled | lead | 2026-12-01T12:30Z | 2026-12-01T12:41Z | found at close: cut-mid-stream |' \
  '| R3 | interrupted | lead | 2026-12-01T13:00Z | 2026-12-01T13:07Z | found at close: api-error:server_error |')" "$(grep '^| R[0-9]' "$T/b5-1.md")"
chain "$T/b5-1.md" "$T/b5-2.md"; ck b5-second-close-adds-none "3 $(cat "$T/b5-1.md")" "$(grep -c '^| R[0-9]' "$T/b5-2.md") $(cat "$T/b5-2.md")"
# the rows the scan wrote are read by line for minutes with no item in flight (raw 240; #41: person 20, limits 30; outside: 15, 11, 7)
rt line --run-body "$T/b5-1.md" --close 2026-12-01T14:00:00Z --ledger "$FX/l41.md"
ck b5-line-reads-the-rows "0 - run timing: raw 4h00m; adjusted 2h37m; blocked: person 20m, limits 45m, stalled 11m, interrupted 7m" "$RC $OUT"

# ---------- AC-B7: generated runs, the script against QA's own replay, and the invariants ----------
if command -v python3 >/dev/null; then
  dur2m() { case "$1" in *h*) h="${1%%h*}"; m="${1#*h}"; m="${m%m}"; echo $((10#$h * 60 + 10#$m)) ;; *) m="${1%m}"; echo $((10#$m)) ;; esac; }
  agree=0; inv=0; n=0
  for seed in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25; do
    d="$T/g$seed"; mkdir -p "$d"
    args="$(python3 -I "$OR" gen "$d" "$seed")"
    # shellcheck disable=SC2086
    want="$(python3 -I "$OR" line $args)"
    # shellcheck disable=SC2086
    rt line $args
    n=$((n + 1))
    if [ "$RC" = 0 ] && [ "$OUT" = "$want" ]; then agree=$((agree + 1)); else echo "     seed $seed: want: $want"; echo "     seed $seed: got:  $RC $OUT"; fi
    set -- $(printf '%s\n' "$OUT" | sed -E 's/^- run timing: raw ([^;]+); adjusted ([^;]+); blocked: person ([^,]+), limits ([^,]+), stalled ([^,]+), interrupted (.+)$/\1 \2 \3 \4 \5 \6/')
    if [ $# = 6 ]; then
      r=$(dur2m "$1"); a=$(dur2m "$2"); s=$(( $(dur2m "$3") + $(dur2m "$4") + $(dur2m "$5") + $(dur2m "$6") ))
      [ "$s" -le "$r" ] && [ "$a" -ge 0 ] && [ "$a" = $((r - s)) ] && inv=$((inv + 1))
    fi
  done
  ck b7-script-agrees-with-qa-replay "$n" "$agree"
  ck b7-blocked-at-most-raw-adjusted-is-raw-less-blocked "$n" "$inv"
else
  skip b7-generated-runs "python3 missing"
fi
done_
