# Helpers for the slice-64 tests: the fake gh (tests/factory/fake-gh/gh), board fixtures, and call-log readers.
# Source after lib.sh. Needs bash 3.2, jq, git.

FAKE_GH="$REPO/tests/factory/fake-gh/gh"
FX64="$REPO/tests/factory/fixtures/board"
SCRIPTS="$PLUGIN/scripts"
BOARD_SH="$SCRIPTS/board.sh"

# fake_setup: put the fake gh first on PATH, with a fresh log and answer folder
fake_setup() {
  mkdir -p "$T/fakebin" "$T/fakedir"
  cp "$FAKE_GH" "$T/fakebin/gh"; chmod +x "$T/fakebin/gh"
  : >"$T/gh.log"; rm -f "$T"/gh.log.count.*
  export FAKE_GH_LOG="$T/gh.log" FAKE_GH_DIR="$T/fakedir"
  export PATH="$T/fakebin:$ORIG_PATH"
  unset FAKE_GH_FAIL FAKE_GH_BOARD FAKE_BOARD_CLEAR FAKE_BOARD_REFUSE_VIEW FAKE_BOARD_IGNORE_SET
}
ORIG_PATH="$PATH"
# log_reset: empty the call log and the per-op counters
log_reset() { : >"$T/gh.log"; rm -f "$T"/gh.log.count.*; }
# log_ops: the op ids in call order, one per line
log_ops() { jq -r '.op' "$T/gh.log"; }
log_count() { log_ops | grep -cx "$1"; }
MUTATION_OPS='B-add|B-set|B-text|B-fcreate|B-foptions|B-vcreate|B-vupdate|T-create|T-link|T-comment|T-edit-comment|T-close'
log_mutations() { log_ops | grep -cE "^($MUTATION_OPS)$"; }
log_unknown() { log_ops | grep -cx unknown; }
# board_load <fixture.json>: a fresh stateful board for the fake
board_load() { cp "$1" "$T/board.json"; export FAKE_GH_BOARD="$T/board.json"; }
# board_norm: the board in a form that compares across runs: option names in order, every item's values, field names, view names
board_norm() {
  jq -S '{fields: [.fields[] | {name, type, options: ([.options[]? | .name])}], items: [.items | sort_by(.id)[] | {id, values}], views: [.views[].name] }' "${1:-$T/board.json}"
}
# the state dir used by the tests, outside any repo
SD="$T/state/factory/board-fixt-77"
bs() { # bs <board.sh args...>: run board.sh against the fake with the fixture project
  bash "$BOARD_SH" "$@" --owner fixt --project 77 2>"$T/bs.err" >"$T/bs.out"
  BS_RC=$?
}
bsa() { bs "$1" --project-id PVT_fixture01 --state-dir "$SD" "${@:2}"; }
