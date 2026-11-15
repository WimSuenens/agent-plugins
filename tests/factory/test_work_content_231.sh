#!/bin/bash
# #231: the roles' deliverables are readable on the tracker while an item runs. Written before the scripts and the text it tests.
#  1. stage-publish.sh push: the item branch is pushed after a stage; a failed push is reported (exit 4), never fatal.
#  2. stage-publish.sh links/append: the files of a stage's commit as permalinks blob/<sha>/<path>, inserted in the result comment.
#  3. post-file.sh <ticket> <file>: scan, split above the comment limit, marker, replace on re-run (a stub gh; no network).
#  4. stage-report.sh --task <n>: one line per stage on the slice ticket, linking the role-task ticket.
#  5. the router points at references/run-publish.md; the scripts are lead-only; the protocol's work/ rules stay.
# Fixtures: tests/factory/fixtures/work231 (the closing comment of the product-owner task #226 of item #225, as posted).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
SP="$PLUGIN/scripts/stage-publish.sh"; PF="$PLUGIN/scripts/post-file.sh"; SR="$PLUGIN/scripts/stage-report.sh"; PT="$PLUGIN/scripts/post-text.sh"
FX="$REPO/tests/factory/fixtures/work231"; RUN="$PLUGIN/skills/run/SKILL.md"; REF="$PLUGIN/references/run-publish.md"; PROTO="$PLUGIN/references/protocol.md"
cd "$T" || exit 1

# ---------- 1 and 2: a repository with a stage commit ----------
mkdir -p origin.git && git init -q --bare origin.git
git init -q -b main item && cd item || exit 1
git commit -q --allow-empty -m base
git remote add origin "$T/origin.git"
git checkout -q -b item/225
mkdir -p work/225 contracts
printf '# Requirement\n' > work/225/01-requirement.md
printf 'Status: done\n' > work/225/01-result-product-owner.md
git add work && git commit -q -m '#225 product-owner: requirement'
S1="$(git rev-parse HEAD)"

bash "$SP" push >"$T/out" 2>"$T/err"; code=$?
ck push-first-exit 0 "$code"
ck push-first-sets-upstream "origin/item/225" "$(git rev-parse --abbrev-ref '@{u}' 2>/dev/null)"
ck push-first-remote-has-commit "$S1" "$(git -C "$T/origin.git" rev-parse item/225)"
printf 'more\n' >> work/225/01-requirement.md; git commit -q -am '#225 product-owner: fix'
S2="$(git rev-parse HEAD)"
bash "$SP" push >/dev/null 2>&1; ck push-second-exit 0 "$?"
ck push-second-remote-has-commit "$S2" "$(git -C "$T/origin.git" rev-parse item/225)"
mv "$T/origin.git" "$T/origin.gone"
git commit -q --allow-empty -m '#225 lead: x'
bash "$SP" push >"$T/out" 2>"$T/err"; code=$?
ck push-failure-exit-4 4 "$code"
ck push-failure-is-reported "1" "$(grep -c '^stage-publish: push failed' "$T/err")"
bash "$PT" scan "$T/err" >/dev/null 2>&1; ck push-failure-names-no-home-path 0 "$?"
mv "$T/origin.gone" "$T/origin.git"

