#!/usr/bin/env bash
# The board script: setup, the three-phase migration of the Factory status field, the views, and the line that makes /factory:run accept a project.
# Usage: bash board.sh plan   [--owner <O>] [--project <N>] [--project-id <P>] [--state-dir <D>]
#        bash board.sh apply  [--owner <O>] [--project <N>] [--project-id <P>] [--state-dir <D>] --yes [--views-confirmed]
#        bash board.sh finish [--owner <O>] [--project <N>] [--project-id <P>] --views-confirmed
#                             [--factory-md <file>] [--tracker-md <file>] [--ops-template <file>]
# The owner and the project number come from the flags, else from the Tracker table of --factory-md (default docs/agents/factory.md).
# The project id comes from --project-id, else from the same table. plan does without it; apply and finish need it.
# It calls gh only through the operations of the tracker-call list (B-fields, B-options, B-items, B-views, B-set, B-fcreate, B-foptions, B-vcreate, B-vupdate).
# It asks no question and never reads the terminal: every "ask the person" is the skill's, and the answer arrives as a flag.
# Exit: 0 done or already migrated; 2 usage, project not given, state dir inside the repo, gh or jq missing, --yes missing;
#       3 a read call failed; 5 a verification difference; 6 phase 3 refused (an item holds an old value); 7 a mutation call failed;
#       10 the views need the person's confirmation.
# See contracts/64-board-script.md in the repo that hosts the factory.

cmd="${1:-}"
[ $# -gt 0 ] && shift
owner=""; project=""; pid=""; state_dir=""; yes=0; vconf=0
factory_md="docs/agents/factory.md"; tracker_md="docs/agents/issue-tracker.md"; ops_template=""
while [ $# -gt 0 ]; do
  case "$1" in
    --owner) owner="${2:-}"; shift 2 || { echo "board: --owner needs a value" >&2; exit 2; } ;;
    --project) project="${2:-}"; shift 2 || { echo "board: --project needs a value" >&2; exit 2; } ;;
    --project-id) pid="${2:-}"; shift 2 || { echo "board: --project-id needs a value" >&2; exit 2; } ;;
    --state-dir) state_dir="${2:-}"; shift 2 || { echo "board: --state-dir needs a value" >&2; exit 2; } ;;
    --factory-md) factory_md="${2:-}"; shift 2 || { echo "board: --factory-md needs a value" >&2; exit 2; } ;;
    --tracker-md) tracker_md="${2:-}"; shift 2 || { echo "board: --tracker-md needs a value" >&2; exit 2; } ;;
    --ops-template) ops_template="${2:-}"; shift 2 || { echo "board: --ops-template needs a value" >&2; exit 2; } ;;
    --yes) yes=1; shift ;;
    --views-confirmed) vconf=1; shift ;;
    *) echo "board: unknown option $1" >&2; exit 2 ;;
  esac
done
case "$cmd" in
  plan | apply | finish) ;;
  *) echo "usage: board.sh plan|apply|finish [--owner <O>] [--project <N>] [--project-id <P>] [--state-dir <D>] [--yes] [--views-confirmed]" >&2; exit 2 ;;
esac

if [ "$cmd" = apply ] && [ "$yes" != 1 ]; then
  echo "board: apply needs --yes" >&2
  exit 2
fi
if [ "$cmd" = finish ] && [ "$vconf" != 1 ]; then
  echo "board: finish needs --views-confirmed" >&2
  exit 2
fi
command -v jq >/dev/null 2>&1 || { echo "board: jq missing" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "board: gh: not found" >&2; exit 2; }

tmp="$(mktemp -d)" || { echo "board: cannot make a scratch folder" >&2; exit 2; }
trap 'rm -rf "$tmp"' EXIT

# the value of a row of the Tracker key table: | <key> | <value> |
table_get() {
  [ -r "$2" ] || return 0
  awk -F'|' -v k="$1" '
    /^\|/ { a = $2; b = $3; gsub(/^ +| +$/, "", a); gsub(/^ +| +$/, "", b); if (a == k) { print b; exit } }
  ' "$2"
}
t_owner="$(table_get owner "$factory_md")"
t_project="$(table_get "project number" "$factory_md")"
[ -n "$owner" ] || owner="$t_owner"
[ -n "$project" ] || project="$t_project"
# the table's project id belongs to the table's project: use it only when this is that project
if [ -z "$pid" ] && [ "$owner" = "$t_owner" ] && [ "$project" = "$t_project" ]; then
  pid="$(table_get "project id" "$factory_md")"
