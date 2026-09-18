"""Pull picture and vector assets out of a page raster.

    extract.py crop  page.png --box 532,265,988,607 --aspect 1.571 --scale 3 \
                     --out work/img/photo.png
    extract.py trace page.png --box 1216,26,1498,122 --color DDA92F \
                     --name logo_mark --out work/traced.json

`crop` lifts a photograph. Give `--aspect` when the target frame's proportions
differ from the source box: it centre-crops to fit rather than letting the
builder stretch the image, which is instantly visible on anything with a
horizon or a face in it. Measure the box on content only -- a few pixels of page
background baked into the crop show up as a pale border once it is placed.

`trace` turns flat artwork -- a logo, a map outline, a pictogram -- into vector
paths via potrace, which the builder emits as native freeform shapes. Trace one
colour at a time (`--color`) so each layer can be recoloured independently; a
two-colour logo becomes two named entries. Results accumulate in one traced.json.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import is_background, load_rgb, near  # noqa: E402
from custgeom import bbox, map_points, parse_path, subpaths_to_d  # noqa: E402


def ints(value) -> list[int]:
    if isinstance(value, (list, tuple)):
        value = " ".join(str(v) for v in value)
    return [int(float(v)) for v in str(value).replace(",", " ").split()]


def cmd_crop(args) -> dict:
    img = Image.open(args.page).convert("RGB")
    x0, y0, x1, y1 = ints(args.box)
    w, h = x1 - x0, y1 - y0
    if args.aspect:
        want_h = round(w / args.aspect)
        if want_h <= h:
            top = y0 + (h - want_h) // 2
            box = (x0, top, x1, top + want_h)
        else:                         # too tall for the frame: crop the sides
            want_w = round(h * args.aspect)
            left = x0 + (w - want_w) // 2
            box = (left, y0, left + want_w, y1)
    else:
        box = (x0, y0, x1, y1)
    out_img = img.crop(box)
    if args.scale != 1:
        out_img = out_img.resize((out_img.width * args.scale, out_img.height * args.scale),
                                 Image.LANCZOS)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out_img.save(out)
    return {"file": str(out), "source_box": list(box),
            "size": list(out_img.size),
            "aspect": round(out_img.width / out_img.height, 4)}


def potrace_mask(mask: np.ndarray, upscale: int, turdsize: int) -> str:
    """Trace a boolean mask, returning SVG path data in mask-pixel coordinates."""
    h, w = mask.shape
    img = Image.fromarray((mask * 255).astype("uint8"), "L")
    img = img.resize((w * upscale, h * upscale), Image.LANCZOS)
    bw = img.point(lambda v: 0 if v > 127 else 255, "L").convert("1")  # potrace traces black

    with tempfile.TemporaryDirectory() as td:
        pbm, svg = Path(td) / "in.pbm", Path(td) / "out.svg"
        bw.save(pbm)
        try:
            subprocess.run(["potrace", "-s", "--flat", "-a", "1.0", "-O", "0.2",
                            "-t", str(turdsize * upscale), "-o", str(svg), str(pbm)],
                           check=True, capture_output=True)
        except FileNotFoundError:
            raise SystemExit("potrace is not installed -- run this through the "
                             "Docker toolchain (scripts/run.ps1), which bundles it")
        text = svg.read_text()

    import re

    tf = re.search(r'transform="translate\(([-\d.]+),([-\d.]+)\)\s*scale\(([-\d.]+),([-\d.]+)\)"',
                   text)
    tx, ty, sx, sy = (float(g) for g in tf.groups()) if tf else (0.0, 0.0, 1.0, 1.0)
    subpaths = []
    for d in re.findall(r'\sd="([^"]+)"', text):
        subpaths += parse_path(d)
    if not subpaths:
        raise SystemExit("nothing traced -- check --color/--box")
    subpaths = map_points(subpaths,
                          lambda p: ((p[0] * sx + tx) / upscale, (p[1] * sy + ty) / upscale))
    return subpaths_to_d(subpaths)


def cmd_trace(args) -> dict:
    a = load_rgb(args.page)
    x0, y0, x1, y1 = ints(args.box)
    sub = a[y0:y1, x0:x1]
    if args.color:
        mask = near(sub, args.color, args.tol)
    elif args.dark:
        mask = sub.min(axis=-1) < args.dark
    else:
        mask = ~is_background(sub)

    d = potrace_mask(mask, args.upscale, args.turdsize)
    box = [round(v, 3) for v in bbox(parse_path(d))]
    entry = {"d": d, "bbox": box,
             "source_box": [x0, y0, x1, y1],
             "page_box": [x0 + box[0], y0 + box[1], x0 + box[2], y0 + box[3]],
             "aspect": round((box[2] - box[0]) / max(box[3] - box[1], 1e-6), 4)}

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    data = json.loads(out.read_text()) if out.exists() else {}
    data[args.name] = entry
    out.write_text(json.dumps(data, indent=1))
    return {args.name: {k: v for k, v in entry.items() if k != "d"},
            "path_chars": len(d), "file": str(out)}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["crop", "trace"])
    ap.add_argument("page")
    ap.add_argument("--box", nargs="+", required=True, help="x0,y0,x1,y1 in source px")
    ap.add_argument("--out", required=True)
    ap.add_argument("--aspect", type=float, help="crop: target width/height")
    ap.add_argument("--scale", type=int, default=1, help="crop: upscale factor")
    ap.add_argument("--color", help="trace: hex colour layer to trace")
    ap.add_argument("--dark", type=int, help="trace: treat pixels darker than this as ink")
    ap.add_argument("--tol", type=int, default=60)
    ap.add_argument("--name", help="trace: key to store under in traced.json")
    ap.add_argument("--upscale", type=int, default=4,
                    help="trace: smooths contours before tracing (default 4)")
    ap.add_argument("--turdsize", type=int, default=3,
                    help="trace: drop specks smaller than this (default 3)")
    args = ap.parse_args()

    if args.command == "trace" and not args.name:
        ap.error("trace needs --name")
    result = cmd_crop(args) if args.command == "crop" else cmd_trace(args)
    print(json.dumps(result, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
