#!/usr/bin/env python3
"""WCAG 2.x contrast ratios for colour pairs.

Usage:
  contrast.py FG BG [FG BG ...]        e.g. contrast.py "#6b7280" "#ffffff" "#fff" "#2563eb"
  contrast.py --level AAA FG BG ...

Accepts #rgb, #rrggbb and #rrggbbaa (alpha is composited over BG).
Prints each pair's ratio and its pass/fail for normal text, large text and
UI components (non-text). Exits 1 if any pair fails normal text at the
chosen level, so it can gate a script.
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


def ratio(fg_hex, bg_hex):
    bg, _ = parse(bg_hex)
    fg, alpha = parse(fg_hex)
    fg = composite(fg, alpha, bg)
    hi, lo = sorted((luminance(fg), luminance(bg)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def main(argv):
    level = "AA"
    if argv[:1] == ["--level"]:
        level, argv = argv[1].upper(), argv[2:]
    if not argv or len(argv) % 2:
        print(__doc__)
        return 2
    t = THRESHOLDS[level]
    failed = False
    for fg, bg in zip(argv[::2], argv[1::2]):
        r = ratio(fg, bg)
        marks = {k: ("pass" if r >= v else "FAIL") for k, v in t.items()}
        failed |= marks["text"] == "FAIL"
        print(f"{fg} on {bg}: {r:.2f}:1  text {marks['text']}  large {marks['large']}  ui {marks['ui']}  ({level})")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
