"""Shared bits: where the skill lives, colour helpers, image loading."""
from __future__ import annotations

import os
from pathlib import Path

import numpy as np
from PIL import Image

SKILL = Path(os.environ.get("PAGE2PPTX_SKILL", Path(__file__).resolve().parent.parent))
ASSETS = SKILL / "assets"

# Barlow-ish defaults; build_deck overrides them per family from the real TTF.
ASCENT, DESCENT, CAP = 1.00, 0.20, 0.70


def load_rgb(path: str | Path) -> np.ndarray:
    """Page image as an int array, shape (h, w, 3)."""
    return np.asarray(Image.open(path).convert("RGB")).astype(int)


def hexstr(rgb) -> str:
    return "%02X%02X%02X" % tuple(int(round(v)) for v in rgb[:3])


def unhex(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def near(a: np.ndarray, colour: str, tol: int = 40) -> np.ndarray:
    """Mask of pixels within `tol` of a hex colour, per channel."""
    r, g, b = unhex(colour)
    return ((abs(a[..., 0] - r) < tol) & (abs(a[..., 1] - g) < tol)
            & (abs(a[..., 2] - b) < tol))


def is_background(a: np.ndarray, floor: int = 232, spread: int = 14) -> np.ndarray:
    """Light, near-neutral pixels -- the page background.

    Keyed on neutrality as well as lightness so a soft drop shadow, which is
    light but still neutral, is treated as background rather than as content.
    """
    return (a.min(axis=-1) > floor) & ((a.max(axis=-1) - a.min(axis=-1)) < spread)


def tight_box(mask: np.ndarray, window=None):
    """Tight (x0, y0, x1, y1) of True pixels, optionally inside a window."""
    if window:
        x0, y0, x1, y1 = (int(v) for v in window)
        sub = mask[y0:y1, x0:x1]
    else:
        x0, y0 = 0, 0
        sub = mask
    ys, xs = np.nonzero(sub)
    if not len(xs):
        return None
    return (x0 + int(xs.min()), y0 + int(ys.min()),
            x0 + int(xs.max()), y0 + int(ys.max()))


def runs(mask_row: np.ndarray, min_len: int = 1) -> list[tuple[int, int]]:
    """Contiguous True runs in a 1-D mask, as inclusive (start, end) pairs."""
    out, start = [], None
    for i, v in enumerate(mask_row):
        if v and start is None:
            start = i
        elif not v and start is not None:
            if i - start >= min_len:
                out.append((start, i - 1))
            start = None
    if start is not None and len(mask_row) - start >= min_len:
        out.append((start, len(mask_row) - 1))
    return out
