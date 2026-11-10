#!/usr/bin/env python3
"""Replay of the written rules of slice 94, from the contracts' text (not from the plugin): the percent rule and the per-stage minute rule
(contract 94-hansei-lean sections 3 and 4), the waste count (94-a3-v2 section 3.1) and the target comparison (94-a3-v2 section 3.2).
Usage: lean_replay.py pct <w> <t> | stages <case.json> | waste <case dir> | target <direction> <target> <after> [change]
Expected values live in the tests, written from the contracts' worked examples before the build."""
import sys, os, re, json, glob

TIMWOODS = ["transport", "inventory", "motion", "waiting", "overproduction", "over-processing", "defects", "skills"]

def pct(w, t):
    if t == 0:
        return "not captured (total is 0m)"
    return "%d%%" % ((200 * w + t) // (2 * t))

def hm(s):
    h, m = s.split(":")
    return int(h) * 60 + int(m)

def stages(c):
    s, e = hm(c["started"]), hm(c["approved"])
    rows = [(r[0], hm(r[1]), hm(r[2])) for r in c["rows"]]
    W = set()
    for a, b in c["waits"]:
        for m in range(hm(a), hm(b)):
            if s <= m < e:
                W.add(m)
    order, work, wait = [], {}, {}
    def name(st):
        return re.sub(r" \(round [0-9]+\)$", "", st)
    for st, a, b in rows:
        n = name(st)
        if n not in order:
            order.append(n)
            work[n] = wait[n] = 0
    merge = "Merge approval"
    work[merge] = wait[merge] = 0
    for m in range(s, e):
        owner = None
        for st, a, b in rows:
            if a <= m < b:
                owner = name(st); break
        if owner is None:
            later = [(a, i) for i, (st, a, b) in enumerate(rows) if a > m]
            owner = name(rows[min(later)[1]][0]) if later else merge
        (wait if m in W else work)[owner] += 1
    parts = ["%s %dm / %dm" % (n, work[n], wait[n]) for n in order]
    if work[merge] + wait[merge] > 0:
        parts.append("%s %dm / %dm" % (merge, work[merge], wait[merge]))
    tw = sum(work.values()); tl = sum(wait.values())
    return "; ".join(parts), tw, tl

def cells(line):
    return [x.strip() for x in line.strip().strip("|").split("|")]

TOKEN = re.compile(r"waste: ([a-z-]+)(?=[ ,;]|$)")

def waste(d):
    out, skipped = [], []
    ledger = os.path.join(d, "ledger.md")
    counts = dict((t, 0) for t in TIMWOODS)
    untagged = 0
    def take(word, where):
        if word in counts:
            counts[word] += 1
        else:
            skipped.append("skipped: %s (waste tag not in its grammar)" % where)
    andons = sorted(glob.glob(os.path.join(d, "andon-*.md")))
    for f in andons:
        lines = open(f).read().split("\n")
        while lines and lines[-1] == "":
            lines.pop()
        last = lines[-1] if lines else ""
        mm = re.match(r"^- waste: (.*)$", last)
        if mm and mm.group(1).strip() not in ("-", ""):
            take(mm.group(1).strip(), os.path.basename(f))
        else:
            untagged += 1
    have_ledger = os.path.exists(ledger)
    n_entries = len(andons)
    if have_ledger:
        sect = None
        for l in open(ledger).read().split("\n"):
            if l.startswith("### "):
                sect = l[4:].strip(); continue
            if not l.startswith("|") or set(l.replace("|", "").strip()) <= set("- "):
                continue
            c = cells(l)
            if sect == "Waits" and c[0] != "Id":
                kind, what = c[1], c[6] if len(c) > 6 else ""
                if kind == "andon":
                    continue
                n_entries += 1
                toks = TOKEN.findall(what)
                if toks:
                    for t in toks[:1]:
                        take(t, c[0])
                else:
                    untagged += 1
            if sect == "Tasks" and c[0] != "#":
                for t in TOKEN.findall(c[8] if len(c) > 8 else ""):
                    n_entries += 1
                    take(t, "Tasks row " + c[0])
    if not have_ledger:
        out.append("not captured (no ledger comment readable)")
    else:
        parts = sorted([(-counts[t], TIMWOODS.index(t), t) for t in TIMWOODS if counts[t] > 0])
        if parts:
            out.append(", ".join("%s %d" % (t, -n) for n, i, t in parts) + "; untagged " + (str(untagged) if untagged else "none"))
        elif n_entries == 0 and not skipped:
            out.append("none (no andon or wait in the run's items)")
        else:
            out.append("none (no tagged entry)")
    return out + skipped

def target(direction, tgt, after, change=""):
    if after.startswith("not captured") or after.startswith("n/a"):
        return "none (after reading not captured)"
    if change.startswith("not comparable"):
        return "none (readings not comparable)"
    if change.startswith("not captured"):
        return "none (after reading not captured)"
    a, t = float(after), float(tgt)
    ok = a <= t if direction == "down" else a >= t
    return "%s — %s" % (tgt, "reached" if ok else "not reached")

if __name__ == "__main__":
    c = sys.argv[1]
    if c == "pct":
        print(pct(int(sys.argv[2]), int(sys.argv[3])))
    elif c == "stages":
        line, w, l = stages(json.load(open(sys.argv[2])))
        print(line); print("working %d waiting %d" % (w, l))
    elif c == "waste":
        print("\n".join(waste(sys.argv[2])))
    elif c == "target":
        print(target(*sys.argv[2:]))
