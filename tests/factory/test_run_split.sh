#!/bin/bash
# #207, the split of the run skill before slice 4: SKILL.md is a router, the rest lives in references/run-*.md.
# A no rule lost, B pointers resolve, D five scenarios read through, E size, plus the fence and steps 0 to 7 staying put.
# The pins in the other tests read the whole skill through run_all_file (lib.sh).
# shellcheck disable=SC1091
. "$(dirname "$0")/lib.sh"
FX="$REPO/tests/factory/fixtures/split"
OLD="$FX/run-skill-3.0.0.md"      # plugins/factory/skills/run/SKILL.md of origin/main at 19d1df3 (factory 3.0.0), before the split
ALLOW="$FX/allowed-missing.txt"   # old lines that may be missing from router and references (a line a pointer replaced); verbatim, one per line
ROUTER="$RUN_ROUTER"
refs="$(run_refs)"
nrefs="$(printf '%s\n' "$refs" | grep -c .)"
bytes() { wc -c <"$1" | tr -d ' '; }

# ---- A. no rule lost; nothing added except pointer lines, stub headings and the three header lines of a reference
ck a0-fixture-is-the-old-skill 115665 "$(bytes "$OLD")"
ck a0-references-exist yes "$([ "$nrefs" -ge 5 ] && echo yes || echo no)"
# shellcheck disable=SC2086
rep="$(awk -v allow="$ALLOW" -v nref="$nrefs" '
  BEGIN { while ((getline l < allow) > 0) if (l != "") { ok[l]++; nallow++ } }
  FNR == 1 { fi++ }
  fi == 1 { if ($0 != "") { c[$0]++; old[$0] = 1 } next }
  $0 == "" { next }
  fi <= 1 + nref { if (FNR <= 3) { hdr++; next }
                   if (c[$0] > 0) c[$0]--; else { added++; print "ADDED in " FILENAME ": " $0 }
                   next }
  { if (c[$0] > 0) { c[$0]--; next }
    if ($0 ~ /^#+ / && old[$0]) { stubs++; next }
    if ($0 ~ /references\/run-/) { ptr++; next }
    added++; print "ADDED in router: " $0 }
  END { for (l in c) if (c[l] > 0) { if (ok[l] > 0) allowed += c[l]; else { lost++; print "LOST: " l } }
        print "SUMMARY lost=" lost+0 " added=" added+0 " allowed=" allowed+0 " allowlist=" nallow+0 " stubs=" stubs+0 " pointers=" ptr+0 " headers=" hdr+0 }
' "$OLD" $refs "$ROUTER")"
printf '%s\n' "$rep" | grep -v '^SUMMARY' | head -20
sum="$(printf '%s\n' "$rep" | grep '^SUMMARY')"
echo "     $sum"
num() { printf '%s\n' "$sum" | sed -n "s/.*$1=\([0-9]*\).*/\1/p"; }
ck a1-no-old-line-lost 0 "$(num lost)"
ck a2-no-line-added-but-pointers-stubs-headers 0 "$(num added)"
ck a3-allow-list-is-explicit-and-small "yes" "$([ "$(num allowlist)" -le 10 ] && echo yes || echo no)"
ck a4-title-and-trigger-line-per-reference "$((nrefs * 2))" "$(num headers)"
# the two directions together: a pointer line is the only thing that may differ, and every reference starts with title, blank, trigger
for r in $refs; do
  ck "a5-$(basename "$r")-header-shape" "yes" "$(awk 'NR==1 && /^# /{a=1} NR==2 && $0==""{b=1} NR==3 && /^Read this when /{c=1} END{print (a&&b&&c) ? "yes" : "no"}' "$r")"
done

# ---- B. pointers resolve
named="$(grep -o 'references/run-[a-z0-9-]*\.md' "$ROUTER" | sort -u)"
for n in $named; do ck "b1-named-$(basename "$n")-exists" 1 "$([ -s "$PLUGIN/$n" ] && echo 1 || echo 0)"; done
ck b2-router-names-some-reference yes "$([ -n "$named" ] && echo yes || echo no)"
for r in $refs; do
  b="$(basename "$r")"
  # a trigger sentence: a line of the router that starts with a capital, says when, and then `: read` plus the file
  t="$(grep -cE "^[A-Z][^:]{20,}: read \`references/$b\`" "$ROUTER")"
  ck "b3-$b-has-a-trigger-sentence" yes "$([ "$t" -ge 1 ] && echo yes || echo no)"
  ck "b4-$b-names-no-other-reference" 0 "$(grep -c 'references/run-' "$r")"
done
ck b5-router-names-only-existing-run-files "$(printf '%s\n' "$named" | grep -c .)" "$(printf '%s\n' "$named" | while read -r n; do [ -s "$PLUGIN/$n" ] && echo y; done | grep -c .)"
ck b6-no-reference-names-the-router-as-a-pointer 0 "$(for r in $refs; do grep -l 'read `skills/run/SKILL.md`' "$r"; done | grep -c .)"

# ---- the references are read, not substituted: a reference that writes ${CLAUDE_PLUGIN_ROOT} in a command says so in its header (code review of #223)
for r in $refs; do
  if tail -n +4 "$r" | grep -qF '${CLAUDE_PLUGIN_ROOT}'; then
    ck "g1-$(basename "$r")-says-plugin-root-is-not-substituted" yes "$(sed -n 3p "$r" | grep -qF 'is not substituted' && sed -n 3p "$r" | grep -qF 'Plugin root:' && echo yes || echo no)"
  fi
done
ck g2-router-says-only-it-is-substituted 1 "$(grep -c 'Only this file has `${CLAUDE_PLUGIN_ROOT}` substituted' "$ROUTER")"

# ---- the router holds exactly the sections every item needs: a rule cannot move out of it (or into it) without this list changing (code review of #223)
heads="$(awk '/^```/{f=!f; next} !f && /^#+ /' "$ROUTER" | tr '\n' '|')"
want='# Factory lead|## 0. Resume or start|## The run cycle|## Maintenance cycle|## The integrator|## 1. Clarify the destination|## 2. Chart the route|## 3. Clear the frontier'"'"'s one-way doors|## 4. Cut the next slice|## 5. Start the item|## 6. Run the stages|### Optional code review|### Environment and shared resources|### Acceptance demo|### Two-way decisions|### Report at each stage boundary|## 7. Take a one-way door to the person|## 8. Close the item and resurvey|## 9. Close the run|## The board|### Needs you|## Role tasks|## Scan before posting|## Parallel slices|## Interruptions|## Idea intake|## Improvement loop|## Skill graduation|## Role knowledge|## Andon|### Detection|### Procedure|### The 5 Whys|### Overrides|### Run identity|### Run start|### Settle round|### The comment|## Context|'
ck h1-router-headings-are-the-pinned-list "$want" "$heads"
# a moved rule is in the references only: no long line of the router is also a line of a reference
dup="$(for r in $refs; do tail -n +4 "$r"; done | awk 'length($0) > 40' | sort -u | comm -12 - <(awk 'length($0) > 40' "$ROUTER" | sort -u) | wc -l | tr -d ' ')"
ck h2-no-rule-text-in-both-router-and-references 0 "$dup"

# ---- the fence and steps 0 to 7 stay in the router, word for word (F1 step 8.1, F2 step 7, F3 step 6)
sec() { awk -v n="$2" '/^```/ {fence=!fence; if (on) print; next} !fence && /^## / {if (on) exit; if (substr($0, 4) == n) on=1} on {print}' "$1"; }
for h in "0. Resume or start" "The run cycle" "The integrator" "1. Clarify the destination" "2. Chart the route" "3. Clear the frontier's one-way doors" "4. Cut the next slice" "5. Start the item" "6. Run the stages" "7. Take a one-way door to the person" "The board" "Role tasks" "Scan before posting" "Role knowledge" "Context"; do
  ck "f-section-unchanged-in-router: $h" "$(sec "$OLD" "$h" | cksum)" "$(sec "$ROUTER" "$h" | cksum)"
done
f81() { awk '/^1\. Once delivery and documentation are done/ {on=1} /^(2\. Complete the ledger|After the approval of 8\.1)/ {on=0} on' "$1"; }
ck f1-step-8-1-unchanged-in-router "$(f81 "$OLD" | cksum)" "$(f81 "$ROUTER" | cksum)"
ck f1-step-8-1-not-empty yes "$([ "$(f81 "$ROUTER" | grep -c .)" -ge 6 ] && echo yes || echo no)"
ck f1-production-sentence-in-router 1 "$(grep -c '^Production actions wait for the person.s explicit approval' "$ROUTER")"

# ---- D. five scenarios: which files the lead reads, each reached from the router by its trigger sentence alone
# ptr <phrase>: the run-*.md files named on router lines that contain the phrase (a trigger phrase of a pointer line)
ptr() { grep -F -- "$1" "$ROUTER" | grep -o 'references/run-[a-z0-9-]*\.md' | sort -u; }
# scn <name> <expected files, space separated> <phrase>...: each phrase must lead to at least one file; the union must equal the expected set
scn() {
  local name="$1" want="$2" p got="" miss=0 total sz
  shift 2
  for p in "$@"; do
    r="$(ptr "$p")"
    if [ -z "$r" ]; then miss=$((miss + 1)); echo "     no pointer for: $p"; fi
    got="$got $r"
  done
  got="$(printf '%s\n' $got | sed 's#references/##' | sort -u | tr '\n' ' ' | sed 's/ $//')"
  ck "d-$name-every-phrase-has-a-pointer" 0 "$miss"
  ck "d-$name-files" "$want" "$got"
  total="$(bytes "$ROUTER")"
  for p in $got; do total=$((total + $(bytes "$PLUGIN/references/$p"))); done
  echo "     d-$name reads SKILL.md + ${got:-nothing}: $total bytes"
}
scn start-a-run "run-andon-detect.md run-improve.md run-intake.md run-overrides.md" \
  "At every run start" "At run start, before intake" "At step 0 and at step 5" "reported at run start" "on the run-start answer" "at run start and item start"
scn spawn-a-role-task "run-andon-detect.md run-parallel.md" \
  "At each result" "the architect's result is read" "when you brief QA or security"
scn an-andon-is-raised "run-andon-detect.md run-andon.md run-overrides.md" \
  "When an abnormality is raised or detected" "When a detection hits" "When you write the chain of an andon" "When you post the andon comment" "When a countermeasure is an override" "At each result"
scn close-an-item "run-close-item.md run-parallel.md" \
  "After the approval of 8.1" "after each merge (the resurvey pause)"
scn close-the-run "run-close-run.md run-improve.md run-overrides.md" \
  "When the backlog is empty, the budget is reached" "At step 9.3" "before an A3 draft leaves the project"
# every reference is reached by at least one scenario phrase above, or by a pointer of its own section
for r in $refs; do ck "d-$(basename "$r")-reachable" yes "$([ "$(grep -c "references/$(basename "$r")" "$ROUTER")" -ge 1 ] && echo yes || echo no)"; done

# ---- E. size
rb="$(bytes "$ROUTER")"; tot="$rb"; for r in $refs; do tot=$((tot + $(bytes "$r"))); done
ck e1-router-at-most-70000 yes "$([ "$rb" -le 70000 ] && echo yes || echo no)"
item="$rb"; for f in run-close-item.md run-parallel.md run-andon-detect.md; do [ -f "$PLUGIN/references/$f" ] && item=$((item + $(bytes "$PLUGIN/references/$f"))); done
echo "     e router before $(bytes "$OLD"), after $rb; router plus references $tot; a typical item reads (router, run-close-item, run-parallel, run-andon-detect) $item"
ck e2-total-not-below-old-size yes "$([ "$tot" -ge "$(bytes "$OLD")" ] && echo yes || echo no)"
ck e3-typical-item-below-old yes "$([ "$item" -lt "$(bytes "$OLD")" ] && echo yes || echo no)"
done_
