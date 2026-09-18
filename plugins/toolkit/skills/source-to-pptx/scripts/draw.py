"""Thin drawing helpers over python-pptx: shapes, strokes, text lines, icons."""
from __future__ import annotations

import sys
from pathlib import Path

from lxml import etree
from pptx.enum.shapes import MSO_CONNECTOR, MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.oxml.ns import qn
from pptx.util import Emu, Inches, Pt

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import ASCENT, DESCENT  # noqa: E402
from custgeom import apply_custgeom, bbox, parse_path  # noqa: E402

A_NS = "http://schemas.openxmlformats.org/drawingml/2006/main"


def hexrgb(value: str):
    from pptx.dml.color import RGBColor

    return RGBColor.from_string(value)


# --- raw XML helpers ---------------------------------------------------------

def _insert_after_fill(sp_pr, element) -> None:
    """spPr children follow a fixed order; effectLst goes after ln/fill."""
    for tag in ("a:ln", "a:blipFill", "a:gradFill", "a:solidFill", "a:noFill",
                "a:prstGeom", "a:custGeom"):
        found = sp_pr.findall(qn(tag))
        if found:
            found[-1].addnext(element)
            return
    sp_pr.append(element)


def soft_shadow(shape, blur_pt=9.0, dist_pt=2.5, alpha=0.13, color="404040") -> None:
    xml = (
        '<a:effectLst xmlns:a="{ns}">'
        '<a:outerShdw blurRad="{blur}" dist="{dist}" dir="5400000" rotWithShape="0">'
        '<a:srgbClr val="{col}"><a:alpha val="{alpha}"/></a:srgbClr>'
        "</a:outerShdw></a:effectLst>"
    ).format(ns=A_NS, blur=int(blur_pt * 12700), dist=int(dist_pt * 12700),
             col=color, alpha=int(alpha * 100000))
    sp_pr = shape._element.spPr
    element = etree.fromstring(xml)
    existing = sp_pr.find(qn("a:effectLst"))  # shadow.inherit = False leaves an empty one
    if existing is not None:
        sp_pr.replace(existing, element)
    else:
        _insert_after_fill(sp_pr, element)


def no_shadow(shape) -> None:
    shape.shadow.inherit = False


def round_stroke(shape) -> None:
    """Round caps and joins, matching the source icon style."""
    ln = shape._element.spPr.find(qn("a:ln"))
    if ln is None:
        return
    ln.set("cap", "rnd")
    join = etree.Element(qn("a:round"))
    tail = ln.find(qn("a:tailEnd"))
    if tail is not None:  # schema order: round comes before head/tailEnd
        tail.addprevious(join)
    else:
        ln.append(join)


def arrow_end(shape, size="med") -> None:
    """Put an arrowhead on the shape's end point.

    A connector drawn right-to-left is stored flipped, which swaps which end of
    the path is visually last -- so on an odd number of flips the head belongs
    on headEnd instead, or the arrow points backwards.
    """
    sp_pr = shape._element.spPr
    ln = sp_pr.find(qn("a:ln"))
    xfrm = sp_pr.find(qn("a:xfrm"))
    flips = 0
    if xfrm is not None:
        flips = sum(xfrm.get(f) in ("1", "true") for f in ("flipH", "flipV"))
    tag = "a:headEnd" if flips % 2 else "a:tailEnd"
    ln.append(etree.Element(qn(tag), type="triangle", w=size, len=size))


# --- shapes ------------------------------------------------------------------

def rect(shapes, x, y, w, h, *, radius=None, fill=None, gradient=None,
         line=None, line_pt=1.0, name=None):
    kind = MSO_SHAPE.ROUNDED_RECTANGLE if radius is not None else MSO_SHAPE.RECTANGLE
    shp = shapes.add_shape(kind, Inches(x), Inches(y), Inches(w), Inches(h))
    if radius is not None:
        shp.adjustments[0] = radius
    if gradient:
        shp.fill.gradient()
        shp.fill.gradient_angle = 45.0
        stops = shp.fill.gradient_stops
        stops[0].color.rgb = hexrgb(gradient[0])
        stops[0].position = 0.0
        stops[1].color.rgb = hexrgb(gradient[1])
        stops[1].position = 1.0
    elif fill:
        shp.fill.solid()
        shp.fill.fore_color.rgb = hexrgb(fill)
    else:
        shp.fill.background()
    if line:
        shp.line.color.rgb = hexrgb(line)
        shp.line.width = Pt(line_pt)
    else:
        shp.line.fill.background()
    shp.text_frame.word_wrap = False
    no_shadow(shp)
    if name:
        shp.name = name
    return shp