# links: permalinks carry the stage's sha
git remote set-url origin 'https://github.com/example-org/example-repo.git'
bash "$SP" links --github example-org/example-repo "$S1" >"$T/links" 2>"$T/err"; code=$?
ck links-exit 0 "$code"
ck links-two-files 2 "$(grep -c '^- ' "$T/links")"
has links-requirement-permalink "$T/links" "[work/225/01-requirement.md](https://github.com/example-org/example-repo/blob/$S1/work/225/01-requirement.md)"
has links-result-permalink "$T/links" "https://github.com/example-org/example-repo/blob/$S1/work/225/01-result-product-owner.md"
ck links-every-url-has-the-full-sha 0 "$(grep '^- ' "$T/links" | grep -vc "/blob/$S1/")"
ck links-no-branch-name 0 "$(grep -c 'item/' "$T/links")"
# the repo comes from origin when --github is absent (https and ssh forms)
bash "$SP" links "$S1" 2>/dev/null | grep -q "github.com/example-org/example-repo/blob/$S1/"; ck links-repo-from-https-origin 0 "$?"
git remote set-url origin 'git@github.com:example-org/example-repo.git'
bash "$SP" links "$S1" 2>/dev/null | grep -q "github.com/example-org/example-repo/blob/$S1/"; ck links-repo-from-ssh-origin 0 "$?"
git remote set-url origin 'https://github.com/example-org/example-repo.git'
# a range lists the files of every commit of the stage, on the head's sha
printf '# Contract\n' > contracts/225-x.md; git add contracts; git commit -q -m '#225 architect: contract'
S3="$(git rev-parse HEAD)"
bash "$SP" links --github example-org/example-repo "$S1^..$S3" >"$T/links" 2>/dev/null
has links-range-includes-contract "$T/links" "/blob/$S3/contracts/225-x.md"
has links-range-includes-earlier-file "$T/links" "/blob/$S3/work/225/01-requirement.md"
bash "$SP" links --github bad "$S1" >/dev/null 2>&1; ck links-bad-repo-exit-2 2 "$?"
bash "$SP" links --github example-org/example-repo deadbeefdeadbeef >/dev/null 2>&1; ck links-unknown-rev-exit-2 2 "$?"
# the permalink still resolves after work/ is removed and the branch is deleted: the commit stays reachable by its sha
git rm -q -r work && git commit -q -m '#225 lead: remove work'
git checkout -q main && git branch -q -D item/225
git cat-file -e "$S1:work/225/01-requirement.md" 2>/dev/null; ck permalink-blob-still-resolves-by-sha 0 "$?"
ck permalink-path-is-the-tree-of-the-sha "# Requirement" "$(git show "$S1:work/225/01-requirement.md" | head -1)"
git checkout -q -b item/225 "$S3"

# append: the block goes into the result comment's visible head, before <details>, once
cp "$FX/result-226.md" "$T/res.md"
bash "$SP" append --github example-org/example-repo "$T/res.md" "$S1" >/dev/null 2>"$T/err"; code=$?
ck append-exit 0 "$code"
ck append-keeps-line-1-marker "<!-- factory:result v1 -->" "$(head -1 "$T/res.md")"
has append-has-permalink "$T/res.md" "/blob/$S1/work/225/01-requirement.md"
ck append-before-details "1" "$(awk '/blob\//{b=NR} /^<details>/{d=NR} END{print (b>0 && b<d) ? 1 : 0}' "$T/res.md")"
ck append-keeps-details-byte-for-byte "$(sed -n '/^<details>/,$p' "$FX/result-226.md" | cksum)" "$(sed -n '/^<details>/,$p' "$T/res.md" | cksum)"
bash "$SP" append --github example-org/example-repo "$T/res.md" "$S1" >/dev/null 2>&1
ck append-twice-one-block "1" "$(grep -c '^Files of this stage' "$T/res.md")"
bash "$PT" scan "$T/res.md" >/dev/null 2>&1; ck append-result-scans-clean 0 "$?"
# a long result still splits with the block in part 1
{ sed '/^<\/details>/,$d' "$T/res.md"; awk 'BEGIN{for(i=0;i<1500;i++) printf "line %d of a long details body, long enough to need a split of the closing comment\n", i}'; printf '\n</details>\n'; } > "$T/long.md"
n="$(bash "$PT" split "$T/long.md" "$T/parts" 2>/dev/null)"
ck split-after-append-two-or-more-parts 1 "$([ "$n" -ge 2 ] && echo 1 || echo 0)"
has split-after-append-part-1-has-block "$T/parts/part-1.md" "/blob/$S1/work/225/01-requirement.md"
cd "$T" || exit 1

