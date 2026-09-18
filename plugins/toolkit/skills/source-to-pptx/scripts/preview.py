"""Rasterise icon and traced path data to a contact sheet.

    preview.py --icons                       # the whole library
    preview.py --icons store globe target    # just these
    preview.py --traced work/traced.json     # logo/map traces
    preview.py --icons --out work/review/icons.png

Worth a look before building: a broken path or a mis-traced logo is obvious here
and confusing once it is a shape inside a deck.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import iconlib  # noqa: E402
from custgeom import bbox, parse_path  # noqa: E402

INK = (17, 24, 39)


def flatten(subpaths, steps: int = 16):
    """Sub-paths -> polylines."""
    polys = []
    for sp in subpaths:
        pts, cur = [sp.start], sp.start
        for kind, seg in sp.segs:
            if kind == "L":
                pts.append(seg[0])
                cur = seg[0]
            else:
                p0, (p1, p2, p3) = cur, seg
                for i in range(1, steps + 1):
                    t = i / steps
                    u = 1 - t
                    pts.append((
                        u**3 * p0[0] + 3*u*u*t * p1[0] + 3*u*t*t * p2[0] + t**3 * p3[0],
                        u**3 * p0[1] + 3*u*u*t * p1[1] + 3*u*t*t * p2[1] + t**3 * p3[1]))
                cur = p3
        if sp.closed:
            pts.append(sp.start)   # Z: the closing edge is implicit in the data
        polys.append(pts)
    return polys


def draw_icon_tile(prims, size: int, grid: float) -> Image.Image:
    img = Image.new("RGB", (size, size), "white")
    dr = ImageDraw.Draw(img)
    s = size / grid
    for kind, spec in prims:
        if kind in ("path", "arrowpath", "fill"):
            for poly in flatten(parse_path(spec)):
                pts = [(x * s, y * s) for x, y in poly]
                if kind == "fill":
                    dr.polygon(pts, fill=INK)
                    continue
                dr.line(pts, fill=INK, width=max(2, size // 60), joint="curve")
                if kind == "arrowpath":       # stand-in for the native arrowhead
                    x, y = pts[-1]
                    r = size / 28
                    dr.ellipse([x - r, y - r, x + r, y + r], fill=INK)
        elif kind in ("oval", "dot"):
            x, y, w, h = spec
            box = [x * s, y * s, (x + w) * s, (y + h) * s]
            if kind == "dot":
                dr.ellipse(box, fill=INK)
            else:
                dr.ellipse(box, outline=INK, width=max(2, size // 60))
    return img


def draw_path_tile(d: str, size: int, pad: int = 8) -> Image.Image:
    sp = parse_path(d)
    x0, y0, x1, y1 = bbox(sp)
    scale = (size - 2 * pad) / max(x1 - x0, y1 - y0, 1e-6)
    img = Image.new("RGB", (size, size), "white")
    dr = ImageDraw.Draw(img)
    for poly in flatten(sp):
        dr.polygon([((px - x0) * scale + pad, (py - y0) * scale + pad) for px, py in poly],
                   fill=INK)
    return img


def sheet(tiles, out: Path, cols: int = 6, size: int = 150) -> None:
    rows = (len(tiles) + cols - 1) // cols
    pad, label = 8, 18
    img = Image.new("RGB", (cols * (size + pad) + pad,
                            rows * (size + pad + label) + pad), "white")
    dr = ImageDraw.Draw(img)
    for i, (name, tile) in enumerate(tiles):
        x = pad + (i % cols) * (size + pad)
        y = pad + (i // cols) * (size + pad + label)
        dr.text((x, y), name[:22], fill=(190, 0, 0))
        img.paste(tile, (x, y + label))
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"wrote {out}  ({len(tiles)} tiles)")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--icons", nargs="*", help="icon names, or none for all")
    ap.add_argument("--traced", help="a traced.json written by extract.py")
    ap.add_argument("--out", default="work/review/preview.png")
    ap.add_argument("--size", type=int, default=150)
    args = ap.parse_args()

    tiles = []
    if args.icons is not None:
        data = iconlib.load()
        names = args.icons or sorted(data["icons"])
        grid = float(data.get("viewbox", 64))
        tiles += [(n, draw_icon_tile(data["icons"][n]["prims"], args.size, grid))
                  for n in names]
    if args.traced:
        for name, entry in json.loads(Path(args.traced).read_text()).items():
            tiles.append((name, draw_path_tile(entry["d"], args.size)))
    if not tiles:
        ap.error("give --icons and/or --traced")
    sheet(tiles, Path(args.out), size=args.size)
    return 0


if __name__ == "__main__":
    sys.exit(main())
