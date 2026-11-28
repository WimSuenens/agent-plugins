# QA 286 runtime proof: scenario transcript (scenario script below, then its output)

```bash
#!/bin/bash
# Runtime proof for #286 (AC-A1, AC-B4): the new standard's run-start, run-wait and run-close commands, in the order the text names them,
# on a throwaway sandbox (a copy of plugins/factory at the commit under test, three project variants). No tracker writes: every
# `gh issue edit --body-file` of the text is a copy of the body file here.
set -u
WT="$1"; SB="$(mktemp -d "$2/sandbox.XXXXXX")"
git -C "$WT" archive HEAD plugins/factory tests/factory/fixtures/run286 tests/factory/fixtures/a3/v4-ok.md | tar -x -C "$SB"
P="$SB/plugins/factory/scripts"; FX="$SB/tests/factory/fixtures/run286"
say() { printf '\n$ %s\n' "$*" | sed "s|$SB|<sb>|g" >&2; }
run() { say "$*"; "$@"; rc=$?; echo "[exit $rc]" >&2; return $rc; }
echo "commit under test: $(git -C "$WT" rev-parse --short HEAD); sandbox: <scratch>/$(basename "$SB")"
echo "session id in the environment: CLAUDE_SESSION_ID=${CLAUDE_SESSION_ID:-<unset>}"
SID=0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c   # the lead session of the transcript fixture lead-b5.jsonl
for v in obeya-on obeya-off no-obeya; do
  D="$SB/proj-$v"; mkdir -p "$D/docs/agents"
  case $v in
    obeya-on)  printf '# Factory\n\n## Obeya\n\n- obeya: on\n' > "$D/docs/agents/factory.md" ;;
    obeya-off) printf '# Factory\n\n## Obeya\n\n- obeya: off\n' > "$D/docs/agents/factory.md" ;;
    no-obeya)  printf '# Factory\n\n## Ownership\n\n- tests/: qa-engineer\n' > "$D/docs/agents/factory.md" ;;
  esac
  cd "$D" || exit 1
  echo; echo "=================== variant $v: docs/agents/factory.md ==================="; cat docs/agents/factory.md
  grep -c 'obeya-discipline' docs/agents/factory.md | sed 's/^/obeya-discipline lines: /'
  # a closed run section of an earlier run (step 0 replaces it: references/run-overrides.md, Run identity)
  printf '# Map: sandbox\n\n## Factory run\n\n- started: 2026-11-20T09:00:00Z\n- step: 9 (run closed)\n- in flight: none\n- A3: https://example.invalid/issues/9#issuecomment-9\n\n## Destination\n\nsandbox\n' > old.md
  echo "--- step 0: run start"
  run bash "$P/run-state.sh" start old.md --now 2026-12-01T10:00:00Z > new.md; cat new.md
  run bash "$P/run-state.sh" add-session new.md "$SID" > s.md; grep -- '- lead sessions' s.md
  run bash "$P/run-state.sh" started s.md
  cp s.md posted.md   # stands for gh issue edit --body-file
  echo "--- step 4: the Lead asks which slice next (no item in flight); the answer is read at 10:08"
  run bash "$P/run-state.sh" add-run-wait posted.md --kind person --start 2026-12-01T10:02:00Z --end 2026-12-01T10:08:00Z --what 'which slice next? (step 4)' > w1.md && cp w1.md posted.md
  echo "--- item #41 runs 10:10 to its approval at 12:00 (ledger fixture l41.md); step 8 writes closed in this run"
  sed 's|^- closed in this run: none$|- closed in this run: #41 https://example.invalid/issues/41#issuecomment-1|; s|^- step: 0$|- step: 9|' posted.md > c.md && cp c.md posted.md
  echo "--- step 9.0: Close the run now? put 13:30, answer read 13:45"
  run bash "$P/run-state.sh" add-run-wait posted.md --kind person --start 2026-12-01T13:30:00Z --end 2026-12-01T13:45:00Z --what 'Close the run now? (step 9.0)' > w2.md && cp w2.md posted.md
  echo "--- step 9.2 a: close stamp 2026-12-01T14:00:00Z; b: run-close scan of the lead transcript"
  run bash "$P/run-state.sh" lead-sessions posted.md
  cp "$FX/lead-b5.jsonl" "$SID.jsonl"
  run bash "$P/cut-offs.sh" --until 2026-12-01T14:00:00Z -- "$SID.jsonl" > co.tsv; cat co.tsv
  echo "--- c: gaps, one add-run-wait per line"
  run bash "$P/run-timing.sh" gaps --run-body posted.md --close 2026-12-01T14:00:00Z --ledger "$FX/l41.md" -- co.tsv > gaps.tsv; cat gaps.tsv
  while IFS="$(printf '\t')" read -r k s e w; do
    bash "$P/run-state.sh" add-run-wait posted.md --kind "$k" --start "$s" --end "$e" --what "$w" > n.md && cp n.md posted.md
  done < gaps.tsv
  sed -n '/^### Run waits/,/^## /p' posted.md
  echo "--- d: run-timing.sh line"
  run bash "$P/run-timing.sh" line --run-body posted.md --close 2026-12-01T14:00:00Z --ledger "$FX/l41.md" > line.txt; cat line.txt
  echo "--- the A3 v4 (v4-ok.md with this run's run timing line and series 3.10)"
  awk -v l="$(cat line.txt)" '/^- run timing:/ {print l; next} {print}' "$SB/tests/factory/fixtures/a3/v4-ok.md" | sed 's/series 2\.3)/series 3.10)/' > a3.md
  grep -E '^<!-- factory:a3|^- run timing|^- discipline|^- run compared|^- guardrails' a3.md
  run bash "$P/a3-check.sh" a3.md
  echo "--- e: after Post A3, created_at 2026-12-01T14:03:12Z; d again"
  run bash "$P/run-timing.sh" line --run-body posted.md --close 2026-12-01T14:03:12Z --ledger "$FX/l41.md"
  cat new.md posted.md line.txt > "$SB/out-$v.txt"
done
echo; echo "=================== the three variants give the same bytes ==================="
cmp "$SB/out-obeya-on.txt" "$SB/out-obeya-off.txt" && cmp "$SB/out-obeya-on.txt" "$SB/out-no-obeya.txt" && echo "identical: obeya on = obeya off = no Obeya section"
echo "scripts that read docs/agents/factory.md: $(grep -l 'docs/agents/factory.md' "$P/run-state.sh" "$P/run-timing.sh" "$P/a3-check.sh" | xargs -n1 basename | tr '\n' ' ') (comments only:)"
grep -n 'factory\.md' "$P/run-state.sh" "$P/run-timing.sh" "$P/a3-check.sh" | sed "s|$SB/||"
```

