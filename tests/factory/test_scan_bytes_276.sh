#!/bin/bash
# #276 review: the scan reads a file byte for byte whatever the locale: a line with bytes that are not UTF-8, or a NUL byte, still
# yields "scan: <file>:<line>: <kind>" for its home path or secret.
# Synthetic files only.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
PT="$PLUGIN/scripts/post-text.sh"
cd "$T" || exit 1
HM=/ho; HM="${HM}me"
export HOME=/srv/hostuser
K=gh; K="${K}p_0123456789abcdef0123456789abcdef0123"
# not UTF-8, under a UTF-8 locale when the system has one
U8=""; for l in en_US.UTF-8 C.UTF-8 en_US.utf8; do locale -a 2>/dev/null | grep -qix "$l" && { U8=$l; break; }; done
printf 'a\n\377\376 %s/alice/x\n' "$HM" >bad.log
out="$(LC_ALL="${U8:-C}" bash "$PT" scan bad.log 2>&1)"; rc=$?
ck non-utf8-home-path-refused-rc 1 "$rc"
ck non-utf8-home-path-line "scan: bad.log:2: home-path" "$out"
printf 'a\n\377 TOKEN=%s\n' "$K" >bads.log
out="$(LC_ALL="${U8:-C}" bash "$PT" scan bads.log 2>&1)"; ck non-utf8-secret-line "scan: bads.log:2: secret" "$out"
# a NUL byte: the hit still names its line and kind
printf 'a\nb\nabc\000 %s/alice/x\n' "$HM" >nul.log
out="$(bash "$PT" scan nul.log 2>&1)"; rc=$?
ck nul-home-path-refused-rc 1 "$rc"
ck nul-home-path-line "scan: nul.log:3: home-path" "$out"
done_
