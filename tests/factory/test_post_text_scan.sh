#!/bin/bash
# Slice 1 of #207, the slice-0 leftover: post-text.sh render scans the draft itself, so the closing comment path is script-enforced.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
PT="$PLUGIN/scripts/post-text.sh"; RUN="$PLUGIN/skills/run/SKILL.md"
cd "$T" || exit 1
printf 'Status: done\nAbnormality: none\nSummary: built it\nArtifacts: x\n' >clean.md
H=/Use; H="${H}rs"   # built here so this file holds no home path itself
printf 'Status: done\nAbnormality: none\nSummary: built it\nArtifacts: %s/alice/proj/x\n' "$H" >homepath.md
K=gh; K="${K}p_0123456789abcdef0123456789abcdef0123"
printf 'Status: done\nAbnormality: none\nSummary: key %s\n' "$K" >secret.md

bash "$PT" render clean.md out-clean.md >/dev/null 2>&1; ck render-clean-rc 0 "$?"
ck render-clean-first-line "<!-- factory:result v1 -->" "$(head -n1 out-clean.md)"
out="$(bash "$PT" render homepath.md out-home.md 2>&1)"; rc=$?
ck render-home-path-refused-rc 1 "$rc"
ck render-home-path-line "scan: homepath.md:4: home-path" "$out"
ck render-home-path-no-output "no" "$([ -e out-home.md ] && echo yes || echo no)"
out="$(bash "$PT" render secret.md out-secret.md 2>&1)"; rc=$?
ck render-secret-refused-rc 1 "$rc"
ck render-secret-line "scan: secret.md:3: secret" "$out"
ck render-secret-never-prints-text "no" "$(printf '%s' "$out" | grep -q ghp_ && echo yes || echo no)"
# a draft with no Status is still exit 3 (the shape error), not a scan result
printf 'Summary: x\n' >nostatus.md; bash "$PT" render nostatus.md out-ns.md >/dev/null 2>&1; ck render-shape-error-still-3 3 "$?"

# standard text: the closing comment path no longer carries its own scan step
hasnt closing-comment-no-own-scan-step "$RUN" '(1) **scan** the draft'
has closing-comment-render-scans "$RUN" '(1) **render** it (`post-text.sh render <draft> <out>`, which scans the draft itself: a hit prints the file and line, writes nothing and exits 1; then post nothing, tell the person, keep the task `Running` and the issue open)'
has scan-rule-names-render "$RUN" '`post-text.sh render` scans its draft itself'
done_