fi
if [ -z "$owner" ] || [ -z "$project" ]; then
  echo "board: say which project (--owner, --project)" >&2
  exit 2
fi
case "$project" in '' | *[!0-9]*) echo "board: project number must be a number" >&2; exit 2 ;; esac

# ---------- state dir ----------
physical() {
  local p="$1" rest="" base
  case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
  while [ ! -d "$p" ]; do
    base="$(basename "$p")"
    rest="/$base$rest"
    p="$(dirname "$p")"
  done
  printf '%s%s' "$(cd "$p" && pwd -P)" "$rest"
}
tail2() { printf '…/%s/%s' "$(basename "$(dirname "$1")")" "$(basename "$1")"; }

if [ "$cmd" != finish ]; then
  [ -n "$state_dir" ] || state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/factory/board-$owner-$project"
  state_dir="$(physical "$state_dir")"
  top="$(git rev-parse --show-toplevel 2>/dev/null)" || top=""
  if [ -n "$top" ]; then
    top="$(cd "$top" && pwd -P)"
    case "$state_dir/" in
      "$top"/*) echo "board: state dir is inside the repository" >&2; exit 2 ;;
    esac
  fi
  case "$state_dir/" in
    */work/*) echo "board: state dir is inside the repository" >&2; exit 2 ;;
  esac
fi

# ---------- reads and writes through gh ----------
# rd <op> <dest> <gh args...>
rd() {
  local op="$1" dest="$2"
  shift 2
  if ! "$@" >"$dest" 2>"$tmp/err"; then
    echo "board: read failed ($op): $(head -c 200 "$tmp/err" | tr '\n' ' ')" >&2
    exit 3
  fi
}
# mut <op> <gh args...>   (stdin from $tmp/body when the op sends a body)
mut() {
  local op="$1"
  shift
  if ! "$@" >"$tmp/mutout" 2>"$tmp/err"; then
    echo "board: $op failed: $(head -c 200 "$tmp/err" | tr '\n' ' ')" >&2
    exit 7
  fi
}
mutin() {
  local op="$1"
  shift
  if ! "$@" <"$tmp/body" >"$tmp/mutout" 2>"$tmp/err"; then
    echo "board: $op failed: $(head -c 200 "$tmp/err" | tr '\n' ' ')" >&2
    exit 7
  fi
}

read_fields() { rd B-fields "$tmp/fields.json" gh project field-list "$project" --owner "$owner" --format json --limit 100; }
read_options() {
  rd B-options "$tmp/options.json" gh api graphql \
    -f query='query($f: ID!) { node(id: $f) { ... on ProjectV2SingleSelectField { options { id name color description } } } }' -f f="$fid"
}
read_items() {
  rd B-items "$tmp/items.raw" gh project item-list "$project" --owner "$owner" --format json --limit 1000
  # normalised: id, number, title, status (the option name or null), fields (every other value as returned)
  jq -c '[ .items[] | {id, number: (.content.number // null), title: (.title // .content.title // ""),
           status: (.["factory status"] // null),
           fields: (del(.id, .title, .content, .["factory status"])) } ]' "$tmp/items.raw" >"$tmp/items.json" || {
    echo "board: read failed (B-items): not JSON" >&2
    exit 3
  }
}
read_views() {
  if [ -z "$pid" ]; then
    echo '[]' >"$tmp/views.json"
    views_known=0
    return 0
  fi
  views_known=1
  rd B-views "$tmp/views.raw" gh api graphql \
    -f query='query($p: ID!) { node(id: $p) { ... on ProjectV2 { views(first: 50) { nodes { id name filter layout } } } } }' -f p="$pid"
  jq -c '[ (.data.node.views.nodes // [])[] | .name ]' "$tmp/views.raw" >"$tmp/views.json" || {
    echo "board: read failed (B-views): not JSON" >&2
    exit 3
  }
}

OLD='["Designed","In progress","In review","Ready to deploy"]'
NEWOPTS='["Running","Waiting on you","Blocked"]'
FINAL='["Backlog","Ready","Running","Waiting on you","Blocked","Done"]'
MAPJQ='def mapst: if . == "Designed" then "Ready" elif . == "In progress" or . == "In review" then "Running" elif . == "Ready to deploy" then "Waiting on you" else . end;'
FIELDS_WANTED='["Kind","Role","Tokens","Minutes","Hours","Rework rounds","Person touches"]'

# survey: sets state, fid, hasnew, hasold, nold, fields_ok, views_ok
survey() {
  read_fields
  fid="$(jq -r '[.fields[] | select(.name == "Factory status") | .id][0] // empty' "$tmp/fields.json")"
  read_items
  read_views
  fields_ok=0
  views_ok=0
  hasnew=0
  hasold=0
  nold=0
  if [ -z "$fid" ]; then
    state=fresh
    return 0
  fi
  read_options
  jq -c '[ .data.node.options[] | .name ]' "$tmp/options.json" >"$tmp/optnames.json" || {
    echo "board: read failed (B-options): not JSON" >&2
    exit 3
  }
  jq -e --argjson n "$NEWOPTS" '. as $o | all($n[]; . as $x | $o | index($x) != null)' "$tmp/optnames.json" >/dev/null && hasnew=1
  jq -e --argjson n "$OLD" '. as $o | any($n[]; . as $x | $o | index($x) != null)' "$tmp/optnames.json" >/dev/null && hasold=1
  nold="$(jq --argjson o "$OLD" '[ .[] | select(.status as $s | $o | index($s) != null) ] | length' "$tmp/items.json")"
  jq -e --argjson w "$FIELDS_WANTED" '(.fields | map(.name)) as $n | all($w[]; . as $x | $n | index($x) != null)' "$tmp/fields.json" >/dev/null && fields_ok=1
  jq -e '(index("Needs you") != null) and (index("History") != null)' "$tmp/views.json" >/dev/null && views_ok=1
  if [ "$hasnew" = 0 ]; then
    state="seven-option board"
  elif [ "$nold" != 0 ] || [ "$hasold" = 1 ]; then
    state="migration in progress"
  elif [ "$fields_ok" = 1 ] && [ "$views_ok" = 1 ]; then
    state=migrated
  else
    state="migration in progress"
  fi
}

next_snapshot() {
  local k=0 f n
  if [ -d "$state_dir" ]; then
    for f in "$state_dir"/snapshot-*.json; do
      [ -e "$f" ] || continue
      n="${f##*/snapshot-}"
      n="${n%.json}"
      case "$n" in '' | *[!0-9]*) continue ;; esac
      [ "$n" -gt "$k" ] && k="$n"
    done
  fi
  echo $((k + 1))
}

