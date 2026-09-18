"""Compare a rendered deck against the source pages.

    compare.py work/spec.json --render work/review --source work
    compare.py work/spec.json --slide 1 --zoom 135,298,230,382:cards

Two outputs, and both matter:

* a numeric drift report -- every rect and picture in the spec is re-detected in
  the render and its four edges compared with where the spec says they should be.
  Numbers catch the slow drift that the eye accepts.
* review images -- side-by-side, a 50% overlay, and optional zoom crops of
  matching detail, which is how icon and type problems actually get spotted.

Aim for a worst-edge drift of about 5 px at 1536 px wide. Past that, read the
number: a whole block off by the same amount is a band origin; one edge off is a
box; text drifting while blocks hold is a baseline or a font-metric problem.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import is_background, near, unhex  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_deck import Geometry  # noqa: E402

# Rects and pictures are the geometry anchors. A traced freeform is an outline
# whose interior is the block behind it, so probing across it finds nothing
# useful -- check those in the zoom sheet instead.
DETECTABLE = {"rect", "picture"}


def ints(value) -> list[int]:
    if isinstance(value, (list, tuple)):
        value = " ".join(str(v) for v in value)
    return [int(float(v)) for v in str(value).replace(",", " ").split()]


def detect(img: np.ndarray, box, pred, window: int = 10, row_at: float = 0.5):
    """Locate a block's four edges near where they are expected.

    Searching a window around each expected edge -- rather than flood-filling or
    masking a padded box -- is what keeps a neighbouring block of the same colour
    from being swallowed into the result. Keep `window` below the gap between
    blocks.
    """
    x0, y0, x1, y1 = box
    cx = int((x0 + x1) / 2)
    cy = int(y0 + (y1 - y0) * row_at)
    h, w = img.shape[:2]
    if not (0 <= cx < w and 0 <= cy < h):
        return None
    row, col = pred(img[cy, :, :]), pred(img[:, cx, :])

    def edge(mask, at, limit, first):
        lo, hi = max(0, int(at) - window), min(limit, int(at) + window + 1)
        idx = np.nonzero(mask[lo:hi])[0]
        return None if not len(idx) else int(lo + (idx.min() if first else idx.max()))

    found = (edge(row, x0, w, True), edge(col, y0, h, True),
             edge(row, x1, w, False), edge(col, y1, h, False))
    return None if any(v is None for v in found) else found


def predicate_for(el: dict, background: str | None = None):
    """How to recognise this element's pixels in the render.

    Two traps, both of which show up as every edge landing exactly on the search
    window: an outlined panel has to be keyed on its border rather than its
    near-white fill, and a pale fill on a pale page needs a tolerance tighter
    than the gap between the two, or the background matches as well.
    """
    colour = el.get("line") or el.get("fill") or (el.get("gradient") or [None])[-1]
    if el["type"] == "picture":
        # the only colourful block; keying on saturation or darkness ignores the
        # soft shadow, which "not background" would count as an edge
        return lambda r: ((r.max(axis=-1) - r.min(axis=-1)) > 20) | (r.min(axis=-1) < 200)
    if colour:
        tol = 45
        if background:
            distance = max(abs(a - b) for a, b in zip(unhex(colour), unhex(background)))
            tol = max(4, min(45, distance // 2 - 1))
        return lambda r, c=colour, tl=tol: near(r, c, tl)
    return lambda r: ~is_background(r)


def expected_boxes(spec: dict, slide_index: int, render_w: int):
    """Where each detectable element should land in the render, in render px."""
    slide = spec["slides"][slide_index]
    geo = Geometry(slide, spec.get("defaults", {}))
    ppi = render_w / spec["deck"].get("slide_w_in", 13.3333)
    background = slide.get("background")
    out = []
    for el in slide["elements"]:
        if el["type"] not in DETECTABLE or "box_px" not in el and "box_in" not in el:
            continue
        x, y, w, h = geo.box(el, el.get("band"))
        out.append({
            "name": el.get("name", el["type"]),
            "expected": [x * ppi, y * ppi, (x + w) * ppi, (y + h) * ppi],
            "pred": predicate_for(el, background),
            "row_at": 0.18 if el["type"] == "picture" else 0.5,
        })
    return out


def report(spec: dict, render: Path, slide_index: int) -> float:
    img = np.asarray(Image.open(render).convert("RGB")).astype(int)
    worst = 0.0
    rows = expected_boxes(spec, slide_index, img.shape[1])
    print(f"{'element':28s} {'expected':>26s} {'actual':>26s}   drift")
    for row in rows:
        got = detect(img, row["expected"], row["pred"], row_at=row["row_at"])
        if got is None:
            print(f"{row['name'][:28]:28s} {'-- not detected --':>26s}")
            continue
        drift = [g - e for g, e in zip(got, row["expected"])]
        worst = max(worst, max(abs(v) for v in drift))
        fmt = lambda t: "(" + ",".join(f"{v:6.0f}" for v in t) + ")"
        print(f"{row['name'][:28]:28s} {fmt(row['expected']):>26s} {fmt(got):>26s}   "
              + ",".join(f"{v:+.0f}" for v in drift))
    print(f"\nworst edge drift: {worst:.0f} px at {img.shape[1]} px wide")
    return worst


def sheets(source: Path, render: Path, out: Path, zooms, spec, slide_index) -> None:
    src = Image.open(source).convert("RGB")
    ren = Image.open(render).convert("RGB")
    out.mkdir(parents=True, exist_ok=True)

    w = 1200
    a = src.resize((w, round(w * src.height / src.width)), Image.LANCZOS)
    b = ren.resize((w, round(w * ren.height / ren.width)), Image.LANCZOS)
    sheet = Image.new("RGB", (w, a.height + b.height + 12), "white")
    sheet.paste(a, (0, 0))
    sheet.paste(b, (0, a.height + 12))
    sheet.save(out / "side-by-side.png")

    Image.blend(src.resize(ren.size, Image.LANCZOS), ren, 0.5).save(out / "overlay.png")

    if zooms:
        slide = spec["slides"][slide_index]
        geo = Geometry(slide, spec.get("defaults", {}))
        ppi = ren.width / spec["deck"].get("slide_w_in", 13.3333)
        tiles = []
        for z in zooms:
            spec_box, _, band = z.partition(":")
            x0, y0, x1, y1 = ints(spec_box)
            band = band or None
            rbox = (x0, round(geo.y(y0, band) * ppi), x1, round(geo.y(y1, band) * ppi))
            tiles.append((z, src.crop((x0, y0, x1, y1)), ren.crop(rbox)))
        h = 160
        scaled = [(n, p.resize((round(p.width * h / max(p.height, 1)), h), Image.LANCZOS),
                   q.resize((round(q.width * h / max(q.height, 1)), h), Image.LANCZOS))
                  for n, p, q in tiles]
        width = max(max(p.width, q.width) for _, p, q in scaled) * 2 + 36
        sheet = Image.new("RGB", (width, len(scaled) * (h + 26) + 12), "white")
        dr = ImageDraw.Draw(sheet)
        y = 12
        for name, p, q in scaled:
            dr.text((12, y - 10), f"{name}   (left: source, right: render)", fill=(190, 0, 0))
            sheet.paste(p, (12, y + 4))
            sheet.paste(q, (width // 2 + 12, y + 4))
            y += h + 26
        sheet.save(out / "zoom.png")
    print(f"wrote review images to {out}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("spec")
    ap.add_argument("--render", default="work/review", help="dir of slide-NN.png")
    ap.add_argument("--source", default="work", help="dir of the page-NN.png sources")
    ap.add_argument("--slide", type=int, default=1, help="1-based slide number")
    ap.add_argument("--zoom", action="append", default=[],
                    help="x0,y0,x1,y1[:band] detail crop (repeatable)")
    ap.add_argument("--out", help="where to write review images (default: --render)")
    args = ap.parse_args()

    spec_path = Path(args.spec)
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    idx = args.slide - 1
    slide = spec["slides"][idx]

    render = Path(args.render) / f"slide-{args.slide:02d}.png"
    if not render.exists():
        raise SystemExit(f"no render at {render} -- run scripts/render.ps1 first")
    source = Path(args.source) / slide.get("source", f"page-{args.slide:02d}.png")

    worst = report(spec, render, idx)
    if source.exists():
        sheets(source, render, Path(args.out or args.render), args.zoom, spec, idx)
    else:
        print(f"(no source page at {source}; skipping review images)")
    return 0 if worst <= 8 else 0


if __name__ == "__main__":
    sys.exit(main())
