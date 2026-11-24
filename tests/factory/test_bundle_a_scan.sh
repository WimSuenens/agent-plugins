#!/bin/bash
# Bundle A item 2 (#252): the home-path scan matches the host's home only; a guest account's folder in a provisioning script passes.
# Synthetic files only.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
PT="$PLUGIN/scripts/post-text.sh"; SPUB="$PLUGIN/scripts/stage-publish.sh"
cd "$T" || exit 1
HM=/ho; HM="${HM}me"; US=/Us; US="${US}ers"; RT=/ro; RT="${RT}ot"
# a synthetic provisioning script for a guest machine
printf '#!/bin/sh\nmkdir -p %s/.ssh\ncp key %s/.ssh/authorized_keys\nchown -R guest %s/.ssh\n' "$RT" "$RT" "$RT" >guest.sh
export HOME=/srv/hostuser
bash "$PT" scan guest.sh; ck guest-root-path-passes 0 "$?"
printf 'x %s/ok/x\n' "$RT" >g2.md; bash "$PT" scan g2.md; ck guest-root-path-mid-line-passes 0 "$?"
# the host's own shapes are still refused
printf 'a\ncd %s/alice/proj\n' "$US" >h1.sh; out="$(bash "$PT" scan h1.sh)"; ck mac-home-refused-rc 1 "$?"; ck mac-home-names-line "scan: h1.sh:2: home-path" "$out"
printf 'cd %s/alice/proj\n' "$HM" >h2.sh; bash "$PT" scan h2.sh >/dev/null; ck linux-home-refused 1 "$?"
printf 'C:\\%s\\bob\\x\n' "${US#/}" >h3.sh; bash "$PT" scan h3.sh >/dev/null; ck windows-home-refused 1 "$?"
# the literal value of $HOME
printf 'a\nb\nsee /srv/hostuser/work/x\n' >h4.sh; out="$(bash "$PT" scan h4.sh)"; ck home-literal-refused-rc 1 "$?"; ck home-literal-names-line "scan: h4.sh:3: home-path" "$out"
printf 'see /srv/hostuserx/work\n' >h5.sh; bash "$PT" scan h5.sh >/dev/null; ck home-literal-needs-boundary 0 "$?"
# $HOME = /root: the root folder is then the host's home and is refused
printf 'cd %s/x\n' "$RT" >h6.sh; ( HOME="$RT"; bash "$PT" scan h6.sh >/dev/null ); ck root-is-home-refused 1 "$?"
# $HOME = / or empty adds no rule
( HOME=/; bash "$PT" scan guest.sh >/dev/null ); ck home-slash-no-rule 0 "$?"
( HOME=; bash "$PT" scan guest.sh >/dev/null ); ck home-empty-no-rule 0 "$?"
# a secret is still refused, and the text is never printed
K=gh; K="${K}p_0123456789abcdef0123456789abcdef0123"; printf 'a\nTOKEN=%s\n' "$K" >s.sh
out="$(bash "$PT" scan s.sh)"; ck secret-refused-rc 1 "$?"; ck secret-line "scan: s.sh:2: secret" "$out"
ck scan-never-prints-text "no" "$(printf '%s' "$out" | grep -q 'ghp_\|hostuser' && echo yes || echo no)"

# stage-publish: a guest script pushes; a host path is refused with file, line and what to do
git init -q --bare "$T/origin.git"; git clone -q "$T/origin.git" "$T/w" 2>/dev/null; cd "$T/w" || exit 1
git config commit.gpgsign false; git checkout -q -b item/1
cp ../guest.sh provision.sh; git add -A; git commit -q -m "#1 devops: provision"
bash "$SPUB" push . 2>/dev/null; ck publish-guest-script-pushes 0 "$?"
printf 'x\ncd %s/alice/p\n' "$US" >host.sh; git add -A; git commit -q -m "#1 devops: host path"
err="$(bash "$SPUB" push . 2>&1 >/dev/null)"; ck publish-host-path-refused 5 "$(bash "$SPUB" push . >/dev/null 2>&1; echo $?)"
printf '%s' "$err" | grep -q 'scan: host.sh:2: home-path'; ck publish-names-file-and-line 0 "$?"
printf '%s' "$err" | grep -q 'fix the line'; ck publish-says-fix-the-line 0 "$?"
printf '%s' "$err" | grep -q 'do not use a plain `git push`'; ck publish-says-no-plain-push 0 "$?"
printf '%s' "$err" | grep -q 'file an issue'; ck publish-says-file-an-issue 0 "$?"
done_