# ---------- 3: post-file.sh on a stub gh ----------
mkdir -p bin store
cat > bin/gh <<'GH'
#!/bin/bash
# stub gh: comments of ticket N live in $GH_STORE/N/<id>.md with the author in <id>.user; calls are logged
st="${GH_STORE:?}"; all="$*"; echo "$all" >> "$st/log"
case "$1 $2" in
  "api user") echo bot ;;
  "issue comment")
    n="$3"; mkdir -p "$st/$n"; id=$(( $(cat "$st/next" 2>/dev/null || echo 100) + 1 )); echo "$id" > "$st/next"
    f=""; p=""; for a in "$@"; do [ "$p" = "--body-file" ] && f="$a"; p="$a"; done
    cp "$f" "$st/$n/$id.md"; echo bot > "$st/$n/$id.user"
    echo "https://github.com/example-org/example-repo/issues/$n#issuecomment-$id" ;;
  "api "*)
    case "$all" in
      *"--method PATCH"*) id="${all##*issues/comments/}"; id="${id%% *}"; f="${all##*body=@}"; f="${f%% *}"
        d="$(dirname "$(ls "$st"/*/"$id.md")")"; cp "$f" "$d/$id.md" ;;
      *"--method DELETE"*) id="${all##*issues/comments/}"; id="${id%% *}"
        rm -f "${st:?}"/*/"${id:?}.md" "${st:?}"/*/"${id:?}.user" ;;
      *"issues/"*"/comments"*) n="${all##*issues/}"; n="${n%%/*}"; printf '['; sep=""
        for f in $(ls "$st/$n"/*.md 2>/dev/null | sort); do id="$(basename "$f" .md)"
          printf '%s{"id":%s,"user":{"login":"%s"},"body":%s}' "$sep" "$id" "$(cat "${f%.md}.user")" "$(jq -Rs . < "$f")"; sep=","; done
        printf ']\n' ;;
    esac ;;
esac
exit 0
GH
chmod +x bin/gh
export GH_STORE="$T/store" PATH="$T/bin:$PATH"
cnt() { ls "$GH_STORE/$1"/*.md 2>/dev/null | wc -l | tr -d ' '; }
printf '# Requirement 225\n\nThe Reference page becomes an overview.\n' > 01-requirement.md
bash "$PF" 226 01-requirement.md >"$T/out" 2>"$T/err"; code=$?
ck pf-small-exit 0 "$code"
ck pf-small-one-comment 1 "$(cnt 226)"
c1="$(ls "$GH_STORE"/226/*.md | head -1)"
ck pf-marker-line-1 "<!-- factory:artifact v1 -->" "$(head -1 "$c1")"
ck pf-file-name-line-2 "<!-- file: 01-requirement.md part 1/1 -->" "$(sed -n 2p "$c1")"
has pf-body-posted "$c1" "The Reference page becomes an overview."
# re-run: replaced, not copied
printf '# Requirement 225\n\nChanged text.\n' > 01-requirement.md
bash "$PF" 226 01-requirement.md >/dev/null 2>&1; ck pf-rerun-exit 0 "$?"
ck pf-rerun-still-one-comment 1 "$(cnt 226)"
has pf-rerun-has-new-text "$c1" "Changed text."
hasnt pf-rerun-old-text-gone "$c1" "becomes an overview"
bash "$PF" 226 01-requirement.md >/dev/null 2>&1
ck pf-rerun-unchanged-still-one 1 "$(cnt 226)"
# a second file on the same ticket is its own comment; the first one is left alone
printf 'Status: pass\n' > 02-result-qa-engineer.md
bash "$PF" 226 02-result-qa-engineer.md >/dev/null 2>&1
ck pf-two-files-two-comments 2 "$(cnt 226)"
has pf-first-file-untouched "$c1" "Changed text."
# the same file on another ticket
bash "$PF" 227 01-requirement.md >/dev/null 2>&1; ck pf-other-ticket-own-comment 1 "$(cnt 227)"
# a comment of someone else with the marker is never replaced
mkdir -p "$GH_STORE/228"; printf '<!-- factory:artifact v1 -->\n<!-- file: 01-requirement.md part 1/1 -->\nforeign\n' > "$GH_STORE/228/900.md"; echo other > "$GH_STORE/228/900.user"
bash "$PF" 228 01-requirement.md >/dev/null 2>&1
ck pf-foreign-comment-kept "foreign" "$(sed -n 3p "$GH_STORE/228/900.md")"
ck pf-own-comment-added-beside-foreign 2 "$(cnt 228)"
# 70,000 characters: two comments, each under the 65,536 limit, nothing lost
awk 'BEGIN{for(i=1;i<=1000;i++) printf "Criterion %04d: the page lists the agents with name, description and model, and it is derived.\n", i}' > big.md
ck pf-big-fixture-size-over-70000 1 "$([ "$(wc -c < big.md)" -ge 70000 ] && echo 1 || echo 0)"
bash "$PF" 229 big.md >/dev/null 2>"$T/err"; code=$?
ck pf-big-exit 0 "$code"
ck pf-big-two-comments 2 "$(cnt 229)"
ck pf-big-each-under-limit 0 "$(for f in "$GH_STORE"/229/*.md; do [ "$(wc -m < "$f")" -le 65536 ] || echo big; done | wc -l | tr -d ' ')"
ck pf-big-part-names "<!-- file: big.md part 1/2 --> <!-- file: big.md part 2/2 -->" "$(for f in $(ls "$GH_STORE"/229/*.md | sort); do sed -n 2p "$f"; done | paste -sd' ' -)"
ck pf-big-every-line-posted 1000 "$(cat "$GH_STORE"/229/*.md | grep -c '^Criterion ')"
ck pf-big-marker-on-both "2" "$(grep -l '^<!-- factory:artifact v1 -->$' "$GH_STORE"/229/*.md | wc -l | tr -d ' ')"
# re-run of the big file replaces both; a shrink to one part deletes the surplus comment
bash "$PF" 229 big.md >/dev/null 2>&1; ck pf-big-rerun-still-two 2 "$(cnt 229)"
head -20 big.md > small2.md; cp small2.md big.md
bash "$PF" 229 big.md >/dev/null 2>&1; ck pf-shrink-to-one-comment 1 "$(cnt 229)"
ck pf-shrink-part-name "<!-- file: big.md part 1/1 -->" "$(sed -n 2p "$(ls "$GH_STORE"/229/*.md | head -1)")"
# a code fence open at a cut is closed and reopened
{ echo '```'; awk 'BEGIN{for(i=1;i<=1000;i++) printf "code line %04d with enough text to fill the part up quickly, more more more\n", i}'; echo '```'; } > fence.md
bash "$PF" 230 fence.md >/dev/null 2>&1
ck pf-fence-balanced-in-each-part 0 "$(for f in "$GH_STORE"/230/*.md; do [ $(( $(grep -c '^```' "$f") % 2 )) = 0 ] || echo odd; done | wc -l | tr -d ' ')"
# a part is never longer than the limit even for one huge line
awk 'BEGIN{for(i=0;i<70000;i++) printf "x"; printf "\n"}' > line.md
bash "$PF" 231 line.md >/dev/null 2>&1
ck pf-huge-line-cut-under-limit 0 "$(for f in "$GH_STORE"/231/*.md; do [ "$(wc -m < "$f")" -le 65536 ] || echo big; done | wc -l | tr -d ' ')"
# the scan: a home path and a secret are refused, nothing is posted
printf 'See /%s/%s/project for the notes.\n' Users someone > homepath.md
before="$(wc -l < "$GH_STORE/log" | tr -d ' ')"
bash "$PF" 232 homepath.md >"$T/out" 2>"$T/err"; code=$?
ck pf-home-path-refused-exit-1 1 "$code"
ck pf-home-path-nothing-posted 0 "$(cnt 232)"
ck pf-home-path-no-tracker-call "$before" "$(wc -l < "$GH_STORE/log" | tr -d ' ')"
has pf-home-path-scan-line "$T/err" "homepath.md:1: home-path"
hasnt pf-scan-never-prints-the-text "$T/err" "someone"
printf 'token %s_%s\n' ghp aaaaaaaaaaaaaaaaaaaaaaaaaaaa > secret.md
bash "$PF" 232 secret.md >/dev/null 2>"$T/err"; ck pf-secret-refused-exit-1 1 "$?"
ck pf-secret-nothing-posted 0 "$(cnt 232)"
# a re-run whose file now has a hit leaves the earlier comments as they were
cp 01-requirement.md keep.md; bash "$PF" 233 keep.md >/dev/null 2>&1
printf 'now /%s/%s/x\n' Users someone > keep.md; bash "$PF" 233 keep.md >/dev/null 2>&1
ck pf-rerun-with-hit-keeps-earlier 1 "$(cat "$GH_STORE"/233/*.md | grep -c 'Changed text')"
# usage
bash "$PF" >/dev/null 2>&1; ck pf-no-args-exit-2 2 "$?"
bash "$PF" abc 01-requirement.md >/dev/null 2>&1; ck pf-bad-ticket-exit-2 2 "$?"
bash "$PF" 226 missing.md >/dev/null 2>&1; ck pf-missing-file-exit-2 2 "$?"
# a failing tracker call is reported and exits 3
mkdir -p bin2
cat > bin2/gh <<'GH'
#!/bin/bash
case "$1 $2" in "api user") echo bot ;; "api repos"*) echo '[]' ;; *) echo "boom" >&2; exit 1 ;; esac
GH
chmod +x bin2/gh
PATH="$T/bin2:$PATH" bash "$PF" 234 01-requirement.md >/dev/null 2>"$T/err"; ck pf-tracker-failure-exit-3 3 "$?"
has pf-tracker-failure-says-so "$T/err" "post-file: posting part 1 failed"
cd "$T" || exit 1

# ---------- 4: the stage line on the slice ticket ----------
bash "$SR" --run-body run-body-missing.md --task abc >/dev/null 2>&1; ck sr-task-not-a-number-exit-2 2 "$?"
has sr-usage-names-task "$SR" "--task"
has sr-prints-role-task-line "$SR" "role task: "

# ---------- 5: router, reference, lead-only, rules that stay ----------
ck router-at-most-70000-bytes 1 "$([ "$(wc -c < "$RUN")" -le 70000 ] && echo 1 || echo 0)"
has router-points-at-reference "$RUN" 'references/run-publish.md'
has router-names-push-script "$RUN" 'stage-publish.sh'
has router-names-post-file "$RUN" 'post-file.sh'
ck reference-exists 1 "$([ -f "$REF" ] && echo 1 || echo 0)"
for w in 'post-file.sh' 'stage-publish.sh' 'blob/<sha>/<path>' 'factory:artifact v1' '65,536' 'push failed' 'earlier than today' 'never widen'; do
  has "reference-says-$w" "$REF" "$w"
done
for k in 'requirement' 'contracts' 'QA verdict' 'security verdict'; do has "reference-inline-list-$k" "$REF" "$k"; done
ck reference-names-no-repo-of-this-project 0 "$(grep -ci 'WimSuenens\|agent-plugins' "$REF" 2>/dev/null)"
bash "$PT" scan "$REF" >/dev/null 2>&1; ck reference-no-home-path 0 "$?"
# lead-only: no role file, and nothing the roles read, tells a role to run them
for f in "$PLUGIN"/agents/*.md "$PROTO"; do
  n="$(basename "$f" .md)"
  ck "leadonly-$n-no-post-file" 0 "$(grep -c 'post-file.sh\|stage-publish.sh' "$f")"
done
has reference-says-lead-only "$REF" 'Only the lead runs these scripts'
# the protocol's rules about work/ paths stay as they were
has proto-work-rule-adr "$PROTO" 'An ADR, requirement, or doc that lands on main never cites a path under `work/`, because `work/` is removed before the merge.'
has proto-work-rule-cards "$PROTO" 'neither names a path under `work/` or a branch (`item/<n>`, `frontier/<n>`)'
has proto-work-rule-briefs "$PROTO" "a brief's \`Output\` line names the draft result file, and a result may name the files it wrote."
done_
