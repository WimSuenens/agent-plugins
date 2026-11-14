#!/bin/bash
# #214: six review leftovers of slice 1 of #207 and of #211. One block per item, in the order they were built.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
PA="$PLUGIN/scripts/protected-areas.sh"; SK="$PLUGIN/scripts/skip.sh"; MG="$PLUGIN/scripts/merge-gate.sh"
PT="$PLUGIN/scripts/post-text.sh"; AD="$PLUGIN/scripts/andon-detect.sh"; HANSEI="$PLUGIN/references/hansei.md"
cd "$T" || exit 1
mkdir -p "$T/bin"
cat >"$T/bin/gh" <<'SH'
#!/bin/bash
[ "$1 $2" = "pr view" ] && { cat "$PRJSON"; exit 0; }
exit 99
SH
chmod +x "$T/bin/gh"; export PATH="$T/bin:$PATH"; export PRJSON="$T/pr.json"
jq -n --arg b $'## Proof\n\n```\nok\n```\n' '{body:$b,statusCheckRollup:[{name:"ci",conclusion:"SUCCESS"}]}' >"$PRJSON"

# --- item 2: protected-paths is read from origin/main first, relative to the repository top level
R2="$T/r2"; mkdir -p "$R2/docs/agents" "$R2/sub"
( cd "$R2" && git init -q -b main . && printf 'factory-state: 2\nprotected-paths: infra/*\n' >docs/agents/factory.md && git add -A && git commit -qm base \
  && git update-ref refs/remotes/origin/main HEAD && git checkout -qb slice )
printf 'factory-state: 2\n' >"$R2/docs/agents/factory.md"   # the branch drops the line that judges it
printf 'Paths:\n- infra/main.tf\nshared: none\n' >"$T/infra.md"
( cd "$R2" && bash "$SK" protected "$T/infra.md" >/dev/null ); ck item2-skip-sees-line-from-main 1 "$?"
( cd "$R2/sub" && bash "$SK" protected "$T/infra.md" >/dev/null ); ck item2-skip-from-subdirectory 1 "$?"
( cd "$R2" && bash "$MG" check 7 --qa pass --security pass --paths "infra/main.tf" >/dev/null ); ck item2-gate-sees-line-from-main 10 "$?"
# where main has no such line the working tree's own line still counts (the branch that introduces it)
R2b="$T/r2b"; mkdir -p "$R2b/docs/agents"
( cd "$R2b" && git init -q -b main . && printf 'factory-state: 2\n' >docs/agents/factory.md && git add -A && git commit -qm base && git update-ref refs/remotes/origin/main HEAD )
printf 'factory-state: 2\nprotected-paths: infra/*\n' >"$R2b/docs/agents/factory.md"
( cd "$R2b" && bash "$SK" protected "$T/infra.md" >/dev/null ); ck item2-working-tree-line-where-main-has-none 1 "$?"

# --- item 1: a changed path with a space keeps its components; --paths is one path per line, a one-line list still splits on whitespace
printf 'factory-state: 2\nprotected-paths: my docs/*\n' >"$T/ws.fm"
R1="$T/r1"; mkdir -p "$R1/docs/agents"; ( cd "$R1" && git init -q -b main . && cp "$T/ws.fm" docs/agents/factory.md && git add -A && git commit -qm b )
printf 'Paths:\n- plugins/x/a.md\nshared: none\n' >"$T/plain.md"
( cd "$R1" && bash "$SK" protected --paths "my docs/page.md" "$T/plain.md" >/dev/null ); ck item1-skip-space-path-protected-by-glob 1 "$?"
( cd "$T" && bash "$SK" protected --paths "contracts/my notes.md" "$T/plain.md" >/dev/null ); ck item1-skip-space-path-in-contracts 1 "$?"
( cd "$T" && bash "$SK" protected --paths $'plugins/x/a.md\ncontracts/my notes.md' "$T/plain.md" >/dev/null ); ck item1-skip-newline-list 1 "$?"
( cd "$T" && bash "$SK" protected --paths $'plugins/x/my a.md\ndocs/b c.md' "$T/plain.md" >/dev/null ); ck item1-skip-space-paths-clean 0 "$?"
bash "$MG" check 7 --qa pass --security pass --paths "contracts/my notes.md" >/dev/null 2>&1; ck item1-gate-space-path-in-contracts 10 "$?"
bash "$MG" check 7 --qa pass --security pass --paths $'plugins/x/a.md\nsrc/my secrets/k.txt' >/dev/null 2>&1; ck item1-gate-newline-list 10 "$?"
( cd "$R1" && bash "$MG" check 7 --qa pass --security pass --paths "my docs/page.md" >/dev/null 2>&1 ); ck item1-gate-space-path-protected-by-glob 10 "$?"
bash "$MG" check 7 --qa pass --security pass --paths "plugins/x/a.md docs/b.md" >/dev/null 2>&1; ck item1-gate-legacy-one-line-list-clean 0 "$?"

