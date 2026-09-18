"""Normalise any source into page rasters plus a description of what came in.

    ingest.py <input.pdf|image> [--out DIR] [--width 1536] [--dpi N] [--pages 2-5]

Writes DIR/page-01.png ... and DIR/source.json. The report says how many pages
there are, their physical size, and -- the branch that matters -- whether a PDF
carries a real text layer, in which case pdftext.py can seed the spec directly
instead of everything being measured off pixels.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

from PIL import Image

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tif", ".tiff", ".gif"}


def parse_pages(spec: str | None, count: int) -> list[int]:
    """'2', '2-5', '1,4,7' or None -> zero-based page indices."""
    if not spec:
        return list(range(count))
    out: list[int] = []
    for part in spec.split(","):
        part = part.strip()
        if "-" in part:
            lo, hi = part.split("-")
            out += list(range(int(lo) - 1, int(hi)))
        else:
            out.append(int(part) - 1)
    return [p for p in out if 0 <= p < count]


def ingest_pdf(src: Path, out: Path, width: int | None, dpi: float | None,
               pages: str | None) -> dict:
    import pypdfium2 as pdfium

    doc = pdfium.PdfDocument(str(src))
    wanted = parse_pages(pages, len(doc))
    report = {"kind": "pdf", "input": str(src), "page_count": len(doc), "pages": []}

    for n, idx in enumerate(wanted, start=1):
        page = doc[idx]
        w_pt, h_pt = page.get_size()          # points, 72 per inch
        scale = (width / w_pt) if width else (dpi or 200) / 72.0
        img = page.render(scale=scale).to_pil()
        name = f"page-{n:02d}.png"
        img.save(out / name)
        report["pages"].append({
            "index": idx + 1, "file": name,
            "w_px": img.width, "h_px": img.height,
            "w_in": round(w_pt / 72, 4), "h_in": round(h_pt / 72, 4),
            "aspect": round(img.width / img.height, 4),
            "px_per_in": round(img.width / (w_pt / 72), 2),
        })

    report["has_text_layer"] = pdf_has_text(src, [p["index"] for p in report["pages"]])
    return report


def pdf_has_text(src: Path, page_numbers: list[int]) -> bool:
    """True when the PDF holds selectable text rather than just scanned pixels."""
    try:
        import pdfplumber
    except ImportError:
        return False
    with pdfplumber.open(str(src)) as pdf:
        for n in page_numbers[:5]:
            if len(pdf.pages[n - 1].chars) > 20:
                return True
    return False


def ingest_image(src: Path, out: Path, width: int | None) -> dict:
    img = Image.open(src).convert("RGB")
    if width and img.width != width:
        img = img.resize((width, round(img.height * width / img.width)), Image.LANCZOS)
    name = "page-01.png"
    if src.suffix.lower() == ".png" and img.size == Image.open(src).size:
        shutil.copy(src, out / name)
    else:
        img.save(out / name)
    return {
        "kind": "image", "input": str(src), "page_count": 1, "has_text_layer": False,
        "pages": [{"index": 1, "file": name, "w_px": img.width, "h_px": img.height,
                   "w_in": None, "h_in": None,
                   "aspect": round(img.width / img.height, 4), "px_per_in": None}],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("input")
    ap.add_argument("--out", default="work")
    ap.add_argument("--width", type=int, default=1536,
                    help="render each page to this pixel width (default 1536)")
    ap.add_argument("--dpi", type=float, help="render at a fixed DPI instead of --width")
    ap.add_argument("--pages", help="page selection, e.g. 2-5 or 1,4,7")
    args = ap.parse_args()

    src = Path(args.input)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    if not src.exists():
        print(f"no such file: {src}", file=sys.stderr)
        return 1

    if src.suffix.lower() == ".pdf":
        report = ingest_pdf(src, out, None if args.dpi else args.width, args.dpi, args.pages)
    elif src.suffix.lower() in IMAGE_SUFFIXES:
        report = ingest_image(src, out, args.width if args.width else None)
    else:
        print(f"unsupported input type: {src.suffix}", file=sys.stderr)
        return 1

    (out / "source.json").write_text(json.dumps(report, indent=1))
    print(json.dumps(report, indent=1))
    ratio = report["pages"][0]["aspect"]
    hint = "16:9" if abs(ratio - 16 / 9) < 0.03 else "4:3" if abs(ratio - 4 / 3) < 0.03 else \
           "A4 portrait" if abs(ratio - 0.707) < 0.03 else f"{ratio:.3f}:1"
    print(f"\n{report['page_count']} page(s), first page aspect {hint}, "
          f"text layer: {report['has_text_layer']}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
