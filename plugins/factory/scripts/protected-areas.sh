# Sourced, not run. The one definition of the protected areas, shared by skip.sh and merge-gate.sh:
# contracts, authentication (auth, oauth, login), secrets, migrations, and the one-way door (declared, never a path).
# protected_path_area <path>: prints the area (contract, authentication, secrets, migration) and returns 0 for a protected path;
#   prints nothing and returns 1 otherwise. ASCII case is folded.
# protected_touch_area <name>: prints the area for a declared name (contract|contracts, authentication, secrets,
#   migration|data-migration, door|one-way-door) and returns 0; returns 1 for an unknown name.
protected_path_area() {
  local lp
  lp="$(printf '%s' "$1" | LC_ALL=C tr 'A-Z' 'a-z')"
  case "$lp" in
    contracts | contracts/* | */contracts/*) echo contract ;;
    *auth* | *login*) echo authentication ;;
    .env* | */.env* | *secret* | *credential* | *.pem | *.key) echo secrets ;;
    *migrat* | *.sql) echo migration ;;
    *) return 1 ;;
  esac
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
