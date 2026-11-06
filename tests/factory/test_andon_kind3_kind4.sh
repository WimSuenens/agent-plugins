#!/bin/bash
# AC-4 (kind 3, role outside its role) and AC-5 (kind 4, slow stage, the 2x test).
# The Lead follows the written rules of plugins/factory/skills/run/SKILL.md `## Andon`, `### Detection`; these are
# executable transcriptions of those steps (the only code, the Lead being an agent), run on scratch repos and stage-log fixtures.
# The text itself is pinned in test_andon_text.sh.
. "$(dirname "$0")/lib.sh"

# ---------- kind 3 ----------
# owner_of <factory.md> <path>: the Owner of the row with the longest matching token, or empty (unowned)
owner_of() {
  awk -F'|' -v P="$2" '
    /^\| / && NF>=4 {
      cell=$2; owner=$3; gsub(/^ +| +$/,"",owner)
      s=cell
      while (match(s, /`[^`]*`/)) {
        tok=substr(s,RSTART+1,RLENGTH-2); rest=substr(s,RSTART+RLENGTH); s=rest
        if (tok !~ /[\/.]/) continue
        if (tok ~ /^[# ]/) continue
        if (rest ~ /^ *section/) continue
        m=0
        if (tok ~ /\/$/) { t=substr(tok,1,length(tok)-1); if (P==t || index(P,tok)==1) m=1 }
        else if (tok ~ /\*/) { re=tok; gsub(/[.]/,"\\.",re); gsub(/\*/,".*",re); if (P ~ "^" re "$") m=1 }
        else if (P==tok) m=1
        if (m && length(tok)>best) { best=length(tok); own=owner }
      }
    }
    END { print own }' "$1"
}
ROLES="product-owner architect developer qa-engineer security-reviewer devops docs-writer"
# kind3 <repo> <factory.md> <base>: prints one line per flagged commit
kind3() {
  git -C "$1" log --no-merges --format='%H%x09%s' "$3"..HEAD | while IFS="$(printf '\t')" read -r sha subj; do
    r="$(printf '%s' "$subj" | sed -nE 's/^#[0-9]+ ([a-z-]+): .*/\1/p')"
    [ -n "$r" ] || continue
    case " $ROLES " in *" $r "*) ;; *) continue ;; esac
    git -C "$1" diff-tree -z --no-commit-id --name-only -r --no-renames "$sha" | while IFS= read -r -d '' p; do
      case "$p" in *[[:cntrl:]]*) echo "role-outside-role: $(echo $sha | cut -c1-7) $r changed an unclassifiable path (name escaped: $(printf '%q' "$p"))"; continue ;; esac
      o="$(owner_of "$2" "$p")"
      [ -n "$o" ] && [ "$o" != "$r" ] && echo "role-outside-role: $(echo $sha | cut -c1-7) $r changed $p (owner $o)"
    done
  done
}
mkrepo() { rm -rf "$1"; mkdir -p "$1/docs/agents"; git -C "$1" init -q -b main; cp "$REPO/docs/agents/factory.md" "$1/docs/agents/factory.md"
  echo base > "$1/README.md"; mkdir -p "$1/docs"; git -C "$1" add -A; git -C "$1" commit -qm "base"; git -C "$1" checkout -q -b item/7; }
cm() { # repo role-or-text paths...  (writes each path, commits with subject)
  r="$1"; subj="$2"; shift 2; for p in "$@"; do mkdir -p "$(dirname "$r/$p")"; echo "$RANDOM$p" >> "$r/$p"; done; git -C "$r" add -A; git -C "$r" commit -qm "$subj"; }

# the table of this repository is the fixture
FM="$REPO/docs/agents/factory.md"
ck k3-table-owner-plugins developer "$(owner_of "$FM" plugins/factory/x.sh)"
ck k3-table-owner-tests qa-engineer "$(owner_of "$FM" tests/fixtures/y.md)"
ck k3-table-owner-reviews-qa-glob qa-engineer "$(owner_of "$FM" reviews/qa-7.md)"
ck k3-table-owner-reviews-security-glob security-reviewer "$(owner_of "$FM" reviews/security-7.md)"
ck k3-table-longest-match-requirements product-owner "$(owner_of "$FM" docs/requirements/7-x.md)"
ck k3-table-docs-rest docs-writer "$(owner_of "$FM" docs/guide.md)"
ck k3-table-readme docs-writer "$(owner_of "$FM" README.md)"
ck k3-table-adr architect "$(owner_of "$FM" docs/adr/0014-x.md)"
ck k3-table-work-unowned "" "$(owner_of "$FM" work/7/00-lead-state.md)"
ck k3-table-prose-row-skipped "" "$(owner_of "$FM" scripts/deploy.sh)"

R="$T/k3"; mkrepo "$R"
cm "$R" "#7 developer: build" plugins/factory/x.sh
cm "$R" "#7 developer: add fixture" tests/fixtures/y.md
cm "$R" "#7 qa-engineer: verdict" tests/t.sh reviews/qa-7.md
mkdir -p "$R/work/7"; cm "$R" "#7 lead: remove work/" work/7/00-lead-state.md
out="$(kind3 "$R" "$R/docs/agents/factory.md" main)"
ck k3-ac4-exactly-one-flag 1 "$(echo "$out" | grep -c .)"
case "$out" in "role-outside-role: "*" developer changed tests/fixtures/y.md (owner qa-engineer)") ok=1 ;; *) ok=0 ;; esac
ck k3-ac4-flags-the-second-commit 1 "$ok"
sha2="$(git -C "$R" log --format='%h %s' | grep 'add fixture' | cut -d' ' -f1)"
ck k3-ac4-sha-is-second-commit "$sha2" "$(echo "$out" | awk '{print $2}')"
# role's own messages in work/<id>/ and the lead's commits are never flagged; unowned paths too
cm "$R" "#7 developer: result" work/7/06-result-developer.md
cm "$R" "#7 lead: edit anything" plugins/factory/z.md tests/q.sh docs/requirements/7-x.md
cm "$R" "no role pattern here" tests/q2.sh
cm "$R" "#7 reviewer: not one of the seven" tests/q3.sh
cm "$R" "#7 developer: fix 3" scripts/unowned.sh
ck k3-never-flagged-work-lead-unroled-unowned 1 "$(kind3 "$R" "$R/docs/agents/factory.md" main | grep -c .)"
# a delete counts; a rename lists both paths
git -C "$R" rm -q tests/t.sh; git -C "$R" commit -qm "#7 developer: delete test"
out="$(kind3 "$R" "$R/docs/agents/factory.md" main)"
ck k3-delete-counts 1 "$(echo "$out" | grep -c 'developer changed tests/t.sh (owner qa-engineer)')"
git -C "$R" mv plugins/factory/x.sh tests/moved.sh; git -C "$R" commit -qm "#7 developer: move into tests"
out="$(kind3 "$R" "$R/docs/agents/factory.md" main)"
ck k3-rename-flags-new-path 1 "$(echo "$out" | grep -c 'developer changed tests/moved.sh (owner qa-engineer)')"
git -C "$R" mv tests/moved.sh plugins/factory/back.sh; git -C "$R" commit -qm "#7 qa-engineer: move out of tests"
out="$(kind3 "$R" "$R/docs/agents/factory.md" main)"
ck k3-rename-flags-old-and-new-path 1 "$(echo "$out" | grep -c 'qa-engineer changed plugins/factory/back.sh (owner developer)')"
# a merge commit is not read
git -C "$R" checkout -q -b side main; cm "$R" "#7 qa-engineer: ok" tests/side.sh; git -C "$R" checkout -q item/7
before="$(kind3 "$R" "$R/docs/agents/factory.md" main | wc -l)"
git -C "$R" merge -q --no-ff side -m "#7 developer: merge side" 2>/dev/null
ck k3-merge-commit-not-read "$before" "$(kind3 "$R" "$R/docs/agents/factory.md" main | wc -l)"
# a `section` row is skipped; whole-file ownership is all the rule sees: a lead edit of the file is flagged only if the file's owner differs
R2="$T/k3b"; mkrepo "$R2"
{ cat "$REPO/docs/agents/factory.md"; } > /dev/null
ck k3-section-row-token-skipped "" "$(printf '%s\n' '| Path | Owner |' '|---|---|' '| `docs/agents/factory.md` section `## Overrides` | lead |' '| `docs/` (rest) | docs-writer |' > "$T/tbl.md"; owner_of "$T/tbl.md" nothing/here)"
ck k3-section-row-does-not-own-file docs-writer "$(owner_of "$T/tbl.md" docs/agents/factory.md)"
ck k3-section-row-docs-rest-owns-docs-writer-other docs-writer "$(owner_of "$T/tbl.md" docs/guide.md)"

# ---- S4: git diff-tree -z with an accented and a newline filename (without -z git quote-escapes both) ----
R3="$T/k3z"; mkrepo "$R3"
nl="$(printf 'tests/bad\nname.sh')"
cm "$R3" "#7 developer: accented" "plugins/factory/caf$(printf '\303\251').md"
cm "$R3" "#7 developer: newline name" "$nl"
cm "$R3" "#7 developer: leading quote" 'tests/"q.sh'
out="$(kind3 "$R3" "$R3/docs/agents/factory.md" main)"
ck k3z-accented-name-classified-not-flagged 0 "$(echo "$out" | grep -c 'caf')"
ck k3z-newline-name-flagged-unclassifiable 1 "$(echo "$out" | grep -c 'changed an unclassifiable path (name escaped: ')"
ck k3z-leading-quote-seen-as-its-real-name 1 "$(echo "$out" | grep -c 'developer changed tests/"q.sh (owner qa-engineer)')"
# the reproduction of S4: without -z, git writes the accented name as an escaped, quoted string that matches no token, so the rule would miss it
ck k3z-without-z-name-is-escaped 1 "$(git -C "$R3" -c core.quotepath=true diff-tree --no-commit-id --name-only -r --no-renames "$(git -C "$R3" log --format=%H --grep=accented -1)" | grep -c '^"')"

# ---- rule 5.6: commits that touch the ownership table or ## Overrides ----
# rule56 <repo> <lead email> <base>: prints rules-touched-by-non-lead lines
section_of() { git -C "$1" show "$2:docs/agents/factory.md" 2>/dev/null | awk -v h="$3" '$0==h {f=1; next} f && /^## / {exit} f {print}'; }
rule56() {
  git -C "$1" log --no-merges --format='%H%x09%ae%x09%s' "$3"..HEAD | while IFS="$(printf '\t')" read -r sha ae subj; do
    a="$(section_of "$1" "$sha^" '## Overrides')|$(section_of "$1" "$sha^" '## Ownership')"
    b="$(section_of "$1" "$sha" '## Overrides')|$(section_of "$1" "$sha" '## Ownership')"
    [ "$a" = "$b" ] && continue
    case "$subj" in "#"[0-9]*" lead: "*) [ "$ae" = "$2" ] && continue ;; esac
    echo "rules-touched-by-non-lead: $(echo $sha | cut -c1-7)"
  done; }
R4="$T/k56"; mkrepo "$R4"
printf '\n## Overrides\n\n### x\n\n- rule: a\n' >> "$R4/docs/agents/factory.md"; git -C "$R4" add -A; GIT_AUTHOR_EMAIL=lead@example.invalid git -C "$R4" commit -qm "base overrides" ; git -C "$R4" tag base2; git -C "$R4" checkout -q -B item/7
base="$(git -C "$R4" rev-parse HEAD)"
LEAD=lead@example.invalid
edit_ov() { sed -i '' "s/- rule: .*/- rule: $1/" "$R4/docs/agents/factory.md"; git -C "$R4" add -A; }
edit_ov b; GIT_AUTHOR_EMAIL=$LEAD git -C "$R4" commit -qm "#7 lead: override x"
ck k56-genuine-lead-commit-not-flagged 0 "$(rule56 "$R4" $LEAD "$base" | grep -c .)"
base="$(git -C "$R4" rev-parse HEAD)"
edit_ov c; GIT_AUTHOR_EMAIL=forger@example.invalid git -C "$R4" commit -qm "#7 lead: override x"
ck k56-forged-lead-subject-by-other-author-flagged 1 "$(rule56 "$R4" $LEAD "$base" | grep -c 'rules-touched-by-non-lead')"
# the path rule alone never sees it: the role is `lead`, so kind 3's path rule reads nothing (that is the S-finding)
ck k56-path-rule-alone-misses-the-forgery 0 "$(kind3 "$R4" "$R4/docs/agents/factory.md" "$base" | grep -c .)"
base="$(git -C "$R4" rev-parse HEAD)"
edit_ov d; GIT_AUTHOR_EMAIL=$LEAD git -C "$R4" commit -qm "#7 developer: tweak the override"
ck k56-role-subject-touching-overrides-flagged 1 "$(rule56 "$R4" $LEAD "$base" | grep -c .)"
base="$(git -C "$R4" rev-parse HEAD)"
sed -i '' 's/| `plugins\/` | developer |/| `plugins\/` | qa-engineer |/' "$R4/docs/agents/factory.md"; git -C "$R4" add -A; GIT_AUTHOR_EMAIL=$LEAD git -C "$R4" commit -qm "#7 qa-engineer: take plugins"
ck k56-ownership-table-edit-by-role-flagged 1 "$(rule56 "$R4" $LEAD "$base" | grep -c .)"
base="$(git -C "$R4" rev-parse HEAD)"
sed -i '' 's/^Item worktrees live at/Item worktrees are at/' "$R4/docs/agents/factory.md"; git -C "$R4" add -A; GIT_AUTHOR_EMAIL=$LEAD git -C "$R4" commit -qm "#7 docs-writer: prose"
ck k56-prose-commit-exists 1 "$(git -C "$R4" log --format=%s "$base"..HEAD | grep -c 'docs-writer: prose')"
ck k56-edit-outside-overrides-and-table-not-flagged 0 "$(rule56 "$R4" $LEAD "$base" | grep -c .)"
# a branch commit editing the table is judged by the origin/main copy: the table the branch edited does not exempt it
ck k56-judged-by-base-copy "qa-engineer" "$(owner_of "$R4/docs/agents/factory.md" plugins/factory/x.sh)"
ck k56-base-copy-says-developer "developer" "$(git -C "$R4" show base2:docs/agents/factory.md > "$T/base-fm.md"; owner_of "$T/base-fm.md" plugins/factory/x.sh)"

# ---- kind 6(b): a FREEZE line is trusted only when the map body's last editor is the lead's account ----
freeze() { # last-editor lead-account body-line plugin-root -> outcome
  [ -n "$1" ] && [ "$1" = "$2" ] || { echo "not captured (map body last edited by ${1:-unknown})"; return; }
  sha="$(printf '%s\n' "$3" | grep 'FREEZE:' | grep -oE '`[0-9a-f]{12}`' | head -1 | tr -d '`')"
  [ -n "$sha" ] || { echo "freeze: none"; return; }
  seg="${4##*/}"; [ "$sha" = "$seg" ] && echo "freeze: ok" || echo "kind 6: installed $seg, FREEZE line $sha"; }
BODY='Factory run. FREEZE: `9147301f75c3` frozen install'
ck k6b-lead-edited-matching-ok "freeze: ok" "$(freeze lead lead "$BODY" /x/factory/9147301f75c3)"
ck k6b-lead-edited-differs-kind6 "kind 6: installed 1234567890ab, FREEZE line 9147301f75c3" "$(freeze lead lead "$BODY" /x/factory/1234567890ab)"
ck k6b-other-editor-not-captured "not captured (map body last edited by mallory)" "$(freeze mallory lead "$BODY" /x/factory/1234567890ab)"
ck k6b-editor-unreadable-not-captured "not captured (map body last edited by unknown)" "$(freeze '' lead "$BODY" /x/factory/9147301f75c3)"
ck k6b-no-freeze-line "freeze: none" "$(freeze lead lead 'no line' /x/factory/9147301f75c3)"

# ---------- kind 4 ----------
# slow <role> <row#> from a stage log + waits: implements the written steps
# stage rows: "# | Stage | Role | Start | End | Waits" (minutes since 00:00 for Start/End); waits: "id kind held start end"
slowcheck() { # args: stagefile waitfile row#
  awk -v ROW="$3" -v WF="$2" '
    BEGIN { while ((getline l < WF) > 0) { split(l,w," "); wk[w[1]]=w[2]; wh[w[1]]=w[3]; ws[w[1]]=w[4]; we[w[1]]=w[5] } }
    { n++; num[n]=$1; role[n]=$3; st[n]=$4; en[n]=$5; wl[n]=$6 }
    function work(i,   k,c,cnt,sorted,a,b,u,x,y,t,tmp,m,j) {
      # union of the held waits of kinds person limits stalled interrupted andon, cut to the row
      cnt=0; split(wl[i],c,",")
      for (k in c) { id=c[k]; if (id=="" || id=="-") continue
        if (wh[id]!="yes") continue
        if (wk[id] !~ /^(person|limits|stalled|interrupted|andon)$/) continue
        a=(ws[id]>st[i])?ws[id]:st[i]; b=(we[id]<en[i])?we[id]:en[i]
        if (b>a) { cnt++; A[cnt]=a; B[cnt]=b } }
      for (x=1;x<=cnt;x++) for (y=x+1;y<=cnt;y++) if (A[y]<A[x]) { t=A[x];A[x]=A[y];A[y]=t; t=B[x];B[x]=B[y];B[y]=t }
      u=0; cur_s=-1; cur_e=-1
      for (x=1;x<=cnt;x++) { if (A[x]>cur_e) { if (cur_e>=0) u+=cur_e-cur_s; cur_s=A[x]; cur_e=B[x] } else if (B[x]>cur_e) cur_e=B[x] }
      if (cur_e>=0) u+=cur_e-cur_s
      return (en[i]-st[i])-u }
    END {
      i=ROW; earlier=0
      for (j=1;j<=n;j++) if (role[j]==role[i] && num[j]<num[i]) { earlier++; e[earlier]=work(j) }
      if (earlier<3) { print "no baseline: fewer than 3 earlier rows"; exit }
      for (x=1;x<=earlier;x++) for (y=x+1;y<=earlier;y++) if (e[y]<e[x]) { t=e[x];e[x]=e[y];e[y]=t }
      m=(earlier%2)?e[(earlier+1)/2]:(e[earlier/2]+e[earlier/2+1])/2
      own=work(i)
      if (own > 2*m) print "slow: " own " against median " m " of " earlier " earlier rows"; else print "not flagged"
    }' "$1"
}
# fixture of the contract: developer rows 1-3 working 30m, 40m, 50m (median 40m)
mkdev() { # <fourth row duration minutes> <waits column>
  printf '1 Build developer 0 30 -\n2 Build developer 100 140 -\n3 Build developer 200 250 -\n4 Build developer 300 %s %s\n' "$((300 + $1))" "$2" > "$T/sl"; }
: > "$T/wl"
mkdev 80 -;  ck k4-exactly-2x-not-flagged "not flagged" "$(slowcheck "$T/sl" "$T/wl" 4)"
mkdev 84 -;  ck k4-2.1x-flagged "slow: 84 against median 40 of 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 4)"
mkdev 81 -;  ck k4-just-over-flagged "slow: 81 against median 40 of 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 4)"
echo "W2 limits yes 310 490" > "$T/wl"
mkdev 210 W2; ck k4-wait-explains-duration "not flagged" "$(slowcheck "$T/sl" "$T/wl" 4)"
echo "W2 limits no 310 490" > "$T/wl"
mkdev 210 W2; ck k4-wait-not-held-does-not-explain "slow: 210 against median 40 of 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 4)"
echo "W2 other yes 310 490" > "$T/wl"
mkdev 210 W2; ck k4-unlisted-kind-does-not-explain "slow: 210 against median 40 of 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 4)"
printf 'W2 limits yes 310 400\nW3 andon yes 390 450\n' > "$T/wl"
mkdev 230 W2,W3; ck k4-overlapping-waits-count-once "slow: 90 against median 40 of 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 4)"
printf 'W2 limits yes 450 700\n' > "$T/wl"
mkdev 210 W2; ck k4-wait-cut-to-the-row "slow: 150 against median 40 of 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 4)"
: > "$T/wl"
printf '1 Build developer 0 30 -\n2 Build developer 100 140 -\n3 Build developer 200 800 -\n' > "$T/sl"
ck k4-two-earlier-rows-not-tested "no baseline: fewer than 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 3)"
ck k4-first-row-of-role-same-note "no baseline: fewer than 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 1)"
printf '1 Build developer 0 30 -\n2 Verification qa-engineer 30 35 -\n3 Build developer 100 140 -\n4 Build developer 200 250 -\n5 Verification qa-engineer 260 999 -\n6 Build developer 300 380 -\n' > "$T/sl"
ck k4-other-roles-rows-not-counted "not flagged" "$(slowcheck "$T/sl" "$T/wl" 6)"
ck k4-qa-has-one-earlier-row "no baseline: fewer than 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 5)"
# feedback rounds count as earlier rows
printf '1 Build developer 0 30 -\n2 Build_(round_2) developer 100 140 -\n3 Build_(round_3) developer 200 250 -\n4 Build_(round_4) developer 300 384 -\n' > "$T/sl"
ck k4-feedback-rounds-are-earlier-rows "slow: 84 against median 40 of 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 4)"
# even count: mean of the two middle values may end in .5
printf '1 B developer 0 30 -\n2 B developer 100 140 -\n3 B developer 200 250 -\n4 B developer 300 360 -\n5 B developer 400 495 -\n' > "$T/sl"
ck k4-even-median-half "slow: 95 against median 45 of 4 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 5)"
printf '1 B developer 0 30 -\n2 B developer 100 141 -\n3 B developer 200 250 -\n4 B developer 300 360 -\n5 B developer 400 491 -\n' > "$T/sl"
ck k4-even-median-exactly-2x-not-flagged "not flagged" "$(slowcheck "$T/sl" "$T/wl" 5)"
printf '1 B developer 0 30 -\n2 B developer 100 141 -\n3 B developer 200 250 -\n4 B developer 300 360 -\n5 B developer 400 492 -\n' > "$T/sl"
ck k4-even-median-just-over-no-rounding "slow: 92 against median 45.5 of 4 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 5)"
# QA-49 F1: a 60m andon pause inside a 90m row. Listed in the row's Waits it is excluded (30m working); left out (Notes only) the row reads 90m and is flagged.
printf 'W9 andon yes 320 380\n' > "$T/wl"
mkdev 90 W9; ck k4-f1-pause-listed-in-waits-not-flagged "not flagged" "$(slowcheck "$T/sl" "$T/wl" 4)"
mkdev 90 -;  ck k4-f1-pause-only-in-notes-flagged-falsely "slow: 90 against median 40 of 3 earlier rows" "$(slowcheck "$T/sl" "$T/wl" 4)"
done_
