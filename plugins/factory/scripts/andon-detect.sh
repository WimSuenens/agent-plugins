#!/bin/bash
# The mechanical andon detections of skills/run/SKILL.md `## Andon`, `### Detection`: kind 3 (a role changed a path another role owns)
# and kind 4 (a role task slower than twice the median of the same role's earlier tasks). The lead runs it; it prints one line per hit
# and decides nothing: the andon procedure stays with the lead.
# Usage:
#   andon-detect.sh kind3 [--in <dir>] [--base <ref>] [--head <ref>] [--table <file>]
#       Commits <base>..<head>, not merges. Defaults: repo = the current directory, head = HEAD, base = `git merge-base origin/main <head>`.
#       The role is read from the subject `^#[0-9]+ ([a-z-]+): `; only the seven roles are read. The ownership table is
#       `git show origin/main:docs/agents/factory.md` unless --table names a file (a table of the branch must never judge the branch).
#       Prints `role-outside-role: <sha7> <role> changed <path> (owner <owner>)`, or `... changed an unclassifiable path (name escaped: <%q form>)`.
#   andon-detect.sh owner <table> <path>
#       The Owner of the table row with the longest matching token, empty when the path is unowned.
#   andon-detect.sh kind4 (--ledger <ledger.md> --times <times.tsv> | --rows <file> --waits <file>) <row#>
#       Prints `slow: <own> against median <m> of <n> earlier rows`, `not flagged`, or `no baseline: fewer than 3 earlier rows`.
#   andon-detect.sh working (--ledger <ledger.md> --times <times.tsv> | --rows <file> --waits <file>)
#       Prints `<row#> <role> <agent-working minutes>` for every row.
#   --ledger is the ledger comment (its Tasks and Waits tables); --times has one line per role-task sub-issue:
#   `<issue number>\t<createdAt>\t<closedAt>` (ISO UTC). Times count in whole minutes (seconds cut).
#   --rows lines: `<row#> <stage> <role> <start> <end> <waits: W1,W2 or ->`; --waits lines: `<id> <kind> <held yes|no> <start> <end>`
#   (numbers of minutes). Agent-working time = end - start less the union of the held waits of kind person, limits, stalled,
#   interrupted or andon that the row lists, each cut to the row.
# Exit: 0 done (hits or none); 2 usage or an unreadable input; 3 no ownership table.
# bash 3.2 compatible; needs git and awk.

ROLES="product-owner architect developer qa-engineer security-reviewer devops docs-writer"

usage() { sed -n '2,/^# bash 3.2/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

owner_of() { # <table> <path>
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

kind3() {
  local repo=. base="" head=HEAD table="" tmp="" rc=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --in) repo="${2:?}"; shift 2 ;;
      --base) base="${2:?}"; shift 2 ;;
      --head) head="${2:?}"; shift 2 ;;
      --table) table="${2:?}"; shift 2 ;;
      *) usage ;;
    esac
  done
  [ -n "$base" ] || base="$(git -C "$repo" merge-base origin/main HEAD)" || { echo "andon-detect: no merge base with origin/main" >&2; exit 2; }
  if [ -z "$table" ]; then
    tmp="$(mktemp)"
    git -C "$repo" show origin/main:docs/agents/factory.md > "$tmp" 2>/dev/null || { rm -f "$tmp"; echo "andon-detect: no ownership table at origin/main" >&2; exit 3; }
    table="$tmp"
  fi
  [ -r "$table" ] || { echo "andon-detect: unreadable table" >&2; exit 3; }
  git -C "$repo" log --no-merges --format='%H%x09%s' "$base".."$head" | while IFS="$(printf '\t')" read -r sha subj; do
    r="$(printf '%s' "$subj" | sed -nE 's/^#[0-9]+ ([a-z-]+): .*/\1/p')"
    [ -n "$r" ] || continue
    case " $ROLES " in *" $r "*) ;; *) continue ;; esac
    git -C "$repo" diff-tree -z --no-commit-id --name-only -r --no-renames "$sha" | while IFS= read -r -d '' p; do
      case "$p" in *[[:cntrl:]]*) echo "role-outside-role: ${sha:0:7} $r changed an unclassifiable path (name escaped: $(printf '%q' "$p"))"; continue ;; esac
      o="$(owner_of "$table" "$p")"
      [ -n "$o" ] && [ "$o" != "$r" ] && echo "role-outside-role: ${sha:0:7} $r changed $p (owner $o)"
    done
  done
  [ -z "$tmp" ] || rm -f "$tmp"
  return $rc
}