# ---------- plan ----------
do_plan() {
  survey
  if [ "$state" = migrated ]; then
    echo "already migrated"
    return 0
  fi
  echo "board: project $owner/$project"
  echo "state: $state"
  if [ "$state" = fresh ]; then
    echo "board: fresh project: nothing to migrate; apply creates the fields"
    return 0
  fi
  local c
  cnt() { jq --arg s "$1" '[ .[] | select(.status == $s) ] | length' "$tmp/items.json"; }
  echo "map: Designed -> Ready ($(cnt Designed) items)"
  echo "map: In progress -> Running ($(cnt 'In progress') items)"
  echo "map: In review -> Running ($(cnt 'In review') items)"
  echo "map: Ready to deploy -> Waiting on you ($(cnt 'Ready to deploy') items)"
  echo "map: Backlog -> Backlog (unchanged, $(cnt Backlog) items)"
  echo "map: Ready -> Ready (unchanged, $(cnt Ready) items)"
  for c in Running "Waiting on you" Blocked; do
    [ "$(cnt "$c")" != 0 ] && echo "map: $c -> $c (unchanged, $(cnt "$c") items)"
  done
  echo "map: Done -> Done (unchanged, $(cnt Done) items)"
  local nostatus
  nostatus="$(jq -r '[ .[] | select(.status == null) | (if .number != null then "#\(.number)" else .title end) ] | join(", ")' "$tmp/items.json")"
  echo "map: no Factory status -> left as it is ($(jq '[ .[] | select(.status == null) ] | length' "$tmp/items.json") items${nostatus:+: $nostatus})"
  local change stay
  change="$(jq --argjson o "$OLD" '[ .[] | select(.status as $s | $o | index($s) != null) ] | length' "$tmp/items.json")"
  stay="$(jq --argjson o "$OLD" '[ .[] | select(.status != null and (.status as $s | $o | index($s) == null)) ] | length' "$tmp/items.json")"
  echo "count: change $change, stay $stay"
  echo "note: In progress and In review both become Running. The old distinction is restorable only from the snapshot, never from the board."
  echo "snapshot: $(tail2 "$state_dir")/snapshot-$(next_snapshot).json (written by apply, before the first change)"
}

