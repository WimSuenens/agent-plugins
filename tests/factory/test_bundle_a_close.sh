#!/bin/bash
# Bundle A item 4 (#243): the requirement survives the close. close-item.sh refuses while an artifact a result names outside the item folder is missing there.
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
CI="$PLUGIN/scripts/close-item.sh"
cd "$T" || exit 1
mk() { # <name>: a main checkout with an item worktree on item/5 holding work/5/
  rm -rf "$1" "$1-wt"; mkdir "$1" && cd "$1" && git init -q -b main . && git config commit.gpgsign false
  echo base >README.md; git add -A; git commit -q -m base
  git worktree add -q -b item/5 "../$1-wt" >/dev/null 2>&1
  mkdir -p "../$1-wt/work/5"
  cd ..
}
res() { # <name> <artifacts line>
  printf 'Status: done\nAbnormality: none\nSummary: s\nArtifacts: %s\n' "$2" >"$1-wt/work/5/01-result-product-owner.md"
}
run() { (cd "$1" && bash "$CI" 5 2>&1); }

# requirement filed at its home: passes and the folder goes
mk a; res a "docs/requirements/5-x.md"; mkdir -p a-wt/docs/requirements; echo r >a-wt/docs/requirements/5-x.md
git -C a-wt add -A; git -C a-wt commit -q -m "#5 product-owner: requirement"
out="$(run a)"; ck home-present-rc 0 "$?"; ck home-present-removed "no" "$([ -e a-wt/work/5 ] && echo yes || echo no)"
# the listing is printed before the removal
printf '%s' "$out" | grep -q 'work/5/01-result-product-owner.md'; ck lists-folder-files 0 "$?"

# requirement only in the folder: refused with the file name, nothing removed
mk b; res b "docs/requirements/5-x.md"; echo r >b-wt/work/5/5-x.md
out="$(run b)"; rc=$?; ck only-in-folder-refused 1 "$rc"
printf '%s' "$out" | grep -q 'docs/requirements/5-x.md'; ck refusal-names-file 0 "$?"
ck only-in-folder-kept "yes" "$([ -e b-wt/work/5/01-result-product-owner.md ] && echo yes || echo no)"
ck only-in-folder-no-remove-commit "0" "$(git -C b-wt log --format=%s | grep -c 'remove work/')"

# no artifacts named: passes
mk c; res c "none"
run c >/dev/null; ck none-named-passes 0 "$?"
mk d; res d "work/5/notes.md, reviews/qa-5.md"; mkdir -p d-wt/reviews; echo q >d-wt/reviews/qa-5.md; echo n >d-wt/work/5/notes.md
git -C d-wt add reviews; git -C d-wt commit -q -m "#5 qa-engineer: review"
run d >/dev/null; ck inside-folder-and-present-passes 0 "$?"
# a file at the destination that is not committed is not filed: it goes with the worktree
mk e; res e "docs/requirements/5-y.md"; mkdir -p e-wt/docs/requirements; echo r >e-wt/docs/requirements/5-y.md
run e >/dev/null; ck present-untracked-refused 1 "$?"
# absolute or parent-escaping destinations are refused as malformed, not followed
mk f; res f "../outside.md"; run f >/dev/null; ck parent-escape-refused 1 "$?"
# a glob in the Artifacts line is skipped, not expanded; a traversal after work/ is refused
mk g; res g "docs/*.md"; mkdir -p g/docs; echo x >g/docs/zz.md; run g >/dev/null; ck glob-not-expanded 0 "$?"
mk h; res h "work/5/../../docs/requirements/9-x.md"; run h >/dev/null; ck work-traversal-refused 1 "$?"
# the product owner text names the requirement's home and commit from the start
has po-output-home "$PLUGIN/agents/product-owner.md" 'committed there from the start'
has close-text-names-check "$PLUGIN/references/run-close-item.md" 'refuses while an artifact'
done_
