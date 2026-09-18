"""Seed a spec from a PDF that carries a real text layer.

    pdftext.py source.pdf --page 1 --px-per-in 115.2 --out work/seed.json
    pdftext.py source.pdf --page 1 --px-per-in 115.2 --page-image work/page-01.png \
        --img-dir work/img --out work/seed.json

When `ingest.py` reports `has_text_layer: true`, this is the shortcut: the PDF
already knows every string, its font, its size, its colour and its exact
baseline, so there is nothing to measure. The output is a spec fragment -- a
slide with `text` and `rect` elements in source-pixel coordinates, the same
convention as the measured path -- to edit rather than author from scratch.

Two things still need judgement afterwards. The PDF names fonts that are usually
licensed and often subset-tagged (`ABCDEF+Helvetica-Bold`); `fonts_seen` lists
them with a free equivalent from assets/fonts/catalog.json, and you decide
whether to substitute or keep. And a PDF has no idea what a "card" is: grouping
runs into blocks, and spotting which rectangle is a panel, is still a reading
job.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import ASSETS, hexstr  # noqa: E402

SUBSET = re.compile(r"^[A-Z]{6}\+")


def colour_of(value) -> str:
    """pdfminer colours are gray, RGB or CMYK tuples (or a bare number)."""
    if value is None:
        return "000000"
    if isinstance(value, (int, float)):
        v = max(0.0, min(1.0, float(value))) * 255
        return hexstr((v, v, v))
    vals = list(value)
    if len(vals) == 1:
        v = max(0.0, min(1.0, vals[0])) * 255
        return hexstr((v, v, v))
    if len(vals) == 3:
        return hexstr([max(0.0, min(1.0, v)) * 255 for v in vals])
    if len(vals) == 4:
        c, m, y, k = vals
        return hexstr([255 * (1 - min(1.0, ch + k)) for ch in (c, m, y)])
    return "000000"


def base_font(name: str) -> tuple[str, bool, bool]:
    """'ABCDEF+Helvetica-BoldOblique' -> ('Helvetica', bold, italic)."""
    name = SUBSET.sub("", name or "")
    lower = name.lower()
    bold = "bold" in lower or lower.endswith("-bd") or ",bold" in lower
    italic = "italic" in lower or "oblique" in lower
    stem = re.split(r"[-,]", name)[0]
    stem = re.sub(r"(MT|PS|Std|Pro)$", "", stem)
    return (re.sub(r"(?<!^)(?=[A-Z])", " ", stem).strip(), bold, italic)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pdf")
    ap.add_argument("--page", type=int, default=1, help="1-based")
    ap.add_argument("--px-per-in", type=float, required=True,
                    help="from ingest.py, so coordinates match the page raster")
    ap.add_argument("--out", default="work/seed.json")
    ap.add_argument("--page-image", help="rendered page; enables automatic image crops")
    ap.add_argument("--img-dir", default="work/img")
    ap.add_argument("--min-rect", type=float, default=8.0,
                    help="ignore filled rects smaller than this, in points")
    ap.add_argument("--space-gap", type=float, default=0.16,
                    help="gap between glyphs that means a space, in em (default 0.16)")
    ap.add_argument("--split-gap", type=float, default=1.2,
                    help="gap that splits one visual line into separate text "
                         "elements, in em (default 1.2)")
    args = ap.parse_args()

    import pdfplumber

    scale = args.px_per_in / 72.0        # PDF points -> source pixels
    aliases = json.loads((ASSETS / "fonts" / "catalog.json").read_text())["pdf_aliases"]

    with pdfplumber.open(args.pdf) as pdf:
        page = pdf.pages[args.page - 1]
        page_w, page_h = page.width, page.height

        elements, fonts_seen = [], defaultdict(lambda: {"count": 0, "sizes": set()})

        # --- filled rectangles: cards, panels, rules ------------------------
        for rect in page.rects:
            w, h = rect["x1"] - rect["x0"], rect["bottom"] - rect["top"]
            if w < args.min_rect or h < args.min_rect:
                continue
            el = {"type": "rect",
                  "box_px": [round(rect["x0"] * scale), round(rect["top"] * scale),
                             round(rect["x1"] * scale), round(rect["bottom"] * scale)]}
            if rect.get("fill"):
                el["fill"] = colour_of(rect.get("non_stroking_color"))
            if rect.get("stroke"):
                el["line"] = colour_of(rect.get("stroking_color"))
                el["line_pt"] = round(rect.get("linewidth", 1) or 1, 2)
            elements.append(el)

        # --- text lines -----------------------------------------------------
        # A PDF stores glyphs and positions, not words: spaces are usually a gap
        # rather than a character, and anything sharing a baseline -- three KPI
        # figures side by side, say -- comes back as one "line". So gaps do the
        # work here: a small one becomes a space, a large one splits the line
        # into separate text elements, which is what the layout actually has.
        for line in page.extract_text_lines(return_chars=True):
            chars = line["chars"]
            if not chars:
                continue
            segments, runs, current, prev = [], [], None, None
            for ch in chars:
                fontname = ch.get("fontname", "?")
                family, bold, italic = base_font(fontname)
                size = round(ch.get("size", 12), 1)
                colour = colour_of(ch.get("non_stroking_color"))
                fonts_seen[fontname]["count"] += 1
                fonts_seen[fontname]["sizes"].add(size)

                gap = (ch["x0"] - prev["x1"]) if prev else 0.0
                if prev and gap > args.split_gap * size:
                    segments.append((runs, prev))
                    runs, current = [], None
                elif prev and gap > args.space_gap * size and current:
                    current["t"] += " "

                key = (family, bold, italic, size, colour)
                if current and current["_key"] == key:
                    current["t"] += ch["text"]
                else:
                    current = {"_key": key, "t": ch["text"], "pt": size,
                               "font": family, "c": colour}
                    if bold:
                        current["b"] = True
                    if italic:
                        current["i"] = True
                    runs.append(current)
                if not runs[0].get("_x0"):
                    runs[0]["_x0"] = ch["x0"]
                prev = ch
            if runs:
                segments.append((runs, prev))

            # matrix[5] is the text baseline in PDF space -- exact, unlike the
            # glyph bounding box, which reserves descender room on every line
            baseline_pdf = chars[0].get("matrix", (0,) * 6)[5]
            baseline = (page_h - baseline_pdf) if baseline_pdf else line["bottom"]
            for seg_runs, last in segments:
                x0 = seg_runs[0].pop("_x0", line["x0"])
                for r in seg_runs:
                    r.pop("_key", None)
                    r.pop("_x0", None)
                elements.append({
                    "type": "text", "align": "l",
                    "left_px": round(x0 * scale),
                    "width_px": round((last["x1"] - x0) * scale) + 12,
                    "baseline_px": round(baseline * scale),
                    "runs": seg_runs,
                })

        # --- images ---------------------------------------------------------
        images = []
        page_img = None
        if args.page_image and Path(args.page_image).exists():
            from PIL import Image

            page_img = Image.open(args.page_image).convert("RGB")
            Path(args.img_dir).mkdir(parents=True, exist_ok=True)
        for n, im in enumerate(page.images, start=1):
            box = [round(im["x0"] * scale), round(im["top"] * scale),
                   round(im["x1"] * scale), round(im["bottom"] * scale)]
            el = {"type": "picture", "box_px": box, "name": f"Image {n}"}
            if page_img is not None:
                target = Path(args.img_dir) / f"image-{args.page:02d}-{n:02d}.png"
                page_img.crop(tuple(box)).save(target)
                el["file"] = str(target)
            images.append(el)
        elements += images

    seed = {
        "_note": "Seeded from the PDF text layer. Coordinates are source pixels at "
                 f"{args.px_per_in} px/in. Group these into cards/panels, set the "
                 "fonts, and add bands if the target aspect differs from the page.",
        "page_size_in": [round(page_w / 72, 4), round(page_h / 72, 4)],
        "px_per_in": args.px_per_in,
        "fonts_seen": {
            name: {"count": v["count"], "sizes": sorted(v["sizes"]),
                   "family": base_font(name)[0],
                   "free_equivalent": aliases.get(base_font(name)[0])}
            for name, v in sorted(fonts_seen.items(), key=lambda kv: -kv[1]["count"])
        },
        "elements": elements,
    }
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(seed, indent=1))
    print(json.dumps({k: v for k, v in seed.items() if k != "elements"}, indent=1))
    print(f"\n{len(elements)} elements -> {out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
