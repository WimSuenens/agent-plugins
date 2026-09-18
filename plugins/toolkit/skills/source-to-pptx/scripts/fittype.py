"""Identify the source typeface and fit point sizes to it.

    fittype.py identify page.png --text "ACME-MARKET" --window 75,110,600,185 \
        --color 0B2240 --px-per-in 115.2 --fonts /work/work/fonts /winfonts
    fittype.py size page.png --items items.json --px-per-in 115.2 --fonts /work/work/fonts

`identify` ranks candidate faces by how well their letterforms actually overlap
the source pixels. It sizes each face so its rendered string is exactly as wide
as the measured ink box, renders it, and scores the intersection-over-union
against the source, penalised by any difference in ink density (which is what
separates one weight from the next). Width and aspect ratio alone are not enough:
on a line of body copy they put Lato, Open Sans and Barlow within a percent of
each other, while the overlap score separates them clearly. Run it on the longest
string on the page -- a subtitle, not a number -- since the signal grows with the
number of glyphs.

`size` then fits the final point sizes for a list of measured items with the
chosen faces, and is what fills in the `pt` values of the spec.

items.json: [{"name": "title", "text": "ACME-MARKET", "window": [75,110,600,185],
              "color": "0B2240", "font": "Barlow-Bold.ttf"}, ...]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import is_background, load_rgb, near, tight_box  # noqa: E402


def ints(value) -> list[int]:
    if isinstance(value, (list, tuple)):
        value = " ".join(str(v) for v in value)
    return [int(float(v)) for v in str(value).replace(",", " ").split()]


def measure(page, window, colour, tol) -> dict | None:
    a = load_rgb(page)
    mask = near(a, colour, tol) if colour else ~is_background(a)
    box = tight_box(mask, ints(window))
    if not box:
        return None
    return {"box": list(box), "w": box[2] - box[0] + 1, "h": box[3] - box[1] + 1}


def font_files(dirs: list[str]) -> list[Path]:
    out: list[Path] = []
    for d in dirs:
        p = Path(d)
        if p.is_file():
            out.append(p)
        elif p.is_dir():
            out += sorted(list(p.glob("*.ttf")) + list(p.glob("*.otf")))
    return out


REF_PX = 300  # reference size: big enough that ink metrics are effectively continuous


def ink(text: str, path: Path, size: int = REF_PX) -> tuple[float, float] | None:
    """Ink box of `text` rendered at a reference size."""
    try:
        box = ImageFont.truetype(str(path), size).getbbox(text)
    except OSError:
        return None
    w, h = box[2] - box[0], box[3] - box[1]
    return (w, h) if w > 0 and h > 0 else None


def score(text: str, path: Path, measured_w: float, measured_h: float):
    """Size a face against a measured ink box, and score its proportions."""
    got = ink(text, path)
    if not got:
        return None
    w0, h0 = got
    ratio = (w0 / h0) / (measured_w / measured_h)
    return {
        "width_px_size": REF_PX * measured_w / w0,   # px font size matching the width
        "height_px_size": REF_PX * measured_h / h0,
        "aspect_error": abs(ratio - 1.0),
    }


def render_mask(text: str, path: Path, px_size: float, shape: tuple[int, int]):
    """Binary ink mask of `text` at `px_size`, top-left aligned, padded to `shape`."""
    from PIL import Image, ImageDraw

    size = max(1, int(round(px_size)))
    try:
        font = ImageFont.truetype(str(path), size)
    except OSError:
        return None
    box = font.getbbox(text)
    img = Image.new("L", (box[2] - box[0] + 4, box[3] - box[1] + 4), 0)
    ImageDraw.Draw(img).text((-box[0], -box[1]), text, font=font, fill=255)
    h, w = shape
    canvas = Image.new("L", (w, h), 0)
    canvas.paste(img.crop((0, 0, min(w, img.width), min(h, img.height))), (0, 0))
    return np.asarray(canvas) > 110


def overlap(source: np.ndarray, candidate: np.ndarray, max_shift: int = 3) -> float:
    """Best intersection-over-union of two ink masks over small shifts.

    This is the measurement that actually separates one humanist sans from
    another. Total width and aspect ratio put Lato, Open Sans and Barlow within
    a percent of each other on a line of body copy; the letterforms themselves
    do not overlap anywhere near as well, so comparing rendered ink against the
    source pixels is what makes the ranking trustworthy.
    """
    best = 0.0
    h, w = source.shape
    for dy in range(-max_shift, max_shift + 1):
        for dx in range(-max_shift, max_shift + 1):
            shifted = np.zeros_like(candidate)
            ys0, ys1 = max(0, dy), min(h, h + dy)
            xs0, xs1 = max(0, dx), min(w, w + dx)
            shifted[ys0:ys1, xs0:xs1] = candidate[ys0 - dy:ys1 - dy, xs0 - dx:xs1 - dx]
            inter = np.logical_and(source, shifted).sum()
            union = np.logical_or(source, shifted).sum()
            if union:
                best = max(best, inter / union)
    return best


def family_of(path: Path) -> str:
    try:
        from fontTools.ttLib import TTFont

        names = {r.nameID: r.toUnicode() for r in TTFont(str(path))["name"].names
                 if r.platformID == 3}
        return names.get(16) or names.get(1) or path.stem
    except Exception:
        return path.stem


def source_mask(page, box, colour, tol) -> np.ndarray:
    """Ink mask of the measured box, cropped tight."""
    a = load_rgb(page)
    mask = near(a, colour, tol) if colour else ~is_background(a)
    x0, y0, x1, y1 = box
    return mask[y0:y1 + 1, x0:x1 + 1]


def cmd_identify(args) -> list[dict]:
    m = measure(args.page, args.window, args.color, args.tol)
    if not m:
        raise SystemExit("nothing matched in that window -- check --color/--window")
    to_pt = 72.0 / args.px_per_in
    src = source_mask(args.page, m["box"], args.color, args.tol)
    src_density = src.sum() / src.size
    rows = []
    for path in font_files(args.fonts):
        s = score(args.text, path, m["w"], m["h"])
        if not s:
            continue
        cand = render_mask(args.text, path, s["width_px_size"], src.shape)
        if cand is None:
            continue
        iou = overlap(src, cand)
        # ink density separates weights: same shapes, thicker strokes
        density = cand.sum() / cand.size
        rows.append({
            "file": path.name, "family": family_of(path),
            "match": round(iou, 3),
            "weight_delta": round(density - src_density, 3),
            "aspect_error": round(s["aspect_error"], 4),
            "pt_by_width": round(s["width_px_size"] * to_pt, 1),
            "suggested_pt": round(s["width_px_size"] * to_pt * 2) / 2,
        })
    rows.sort(key=lambda r: -(r["match"] - 0.6 * abs(r["weight_delta"])))
    print(f"measured ink box {m['w']} x {m['h']} px at {args.px_per_in} px/in, "
          f"ink density {src_density:.3f}. Ranked by letterform overlap (1.0 = perfect), "
          f"penalised by weight_delta (candidate minus source ink density: "
          f"positive = too heavy). Confirm the weight in the render/compare loop -- "
          f"at body sizes neighbouring weights are close.", file=sys.stderr)
    return rows[:args.top]


def cmd_size(args) -> list[dict]:
    items = json.loads(Path(args.items).read_text())
    to_pt = 72.0 / args.px_per_in
    files = {p.name: p for p in font_files(args.fonts)}
    out = []
    for item in items:
        m = measure(args.page, item["window"], item.get("color"), args.tol)
        if not m:
            out.append({"name": item.get("name"), "error": "no match in window"})
            continue
        path = files.get(item["font"])
        if path is None:
            out.append({"name": item.get("name"), "error": f"font not found: {item['font']}"})
            continue
        s = score(item["text"], path, m["w"], m["h"])
        pw, ph = s["width_px_size"] * to_pt, s["height_px_size"] * to_pt
        out.append({
            "name": item.get("name"), "text": item["text"], "font": item["font"],
            "box": m["box"], "w": m["w"], "h": m["h"],
            "pt_by_width": round(pw, 1), "pt_by_height": round(ph, 1),
            "aspect_error": round(s["aspect_error"], 4),
            "pt": round(pw * 2) / 2,
            "baseline_px": m["box"][3] if not any(c in item["text"] for c in "gjpqy,;") else None,
            "left_px": m["box"][0],
        })
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["identify", "size"])
    ap.add_argument("page")
    ap.add_argument("--text")
    ap.add_argument("--window", nargs="+")
    ap.add_argument("--color")
    ap.add_argument("--tol", type=int, default=60)
    ap.add_argument("--items")
    ap.add_argument("--px-per-in", type=float, required=True)
    ap.add_argument("--fonts", nargs="+", default=["work/fonts", "/winfonts"])
    ap.add_argument("--top", type=int, default=12)
    args = ap.parse_args()

    if args.command == "identify" and not (args.text and args.window):
        ap.error("identify needs --text and --window")
    if args.command == "size" and not args.items:
        ap.error("size needs --items")

    print(json.dumps(cmd_identify(args) if args.command == "identify" else cmd_size(args),
                     indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