# ledger_to_numeric <ledger> <times> <rows out> <waits out>
ledger_to_numeric() {
  awk -F'|' '
    function mins(s,   y,mo,d,h,mi,a,yy,era,yoe,doy,doe,days) {
      # 2026-11-12T21:14:26Z or 2026-11-12T21:14Z -> whole minutes since the epoch (days from civil)
      if (s !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}/) return ""
      y=substr(s,1,4)+0; mo=substr(s,6,2)+0; d=substr(s,9,2)+0; h=substr(s,12,2)+0; mi=substr(s,15,2)+0
      yy=y-(mo<=2); era=int(yy/400); yoe=yy-era*400
      doy=int((153*(mo+(mo>2?-3:9))+2)/5)+d-1; doe=yoe*365+int(yoe/4)-int(yoe/100)+doy
      days=era*146097+doe-719468
      return days*1440+h*60+mi
    }
    function trim(x) { gsub(/^ +| +$/,"",x); return x }
    FILENAME==TIMES { split($0,t,"\t"); cs[t[1]]=mins(t[2]); ce[t[1]]=mins(t[3]); next }
    /^### Tasks/ { sec="t"; next }
    /^### Waits/ { sec="w"; next }
    /^### / { sec=""; next }
    sec=="t" && /^\| [0-9]+ \|/ {
      n=trim($2); task=trim($3); sub(/^#/,"",task); stage=trim($4); gsub(/ /,"_",stage); role=trim($5); w=trim($7); gsub(/ /,"",w)
      if (!(task in cs) || cs[task]=="" || ce[task]=="") next
      print n, stage, role, cs[task], ce[task], (w==""?"-":w) > ROWS
    }
    sec=="w" && /^\| W[0-9]+ \|/ {
      print trim($2), trim($3), trim($7), mins(trim($5)), mins(trim($6)) > WAITS
    }' ROWS="$3" WAITS="$4" TIMES="$2" "$2" "$1"
  [ -e "$3" ] || : > "$3"; [ -e "$4" ] || : > "$4"
}

# core <rows> <waits> <mode: slow|working> [row#]
core() {
  awk -v ROW="$4" -v WF="$2" -v MODE="$3" '
    BEGIN { while ((getline l < WF) > 0) { split(l,w," "); wk[w[1]]=w[2]; wh[w[1]]=w[3]; ws[w[1]]=w[4]; we[w[1]]=w[5] } }
    { n++; num[n]=$1; role[n]=$3; st[n]=$4; en[n]=$5; wl[n]=$6 }
    function work(i,   k,c,cnt,a,b,u,x,y,t,id,cur_s,cur_e) {
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
      if (MODE=="working") { for (j=1;j<=n;j++) print num[j], role[j], work(j); exit }
      i=0; for (j=1;j<=n;j++) if (num[j]==ROW) i=j
      if (!i) { print "andon-detect: no row " ROW > "/dev/stderr"; exit 2 }
      earlier=0
      for (j=1;j<=n;j++) if (role[j]==role[i] && num[j]+0<num[i]+0) { earlier++; e[earlier]=work(j) }
      if (earlier<3) { print "no baseline: fewer than 3 earlier rows"; exit }
      for (x=1;x<=earlier;x++) for (y=x+1;y<=earlier;y++) if (e[y]<e[x]) { t=e[x];e[x]=e[y];e[y]=t }
      m=(earlier%2)?e[(earlier+1)/2]:(e[earlier/2]+e[earlier/2+1])/2
      own=work(i)
      if (own > 2*m) print "slow: " own " against median " m " of " earlier " earlier rows"; else print "not flagged"
    }' "$1"
}

timed() { # shared parser for kind4 and working: sets rows and waits files in $tmpd, row in $row
  ledger=""; times=""; rows=""; waits=""; row=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --ledger) ledger="${2:?}"; shift 2 ;;
      --times) times="${2:?}"; shift 2 ;;
      --rows) rows="${2:?}"; shift 2 ;;
      --waits) waits="${2:?}"; shift 2 ;;
      --*) usage ;;
      *) row="$1"; shift ;;
    esac
  done
  tmpd="$(mktemp -d)"
  if [ -n "$ledger" ]; then
    [ -r "$ledger" ] && [ -r "$times" ] || { echo "andon-detect: unreadable --ledger or --times" >&2; exit 2; }
    rows="$tmpd/rows"; waits="$tmpd/waits"
    ledger_to_numeric "$ledger" "$times" "$rows" "$waits"
  fi
  [ -r "$rows" ] && [ -r "$waits" ] || { rm -rf "$tmpd"; echo "andon-detect: need --ledger and --times, or --rows and --waits" >&2; exit 2; }
}

case "${1:-}" in
  kind3) shift; kind3 "$@" ;;
  owner) [ $# -eq 3 ] && [ -r "$2" ] || usage; owner_of "$2" "$3" ;;
  kind4) shift; timed "$@"; case "$row" in ''|*[!0-9]*) rm -rf "$tmpd"; usage ;; esac; core "$rows" "$waits" slow "$row"; rc=$?; rm -rf "$tmpd"; exit $rc ;;
  working) shift; timed "$@"; core "$rows" "$waits" working; rc=$?; rm -rf "$tmpd"; exit $rc ;;
  *) usage ;;
esac
