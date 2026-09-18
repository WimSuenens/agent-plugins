"""Measure a page raster. Every subcommand prints JSON on stdout.

    probe.py palette page.png [--n 10]
    probe.py blocks  page.png [--min-side 40]
    probe.py box     page.png --window 69,266,290,605 [--color 0B2240|--content|--ink]
    probe.py lines   page.png --window 74,380,286,580 [--color FFFFFF]
    probe.py cols    page.png --window 60,260,1480,620
    probe.py sample  page.png --at 150,300 --at 400,300
    probe.py edges   page.png --expect 69,266,290,605 --color 0B2240

Two habits keep these numbers honest, and both are easy to get wrong:

* Keep a window strictly inside the thing you are measuring. A window that
  overhangs a card by even 5 px picks up the page background, and a "white text"
  probe then returns the whole window.
* Prefer `edges` over `box` once you know roughly where something is. It looks
  for each edge only near where you expect it, so a neighbouring card of the
  same colour cannot be swallowed into the result.
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter

import numpy as np

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from common import hexstr, is_background, load_rgb, near, runs, tight_box, unhex  # noqa: E402


# --- argument parsing ------------------------------------------------------

def ints(value) -> list[int]:
    """Parse "x0,y0,x1,y1".

    Accepts spaces as well as commas: PowerShell splits an unquoted comma list
    into separate argv entries, so the value can arrive already re-joined.
    """
    if isinstance(value, (list, tuple)):
        value = " ".join(str(v) for v in value)
    return [int(float(v)) for v in str(value).replace(",", " ").split()]


# --- predicates --------------------------------------------------------------

def predicate(args, a: np.ndarray):
    """Build a pixel mask from the --color / --content / --ink options."""
    if getattr(args, "color", None):
        return near(a, args.color, args.tol)
    if getattr(args, "ink", False):        # any non-background, saturated or dark
        return (~is_background(a)) & ((a.max(axis=-1) - a.min(axis=-1) > 20)
                                      | (a.min(axis=-1) < 200))
    return ~is_background(a)               # --content, the default


def window_of(args, a: np.ndarray):
    if getattr(args, "window", None):
        return tuple(ints(args.window))
    return (0, 0, a.shape[1], a.shape[0])


# --- connected components (run-length, two pass) ------------------------------

def components(mask: np.ndarray, min_side: int):
    """Label True regions and return their boxes, largest first."""
    h, w = mask.shape
    parent: dict[int, int] = {}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(x, y):
        rx, ry = find(x), find(y)
        if rx != ry:
            parent[max(rx, ry)] = min(rx, ry)

    prev: list[tuple[int, int, int]] = []
    rows: list[list[tuple[int, int, int]]] = []
    label = 0
    for y in range(h):
        cur = []
        for s, e in runs(mask[y]):
            label += 1
            parent[label] = label
            for ps, pe, plabel in prev:
                if s <= pe and ps <= e:
                    union(label, plabel)
            cur.append((s, e, label))
        rows.append(cur)
        prev = cur

    boxes: dict[int, list[int]] = {}
    for y, cur in enumerate(rows):
        for s, e, lab in cur:
            root = find(lab)
            b = boxes.get(root)
            if b is None:
                boxes[root] = [s, y, e, y, e - s + 1]
            else:
                b[0], b[1] = min(b[0], s), min(b[1], y)
                b[2], b[3] = max(b[2], e), max(b[3], y)
                b[4] += e - s + 1
    out = [dict(box=[b[0], b[1], b[2], b[3]], pixels=b[4]) for b in boxes.values()
           if b[2] - b[0] >= min_side and b[3] - b[1] >= min_side]
    return sorted(out, key=lambda d: -d["pixels"])


def corner_radius(mask: np.ndarray, box) -> int:
    """Rough corner radius: how far in the fill starts on the block's top row."""
    x0, y0, x1, y1 = box
    row = mask[y0 + 1, x0:x1 + 1]
    idx = np.nonzero(row)[0]
    return int(idx.min()) if len(idx) else 0


# --- subcommands -------------------------------------------------------------