```text
commit under test: 454a218; sandbox: <scratch>/sandbox.SfXhdL
session id in the environment: CLAUDE_SESSION_ID=<unset>

=================== variant obeya-on: docs/agents/factory.md ===================
# Factory

## Obeya

- obeya: on
obeya-discipline lines: 0
--- step 0: run start

$ bash <sb>/plugins/factory/scripts/run-state.sh start old.md --now 2026-12-01T10:00:00Z
[exit 0]
# Map: sandbox

## Factory run

- started: 2026-12-01T10:00:00Z
- step: 0
- in flight: none
- FREEZE: none yet
- lead sessions: none yet
- closed in this run: none
- previous run: https://example.invalid/issues/9#issuecomment-9
- baseline: not yet

### Run waits

| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|

## Destination

sandbox

$ bash <sb>/plugins/factory/scripts/run-state.sh add-session new.md 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c
[exit 0]
- lead sessions: 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c

$ bash <sb>/plugins/factory/scripts/run-state.sh started s.md
2026-12-01T10:00:00Z
[exit 0]
--- step 4: the Lead asks which slice next (no item in flight); the answer is read at 10:08

$ bash <sb>/plugins/factory/scripts/run-state.sh add-run-wait posted.md --kind person --start 2026-12-01T10:02:00Z --end 2026-12-01T10:08:00Z --what which slice next? (step 4)
[exit 0]
--- item #41 runs 10:10 to its approval at 12:00 (ledger fixture l41.md); step 8 writes closed in this run
--- step 9.0: Close the run now? put 13:30, answer read 13:45

$ bash <sb>/plugins/factory/scripts/run-state.sh add-run-wait posted.md --kind person --start 2026-12-01T13:30:00Z --end 2026-12-01T13:45:00Z --what Close the run now? (step 9.0)
[exit 0]
--- step 9.2 a: close stamp 2026-12-01T14:00:00Z; b: run-close scan of the lead transcript

$ bash <sb>/plugins/factory/scripts/run-state.sh lead-sessions posted.md
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c
[exit 0]

$ bash <sb>/plugins/factory/scripts/cut-offs.sh --until 2026-12-01T14:00:00Z -- 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl
[exit 0]
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl	limits	2026-12-01T12:05:30Z	2026-12-01T12:20:10Z	api-error:rate_limit
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl	stalled	2026-12-01T12:30:20Z	2026-12-01T12:41:30Z	cut-mid-stream
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl	interrupted	2026-12-01T13:00:05Z	2026-12-01T13:07:59Z	api-error:server_error
--- c: gaps, one add-run-wait per line

$ bash <sb>/plugins/factory/scripts/run-timing.sh gaps --run-body posted.md --close 2026-12-01T14:00:00Z --ledger <sb>/tests/factory/fixtures/run286/l41.md -- co.tsv
[exit 0]
limits	2026-12-01T12:05Z	2026-12-01T12:20Z	found at close: api-error:rate_limit
stalled	2026-12-01T12:30Z	2026-12-01T12:41Z	found at close: cut-mid-stream
interrupted	2026-12-01T13:00Z	2026-12-01T13:07Z	found at close: api-error:server_error
### Run waits

| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|
| R1 | person | lead | 2026-12-01T10:02Z | 2026-12-01T10:08Z | which slice next? (step 4) |
| R2 | person | lead | 2026-12-01T13:30Z | 2026-12-01T13:45Z | Close the run now? (step 9.0) |
| R3 | limits | lead | 2026-12-01T12:05Z | 2026-12-01T12:20Z | found at close: api-error:rate_limit |
| R4 | stalled | lead | 2026-12-01T12:30Z | 2026-12-01T12:41Z | found at close: cut-mid-stream |
| R5 | interrupted | lead | 2026-12-01T13:00Z | 2026-12-01T13:07Z | found at close: api-error:server_error |

## Destination
--- d: run-timing.sh line

$ bash <sb>/plugins/factory/scripts/run-timing.sh line --run-body posted.md --close 2026-12-01T14:00:00Z --ledger <sb>/tests/factory/fixtures/run286/l41.md
[exit 0]
- run timing: raw 4h00m; adjusted 2h16m; blocked: person 41m, limits 45m, stalled 11m, interrupted 7m
--- the A3 v4 (v4-ok.md with this run's run timing line and series 3.10)
<!-- factory:a3 v4 -->
- run timing: raw 4h00m; adjusted 2h16m; blocked: person 41m, limits 45m, stalled 11m, interrupted 7m
- discipline: off
- run compared: none (no run with discipline off in series 3.10)
- guardrails: first-pass yield 1 of 2 items passed first time; rework per item 0, 1 (2 of 2 items)

$ bash <sb>/plugins/factory/scripts/a3-check.sh a3.md
ok v4
[exit 0]
--- e: after Post A3, created_at 2026-12-01T14:03:12Z; d again

$ bash <sb>/plugins/factory/scripts/run-timing.sh line --run-body posted.md --close 2026-12-01T14:03:12Z --ledger <sb>/tests/factory/fixtures/run286/l41.md
- run timing: raw 4h03m; adjusted 2h19m; blocked: person 41m, limits 45m, stalled 11m, interrupted 7m
[exit 0]

=================== variant obeya-off: docs/agents/factory.md ===================
# Factory

## Obeya

- obeya: off
obeya-discipline lines: 0
--- step 0: run start

$ bash <sb>/plugins/factory/scripts/run-state.sh start old.md --now 2026-12-01T10:00:00Z
[exit 0]
# Map: sandbox

## Factory run

- started: 2026-12-01T10:00:00Z
- step: 0
- in flight: none
- FREEZE: none yet
- lead sessions: none yet
- closed in this run: none
- previous run: https://example.invalid/issues/9#issuecomment-9
- baseline: not yet

### Run waits

| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|

## Destination

sandbox

$ bash <sb>/plugins/factory/scripts/run-state.sh add-session new.md 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c
[exit 0]
- lead sessions: 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c

$ bash <sb>/plugins/factory/scripts/run-state.sh started s.md
2026-12-01T10:00:00Z
[exit 0]
--- step 4: the Lead asks which slice next (no item in flight); the answer is read at 10:08

$ bash <sb>/plugins/factory/scripts/run-state.sh add-run-wait posted.md --kind person --start 2026-12-01T10:02:00Z --end 2026-12-01T10:08:00Z --what which slice next? (step 4)
[exit 0]
--- item #41 runs 10:10 to its approval at 12:00 (ledger fixture l41.md); step 8 writes closed in this run
--- step 9.0: Close the run now? put 13:30, answer read 13:45

$ bash <sb>/plugins/factory/scripts/run-state.sh add-run-wait posted.md --kind person --start 2026-12-01T13:30:00Z --end 2026-12-01T13:45:00Z --what Close the run now? (step 9.0)
[exit 0]
--- step 9.2 a: close stamp 2026-12-01T14:00:00Z; b: run-close scan of the lead transcript

$ bash <sb>/plugins/factory/scripts/run-state.sh lead-sessions posted.md
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c
[exit 0]

$ bash <sb>/plugins/factory/scripts/cut-offs.sh --until 2026-12-01T14:00:00Z -- 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl
[exit 0]
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl	limits	2026-12-01T12:05:30Z	2026-12-01T12:20:10Z	api-error:rate_limit
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl	stalled	2026-12-01T12:30:20Z	2026-12-01T12:41:30Z	cut-mid-stream
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl	interrupted	2026-12-01T13:00:05Z	2026-12-01T13:07:59Z	api-error:server_error
--- c: gaps, one add-run-wait per line

$ bash <sb>/plugins/factory/scripts/run-timing.sh gaps --run-body posted.md --close 2026-12-01T14:00:00Z --ledger <sb>/tests/factory/fixtures/run286/l41.md -- co.tsv
[exit 0]
limits	2026-12-01T12:05Z	2026-12-01T12:20Z	found at close: api-error:rate_limit
stalled	2026-12-01T12:30Z	2026-12-01T12:41Z	found at close: cut-mid-stream
interrupted	2026-12-01T13:00Z	2026-12-01T13:07Z	found at close: api-error:server_error
### Run waits

| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|
| R1 | person | lead | 2026-12-01T10:02Z | 2026-12-01T10:08Z | which slice next? (step 4) |
| R2 | person | lead | 2026-12-01T13:30Z | 2026-12-01T13:45Z | Close the run now? (step 9.0) |
| R3 | limits | lead | 2026-12-01T12:05Z | 2026-12-01T12:20Z | found at close: api-error:rate_limit |
| R4 | stalled | lead | 2026-12-01T12:30Z | 2026-12-01T12:41Z | found at close: cut-mid-stream |
| R5 | interrupted | lead | 2026-12-01T13:00Z | 2026-12-01T13:07Z | found at close: api-error:server_error |

## Destination
--- d: run-timing.sh line

$ bash <sb>/plugins/factory/scripts/run-timing.sh line --run-body posted.md --close 2026-12-01T14:00:00Z --ledger <sb>/tests/factory/fixtures/run286/l41.md
[exit 0]
- run timing: raw 4h00m; adjusted 2h16m; blocked: person 41m, limits 45m, stalled 11m, interrupted 7m
--- the A3 v4 (v4-ok.md with this run's run timing line and series 3.10)
<!-- factory:a3 v4 -->
- run timing: raw 4h00m; adjusted 2h16m; blocked: person 41m, limits 45m, stalled 11m, interrupted 7m
- discipline: off
- run compared: none (no run with discipline off in series 3.10)
- guardrails: first-pass yield 1 of 2 items passed first time; rework per item 0, 1 (2 of 2 items)

$ bash <sb>/plugins/factory/scripts/a3-check.sh a3.md
ok v4
[exit 0]
--- e: after Post A3, created_at 2026-12-01T14:03:12Z; d again

$ bash <sb>/plugins/factory/scripts/run-timing.sh line --run-body posted.md --close 2026-12-01T14:03:12Z --ledger <sb>/tests/factory/fixtures/run286/l41.md
- run timing: raw 4h03m; adjusted 2h19m; blocked: person 41m, limits 45m, stalled 11m, interrupted 7m
[exit 0]

=================== variant no-obeya: docs/agents/factory.md ===================
# Factory

## Ownership

- tests/: qa-engineer
obeya-discipline lines: 0
--- step 0: run start

$ bash <sb>/plugins/factory/scripts/run-state.sh start old.md --now 2026-12-01T10:00:00Z
[exit 0]
# Map: sandbox

## Factory run

- started: 2026-12-01T10:00:00Z
- step: 0
- in flight: none
- FREEZE: none yet
- lead sessions: none yet
- closed in this run: none
- previous run: https://example.invalid/issues/9#issuecomment-9
- baseline: not yet

### Run waits

| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|

## Destination

sandbox

$ bash <sb>/plugins/factory/scripts/run-state.sh add-session new.md 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c
[exit 0]
- lead sessions: 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c

$ bash <sb>/plugins/factory/scripts/run-state.sh started s.md
2026-12-01T10:00:00Z
[exit 0]
--- step 4: the Lead asks which slice next (no item in flight); the answer is read at 10:08

$ bash <sb>/plugins/factory/scripts/run-state.sh add-run-wait posted.md --kind person --start 2026-12-01T10:02:00Z --end 2026-12-01T10:08:00Z --what which slice next? (step 4)
[exit 0]
--- item #41 runs 10:10 to its approval at 12:00 (ledger fixture l41.md); step 8 writes closed in this run
--- step 9.0: Close the run now? put 13:30, answer read 13:45

$ bash <sb>/plugins/factory/scripts/run-state.sh add-run-wait posted.md --kind person --start 2026-12-01T13:30:00Z --end 2026-12-01T13:45:00Z --what Close the run now? (step 9.0)
[exit 0]
--- step 9.2 a: close stamp 2026-12-01T14:00:00Z; b: run-close scan of the lead transcript

$ bash <sb>/plugins/factory/scripts/run-state.sh lead-sessions posted.md
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c
[exit 0]

$ bash <sb>/plugins/factory/scripts/cut-offs.sh --until 2026-12-01T14:00:00Z -- 0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl
[exit 0]
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl	limits	2026-12-01T12:05:30Z	2026-12-01T12:20:10Z	api-error:rate_limit
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl	stalled	2026-12-01T12:30:20Z	2026-12-01T12:41:30Z	cut-mid-stream
0b7c4f1e-2d55-4c1e-9a7e-3f0d8e2a1b6c.jsonl	interrupted	2026-12-01T13:00:05Z	2026-12-01T13:07:59Z	api-error:server_error
--- c: gaps, one add-run-wait per line

$ bash <sb>/plugins/factory/scripts/run-timing.sh gaps --run-body posted.md --close 2026-12-01T14:00:00Z --ledger <sb>/tests/factory/fixtures/run286/l41.md -- co.tsv
[exit 0]
limits	2026-12-01T12:05Z	2026-12-01T12:20Z	found at close: api-error:rate_limit
stalled	2026-12-01T12:30Z	2026-12-01T12:41Z	found at close: cut-mid-stream
interrupted	2026-12-01T13:00Z	2026-12-01T13:07Z	found at close: api-error:server_error
### Run waits

| # | Kind | Agent | Start | End | What |
|---|---|---|---|---|---|
| R1 | person | lead | 2026-12-01T10:02Z | 2026-12-01T10:08Z | which slice next? (step 4) |
| R2 | person | lead | 2026-12-01T13:30Z | 2026-12-01T13:45Z | Close the run now? (step 9.0) |
| R3 | limits | lead | 2026-12-01T12:05Z | 2026-12-01T12:20Z | found at close: api-error:rate_limit |
| R4 | stalled | lead | 2026-12-01T12:30Z | 2026-12-01T12:41Z | found at close: cut-mid-stream |
| R5 | interrupted | lead | 2026-12-01T13:00Z | 2026-12-01T13:07Z | found at close: api-error:server_error |

## Destination
--- d: run-timing.sh line

$ bash <sb>/plugins/factory/scripts/run-timing.sh line --run-body posted.md --close 2026-12-01T14:00:00Z --ledger <sb>/tests/factory/fixtures/run286/l41.md
[exit 0]
- run timing: raw 4h00m; adjusted 2h16m; blocked: person 41m, limits 45m, stalled 11m, interrupted 7m
--- the A3 v4 (v4-ok.md with this run's run timing line and series 3.10)
<!-- factory:a3 v4 -->
- run timing: raw 4h00m; adjusted 2h16m; blocked: person 41m, limits 45m, stalled 11m, interrupted 7m
- discipline: off
- run compared: none (no run with discipline off in series 3.10)
- guardrails: first-pass yield 1 of 2 items passed first time; rework per item 0, 1 (2 of 2 items)

$ bash <sb>/plugins/factory/scripts/a3-check.sh a3.md
ok v4
[exit 0]
--- e: after Post A3, created_at 2026-12-01T14:03:12Z; d again

$ bash <sb>/plugins/factory/scripts/run-timing.sh line --run-body posted.md --close 2026-12-01T14:03:12Z --ledger <sb>/tests/factory/fixtures/run286/l41.md
- run timing: raw 4h03m; adjusted 2h19m; blocked: person 41m, limits 45m, stalled 11m, interrupted 7m
[exit 0]

=================== the three variants give the same bytes ===================
identical: obeya on = obeya off = no Obeya section
scripts that read docs/agents/factory.md: run-state.sh run-timing.sh  (comments only:)
plugins/factory/scripts/run-state.sh:29:#   Neither writes to the tracker: the lead scans the printed body and posts it (`gh issue edit --body-file`). Neither reads docs/agents/factory.md.
plugins/factory/scripts/run-timing.sh:19:# A pure function of its arguments: reads no clock, writes no file, calls no network and reads no line of docs/agents/factory.md.
```
