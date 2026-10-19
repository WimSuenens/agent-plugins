#!/usr/bin/env python3
"""WCAG 2.x contrast ratios for colour pairs.

Usage:
  contrast.py [--level AA|AAA] [--kind text|large|ui] [--over HEX] FG BG [FG BG ...]

  --kind   which threshold gates the exit code (default: text).
           text  = body text (AA 4.5:1), large = large text (AA 3:1),
           ui    = UI components, borders, focus rings, meaningful icons (3:1).
  --over   opaque colour behind a translucent BG (a scrim or chip over a
           photo): BG is composited over it first. Run once per extreme
           (lightest and darkest content) to cover every image.

Accepts #rgb, #rgba, #rrggbb and #rrggbbaa. A translucent FG is composited
over BG. Prints each pair's ratio with pass/fail for all three kinds, and
exits 1 if any pair fails the --kind threshold at --level.

Examples:
  contrast.py "#565d52" "#ffffff"                     body text on white
  contrast.py --kind ui "#858c80" "#ffffff"           input border on white
  contrast.py --kind ui --over "#ffffff" "#1b1f1a" "#000000b3"
                                                     dark icon on a 70% black chip over a white photo
"""
import sys

THRESHOLDS = {
    "AA": {"text": 4.5, "large": 3.0, "ui": 3.0},
    "AAA": {"text": 7.0, "large": 4.5, "ui": 3.0},
}


def parse(hex_colour):
    h = hex_colour.strip().lstrip("#")
    if len(h) in (3, 4):
        h = "".join(c * 2 for c in h)
    if len(h) not in (6, 8):
        raise ValueError(f"not a hex colour: {hex_colour}")
    channels = [int(h[i:i + 2], 16) / 255 for i in range(0, len(h), 2)]
    return channels[:3], (channels[3] if len(channels) == 4 else 1.0)


def composite(fg, alpha, bg):
    return [alpha * f + (1 - alpha) * b for f, b in zip(fg, bg)]


def luminance(rgb):
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(fg_hex, bg_hex, over_hex=None):
    bg, bg_alpha = parse(bg_hex)
    if bg_alpha < 1:
        if over_hex is None:
            raise ValueError(f"{bg_hex} is translucent: pass --over with the colour behind it")
        bg = composite(bg, bg_alpha, parse(over_hex)[0])
    fg, alpha = parse(fg_hex)
    fg = composite(fg, alpha, bg)
    hi, lo = sorted((luminance(fg), luminance(bg)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def main(argv):
    level, kind, over = "AA", "text", None
    while argv[:1] and argv[0].startswith("--"):
        flag, value, argv = argv[0], argv[1], argv[2:]
        if flag == "--level":
            level = value.upper()
        elif flag == "--kind":
            kind = value.lower()
        elif flag == "--over":
            over = value
        else:
            print(__doc__)
            return 2
    if not argv or len(argv) % 2 or level not in THRESHOLDS or kind not in THRESHOLDS[level]:
        print(__doc__)
        return 2
    t = THRESHOLDS[level]
    failed = False
    for fg, bg in zip(argv[::2], argv[1::2]):
        try:
            r = ratio(fg, bg, over)
        except ValueError as err:
            print(f"error: {err}", file=sys.stderr)
            return 2
        marks = {k: ("pass" if r >= v else "FAIL") for k, v in t.items()}
        failed |= marks[kind] == "FAIL"
        where = f" (over {over})" if over and parse(bg)[1] < 1 else ""
        print(f"{fg} on {bg}{where}: {r:.2f}:1  text {marks['text']}  large {marks['large']}  ui {marks['ui']}  ({level}, gating {kind})")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