# ---------- apply ----------
foptions_body() { # $1 = JSON list of {id?,name,color,description}
  jq -n --arg f "$fid" --argjson o "$1" '{
    query: "mutation($input: UpdateProjectV2FieldInput!) { updateProjectV2Field(input: $input) { projectV2Field { ... on ProjectV2SingleSelectField { id options { id name } } } } }",
    variables: { input: { fieldId: $f, singleSelectOptions: $o } } }' >"$tmp/body"
}

# verify <same|mapped>: re-read the items and compare every field value of every snapshot item
verify() {
  local mode="$1" msg
  read_items
  msg="$(jq -r --argjson cur "$(cat "$tmp/items.json")" --arg mode "$mode" "$MAPJQ"'
    ($cur | map({key: .id, value: .}) | from_entries) as $c
    | [ .items[] | {id, number, title, status: (.status.name // null), fields} | . as $s
        | ($s.number | if . == null then $s.title else "#\(.)" end) as $label
        | $c[$s.id] as $n
        | if $n == null then "board: item \($label): field \"(item)\" changed (snapshot: present, now: missing)"
          else (if $mode == "mapped" then ($s.status | if . == null then null else mapst end) else $s.status end) as $want
          | if ($n.status != $want and ($mode == "same" or $n.status != $s.status)) then "board: item \($label): field \"Factory status\" changed (snapshot: \($want // "empty"), now: \($n.status // "empty"))"
            else (([ ($s.fields | keys[]), ($n.fields | keys[]) ] | unique)
                  | map(select(($s.fields[.]) != ($n.fields[.])))
                  | .[0]) as $k
              | if $k != null then "board: item \($label): field \"\($k)\" changed (snapshot: \($s.fields[$k] | tostring), now: \($n.fields[$k] | tostring))" else empty end
            end
          end ] | .[0] // empty' "$snapfile")" || { echo "board: verify failed" >&2; exit 3; }
  if [ -n "$msg" ]; then
    echo "$msg" >&2
    exit 5
  fi
  local added
  added="$(jq --slurpfile s "$snapfile" '[ .[] | select(.id as $i | ($s[0].items | map(.id) | index($i)) == null) ] | length' "$tmp/items.json")"
  [ "$added" != 0 ] && echo "note: $added items added since the snapshot"
  return 0
}

write_snapshot() {
  local k note
  k="$(next_snapshot)"
  if [ "$k" = 1 ]; then note="original"; else note="taken before re-run, $state"; fi
  ( umask 077; mkdir -p "$state_dir" ) || { echo "board: cannot make the state dir" >&2; exit 2; }
  chmod 700 "$state_dir" 2>/dev/null
  snapfile="$state_dir/snapshot-$k.json"
  ( umask 077
    jq -n --arg taken "$(date -u +%FT%TZ)" --arg note "$note" --arg o "$owner" --argjson n "$project" --arg pid "$pid" \
      --arg fid "$fid" --slurpfile opts "$tmp/options.json" --slurpfile items "$tmp/items.json" '
      ($opts[0].data.node.options) as $op
      | { taken: $taken, note: $note,
          project: {owner: $o, number: $n, id: $pid},
          field: {id: $fid, name: "Factory status"},
          options: $op,
          items: [ $items[0][] | {id, number, title,
                    status: (.status as $s | if $s == null then null else ({id: ([ $op[] | select(.name == $s) | .id ][0]), name: $s}) end),
                    fields} ] }' >"$snapfile" ) || { echo "board: cannot write the snapshot" >&2; exit 2; }
  chmod 600 "$snapfile" 2>/dev/null
  echo "snapshot: $(tail2 "$snapfile")"
  [ "$k" != 1 ] && echo "original snapshot: snapshot-1.json"
  return 0
}

phase1() {
  echo "phase 1: add Running, Waiting on you, Blocked"
  foptions_body "$(jq -c --argjson n "$NEWOPTS" '(.data.node.options | map({id, name, color, description})) + [ $n[] | {name: ., color: "GRAY", description: ""} ]' "$tmp/options.json")"
  mutin B-foptions gh api graphql --input -
  verify same
  read_options
}

phase2() {
  echo "phase 2: re-set items on an old option"
  local line id name target opt
  jq -r --argjson o "$OLD" "$MAPJQ"' .[] | select(.status as $s | $o | index($s) != null) | [.id, (.status | mapst)] | @tsv' "$tmp/items.json" >"$tmp/toset.tsv"
  while IFS="$(printf '\t')" read -r id target; do
    [ -n "$id" ] || continue
    opt="$(jq -r --arg n "$target" '[ .data.node.options[] | select(.name == $n) | .id ][0] // empty' "$tmp/options.json")"
    if [ -z "$opt" ]; then
      echo "board: option $target not found" >&2
      exit 7
    fi
    mut B-set gh project item-edit --id "$id" --project-id "$pid" --field-id "$fid" --single-select-option-id "$opt"
  done <"$tmp/toset.tsv"
  verify mapped
}

phase3() {
  echo "phase 3: drop the old options"
  read_items
  local bad
  bad="$(jq -r --argjson o "$OLD" '[ .[] | select(.status as $s | $o | index($s) != null) | (if .number != null then "#\(.number)" else .title end) + " (" + .status + ")" ][0] // empty' "$tmp/items.json")"
  if [ -n "$bad" ]; then
    echo "board: item $bad still holds an old value; nothing dropped" >&2
    exit 6
  fi
  read_options
  foptions_body "$(jq -c --argjson f "$FINAL" '.data.node.options as $o | [ $f[] | . as $n | ([ $o[] | select(.name == $n) ][0]) as $e
      | if $e == null then {name: $n, color: "GRAY", description: ""} else {id: $e.id, name: $e.name, color: $e.color, description: $e.description} end ]' "$tmp/options.json")"
  mutin B-foptions gh api graphql --input -
  verify mapped
  read_options
}

create_fields() {
  read_fields
  local names f opts
  names="$(jq -r '.fields[].name' "$tmp/fields.json")"
  has() { printf '%s\n' "$names" | grep -Fxq -- "$1"; }
  has Kind || mut B-fcreate gh project field-create "$project" --owner "$owner" --name Kind --data-type SINGLE_SELECT --single-select-options "map,slice,role task,frontier ticket"
  has Role || mut B-fcreate gh project field-create "$project" --owner "$owner" --name Role --data-type SINGLE_SELECT --single-select-options "product-owner,architect,developer,qa-engineer,security-reviewer,devops,docs-writer"
  for f in Tokens Minutes Hours "Rework rounds" "Person touches"; do
    has "$f" || mut B-fcreate gh project field-create "$project" --owner "$owner" --name "$f" --data-type TEXT
  done
  return 0
}

view_filter() { case "$1" in "Needs you") echo 'factory-status:"Waiting on you"' ;; History) echo 'is:closed kind:slice,"role task"' ;; esac; }

