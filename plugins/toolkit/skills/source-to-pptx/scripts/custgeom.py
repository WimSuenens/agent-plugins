"""SVG path -> DrawingML custom geometry.

Lets us author icons (and trace the logo) as ordinary SVG path data and drop the
result into a PowerPoint shape as a native <a:custGeom>, i.e. a real freeform
shape the user can select, recolour and node-edit -- no picture involved.
"""
from __future__ import annotations

import re
from typing import Callable, Iterable

from pptx.oxml.ns import nsdecls
from pptx.util import Emu

Point = tuple[float, float]

_TOKEN = re.compile(r"[MmLlHhVvCcSsQqTtZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")


class SubPath:
    """One contour: a start point, a list of ('L'|'C', pts) segments, closed flag."""

    def __init__(self, start: Point):
        self.start = start
        self.segs: list[tuple[str, tuple[Point, ...]]] = []
        self.closed = False

    def points(self) -> Iterable[Point]:
        yield self.start
        for _, pts in self.segs:
            yield from pts


def parse_path(d: str) -> list[SubPath]:
    """Parse SVG path data into absolute sub-paths of lines and cubic beziers."""
    tokens = _TOKEN.findall(d)
    i = 0
    subpaths: list[SubPath] = []
    cur: SubPath | None = None
    cmd = ""
    x = y = 0.0
    start_x = start_y = 0.0
    prev_ctrl: Point | None = None

    def num() -> float:
        nonlocal i
        v = float(tokens[i])
        i += 1
        return v

    while i < len(tokens):
        tok = tokens[i]
        if tok.isalpha():
            cmd = tok
            i += 1
        elif cmd in ("M", "m"):
            cmd = "L" if cmd == "M" else "l"
        rel = cmd.islower()
        c = cmd.upper()

        if c == "Z":
            if cur is not None:
                cur.closed = True
                x, y = start_x, start_y
            prev_ctrl = None
            continue
        if c == "M":
            dx, dy = num(), num()
            x, y = (x + dx, y + dy) if rel else (dx, dy)
            start_x, start_y = x, y
            cur = SubPath((x, y))
            subpaths.append(cur)
            prev_ctrl = None
        elif c in ("L", "H", "V"):
            if c == "L":
                dx, dy = num(), num()
                x, y = (x + dx, y + dy) if rel else (dx, dy)
            elif c == "H":
                dx = num()
                x = x + dx if rel else dx
            else:
                dy = num()
                y = y + dy if rel else dy
            assert cur is not None
            cur.segs.append(("L", ((x, y),)))
            prev_ctrl = None
        elif c in ("C", "S"):
            if c == "C":
                a1, b1, a2, b2, a3, b3 = (num() for _ in range(6))
                p1 = (x + a1, y + b1) if rel else (a1, b1)
                p2 = (x + a2, y + b2) if rel else (a2, b2)
                p3 = (x + a3, y + b3) if rel else (a3, b3)
            else:
                a2, b2, a3, b3 = (num() for _ in range(4))
                p1 = (2 * x - prev_ctrl[0], 2 * y - prev_ctrl[1]) if prev_ctrl else (x, y)
                p2 = (x + a2, y + b2) if rel else (a2, b2)
                p3 = (x + a3, y + b3) if rel else (a3, b3)
            assert cur is not None
            cur.segs.append(("C", (p1, p2, p3)))
            prev_ctrl = p2
            x, y = p3
        elif c in ("Q", "T"):
            if c == "Q":
                a1, b1, a2, b2 = (num() for _ in range(4))
                q = (x + a1, y + b1) if rel else (a1, b1)
                p = (x + a2, y + b2) if rel else (a2, b2)
            else:
                a2, b2 = num(), num()
                q = (2 * x - prev_ctrl[0], 2 * y - prev_ctrl[1]) if prev_ctrl else (x, y)
                p = (x + a2, y + b2) if rel else (a2, b2)
            p1 = (x + 2 / 3 * (q[0] - x), y + 2 / 3 * (q[1] - y))
            p2 = (p[0] + 2 / 3 * (q[0] - p[0]), p[1] + 2 / 3 * (q[1] - p[1]))
            assert cur is not None
            cur.segs.append(("C", (p1, p2, p)))
            prev_ctrl = q
            x, y = p
        else:  # unsupported (arcs): skip one number to stay in sync
            num()
    return subpaths


