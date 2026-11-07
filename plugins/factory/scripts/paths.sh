#!/usr/bin/env bash
# The path lists of the contracts of a slice, and the overlap rule that lets two slices run at the same time.
# Usage: bash paths.sh list <contract-file>...
#        bash paths.sh overlap <file>... -- <file>...
#        bash paths.sh check [--ignore <prefix>]... <contract-file>...      (names on stdin, one per line)
# A list is the union of the "Paths:" blocks of the files, read outside code fences: a line "Paths:", then "- <path>" lines, then a "shared:" line.
# list: prints "path <p>" or "shared <s>" per entry ("shared none" is not printed).
# overlap: prints "overlap: no", "overlap: yes <p> <q>" or "overlap: yes shared <s>" (the first pair found, in list order).
# check: prints "off-list: <name>" for each stdin name that is not on the list; a name under an --ignore prefix is skipped.
# Exit: 0 ok / no overlap / none off-list; 1 overlap / at least one off-list; 2 usage, a file without a Paths: block or without a shared: line; 3 a malformed entry (named by line number).
# See contracts/64-parallel-slices.md sections 1 and 2 in the repo that hosts the factory.

PATHS=()
SHARED=()

valid_path() {
  case "$1" in
    "" | /* | ./* | ../* | */../* | */.. | .. ) return 1 ;;
    *" "* | *,* | *'`'* | *'*'* | *'?'* | *'['* ) return 1 ;;
  esac
  return 0
}

# load <file>: appends the entries of the file's blocks to PATHS and SHARED. Returns 0, 2 or 3.
load() {
  local f="$1" line n=0 state=0 got_block=0 got_shared=0 entries=0 e rest s old_ifs
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    echo "paths: $(basename "$f"): unreadable" >&2
    return 2
  fi
  local fence=0
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    line="${line%$'\r'}"
    case "$line" in
      '```'* | '~~~'*) fence=$((1 - fence)); continue ;;
    esac
    [ "$fence" = 1 ] && continue
    if [ "$state" = 0 ]; then
      if [ "$line" = "Paths:" ]; then
        state=1
        entries=0
        got_block=1
      fi
      continue
    fi
    # state 1: inside a block, reading entries
    case "$line" in
      "- "*)
        e="${line#- }"
        if ! valid_path "$e" || [ "${e}" != "${e% }" ]; then
          echo "paths: $(basename "$f"):$n: malformed entry" >&2
          return 3
        fi
        PATHS[${#PATHS[@]}]="$e"
        entries=$((entries + 1))
        ;;
      "shared:"*)
        if [ "$entries" = 0 ]; then
          echo "paths: $(basename "$f"):$n: empty Paths block" >&2
          return 3
        fi
        rest="${line#shared:}"
        rest="${rest# }"
        if [ -z "$rest" ] || [ "$rest" != "${rest% }" ]; then
          echo "paths: $(basename "$f"):$n: malformed shared line" >&2
          return 3
        fi
        old_ifs="$IFS"
        IFS=','
        for s in $rest; do
          s="${s# }"
          if [ "$s" = none ]; then continue; fi
          if [ "$s" != adr-number ]; then
            case "$s" in */) echo "paths: $(basename "$f"):$n: malformed shared entry" >&2; IFS="$old_ifs"; return 3 ;; esac
            if ! valid_path "$s"; then
              echo "paths: $(basename "$f"):$n: malformed shared entry" >&2
              IFS="$old_ifs"
              return 3
            fi
          fi
          SHARED[${#SHARED[@]}]="$s"
        done
        IFS="$old_ifs"
        got_shared=1
        state=0
        ;;
      *)
        # the block ended without a shared: line
        echo "paths: $(basename "$f"):$n: Paths block has no shared line" >&2
        return 2
        ;;
    esac
  done <"$f"
  if [ "$state" = 1 ]; then
    echo "paths: $(basename "$f"): Paths block has no shared line" >&2
    return 2
  fi
  if [ "$got_block" = 0 ]; then
    echo "paths: $(basename "$f"): no Paths block" >&2
    return 2
  fi
  return 0
}