make_views() {
  local v requested=0 flt
  read_views
  if [ "$views_known" = 0 ]; then
    echo "view: project id unknown: cannot look for the views; pass --project-id" >&2
    exit 2
  fi
  for v in "Needs you" History; do
    if jq -e --arg v "$v" 'index($v) != null' "$tmp/views.json" >/dev/null; then
      continue
    fi
    requested=1
    flt="$(view_filter "$v")"
    # the create input has no filter field: create the view, then set the filter with the update call
    jq -n --arg p "$pid" --arg n "$v" '{
      query: "mutation($input: CreateProjectV2ViewInput!) { createProjectV2View(input: $input) { projectV2View { id name } } }",
      variables: { input: { projectId: $p, name: $n, layout: "TABLE_LAYOUT" } } }' >"$tmp/body"
    vid=""
    if "gh" api graphql --input - <"$tmp/body" >"$tmp/mutout" 2>"$tmp/err" \
       && vid="$(jq -r '.data.createProjectV2View.projectV2View.id // empty' "$tmp/mutout")" && [ -n "$vid" ] \
       && jq -n --arg i "$vid" --arg f "$flt" '{
            query: "mutation($input: UpdateProjectV2ViewInput!) { updateProjectV2View(input: $input) { projectV2View { id filter } } }",
            variables: { input: { viewId: $i, filter: $f } } }' >"$tmp/body2" \
       && "gh" api graphql --input - <"$tmp/body2" >"$tmp/mutout2" 2>"$tmp/err"; then
      echo "view: $v: requested; open it once and confirm it shows the filter $flt"
      [ "$v" = History ] && echo "view: History: also set the fields to show (Title, Kind, Role, Parent issue, Tokens, Minutes, Hours, Rework rounds, Person touches) and the order (closed, newest first): the API sets only name, layout and filter"
    elif [ -n "$vid" ]; then
      echo "view: $v: created, but its filter was NOT set. Open the view \"$v\" and set the filter by hand: $flt"
    else
      if [ "$v" = History ]; then
        echo "view: $v: NOT created. Build it by hand: name \"$v\", table layout, filter $flt, show Title, Kind, Role, Parent issue, Tokens, Minutes, Hours, Rework rounds, Person touches, order by closed, newest first"
      else
        echo "view: $v: NOT created. Build it by hand: name \"$v\", table layout, filter $flt"
      fi
    fi
  done
  return "$requested"
}

