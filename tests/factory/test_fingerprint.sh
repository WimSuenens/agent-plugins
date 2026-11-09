#!/bin/bash
# fingerprint.sh: AC-2, AC-3, AC-4, AC-5 and contract 39-plugin-scripts section 1.
# Adopted from the developer's fixture test and extended by QA.
. "$(dirname "$0")/lib.sh"
FROZEN="$HOME/.claude/plugins/cache/wimsuenens/factory/9147301f75c3"
STD_84f=48f28915d19a3b1261c98220136dcab0098061d0c62c0d1ee7a290d8ea6d1c20
TOOL_84f=d079b65b9ad1fb187cd08f0033ff589838e8564baf2bc92a4ff521e63af37652

# --- contract worked example: frozen install and main at 84f282e give the same pair
if [ -d "$FROZEN" ]; then
  ck worked-example-frozen "release: 9147301f75c3 (pre-release install, no semver)
standard: $STD_84f
tooling: $TOOL_84f" "$(bash "$FP" "$FROZEN")"
else
  skip worked-example-frozen "frozen install not present on this machine"
fi
if git -C "$REPO" cat-file -e 84f282e 2>/dev/null; then
  mkdir -p "$T/main" && git -C "$REPO" archive 84f282e plugins/factory | tar -x -C "$T/main"
  ck worked-example-84f282e "release: factory (pre-release install, no semver)
standard: $STD_84f
tooling: $TOOL_84f" "$(bash "$FP" "$T/main/plugins/factory")"
else
  skip worked-example-84f282e "commit 84f282e not in this clone"
fi

# --- AC-2: release 1.3.0 (the #60 release; was 1.2.0 for #57 and 1.1.0 for #49; contract 60-standard-changes section 1) from the real branch tree, both as an install path ending in
#     a version segment and as a --plugin-dir path ending plugins/factory, without git
mkdir -p "$T/cache/wimsuenens/factory" "$T/dir/plugins"
cp -R "$PLUGIN" "$T/cache/wimsuenens/factory/2.2.0"
cp -R "$PLUGIN" "$T/dir/plugins/factory"
rm -rf "$T/cache/wimsuenens/factory/2.2.0/.git" "$T/dir/plugins/factory/.git"
inst="$(cd / && bash "$FP" "$T/cache/wimsuenens/factory/2.2.0")"
pdir="$(cd / && bash "$FP" "$T/dir/plugins/factory")"
ck ac2-install-path-release "release: 2.2.0" "$(line "$inst" 1)"
ck ac2-plugin-dir-release "release: 2.2.0" "$(line "$pdir" 1)"
ck ac2-real-plugin-json "2.2.0" "$(jq -r .version "$PLUGIN/.claude-plugin/plugin.json")"

# --- AC-3: two copies, different absolute paths, different mtimes, separate runs
touch -t 200001010000 "$T/dir/plugins/factory/references/protocol.md" "$T/dir/plugins/factory/scripts/check-bump.sh"
chmod 600 "$T/dir/plugins/factory/agents/developer.md"
pdir2="$(cd "$T" && bash "$FP" dir/plugins/factory/)"   # relative path, trailing slash, other cwd
ck ac3-same-fingerprints "$(sed 1d <<<"$inst")" "$(sed 1d <<<"$pdir2")"
std="$(line "$inst" 2 | sed 's/^standard: //')"; tool="$(line "$inst" 3 | sed 's/^tooling: //')"
ck ac3-standard-64-hex 1 "$(printf '%s' "$std" | grep -Ec '^[0-9a-f]{64}$')"
ck ac3-tooling-64-hex 1 "$(printf '%s' "$tool" | grep -Ec '^[0-9a-f]{64}$')"
# concurrent runs on one tree agree
for i in 1 2 3 4; do bash "$FP" "$T/dir/plugins/factory" > "$T/conc.$i" & done; wait
ck concurrent-runs-agree 1 "$(cat "$T"/conc.* | sort -u | wc -l | awk '{print ($1==3)}')"

# --- algorithm, checked by hand against the contract (manifest of sha256sum lines, sorted bytewise)
manual() { # <root> <files...>
  r="$1"; shift
  ( cd "$r" && for f in "$@"; do printf '%s  %s\n' "$(shasum -a 256 < "$f" | cut -d' ' -f1)" "$f"; done ) | shasum -a 256 | cut -d' ' -f1
}
R="$T/dir/plugins/factory"
stdfiles="$(cd "$R" && ls skills/run/SKILL.md references/*.md agents/*.md | LC_ALL=C sort)"
toolfiles="$(cd "$R" && find hooks scripts -type f ! -path '*/.*' | LC_ALL=C sort)"
ck algorithm-standard "standard: $(manual "$R" $stdfiles)" "$(line "$pdir" 2)"
ck algorithm-tooling "tooling: $(manual "$R" $toolfiles)" "$(line "$pdir" 3)"