def line_shape(shapes, x1, y1, x2, y2, *, color, width_pt, name=None):
    con = shapes.add_connector(MSO_CONNECTOR.STRAIGHT, Inches(x1), Inches(y1),
                               Inches(x2), Inches(y2))
    con.line.color.rgb = hexrgb(color)
    con.line.width = Pt(width_pt)
    round_stroke(con)
    if name:
        con.name = name
    return con


def freeform(shapes, d, x, y, w, h, src, *, color=None, width_pt=None, fill=None,
             name=None):
    shp = shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(x), Inches(y),
                           Emu(max(1, int(w * 914400))), Emu(max(1, int(h * 914400))))
    if fill:
        shp.fill.solid()
        shp.fill.fore_color.rgb = hexrgb(fill)
        shp.line.fill.background()
    else:
        shp.fill.background()
        shp.line.color.rgb = hexrgb(color)
        shp.line.width = Pt(width_pt)
    no_shadow(shp)
    apply_custgeom(shp, d, src, filled=bool(fill))
    if not fill:
        round_stroke(shp)
    shp.text_frame.word_wrap = False
    if name:
        shp.name = name
    return shp


# --- text --------------------------------------------------------------------

def _no_autofit(tf) -> None:
    bodyPr = tf._txBody.bodyPr
    for tag in ("a:normAutofit", "a:spAutoFit", "a:noAutofit"):
        for el in bodyPr.findall(qn(tag)):
            bodyPr.remove(el)
    bodyPr.append(etree.Element(qn("a:noAutofit")))


def text_line(shapes, runs, *, left, width, baseline, align=PP_ALIGN.CENTER, name=None,
              ascent=ASCENT, descent=DESCENT):
    """One line of text placed by its baseline.

    `runs` is a list of dicts with text/size/font/bold/color. The box top is
    baseline - ascent, so glyphs land exactly where they were measured.
    """
    top_size = max(r["size"] for r in runs)
    top = baseline - top_size * ascent / 72
    height = top_size * (ascent + descent) / 72
    box = shapes.add_textbox(Inches(left), Inches(top), Inches(width), Inches(height))
    tf = box.text_frame
    tf.word_wrap = False
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = MSO_ANCHOR.TOP
    p = tf.paragraphs[0]
    p.alignment = align
    p.line_spacing = 1.0
    for spec in runs:
        r = p.add_run()
        r.text = spec["text"]
        r.font.size = Pt(spec["size"])
        r.font.name = spec["font"]
        r.font.bold = spec.get("bold", False)
        r.font.color.rgb = hexrgb(spec["color"])
    _no_autofit(tf)
    if name:
        box.name = name
    return box


def _check_bullet(paragraph, color, offset_in, char, font, size_pct) -> None:
    pPr = paragraph._p.get_or_add_pPr()
    marL = int(offset_in * 914400)
    pPr.set("marL", str(marL))
    pPr.set("indent", str(-marL))
    xml = (
        '<a:root xmlns:a="{ns}">'
        '<a:buClr><a:srgbClr val="{col}"/></a:buClr>'
        '<a:buSzPct val="{pct}"/>'
        '<a:buFont typeface="{bfont}" pitchFamily="2" charset="2"/>'
        '<a:buChar char="{ch}"/></a:root>'
    ).format(ns=A_NS, col=color, pct=int(size_pct * 1000), bfont=font, ch=char)
    for child in etree.fromstring(xml):
        pPr.append(child)


