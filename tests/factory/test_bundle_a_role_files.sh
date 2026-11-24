#!/bin/bash
# Bundle A item 1 (#250): a role's OWN knowledge files are allowed by the changed-paths check and ignored by the overlap check; nothing else is.
# Synthetic repositories only.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
PATHSH="$PLUGIN/scripts/paths.sh"; RF="$PLUGIN/scripts/role-files.sh"
PROTO="$PLUGIN/references/protocol.md"
cd "$T" || exit 1
mkdir ct r && cd r && git init -q -b main . && git config commit.gpgsign false
mkdir -p docs/agents/roles docs/agents/skills/qa-engineer src
echo base >src/a.txt; git add -A; git commit -q -m base; base="$(git rev-parse HEAD)"
cat >../ct/c.md <<'C'
Paths:
- src/a.txt
shared: none
C
chk() { git -c core.quotePath=false diff --no-renames --name-only "$base" HEAD | bash "$PATHSH" check --own-role-files --base "$base" --head HEAD ../ct/c.md; }

# 1 own role file and own skills file: allowed
echo l >docs/agents/roles/qa-engineer.md; echo s >docs/agents/skills/qa-engineer/x.md; echo c >>src/a.txt
git add -A; git commit -q -m "#9 qa-engineer: lessons"
out="$(chk)"; ck own-files-allowed-rc 0 "$?"; ck own-files-allowed-out "" "$out"
# without the flag the old behaviour stays (the files are off-list)
out="$(git diff --no-renames --name-only "$base" HEAD | bash "$PATHSH" check ../ct/c.md)"; ck without-flag-still-flags-rc "off-list: docs/agents/roles/qa-engineer.md
off-list: docs/agents/skills/qa-engineer/x.md" "$out"

# 2 another role's file is flagged
echo l >docs/agents/roles/developer.md; git add -A; git commit -q -m "#9 qa-engineer: touches the developer's file"
out="$(chk)"; ck other-role-file-rc 1 "$?"; ck other-role-file-out "off-list: docs/agents/roles/developer.md" "$out"

# 3 own file touched by another role's commit is flagged
git reset -q --hard HEAD~1
echo more >>docs/agents/roles/qa-engineer.md; git add -A; git commit -q -m "#9 developer: edits the QA file"
out="$(chk)"; ck own-file-by-other-role-rc 1 "$?"; ck own-file-by-other-role-out "off-list: docs/agents/roles/qa-engineer.md" "$out"
git reset -q --hard HEAD~1

# 4 a symlink there never counts
ln -s ../../../src/a.txt docs/agents/skills/qa-engineer/link; git add -A; git commit -q -m "#9 qa-engineer: a link"
out="$(chk)"; ck symlink-rc 1 "$?"; ck symlink-out "off-list: docs/agents/skills/qa-engineer/link" "$out"
git reset -q --hard HEAD~1

# 5 a mixed commit flags only the off-list file
echo x >src/b.txt; echo m >>docs/agents/roles/qa-engineer.md; git add -A; git commit -q -m "#9 qa-engineer: mixed"
out="$(chk)"; ck mixed-rc 1 "$?"; ck mixed-only-offlist "off-list: src/b.txt" "$out"
git reset -q --hard HEAD~1

# 6 a commit with no role in its subject earns no exemption
echo m >>docs/agents/roles/qa-engineer.md; git add -A; git commit -q -m "lead: note"
out="$(chk)"; ck no-role-subject-rc 1 "$?"
git reset -q --hard HEAD~1

# the helper names the same set
echo l >docs/agents/roles/qa-engineer.md; echo z >docs/agents/roles/developer.md; git add -A; git commit -q -m "#9 qa-engineer: two"
ck helper-allowed "docs/agents/roles/qa-engineer.md
docs/agents/skills/qa-engineer/x.md" "$(bash "$RF" allowed --in . --base "$base" --head HEAD)"
git reset -q --hard HEAD~1

# overlap: two slices both naming role files do not overlap; a real shared path still does
cat >../ct/o1.md <<'C'
Paths:
- docs/agents/roles/qa-engineer.md
- src/one/
shared: none
C
cat >../ct/o2.md <<'C'
Paths:
- docs/agents/roles/qa-engineer.md
- docs/agents/skills/qa-engineer/
- src/two/
shared: none
C
cat >../ct/o3.md <<'C'
Paths:
- src/one/x.txt
shared: none
C
ck overlap-role-files-ignored "overlap: no" "$(bash "$PATHSH" overlap ../ct/o1.md -- ../ct/o2.md)"
bash "$PATHSH" overlap ../ct/o1.md -- ../ct/o3.md >/dev/null; ck overlap-real-path-still-1 1 "$?"
cat >../ct/o4.md <<'C'
Paths:
- docs/agents/roles/other.md
shared: none
C
bash "$PATHSH" overlap ../ct/o4.md -- ../ct/o4.md >/dev/null; ck overlap-unknown-role-file-still-overlaps 1 "$?"

# the existing andon kind-3 behaviour reads the same definition
grep -q 'role-files.sh' "$PLUGIN/scripts/andon-detect.sh"; ck andon-uses-shared-definition 0 "$?"

# text: the rule once in the protocol, named in the QA and security Done lines
has protocol-rule "$PROTO" 'changed-paths check and the overlap check allow a role'"'"'s own role file and skills folder'
has protocol-security-not-reviewed "$PROTO" 'security does not review role-knowledge content'
has qa-done-flag "$PLUGIN/agents/qa-engineer.md" 'paths.sh" check --own-role-files'
has sec-done-flag "$PLUGIN/agents/security-reviewer.md" 'paths.sh" check --own-role-files'
done_