# --- AC-4: one byte in each named standard-work file moves standard (and not tooling)
base="$(bash "$FP" "$R")"
for f in skills/run/SKILL.md references/protocol.md references/hansei.md agents/developer.md; do
  cp -R "$R" "$T/c4"; printf 'x' >> "$T/c4/$f"
  out="$(bash "$FP" "$T/c4")"
  differ "ac4-byte-in-$f-moves-standard" "$(line "$base" 2)" "$(line "$out" 2)"
  ck "ac4-byte-in-$f-keeps-tooling" "$(line "$base" 3)" "$(line "$out" 3)"
  rm -rf "$T/c4"
done
# a one-byte change inside the file (same length), not only an append
cp -R "$R" "$T/c4"; f4="$T/c4/agents/qa-engineer.md"; { printf 'Z'; tail -c +2 "$R/agents/qa-engineer.md"; } > "$f4"
ck ac4-same-length-size "$(wc -c < "$R/agents/qa-engineer.md")" "$(wc -c < "$f4")"
differ ac4-same-length-byte-moves-standard "$(line "$base" 2)" "$(line "$(bash "$FP" "$T/c4")" 2)"; rm -rf "$T/c4"
# add and remove files in agents/ and references/
for op in "add agents/new.md" "add references/new.md" "rm agents/architect.md" "rm references/decision-card.md"; do
  set -- $op; cp -R "$R" "$T/c4"
  if [ "$1" = add ]; then echo n > "$T/c4/$2"; else rm "$T/c4/$2"; fi
  differ "ac4-$1-$2-moves-standard" "$(line "$base" 2)" "$(line "$(bash "$FP" "$T/c4")" 2)"
  rm -rf "$T/c4"