def cmd_palette(args):
    a = load_rgb(args.page)
    x0, y0, x1, y1 = window_of(args, a)
    sub = a[y0:y1, x0:x1].reshape(-1, 3)
    quant = (sub // 8 * 8)
    total = len(quant)
    counts = Counter(map(tuple, quant))
    out = []
    for colour, n in counts.most_common(max(args.n * 12, 60)):
        if any(abs(np.array(colour) - np.array(unhex(o["hex"]))).max() < 24 for o in out):
            continue
        members = sub[(np.abs(quant - np.array(colour)).max(axis=1) < 24)]
        out.append({"hex": hexstr(members.mean(axis=0)), "share": round(n / total, 4)})
        if len(out) >= args.n:
            break
    return out


def cmd_blocks(args):
    a = load_rgb(args.page)
    bg = is_background(a)
    found = []
    for entry in cmd_palette(argparse.Namespace(page=args.page, n=8, window=args.window)):
        colour = entry["hex"]
        mask = near(a, colour, args.tol) & ~bg
        if mask.sum() < args.min_side ** 2:
            continue
        for comp in components(mask, args.min_side)[:6]:
            comp["fill"] = colour
            comp["radius_px"] = corner_radius(mask, comp["box"])
            b = comp["box"]
            comp["w"], comp["h"] = b[2] - b[0] + 1, b[3] - b[1] + 1
            found.append(comp)
    return sorted(found, key=lambda d: (d["box"][1], d["box"][0]))


def cmd_box(args):
    a = load_rgb(args.page)
    box = tight_box(predicate(args, a), window_of(args, a))
    if not box:
        return None
    return {"box": list(box), "w": box[2] - box[0] + 1, "h": box[3] - box[1] + 1}


def cmd_lines(args):
    """Row bands of matching pixels -- one per text line, with tight boxes."""
    a = load_rgb(args.page)
    x0, y0, x1, y1 = window_of(args, a)
    mask = predicate(args, a)[y0:y1, x0:x1]
    out = []
    for s, e in runs(mask.any(axis=1), args.min_height):
        band = mask[s:e + 1]
        xs = np.nonzero(band.any(axis=0))[0]
        out.append({
            "box": [x0 + int(xs.min()), y0 + s, x0 + int(xs.max()), y0 + e],
            "h": e - s + 1, "w": int(xs.max() - xs.min() + 1),
            "baseline_px": y0 + e,   # approximate: bottom of the band
        })
    return out


def cmd_cols(args):
    a = load_rgb(args.page)
    x0, y0, x1, y1 = window_of(args, a)
    mask = predicate(args, a)[y0:y1, x0:x1]
    out = []
    for s, e in runs(mask.any(axis=0), args.min_height):
        out.append({"x0": x0 + s, "x1": x0 + e, "w": e - s + 1})
    gaps = [out[i + 1]["x0"] - out[i]["x1"] - 1 for i in range(len(out) - 1)]
    return {"columns": out, "gaps": gaps}


def cmd_sample(args):
    a = load_rgb(args.page)
    out = []
    for point in args.at:
        x, y = ints(point)[:2]
        out.append({"at": [x, y], "hex": hexstr(a[y, x]), "rgb": a[y, x].tolist()})
    return out


def cmd_edges(args):
    """Find a known block's four edges near where they are expected."""
    a = load_rgb(args.page)
    exp = ints(args.expect)
    mask = predicate(args, a)
    x0, y0, x1, y1 = exp
    cx, cy = (x0 + x1) // 2, int(y0 + (y1 - y0) * args.row_at)
    row, col = mask[cy], mask[:, cx]

    def edge(m, at, limit, first):
        lo, hi = max(0, at - args.window_px), min(limit, at + args.window_px + 1)
        idx = np.nonzero(m[lo:hi])[0]
        if not len(idx):
            return None
        return int(lo + (idx.min() if first else idx.max()))

    got = [edge(row, x0, a.shape[1], True), edge(col, y0, a.shape[0], True),
           edge(row, x1, a.shape[1], False), edge(col, y1, a.shape[0], False)]
    return {"expected": exp, "actual": got,
            "drift": [None if g is None else g - e for g, e in zip(got, exp)]}


COMMANDS = {"palette": cmd_palette, "blocks": cmd_blocks, "box": cmd_box,
            "lines": cmd_lines, "cols": cmd_cols, "sample": cmd_sample,
            "edges": cmd_edges}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=sorted(COMMANDS))
    ap.add_argument("page")
    ap.add_argument("--window", nargs="+", help="x0,y0,x1,y1 -- keep it strictly inside the target")
    ap.add_argument("--color", help="hex fill to match, e.g. 0B2240")
    ap.add_argument("--tol", type=int, default=40, help="per-channel tolerance (default 40)")
    ap.add_argument("--content", action="store_true", help="match anything but background")
    ap.add_argument("--ink", action="store_true", help="match saturated or dark pixels only")
    ap.add_argument("--n", type=int, default=10)
    ap.add_argument("--min-side", type=int, default=40)
    ap.add_argument("--min-height", type=int, default=2)
    ap.add_argument("--at", action="append", nargs="+", default=[], help="x,y (repeatable)")
    ap.add_argument("--expect", nargs="+", help="x0,y0,x1,y1 for `edges`")
    ap.add_argument("--window-px", type=int, default=10, help="search radius for `edges`")
    ap.add_argument("--row-at", type=float, default=0.5,
                    help="where to probe across the block, as a fraction of its height")
    args = ap.parse_args()
    print(json.dumps(COMMANDS[args.command](args), indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