def bbox(subpaths: list[SubPath]) -> tuple[float, float, float, float]:
    xs = [p[0] for sp in subpaths for p in sp.points()]
    ys = [p[1] for sp in subpaths for p in sp.points()]
    return min(xs), min(ys), max(xs), max(ys)


def map_points(subpaths: list[SubPath], fn: Callable[[Point], Point]) -> list[SubPath]:
    out = []
    for sp in subpaths:
        n = SubPath(fn(sp.start))
        n.closed = sp.closed
        n.segs = [(k, tuple(fn(p) for p in pts)) for k, pts in sp.segs]
        out.append(n)
    return out


def custgeom_xml(
    subpaths: list[SubPath],
    cx: int,
    cy: int,
    src: tuple[float, float, float, float],
    filled: bool,
) -> str:
    """Render sub-paths into a <a:custGeom> sized to a cx*cy EMU shape.

    `src` is the (x0, y0, x1, y1) user-space box that maps onto the shape.
    """
    sx0, sy0, sx1, sy1 = src
    sw, sh = (sx1 - sx0) or 1.0, (sy1 - sy0) or 1.0

    def to_path(p: Point) -> tuple[int, int]:
        return (
            int(round((p[0] - sx0) / sw * cx)),
            int(round((p[1] - sy0) / sh * cy)),
        )

    fill = "norm" if filled else "none"
    body: list[str] = []
    for sp in subpaths:
        px, py = to_path(sp.start)
        body.append(f'<a:moveTo><a:pt x="{px}" y="{py}"/></a:moveTo>')
        for kind, pts in sp.segs:
            tag = "lnTo" if kind == "L" else "cubicBezTo"
            inner = "".join(
                '<a:pt x="{}" y="{}"/>'.format(*to_path(p)) for p in pts
            )
            body.append(f"<a:{tag}>{inner}</a:{tag}>")
        if sp.closed:
            body.append("<a:close/>")
    return (
        f"<a:custGeom {nsdecls('a')}>"
        "<a:avLst/><a:gdLst/><a:ahLst/><a:cxnLst/>"
        '<a:rect l="0" t="0" r="r" b="b"/>'
        f'<a:pathLst><a:path w="{cx}" h="{cy}" fill="{fill}" stroke="1">'
        + "".join(body)
        + "</a:path></a:pathLst></a:custGeom>"
    )


def apply_custgeom(shape, d: str, src: tuple[float, float, float, float], filled: bool = False):
    """Replace a shape's preset geometry with the geometry of SVG path data `d`."""
    from lxml import etree

    subpaths = parse_path(d)
    xml = custgeom_xml(subpaths, int(shape.width), int(shape.height), src, filled)
    sp_pr = shape._element.spPr
    prst = sp_pr.find(f"{{{sp_pr.nsmap['a']}}}prstGeom")
    new = etree.fromstring(xml)
    if prst is not None:
        sp_pr.replace(prst, new)
    else:
        sp_pr.insert(0, new)
    return shape


def emu(inches: float) -> int:
    return int(Emu(int(round(inches * 914400))))


def subpaths_to_d(subpaths: list[SubPath], nd: int = 3) -> str:
    """Serialise sub-paths back to absolute SVG path data."""
    def f(v: float) -> str:
        return f"{round(v, nd):g}"

    out: list[str] = []
    for sp in subpaths:
        out.append(f"M{f(sp.start[0])},{f(sp.start[1])}")
        for kind, pts in sp.segs:
            if kind == "L":
                out.append(f"L{f(pts[0][0])},{f(pts[0][1])}")
            else:
                out.append("C" + " ".join(f"{f(p[0])},{f(p[1])}" for p in pts))
        if sp.closed:
            out.append("Z")
    return "".join(out)