# --- item 3: render checks Status and Summary first, scans second; scan lines go to stderr
hp="/Us""ers/bob/work"
printf 'Status: done\nSummary: ran in %s\n' "$hp" >"$T/hit.md"
printf 'Status: done\nAbnormality: none\nSomething: %s\n' "$hp" >"$T/hit-nosum.md"
printf 'Status: done\nSummary: fine\n' >"$T/fine.md"
bash "$PT" render "$T/hit-nosum.md" "$T/o1.md" >"$T/o1.out" 2>"$T/o1.err"; ck item3-malformed-with-hit-exit-3 3 "$?"
ck item3-malformed-with-hit-no-output-file "no" "$([ -e "$T/o1.md" ] && echo yes || echo no)"
bash "$PT" render "$T/hit.md" "$T/o2.md" >"$T/o2.out" 2>"$T/o2.err"; ck item3-valid-with-hit-exit-1 1 "$?"
ck item3-scan-line-on-stderr "scan: hit.md:2: home-path" "$(grep '^scan:' "$T/o2.err")"
ck item3-stdout-empty "" "$(cat "$T/o2.out")"
ck item3-valid-with-hit-no-output-file "no" "$([ -e "$T/o2.md" ] && echo yes || echo no)"
bash "$PT" render "$T/fine.md" "$T/o3.md" >/dev/null 2>&1; ck item3-clean-exit-0 0 "$?"

# --- item 4: the gemba commits fallback reads author time (%aI), with the same one-sentence reason as section 2
gm="$(grep -n 'commits fallback has the same shape\|\*\*Which commits:\*\*' "$HANSEI")"
ck item4-gemba-text-found 2 "$(printf '%s\n' "$gm" | grep -c .)"
printf '%s\n' "$gm" >"$T/gm.txt"
hasnt item4-gemba-no-committer-format "$T/gm.txt" '%cI'
hasnt item4-gemba-no-committer-time-window "$T/gm.txt" 'with committer time'
has item4-gemba-author-format "$T/gm.txt" "--format='%H %aI %s' item/<id>"
has item4-gemba-reason "$T/gm.txt" 'Read the author time, not the committer time: a rebase rewrites the committer time of every commit it replays, and the author time stays.'

# --- item 5: the kind 3 exemption of a role's own files does not cover a symlink
R5="$T/k5"; mkdir -p "$R5/docs/agents/skills/developer" "$R5/docs/agents/roles"
( cd "$R5" && git init -q -b main . && cp "$REPO/docs/agents/factory.md" docs/agents/factory.md && echo g >docs/guide.md && git add -A && git commit -qm base && git checkout -q -b item/7 )
( cd "$R5" && echo s >docs/agents/skills/developer/own.md && git add -A && git commit -qm "#7 developer: a regular skill file" )
( cd "$R5" && ln -s ../../../guide.md docs/agents/skills/developer/leak.md && git add -A && git commit -qm "#7 developer: a skill that is a symlink" )
( cd "$R5" && ln -s ../../guide.md docs/agents/roles/developer.md && git add -A && git commit -qm "#7 developer: a role file that is a symlink" )
out5="$(bash "$AD" kind3 --in "$R5" --table "$R5/docs/agents/factory.md" --base main | sed 's/^role-outside-role: [0-9a-f]* //')"
ck item5-symlinks-flagged-regular-file-exempt "developer changed docs/agents/roles/developer.md (owner docs-writer)
developer changed docs/agents/skills/developer/leak.md (owner docs-writer)" "$out5"

# --- item 6: two wildcard rows with the same text before `*` tie-break on total literal characters; an equal tie stays reported
printf '| Path | Owner | Why |\n|---|---|---|\n| `docs/*` | docs-writer | rest |\n| `docs/*.md` | architect | markdown |\n| `src/*.m*` | developer | a |\n| `src/*.*d` | qa-engineer | b |\n' >"$T/t6.md"
ck item6-longer-literal-wins "architect" "$(bash "$AD" owner "$T/t6.md" docs/a.md)"
ck item6-shorter-row-still-owns-the-rest "docs-writer" "$(bash "$AD" owner "$T/t6.md" docs/a.txt)"
ck item6-equal-tie-still-reported "ambiguous owner: src/x.md developer qa-engineer" "$(bash "$AD" owner "$T/t6.md" src/x.md)"

done_