# load_all <file>...: PATHS and SHARED become the union (first occurrence kept)
load_all() {
  local f rc p q dup
  PATHS=()
  SHARED=()
  for f in "$@"; do
    load "$f"
    rc=$?
    [ "$rc" != 0 ] && return "$rc"
  done
  # dedupe
  local up=() us=()
  for p in "${PATHS[@]}"; do
    dup=0
    for q in "${up[@]}"; do [ "$p" = "$q" ] && dup=1; done
    [ "$dup" = 0 ] && up[${#up[@]}]="$p"
  done
  for p in "${SHARED[@]}"; do
    dup=0
    for q in "${us[@]}"; do [ "$p" = "$q" ] && dup=1; done
    [ "$dup" = 0 ] && us[${#us[@]}]="$p"
  done
  PATHS=("${up[@]}")
  SHARED=("${us[@]}")
  return 0
}

# covers <p> <q>: p equals q, or p is a directory prefix of q
covers() {
  [ "$1" = "$2" ] && return 0
  case "$1" in
    */) case "$2" in "$1"*) return 0 ;; esac ;;
  esac
  return 1
}

cmd="${1:-}"
[ $# -gt 0 ] && shift
case "$cmd" in
  list)
    [ $# -ge 1 ] || { echo "usage: paths.sh list <contract-file>..." >&2; exit 2; }
    load_all "$@" || exit $?
    for p in "${PATHS[@]}"; do echo "path $p"; done
    for p in "${SHARED[@]}"; do echo "shared $p"; done
    exit 0
    ;;
  overlap)
    a=()
    b=()
    side=a
    for x in "$@"; do
      if [ "$x" = "--" ] && [ "$side" = a ]; then side=b; continue; fi
      if [ "$side" = a ]; then a[${#a[@]}]="$x"; else b[${#b[@]}]="$x"; fi
    done
    if [ "$side" = a ] || [ ${#a[@]} -eq 0 ] || [ ${#b[@]} -eq 0 ]; then
      echo "usage: paths.sh overlap <file>... -- <file>..." >&2
      exit 2
    fi
    load_all "${a[@]}" || exit $?
    pa=("${PATHS[@]}")
    sa=("${SHARED[@]}")
    load_all "${b[@]}" || exit $?
    pb=("${PATHS[@]}")
    sb=("${SHARED[@]}")
    for p in "${pa[@]}"; do
      for q in "${pb[@]}"; do
        if covers "$p" "$q" || covers "$q" "$p"; then
          echo "overlap: yes $p $q"
          exit 1
        fi
      done
    done
    for p in "${sa[@]}"; do
      for q in "${sb[@]}"; do
        if [ "$p" = "$q" ]; then
          echo "overlap: yes shared $p"
          exit 1
        fi
      done
    done
    echo "overlap: no"
    exit 0
    ;;
  check)
    ign=()
    files=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --ignore) [ $# -ge 2 ] || { echo "paths: --ignore needs a prefix" >&2; exit 2; }; ign[${#ign[@]}]="$2"; shift 2 ;;
        *) files[${#files[@]}]="$1"; shift ;;
      esac
    done
    [ ${#files[@]} -ge 1 ] || { echo "usage: paths.sh check [--ignore <prefix>]... <contract-file>..." >&2; exit 2; }
    load_all "${files[@]}" || exit $?
    rc=0
    while IFS= read -r name || [ -n "$name" ]; do
      [ -n "$name" ] || continue
      skip=0
      for i in "${ign[@]}"; do
        case "$name" in "$i"*) skip=1 ;; esac
      done
      [ "$skip" = 1 ] && continue
      on=0
      for p in "${PATHS[@]}"; do
        covers "$p" "$name" && on=1
      done
      for p in "${SHARED[@]}"; do
        [ "$p" = "$name" ] && on=1
      done
      if [ "$on" = 0 ]; then
        echo "off-list: $name"
        rc=1
      fi
    done
    exit "$rc"
    ;;
  *)
    echo "usage: paths.sh list|overlap|check ..." >&2
    exit 2
    ;;
esac
