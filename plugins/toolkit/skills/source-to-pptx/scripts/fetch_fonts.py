"""Download font families from the Google Fonts repository.

    fetch_fonts.py --family "Barlow Semi Condensed" --out work/fonts
    fetch_fonts.py --family Barlow --styles Bold,SemiBold --out work/fonts
    fetch_fonts.py --shortlist --out work/fonts        # the identification candidates

Rather than carrying a hard-coded URL table that rots, this reads each family's
METADATA.pb from the repo and downloads the static files it lists, so any OFL /
Apache / UFL family can be fetched by name. Families published only as variable
fonts are instanced into static weights, because PowerPoint does not interpolate
a variable font -- an embedded one renders at a single weight.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import ASSETS  # noqa: E402

RAW = "https://raw.githubusercontent.com/google/fonts/main"
LICENCE_DIRS = ("ofl", "apache", "ufl")


def slug(family: str) -> str:
    return re.sub(r"[^a-z0-9]", "", family.lower())


def metadata(family: str) -> tuple[str, str]:
    """Return (licence dir, METADATA.pb text) for a family name."""
    name = slug(family)
    last: Exception | None = None
    for lic in LICENCE_DIRS:
        try:
            with urllib.request.urlopen(f"{RAW}/{lic}/{name}/METADATA.pb", timeout=30) as r:
                return lic, r.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as exc:
            last = exc
    raise SystemExit(f"family not found in google/fonts: {family!r} ({last})")


WEIGHTS = {"Thin": 100, "ExtraLight": 200, "Light": 300, "Regular": 400,
           "Medium": 500, "SemiBold": 600, "Bold": 700, "ExtraBold": 800, "Black": 900}
DEFAULT_STYLES = ["Regular", "Medium", "SemiBold", "Bold"]


def instance_variable(vf_path: Path, family: str, styles: list[str], out: Path) -> list[Path]:
    """Cut static weights out of a variable font.

    Many popular families now ship from google/fonts only as variable fonts, and
    PowerPoint does not interpolate one: an embedded VF renders at a single
    weight. Instancing gives real static faces, named the way PowerPoint expects
    to address them (a non-Regular/Bold weight becomes its own family, matching
    Google's own static naming).
    """
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer

    italic = "Italic" in vf_path.stem
    made = []
    for style in styles:
        weight = WEIGHTS.get(style)
        if weight is None:
            continue
        font = TTFont(str(vf_path))
        axes = {a.axisTag: (a.minValue, a.maxValue) for a in font["fvar"].axes}
        if "wght" not in axes or not axes["wght"][0] <= weight <= axes["wght"][1]:
            font.close()
            continue
        instancer.instantiateVariableFont(font, {"wght": weight}, inplace=True, updateFontNames=False)

        suffix = ("Italic" if style == "Regular" else style + "Italic") if italic else style
        if style in ("Regular", "Bold"):
            fam, sub = family, ("Bold" if style == "Bold" else "Regular")
            if italic:
                sub = (sub + " Italic").replace("Regular Italic", "Italic")
        else:
            fam, sub = f"{family} {style}", "Italic" if italic else "Regular"
        full = f"{fam} {sub}".replace(" Regular", "").strip()
        ps = f"{fam.replace(' ', '')}-{sub.replace(' ', '')}"
        for nid, value in ((1, fam), (2, sub), (4, full), (6, ps), (16, None), (17, None)):
            if value is None:
                font["name"].removeNames(nameID=nid)
            else:
                font["name"].setName(value, nid, 3, 1, 0x409)
        font["OS/2"].usWeightClass = weight

        target = out / f"{family.replace(' ', '')}-{suffix}.ttf"
        font.save(str(target))
        font.close()
        print(f"  cut   {target.name}  (wght {weight} from {vf_path.name})")
        made.append(target)
    return made


def fetch(family: str, styles: list[str] | None, out: Path) -> list[Path]:
    lic, meta = metadata(family)
    files = re.findall(r'filename:\s*"([^"]+)"', meta)
    static = [f for f in files if "[" not in f]
    variable = [f for f in files if "[" in f]

    if not static and variable:
        made: list[Path] = []
        for filename in variable:
            tmp = out / filename
            if not tmp.exists():
                urllib.request.urlretrieve(f"{RAW}/{lic}/{slug(family)}/{filename}", tmp)
            made += instance_variable(tmp, family, styles or DEFAULT_STYLES, out)
            tmp.unlink(missing_ok=True)
        return made

    got = []
    for filename in static:
        stem = Path(filename).stem
        style = stem.split("-", 1)[1] if "-" in stem else "Regular"
        if styles and style not in styles:
            continue
        target = out / filename
        if target.exists() and target.stat().st_size:
            print(f"  have  {filename}")
            got.append(target)
            continue
        url = f"{RAW}/{lic}/{slug(family)}/{filename}"
        try:
            urllib.request.urlretrieve(url, target)
        except urllib.error.HTTPError as exc:
            print(f"  fail  {filename} ({exc})", file=sys.stderr)
            continue
        print(f"  fetch {filename}  ({target.stat().st_size:,} bytes)")
        got.append(target)

    licence = out / f"{slug(family)}-LICENSE.txt"
    if not licence.exists():
        for candidate in ("OFL.txt", "LICENSE.txt"):
            try:
                urllib.request.urlretrieve(f"{RAW}/{lic}/{slug(family)}/{candidate}", licence)
                break
            except urllib.error.HTTPError:
                continue
    return got


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--family", action="append", default=[])
    ap.add_argument("--styles", help="comma list, e.g. Regular,Medium,SemiBold,Bold")
    ap.add_argument("--shortlist", action="store_true",
                    help="fetch the identification candidates from assets/fonts/catalog.json")
    ap.add_argument("--out", default="work/fonts")
    args = ap.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    styles = [s.strip() for s in args.styles.replace(",", " ").split()] if args.styles else None

    families = list(args.family)
    if args.shortlist:
        catalog = json.loads((ASSETS / "fonts" / "catalog.json").read_text())
        families += catalog["identification_shortlist"]
    if not families:
        ap.error("give --family or --shortlist")

    for family in families:
        print(family)
        fetch(family, styles, out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