do_apply() {
  [ -n "$pid" ] || { echo "board: project id unknown (--project-id, or the Tracker table)" >&2; exit 2; }
  survey
  if [ "$state" = migrated ]; then
    echo "already migrated"
    return 0
  fi
  echo "board: project $owner/$project"
  echo "state: $state"
  if [ "$state" = fresh ]; then
    mut B-fcreate gh project field-create "$project" --owner "$owner" --name "Factory status" --data-type SINGLE_SELECT --single-select-options "Backlog,Ready,Running,Waiting on you,Blocked,Done"
    echo "created Factory status with six options"
  else
    local p1=0 p2=0 p3=0
    [ "$hasnew" = 0 ] && p1=1
    { [ "$nold" != 0 ] || [ "$p1" = 1 ]; } && p2=1
    { [ "$hasold" = 1 ] || [ "$p1" = 1 ]; } && p3=1
    if [ "$p1$p2$p3" != "000" ]; then
      write_snapshot
    fi
    if [ "$p1" = 1 ]; then phase1; fi
    if [ "$p2" = 1 ]; then phase2; fi
    if [ "$p3" = 1 ]; then phase3; fi
  fi
  create_fields
  local rc=0
  make_views || rc=$?
  if [ "$rc" != 0 ]; then
    echo "views: confirm that both views exist and filter, then run apply --yes --views-confirmed and finish --views-confirmed"
    return 10
  fi
  echo "board: apply done"
  return 0
}

# ---------- finish ----------
write_file() { # <scratch> <target>: write beside, rename
  mv -f "$1" "$2" || { echo "board: could not write $(basename "$2")" >&2; exit 7; }
}

