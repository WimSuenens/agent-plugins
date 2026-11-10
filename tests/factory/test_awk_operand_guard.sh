#!/bin/bash
# #106: a relative file named like an awk assignment (x=1) is a file, not a variable, in post-text.sh and board.sh.
# Each path runs twice, once with a plain name (the reference) and once with the file literally named x=1; the results must match.
. "$(dirname "$0")/lib.sh"
. "$(dirname "$0")/lib64.sh"
PT="$PLUGIN/scripts/post-text.sh"
exec </dev/null # a misread operand makes awk wait on stdin: fail, do not hang
fake_setup
W="$T/w"; mkdir -p "$W"; cd "$W" || exit 1

# ---------- post-text.sh: render, elide, split ----------
printf '<!-- factory:result v1 -->\nStatus: done\nSummary: one line\nArtifacts: a\n' >draft-plain
cp draft-plain 'x=1'
bash "$PT" render draft-plain out-plain >/dev/null 2>&1; rc_plain=$?
bash "$PT" render 'x=1' out-x >/dev/null 2>&1; rc_x=$?
ck render-draft-named-x=1-exit "$rc_plain" "$rc_x"
ck render-draft-named-x=1-output "$(cat out-plain)" "$(cat out-x 2>/dev/null)"
differ render-reference-not-empty "" "$(cat out-plain)"

{ echo 'before'; echo '```'; i=0; while [ $i -lt 20 ]; do echo "line $i"; i=$((i + 1)); done; echo '```'; echo 'after'; } >in-plain
cp in-plain 'x=1'
n_plain="$(bash "$PT" elide in-plain eo-plain ref --max 10 2>/dev/null)"
n_x="$(bash "$PT" elide 'x=1' eo-x ref --max 10 2>/dev/null)"
ck elide-in-named-x=1-count "$n_plain" "$n_x"
ck elide-in-named-x=1-output "$(cat eo-plain)" "$(cat eo-x 2>/dev/null)"
ck elide-reference-elided-one 1 "$n_plain"

{ printf '<!-- factory:result v1 -->\nStatus: done\nSummary: s\n\n<details>\n<summary>Details</summary>\n\n'
  i=0; while [ $i -lt 1500 ]; do printf 'body line %05d %s\n' "$i" "0123456789012345678901234567890123456789"; i=$((i + 1)); done
  printf '\n</details>\n'; } >sp-plain
cp sp-plain 'x=1'
m_plain="$(bash "$PT" split sp-plain sd-plain 2>/dev/null)"
m_x="$(bash "$PT" split 'x=1' sd-x 2>/dev/null)"
ck split-in-named-x=1-parts "$m_plain" "$m_x"
ck split-reference-has-parts "yes" "$([ "${m_plain:-0}" -ge 2 ] && echo yes || echo no)"
ck split-in-named-x=1-part-1 "$(cat sd-plain/part-1.md)" "$(cat sd-x/part-1.md 2>/dev/null)"

# ---------- board.sh: table_get, factory_md and tracker_md in finish ----------
# table_get: owner and project come from the Tracker table of a relative --factory-md named x=1
board_load "$FX64/board-v1.json"
printf '| Key | Value |\n|---|---|\n| owner | fixt |\n| project number | 77 |\n' >'x=1'
bash "$BOARD_SH" plan --factory-md 'x=1' >"$T/p.out" 2>"$T/p.err"; rc=$?
ck table-get-factory-md-named-x=1-exit 0 "$rc"
has table-get-factory-md-named-x=1-reads-the-table "$T/p.out" "board: project fixt/77"
rm -f 'x=1'

# finish: a migrated board, then both files relative and named like assignments
board_load "$FX64/board-v1.json"; rm -rf "$SD"
bsa apply --yes >/dev/null; bsa apply --yes --views-confirmed >/dev/null
finish_with() { # <factory.md> <tracker.md>
  cp "$FX64/factory-1x.md" "$1"; cp "$FX64/tracker-1x.md" "$2"
  bash "$BOARD_SH" finish --owner fixt --project 77 --project-id PVT_fixture01 --views-confirmed --factory-md "$1" --tracker-md "$2" >"$T/f.out" 2>"$T/f.err"
  FRC=$?
}
finish_with fplain.md tplain.md; rc_plain=$FRC; out_plain="$(cat "$T/f.out")"
finish_with 'x=1' 'y=2'; rc_x=$FRC
ck finish-reference-exit-0 0 "$rc_plain"
ck finish-named-x=1-exit "$rc_plain" "$rc_x"
ck finish-named-x=1-output "$out_plain" "$(cat "$T/f.out")"
ck finish-factory-md-named-x=1 "$(cat fplain.md)" "$(cat 'x=1' 2>/dev/null)"
ck finish-tracker-md-named-y=2 "$(cat tplain.md)" "$(cat 'y=2' 2>/dev/null)"
differ finish-changed-the-tracker-doc "$(cat "$FX64/tracker-1x.md")" "$(cat 'y=2' 2>/dev/null)"
done_
