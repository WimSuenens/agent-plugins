#!/bin/bash
# andon-detect.sh owner (#211): a table token is matched literally except `*`, and the most specific row owns the path
# (exact path, then directory prefix by length, then wildcard by the literal characters before its first `*`); a tie between
# different owners is reported, not decided. Tables are built here at run time.
. "$(dirname "$0")/lib.sh"
AD="$PLUGIN/scripts/andon-detect.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
own() { # <path> <row>...  (each row is `token|owner`)
  p="$1"; shift; { echo '| Path | Owner |'; echo '|---|---|'; for r in "$@"; do printf '| `%s` | %s |\n' "${r%%|*}" "${r#*|}"; done; } > "$T/t.md"
  bash "$AD" owner "$T/t.md" "$p"
}

# ---- point 1: every regex metacharacter but `*` matches literally (`|` cannot sit in a table cell: the cell ends there) ----
for c in '.' '+' '?' '[' ']' '(' ')' '{' '}' '^' '$' '\'; do
  ck "meta-literal-match [$c]" developer "$(own "d/a${c}b/x.md" "d/a${c}b/*.md|developer")"
done
ck meta-dot-not-any-char ""        "$(own d/aXb/x.md 'd/a.b/*.md|developer')"
ck meta-plus-not-repeat ""         "$(own d/aab/x.md 'd/a+b/*.md|developer')"
ck meta-question-not-optional ""   "$(own d/b/x.md 'd/a?b/*.md|developer')"
ck meta-bracket-not-class ""       "$(own d/a/x.md 'd/[ab]/*.md|developer')"
ck meta-paren-not-group ""         "$(own d/a/x.md 'd/(a)/*.md|developer')"
ck meta-brace-not-count ""         "$(own d/aa/x.md 'd/a{2}/*.md|developer')"
ck meta-wildcard-still-wild developer "$(own docs/deep/er/x.md 'docs/*.md|developer')"
ck meta-wildcard-middle developer "$(own plugins/f/skills/run/SKILL.md 'plugins/*/skills/*/SKILL.md|developer')"

ck glob-star-matches-empty developer "$(own d/ab/x.md 'd/a*b/*.md|developer')"
ck glob-middle-segments-in-order developer "$(own p/a1/b2/c.md 'p/*1/*2/*.md|developer')"
ck glob-order-matters "" "$(own p/b2/a1/c.md 'p/*1/*2/*.md|developer')"
ck glob-suffix-must-end "" "$(own p/x.md.bak 'p/*.md|developer')"

# ---- point 2: specificity, not text length ----
ck rank-exact-beats-longer-wildcard docs-writer "$(own plugins/factory/skills/run/SKILL.md 'plugins/factory/skills/*/SKILL.md|developer' 'plugins/factory/skills/run/SKILL.md|docs-writer')"
ck rank-exact-beats-longer-wildcard-order docs-writer "$(own plugins/factory/skills/run/SKILL.md 'plugins/factory/skills/run/SKILL.md|docs-writer' 'plugins/factory/skills/*/SKILL.md|developer')"
ck rank-dir-beats-longer-wildcard architect "$(own docs/adr/x.md 'docs/*/x.md|developer' 'docs/|architect')"
ck rank-longer-dir-wins architect "$(own docs/adr/x.md 'docs/|docs-writer' 'docs/adr/|architect')"
ck rank-longer-dir-wins-order architect "$(own docs/adr/x.md 'docs/adr/|architect' 'docs/|docs-writer')"
ck rank-more-literal-before-star-wins qa-engineer "$(own reviews/qa-7.md 'reviews/*|developer' 'reviews/qa-*|qa-engineer')"
ck rank-stars-do-not-count-as-length qa-engineer "$(own a/b/c.md 'a/*/*/*/*.md|developer' 'a/b/*.md|qa-engineer')"
ck rank-dir-token-itself-matches architect "$(own docs/adr 'docs/adr/|architect' 'docs/|docs-writer')"

# ---- ties ----
ck tie-reported "ambiguous owner: x/y.md developer qa-engineer" "$(own x/y.md 'x/*.md|developer' 'x/*.md|qa-engineer')"
ck tie-reported-exact "ambiguous owner: x/y.md developer qa-engineer" "$(own x/y.md 'x/y.md|developer' 'x/y.md|qa-engineer')"
ck tie-same-owner-is-no-tie developer "$(own x/y.md 'x/*.md|developer' 'x/*.md|developer')"
ck tie-lower-rank-ignored qa-engineer "$(own x/y.md 'x/|developer' 'x/y.md|qa-engineer')"

# ---- kind 3 prints the tie as a role-outside-role line with the commit and role, and keeps its own line where there is none ----
D="$T/r"; mkdir -p "$D/docs/agents"; git -C "$D" init -q -b main
printf '%s\n' '| Path | Owner |' '|---|---|' '| `x/*.md` | developer |' '| `x/*.md` | qa-engineer |' '| `z/` | qa-engineer |' > "$D/docs/agents/factory.md"
echo b > "$D/README.md"; git -C "$D" add -A; git -C "$D" commit -qm base; git -C "$D" checkout -q -b item/9
mkdir -p "$D/x" "$D/z"; echo 1 > "$D/x/y.md"; echo 1 > "$D/z/q"; git -C "$D" add -A; git -C "$D" commit -qm "#9 developer: change"
ck kind3-tie-and-plain-lines "role-outside-role: $(git -C "$D" rev-parse --short=7 HEAD) developer changed x/y.md (ambiguous owner: developer qa-engineer);role-outside-role: $(git -C "$D" rev-parse --short=7 HEAD) developer changed z/q (owner qa-engineer);" \
  "$(bash "$AD" kind3 --in "$D" --table "$D/docs/agents/factory.md" --base main | sort | tr '\n' ';')"
done_