do_finish() {
  [ -n "$pid" ] || true
  [ -r "$factory_md" ] || { echo "board: $(basename "$factory_md") missing" >&2; exit 2; }
  [ -r "$tracker_md" ] || { echo "board: $(basename "$tracker_md") missing" >&2; exit 2; }
  if [ -z "$ops_template" ]; then
    ops_template="$(cd "$(dirname "$0")" && pwd)/../skills/setup-factory-skill/references/issue-tracker-github.factory.md"
  fi
  [ -r "$ops_template" ] || { echo "board: $(basename "$ops_template") missing" >&2; exit 2; }
  grep -q '^## Factory operations$' "$ops_template" || { echo "board: $(basename "$ops_template") has no Factory operations section" >&2; exit 2; }
  grep -q '^| Key | Value |' "$factory_md" || { echo "board: $(basename "$factory_md") has no Tracker key table" >&2; exit 2; }
  [ -w "$(dirname "$factory_md")" ] && [ -w "$factory_md" ] && [ -w "$(dirname "$tracker_md")" ] && [ -w "$tracker_md" ] || { echo "board: a file to write is not writable" >&2; exit 2; }

  survey
  if [ "$state" = fresh ] || [ "$hasnew" = 0 ] || [ "$nold" != 0 ] || [ "$hasold" = 1 ]; then
    echo "board: the board is not migrated: run apply first" >&2
    [ "$nold" != 0 ] && exit 6
    exit 2
  fi
  jq -e --argjson f "$FINAL" '. == $f' "$tmp/optnames.json" >/dev/null || { echo "board: Factory status does not hold the six options in order" >&2; exit 2; }
  [ "$fields_ok" = 1 ] || { echo "board: a field is missing: run apply" >&2; exit 2; }
  if [ "$views_known" = 0 ]; then
    echo "board: project id unknown (--project-id, or the Tracker table)" >&2
    exit 2
  fi
  [ "$views_ok" = 1 ] || { echo "board: a view is missing: run apply" >&2; exit 2; }

  # the values for the Tracker tables
  {
    printf 'key\towner\t%s\n' "$owner"
    printf 'key\tproject number\t%s\n' "$project"
    printf 'key\tproject id\t%s\n' "$pid"
    jq -r '.fields[] | select(.name == "Factory status" or .name == "Kind" or .name == "Role" or .name == "Tokens" or .name == "Minutes" or .name == "Hours" or .name == "Rework rounds" or .name == "Person touches") | "key\tfield id (`\(.name)`)\t\(.id)"' "$tmp/fields.json"
    jq -r '.fields[] | select(.name == "Factory status") | .options[] | "Status\t\(.name)\t\(.id)"' "$tmp/fields.json"
    jq -r '.fields[] | select(.name == "Kind") | .options[] | "Kind\t\(.name)\t\(.id)"' "$tmp/fields.json"
    jq -r '.fields[] | select(.name == "Role") | .options[] | "Role\t\(.name)\t\(.id)"' "$tmp/fields.json"
  } >"$tmp/spec.tsv"

  local has_limit has_kind has_role
  grep -q '^parallel-limit:' "$factory_md" && has_limit=1 || has_limit=0
  grep -q '^| Kind | Option id |' "$factory_md" && has_kind=1 || has_kind=0
  grep -q '^| Role | Option id |' "$factory_md" && has_role=1 || has_role=0

  # 1. factory.md: the Tracker tables, the Parallel slices section
  awk -F'|' -v spec="$tmp/spec.tsv" -v has_limit="$has_limit" -v has_kind="$has_kind" -v has_role="$has_role" '
    function trim(s) { gsub(/^ +| +$/, "", s); return s }
    function emit_tbl(t,   i) { for (i = 1; i <= n[t]; i++) print "| " nm[t, i] " | " id[t, i] " |" }
    function emit_new_tables() {
      if (!has_kind) { print ""; print "| Kind | Option id |"; print "|---|---|"; emit_tbl("Kind"); has_kind = 1 }
      if (!has_role) { print ""; print "| Role | Option id |"; print "|---|---|"; emit_tbl("Role"); has_role = 1 }
    }
    BEGIN {
      FS = "\t"
      while ((getline line < spec) > 0) {
        split(line, f, "\t")
        if (f[1] == "key") { kn++; kk[kn] = f[2]; kv[kn] = f[3]; kidx[f[2]] = kn }
        else { n[f[1]]++; nm[f[1], n[f[1]]] = f[2]; id[f[1], n[f[1]]] = f[3] }
      }
      FS = "|"
      mode = ""
    }
    {
      FS = "|"
      line = $0
      if (mode == "key") {
        if (line !~ /^\|/) {
          for (i = 1; i <= kn; i++) if (!(kk[i] in seen)) print "| " kk[i] " | " kv[i] " |"
          mode = ""
        } else {
          nf = split(line, c, "|")
          key = trim(c[2]); val = trim(c[3])
          if (key in kidx) {
            seen[key] = 1
            i = kidx[key]
            if ((key == "owner" || key == "project number" || key == "project id") && val != "") { print line }
            else { print "| " key " | " kv[i] " |" }
            next
          }
          print line
          next
        }
      }
      if (mode == "tbl") {
        if (line !~ /^\|/) {
          emit_tbl(tbl)
          if (tbl == "Status") emit_new_tables()
          mode = ""
        } else if (line ~ /^\|-/) { print line; next } else { next }
      }
      if (line ~ /^\| Key \| Value \|/) { mode = "key"; print line; next }
      if (line ~ /^\| Status \| Option id \|/) { mode = "tbl"; tbl = "Status"; print line; next }
      if (line ~ /^\| Kind \| Option id \|/) { mode = "tbl"; tbl = "Kind"; print line; next }
      if (line ~ /^\| Role \| Option id \|/) { mode = "tbl"; tbl = "Role"; print line; next }
      if (line == "## Tracker" && !has_limit && !done_limit) {
        print "## Parallel slices"; print ""; print "parallel-limit: 2"; print ""
        print "How many slices may run at the same time, when their path lists do not overlap. `1` means one at a time."; print ""
        done_limit = 1
      }
      print line
    }
    END {
      if (mode == "key") for (i = 1; i <= kn; i++) if (!(kk[i] in seen)) print "| " kk[i] " | " kv[i] " |"
      if (mode == "tbl") { emit_tbl(tbl); if (tbl == "Status") emit_new_tables() }
      if (!has_kind || !has_role) emit_new_tables()
      if (!has_limit && !done_limit) { print ""; print "## Parallel slices"; print ""; print "parallel-limit: 2" }
    }
  ' "$factory_md" >"$factory_md.board.$$" || { rm -f "$factory_md.board.$$"; echo "board: could not build factory.md" >&2; exit 7; }
  write_file "$factory_md.board.$$" "$factory_md"

  # 2. the tracker doc: replace the Factory operations section
  awk -v tpl="$ops_template" '
    BEGIN {
      while ((getline line < tpl) > 0) { if (line == "## Factory operations") on = 1; if (on) sect[++ns] = line }
      while (ns > 0 && sect[ns] == "") ns--
    }
    function put(   i) { for (i = 1; i <= ns; i++) print sect[i]; placed = 1 }
    /^## / {
      if (skipping) { skipping = 0 }
      if ($0 == "## Factory operations") { put(); skipping = 1; print ""; next }
    }
    skipping { next }
    { print }
    END { if (!placed) { print ""; put() } }
  ' "$tracker_md" >"$tracker_md.board.$$" || { rm -f "$tracker_md.board.$$"; echo "board: could not build the tracker doc" >&2; exit 7; }
  # a section ending a file leaves one trailing blank line from the replacement: trim trailing blank lines, keep one newline
  awk '{ a[NR] = $0 } END { n = NR; while (n > 0 && a[n] == "") n--; for (i = 1; i <= n; i++) print a[i] }' "$tracker_md.board.$$" >"$tracker_md.board2.$$" && mv -f "$tracker_md.board2.$$" "$tracker_md.board.$$"
  write_file "$tracker_md.board.$$" "$tracker_md"

  # 3. the last act: line 1 of factory.md
  {
    echo "factory-state: 2"
    echo ""
    if head -n 1 "$factory_md" | grep -q '^factory-state:'; then tail -n +2 "$factory_md" | sed '1{/^$/d;}'; else cat "$factory_md"; fi
  } >"$factory_md.board.$$" || { rm -f "$factory_md.board.$$"; echo "board: could not write the factory-state line" >&2; exit 7; }
  write_file "$factory_md.board.$$" "$factory_md"
  echo "board: finish done: factory-state 2"
  return 0
}

case "$cmd" in
  plan) do_plan ;;
  apply) do_apply ;;
  finish) do_finish ;;
esac
exit $?