done
# rename moves (path is in the manifest)
cp -R "$R" "$T/c4"; mv "$T/c4/agents/devops.md" "$T/c4/agents/devops2.md"
differ ac4-rename-moves-standard "$(line "$base" 2)" "$(line "$(bash "$FP" "$T/c4")" 2)"; rm -rf "$T/c4"
# outside standard work and tooling: neither moves
cp -R "$R" "$T/c4"
echo x >> "$T/c4/README.md" 2>/dev/null || echo x > "$T/c4/README.md"
sed -i '' 's/"description": "/"description": "x/' "$T/c4/.claude-plugin/plugin.json"
for s in "$T"/c4/skills/setup-factory-skill/*; do [ -f "$s" ] && echo x >> "$s"; done
mkdir -p "$T/c4/.in_use" "$T/c4/references/sub"; touch "$T/c4/.orphaned_at" "$T/c4/scripts/.DS_Store" "$T/c4/references/.a.md.swp" "$T/c4/hooks/.x"
echo q > "$T/c4/references/sub/nested.md"; echo q > "$T/c4/references/notes.txt"
out="$(bash "$FP" "$T/c4")"
ck ac4-outside-keeps-standard "$(line "$base" 2)" "$(line "$out" 2)"
ck ac4-outside-keeps-tooling "$(line "$base" 3)" "$(line "$out" 3)"
# plugin.json version change alone: release moves, fingerprints don't
sed -i '' 's/"version": "2.2.0"/"version": "2.2.1"/' "$T/c4/.claude-plugin/plugin.json"
out="$(bash "$FP" "$T/c4")"
ck ac4-version-moves-release "release: 2.2.1" "$(line "$out" 1)"
ck ac4-version-keeps-standard "$(line "$base" 2)" "$(line "$out" 2)"
rm -rf "$T/c4"

# --- AC-5: original / scripts-only change / protocol.md-only change, told apart by the fields alone
cp -R "$R" "$T/t5"; echo '# x' >> "$T/t5/scripts/token-spend.sh"
cp -R "$R" "$T/s5"; echo x >> "$T/s5/references/protocol.md"
o="$(bash "$FP" "$R")"; t5="$(bash "$FP" "$T/t5")"; s5="$(bash "$FP" "$T/s5")"
ck ac5-tooling-copy-same-standard "$(line "$o" 2)" "$(line "$t5" 2)"
differ ac5-tooling-copy-other-tooling "$(line "$o" 3)" "$(line "$t5" 3)"
differ ac5-standard-copy-other-standard "$(line "$o" 2)" "$(line "$s5" 2)"
ck ac5-standard-copy-same-tooling "$(line "$o" 3)" "$(line "$s5" 3)"
differ ac5-two-copies-look-different "$(sed 1d <<<"$t5")" "$(sed 1d <<<"$s5")"
# tooling is recursive under hooks/ and scripts/
mkdir -p "$T/t5/scripts/sub"; echo z > "$T/t5/scripts/sub/z.sh"
differ tooling-recursive "$(line "$t5" 3)" "$(line "$(bash "$FP" "$T/t5")" 3)"
# a file name with a space is listed and hashed
cp -R "$R" "$T/sp"; echo s > "$T/sp/references/a b.md"
differ space-in-name-moves-standard "$(line "$o" 2)" "$(line "$(bash "$FP" "$T/sp")" 2)"

# --- release field and exit codes
mk() { rm -rf "$1"; mkdir -p "$1/.claude-plugin" "$1/skills/run" "$1/references" "$1/agents"; printf '%s\n' "$2" > "$1/.claude-plugin/plugin.json"; echo r > "$1/skills/run/SKILL.md"; }
mk "$T/x/myinstall" '{"name":"factory"}'
out="$(bash "$FP" "$T/x/myinstall")"
ck no-version-label "release: myinstall (pre-release install, no semver)" "$(line "$out" 1)"
ck empty-tooling-set "tooling: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" "$(line "$out" 3)"
mk "$T/x/min" '{"name":"factory","version":"2.10.3","dependencies":["a"]}'
ck minified-json-version "release: 2.10.3" "$(line "$(bash "$FP" "$T/x/min")" 1)"
for v in 1.0 1.0.0-rc1 v1.0.0 1.0.0.0 1..0 abc 1.08.0 01.0.0 1.0.00; do
  mk "$T/x/bad" "{\"version\": \"$v\"}"
  out="$(bash "$FP" "$T/x/bad" 2>"$T/err")"; code=$?
  ck "bad-version-$v-exit-2" 2 "$code"; ck "bad-version-$v-no-stdout" "" "$out"
done
mk "$T/x/emptyver" '{"version": ""}'
out="$(bash "$FP" "$T/x/emptyver" 2>/dev/null)"; code=$?
ck empty-version-exit-2 2 "$code"; ck empty-version-no-stdout "" "$out"   # QA-39 F3, fixed
mk "$T/x/zerover" '{"version":"0.0.0"}'; ck zero-version-is-semver "release: 0.0.0" "$(line "$(bash "$FP" "$T/x/zerover")" 1)"
bash "$FP" "$T/nonexistent" >/dev/null 2>"$T/err"; ck not-a-root-exit-2 2 $?
[ -s "$T/err" ] && ck not-a-root-stderr 1 1 || ck not-a-root-stderr "a reason" ""
bash "$FP" >/dev/null 2>&1; ck no-argument-exit-2 2 $?
mk "$T/x/nopj" '{}'; rm "$T/x/nopj/.claude-plugin/plugin.json"; bash "$FP" "$T/x/nopj" >/dev/null 2>&1; ck no-plugin-json-exit-2 2 $?
mk "$T/x/noskill" '{"version":"1.0.0"}'; rm "$T/x/noskill/skills/run/SKILL.md"; bash "$FP" "$T/x/noskill" >/dev/null 2>&1; ck no-skill-exit-2 2 $?
mkdir "$T/bin"; for c in bash sed sort find cat tr cut awk grep head dirname basename printf wc; do p="$(command -v $c)" && ln -s "$p" "$T/bin/$c"; done
mk "$T/x/ok" '{"version":"1.0.0"}'
PATH="$T/bin" /bin/bash "$FP" "$T/x/ok" >/dev/null 2>&1; ck no-sha-tool-exit-3 3 $?

# --- permissions: an unreadable standard file must not yield a fingerprint as if captured
cp -R "$R" "$T/perm"; chmod 000 "$T/perm/references/hansei.md"
out="$(bash "$FP" "$T/perm" 2>"$T/err")"; code=$?
ck unreadable-file-exit-2 2 "$code"; ck unreadable-file-no-stdout "" "$out"   # QA-39 F2, fixed
ck unreadable-file-names-rel-path "fingerprint: cannot read references/hansei.md" "$(cat "$T/err")"
chmod 644 "$T/perm/references/hansei.md"
# all or nothing for the tooling set too, recursively
mkdir -p "$T/perm/scripts/sub"; echo t > "$T/perm/scripts/sub/t.sh"; chmod 000 "$T/perm/scripts/sub/t.sh"
out="$(bash "$FP" "$T/perm" 2>"$T/err")"; code=$?
ck unreadable-tooling-exit-2 2 "$code"; ck unreadable-tooling-no-stdout "" "$out"
ck unreadable-tooling-names-rel-path "fingerprint: cannot read scripts/sub/t.sh" "$(cat "$T/err")"
chmod 644 "$T/perm/scripts/sub/t.sh"

# --- feedback 15 #8 (security L5): no absolute path in any message; a root is named by its basename
H="$T/home/someone/.claude/plugins/cache/wimsuenens/factory/9147301f75c3"; mkdir -p "$H"
bash "$FP" "$H" >/dev/null 2>"$T/err"; ck not-a-root-basename-only "fingerprint: not a factory plugin root: 9147301f75c3" "$(cat "$T/err")"
bash "$FP" "$H/" >/dev/null 2>"$T/err"; ck not-a-root-trailing-slash-no-path 0 "$(grep -c / "$T/err")"
for d in "$T/x/emptyver" "$T/x/bad"; do
  bash "$FP" "$d" >/dev/null 2>"$T/err"; ck "no-abs-path-in-error-$(basename "$d")" 0 "$(grep -cF "$T" "$T/err")"
done

done_
