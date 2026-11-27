#!/bin/bash
# #276: the home-path scan lets the GitHub-hosted runner account's home folder through (CI stack traces in proof logs); every other account, and the host's own home, is still refused.
# Synthetic files only.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
PT="$PLUGIN/scripts/post-text.sh"
cd "$T" || exit 1
HM=/ho; HM="${HM}me"
export HOME=/srv/hostuser
# a CI stack trace under the runner account's home folder passes
printf 'FAIL x.test.js\n  at Object.<anonymous> (%s/runner/work/app/app/src/x.test.js:3:5)\n' "$HM" >ci.log
bash "$PT" scan ci.log; ck runner-home-passes 0 "$?"
printf 'cd %s/runner\nls %s/runner work\n' "$HM" "$HM" >ci2.log; bash "$PT" scan ci2.log; ck runner-home-at-end-and-before-space-passes 0 "$?"
# a macOS hosted runner uses the same account
US=/Us; US="${US}ers"
printf 'at %s/runner/work/app/x.swift:3\n' "$US" >ci3.log; bash "$PT" scan ci3.log; ck runner-mac-home-passes 0 "$?"
# a name that only starts with the account, and the account as a longer name, are still refused
printf 'cd %s/runneruser/x\n' "$HM" >p1.log; out="$(bash "$PT" scan p1.log)"; ck runner-prefix-refused-rc 1 "$?"; ck runner-prefix-line "scan: p1.log:1: home-path" "$out"
printf 'cd %s/runner.bak/x\n' "$HM" >p2.log; bash "$PT" scan p2.log >/dev/null; ck runner-dotted-refused 1 "$?"
# another account is still refused, also on a line that holds a runner path too
printf 'cd %s/alice/x\n' "$HM" >o1.log; bash "$PT" scan o1.log >/dev/null; ck other-account-refused 1 "$?"
printf 'cp %s/runner/work/a %s/alice/b\n' "$HM" "$HM" >o2.log; out="$(bash "$PT" scan o2.log)"; ck other-account-beside-runner-refused-rc 1 "$?"; ck other-account-beside-runner-line "scan: o2.log:1: home-path" "$out"
printf 'cd %s/bob/x\n' "$US" >o4.log; bash "$PT" scan o4.log >/dev/null; ck other-mac-account-refused 1 "$?"
# an account whose name is the home directory's own name, with the runner path inside it, is still refused (the exemption needs the same left boundary as the rule)
printf 'cd %s/runner/x\n' "$HM$HM" >o5.log; bash "$PT" scan o5.log >/dev/null; ck account-home-holding-runner-path-refused 1 "$?"
printf 'cd %s/runner/x\n' "$US$US" >o6.log; bash "$PT" scan o6.log >/dev/null; ck account-users-holding-runner-path-refused 1 "$?"
# a folder named home inside the runner's home is not another account's home
printf 'at %s/runner/home/alice/x\n' "$HM" >ci4.log; bash "$PT" scan ci4.log; ck home-folder-inside-runner-home-passes 0 "$?"
# two runner paths one separator apart both pass (a PATH line, a command with two arguments)
printf 'PATH=%s/runner:%s/runner/bin\nls %s/runner %s/runner/work\n' "$HM" "$HM" "$HM" "$HM" >ci5.log; bash "$PT" scan ci5.log; ck adjacent-runner-paths-pass 0 "$?"
# a Windows user folder is never exempt, with either slash (the Windows hosted account has another name)
printf 'C:%s/runner/x\n' "$US" >o7.log; bash "$PT" scan o7.log >/dev/null; ck windows-forward-slash-runner-refused 1 "$?"
printf 'C:\\%s\\runner\\x\n' "${US#/}" >o8.log; bash "$PT" scan o8.log >/dev/null; ck windows-backslash-runner-refused 1 "$?"
printf 'C:\\%s\\bob\\x\n' "${US#/}" >o3.log; bash "$PT" scan o3.log >/dev/null; ck windows-home-refused 1 "$?"
# the host's own home is refused even when it is the runner's folder (the factory running inside CI)
( HOME="$HM/runner"; bash "$PT" scan ci.log >/dev/null ); ck runner-as-host-home-refused 1 "$?"
# a secret on a runner line is still refused, and the scan never prints the text
K=gh; K="${K}p_0123456789abcdef0123456789abcdef0123"; printf 'at %s/runner/work/x TOKEN=%s\n' "$HM" "$K" >s.log
out="$(bash "$PT" scan s.log)"; ck secret-beside-runner-refused-rc 1 "$?"; ck secret-beside-runner-line "scan: s.log:1: secret" "$out"
ck scan-never-prints-text "no" "$(printf '%s' "$out" | grep -q 'ghp_\|runner' && echo yes || echo no)"
done_
