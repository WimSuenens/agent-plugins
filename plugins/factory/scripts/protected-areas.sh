# Sourced, not run. The one definition of the protected areas, shared by skip.sh and merge-gate.sh:
# contracts, authentication (auth, oauth, login), secrets, migrations, and the one-way door (declared, never a path).
# protected_path_area <path>: prints the area (contract, authentication, secrets, migration, project) and returns 0 for a protected path;
#   the built-in patterns read one path component at a time (*auth*, *login*, *signin*, *secret*, *credential*, .env*, *.pem, *.key, *migrat*, *.sql)
#   after the words that only look like them (author, secretar, immigrat, emigrat, blogin) are taken out, so author and secretary are no hit;
#   `project` is a path matching a glob of the project's line `protected-paths: <glob>, <glob>` at column 0 of docs/agents/factory.md (the working directory's);
#   prints nothing and returns 1 otherwise. ASCII case is folded.
# protected_touch_area <name>: prints the area for a declared name (contract|contracts, authentication, secrets,
#   migration|data-migration, door|one-way-door) and returns 0; returns 1 for an unknown name.
protected_path_area() {
  local lp rest c w b a="" noglob=0 line g
  lp="$(printf '%s' "$1" | LC_ALL=C tr 'A-Z' 'a-z')"
  # one path component at a time. The word may sit inside a name (authService, userauth, my-secret); the words that only look like it
  # (author, secretary, immigration, blogin) are taken out first, and authoriz* is kept as authz.
  rest="$lp"
  while [ -n "$rest" ]; do
    c="${rest%%/*}"
    case "$rest" in */*) rest="${rest#*/}" ;; *) rest="" ;; esac
    w="${c//authoriz/authz}"
    for b in author secretar immigrat emigrat blogin; do w="${w//$b/_}"; done
    case "$c" in contracts) a=contract ;; esac
    if [ -z "$a" ]; then
      case "$w" in
        *auth* | *login* | *signin*) a=authentication ;;
        .env* | *secret* | *credential* | *.pem | *.key) a=secrets ;;
        *migrat* | *.sql) a=migration ;;
      esac
    fi
    [ -n "$a" ] && { echo "$a"; return 0; }
  done
  # the project's own extension: one line at column 0 in docs/agents/factory.md, `protected-paths: <glob>, <glob>` (shell globs, case folded)
  [ -r docs/agents/factory.md ] || return 1
  line="$(grep -m 1 '^protected-paths:' docs/agents/factory.md | tr -d '\r' | LC_ALL=C tr 'A-Z' 'a-z')"
  line="${line#protected-paths:}"
  case "$-" in *f*) noglob=1 ;; esac
  set -f
  local old_ifs="$IFS"; IFS=','
  for g in $line; do
    g="${g#"${g%%[![:space:]]*}"}"; g="${g%"${g##*[![:space:]]}"}"
    [ -n "$g" ] || continue
    # shellcheck disable=SC2254
    case "$lp" in $g) a=project; break ;; esac
  done
  IFS="$old_ifs"
  [ "$noglob" = 1 ] || set +f
  [ -n "$a" ] && { echo "$a"; return 0; }
  return 1
}
protected_touch_area() {
  case "$1" in
    contract | contracts) echo contract ;;
    authentication) echo authentication ;;
    secrets) echo secrets ;;
    migration | data-migration) echo migration ;;
    door | one-way-door) echo door ;;
    *) return 1 ;;
  esac
}