def bullet_list(shapes, items, *, left, width, first_baseline, spacing, size, font,
                color, bullet_color, text_offset, char="ü", bullet_font="Wingdings",
                size_pct=120, ascent=ASCENT, descent=DESCENT, name=None):
    top = first_baseline - size * ascent / 72
    height = spacing * (len(items) - 1) + size * (ascent + descent) / 72
    box = shapes.add_textbox(Inches(left), Inches(top), Inches(width), Inches(height))
    tf = box.text_frame
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = MSO_ANCHOR.TOP
    for i, item in enumerate(items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = PP_ALIGN.LEFT
        p.line_spacing = Pt(spacing * 72)
        p.space_before = Pt(0)
        p.space_after = Pt(0)
        r = p.add_run()
        r.text = item
        r.font.size = Pt(size)
        r.font.name = font
        r.font.color.rgb = hexrgb(color)
        _check_bullet(p, bullet_color, text_offset, char, bullet_font, size_pct)
    _no_autofit(tf)
    if name:
        box.name = name
    return box


# --- icons -------------------------------------------------------------------

def icon_bbox(prims) -> tuple[float, float, float, float]:
    xs, ys = [], []
    for kind, spec in prims:
        if kind in ("oval", "dot"):
            x, y, w, h = spec
            xs += [x, x + w]
            ys += [y, y + h]
        else:
            x0, y0, x1, y1 = bbox(parse_path(spec))
            xs += [x0, x1]
            ys += [y0, y1]
    return min(xs), min(ys), max(xs), max(ys)


def draw_icon(shapes, prims, *, center_x, top, height, color, stroke_pt, name):
    """Draw a 64-grid icon so its artwork is `height` inches tall, centred on x."""
    ax0, ay0, ax1, ay1 = icon_bbox(prims)
    s = height / (ay1 - ay0)
    ox = center_x - (ax0 + ax1) / 2 * s
    oy = top - ay0 * s

    def X(v):
        return ox + v * s

    def Y(v):
        return oy + v * s

    parts = []
    label = name.replace("Icon ", "")
    for n, (kind, spec) in enumerate(prims, start=1):
        if kind in ("oval", "dot"):
            x, y, w, h = spec
            shp = shapes.add_shape(MSO_SHAPE.OVAL, Inches(X(x)), Inches(Y(y)),
                                   Inches(w * s), Inches(h * s))
            if kind == "dot":
                shp.fill.solid()
                shp.fill.fore_color.rgb = hexrgb(color)
                shp.line.fill.background()
            else:
                shp.fill.background()
                shp.line.color.rgb = hexrgb(color)
                shp.line.width = Pt(stroke_pt)
            no_shadow(shp)
            shp.text_frame.word_wrap = False
            shp.name = f"{label} {n}"
            parts.append(shp)
            continue

        if kind == "fill":
            sub = parse_path(spec)
            x0, y0, x1, y1 = bbox(sub)
            shp = freeform(shapes, spec, X(x0), Y(y0), (x1 - x0) * s, (y1 - y0) * s,
                           (x0, y0, x1, y1), fill=color, name=f"{label} {n}")
            parts.append(shp)
            continue

        sub = parse_path(spec)
        straight = (len(sub) == 1 and len(sub[0].segs) == 1
                    and sub[0].segs[0][0] == "L")
        if straight:
            (x1, y1) = sub[0].start
            (x2, y2) = sub[0].segs[0][1][0]
            shp = line_shape(shapes, X(x1), Y(y1), X(x2), Y(y2),
                             color=color, width_pt=stroke_pt)
        else:
            x0, y0, x1, y1 = bbox(sub)
            shp = freeform(shapes, spec, X(x0), Y(y0), (x1 - x0) * s, (y1 - y0) * s,
                           (x0, y0, x1, y1), color=color, width_pt=stroke_pt)
        if kind == "arrowpath":
            arrow_end(shp)
        shp.name = f"{label} {n}"
        parts.append(shp)

    return group(shapes, parts, name)


def group(shapes, members, name: str):
    """Wrap already-placed shapes in a group spanning their union box."""
    grp = shapes.add_group_shape()
    grp.name = name
    for shp in members:
        grp._element.append(shp._element)
    left = min(s.left for s in members)
    top = min(s.top for s in members)
    right = max(s.left + s.width for s in members)
    bottom = max(s.top + s.height for s in members)
    grp.left, grp.top = Emu(int(left)), Emu(int(top))
    grp.width, grp.height = Emu(int(right - left)), Emu(int(bottom - top))
    xfrm = grp._element.find(qn("p:grpSpPr")).find(qn("a:xfrm"))
    xfrm.find(qn("a:chOff")).set("x", str(int(left)))
    xfrm.find(qn("a:chOff")).set("y", str(int(top)))
    xfrm.find(qn("a:chExt")).set("cx", str(int(right - left)))
    xfrm.find(qn("a:chExt")).set("cy", str(int(bottom - top)))
    return grp


# --- text blocks, rules and tables -------------------------------------------

def textbox(shapes, paragraphs, *, left, top, width, height, align=PP_ALIGN.LEFT,
            anchor=MSO_ANCHOR.TOP, line_spacing=None, space_after=0, wrap=True,
            name=None):
    """A wrapped block of text: what document-like pages are mostly made of.

    `paragraphs` is a list of run-lists, one per paragraph, each run a dict of
    text/size/font/bold/color. Unlike `text_line`, the block is positioned by
    its box rather than by a baseline, because wrapped copy has no single one.
    """
    box = shapes.add_textbox(Inches(left), Inches(top), Inches(width), Inches(height))
    tf = box.text_frame
    tf.word_wrap = wrap
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    tf.vertical_anchor = anchor
    for i, runs in enumerate(paragraphs):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        if line_spacing:
            p.line_spacing = line_spacing
        p.space_before = Pt(0)
        p.space_after = Pt(space_after)
        for spec in runs:
            r = p.add_run()
            r.text = spec["text"]
            r.font.size = Pt(spec["size"])
            r.font.name = spec["font"]
            r.font.bold = spec.get("bold", False)
            r.font.italic = spec.get("italic", False)
            r.font.color.rgb = hexrgb(spec["color"])
    _no_autofit(tf)
    if name:
        box.name = name
    return box


def ellipse(shapes, x, y, w, h, *, fill=None, line=None, line_pt=1.0, name=None):
    shp = shapes.add_shape(MSO_SHAPE.OVAL, Inches(x), Inches(y), Inches(w), Inches(h))
    if fill:
        shp.fill.solid()
        shp.fill.fore_color.rgb = hexrgb(fill)
    else:
        shp.fill.background()
    if line:
        shp.line.color.rgb = hexrgb(line)
        shp.line.width = Pt(line_pt)
    else:
        shp.line.fill.background()
    no_shadow(shp)
    shp.text_frame.word_wrap = False
    if name:
        shp.name = name
    return shp


def table(shapes, rows, *, left, top, width, height, font, size, color,
          header_fill=None, header_color=None, body_fill=None, col_widths=None,
          name=None):
    """A real PowerPoint table -- editable cell by cell, unlike a drawn grid."""
    n_rows, n_cols = len(rows), max(len(r) for r in rows)
    gfx = shapes.add_table(n_rows, n_cols, Inches(left), Inches(top),
                           Inches(width), Inches(height))
    tbl = gfx.table
    if col_widths:
        for i, frac in enumerate(col_widths[:n_cols]):
            tbl.columns[i].width = Inches(width * frac)
    for r, row in enumerate(rows):
        for c in range(n_cols):
            cell = tbl.cell(r, c)
            cell.text = str(row[c]) if c < len(row) else ""
            cell.margin_left = cell.margin_right = Inches(0.06)
            cell.margin_top = cell.margin_bottom = Inches(0.02)
            fill = header_fill if (r == 0 and header_fill) else body_fill
            if fill:
                cell.fill.solid()
                cell.fill.fore_color.rgb = hexrgb(fill)
            for p in cell.text_frame.paragraphs:
                for run in p.runs:
                    run.font.size = Pt(size)
                    run.font.name = font
                    run.font.bold = r == 0
                    run.font.color.rgb = hexrgb(
                        header_color if (r == 0 and header_color) else color)
    if name:
        gfx.name = name
    return gfx
