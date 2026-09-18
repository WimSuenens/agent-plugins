# OOXML mechanics behind the builder

What `draw.py`, `package.py` and `custgeom.py` do underneath, and the traps that
cost time. Read this when extending the builder, or when PowerPoint refuses a
file.

## Contents

- [When PowerPoint refuses to open a deck](#when-powerpoint-refuses-to-open-a-deck)
- [Shape property order](#shape-property-order)
- [Custom geometry](#custom-geometry)
- [Rounded rectangles and pictures](#rounded-rectangles-and-pictures)
- [Connectors and arrowheads](#connectors-and-arrowheads)
- [Groups](#groups)
- [Text frames and baselines](#text-frames-and-baselines)
- [Bullets](#bullets)
- [Theme colours](#theme-colours)
- [Embedded fonts](#embedded-fonts)

## When PowerPoint refuses to open a deck

The error is `0x80070570 ERROR_FILE_CORRUPT`, or a "repair" prompt. It is almost
always invalid XML in a shape, not a broken zip. Bisect: build each section of
the slide into its own file and open them one at a time. `render.ps1` is a good
gate here -- a successful COM `Open` proves the package is valid, which a visual
check does not.

Two real causes, both of which produce a perfectly reasonable-looking file:

**A duplicated `effectLst`.** python-pptx's `shape.shadow.inherit = False`
already writes an empty `<a:effectLst/>`. Appending a second one for a custom
shadow makes the document unreadable. `soft_shadow()` replaces the existing
element instead of adding one.

**A duplicated attribute.** `saveSubsetFonts` is already present on
`<p:presentation>` in the default template. Prepending another copy when
enabling font embedding yields `Attribute saveSubsetFonts redefined`, which
fails before anything else is parsed. `package._set_attr()` replaces when
present, prepends only when absent.

## Shape property order

`<p:spPr>` children follow a fixed sequence, and PowerPoint enforces it:

```
xfrm, <geometry: prstGeom|custGeom>, <fill>, ln, effectLst, scene3d, sp3d
```

Inside `<a:ln>`: fill, dash, join (`round`/`bevel`/`miter`), then `headEnd`,
then `tailEnd`. `round_stroke()` inserts `<a:round/>` *before* any existing
arrowhead for this reason. Appending in the wrong order is another way to get a
file that will not open.

## Custom geometry

`custgeom.py` turns SVG path data into `<a:custGeom>`, which is a real freeform
shape -- selectable, recolourable and node-editable, with no "convert to shape"
step. It parses `M/L/H/V/C/S/Q/T/Z` (absolute and relative), converts quadratics
to cubics, and emits `moveTo`, `lnTo`, `cubicBezTo`, `close` in a path space
sized to the shape's EMU extent.

- **Holes work by even-odd fill.** All sub-paths go into one `<a:path>`, so the
  counter of an `o` or the interior of a traced map renders as a hole. Splitting
  them into separate paths fills the holes in.
- **Open paths** set `fill="none" stroke="1"`; closed traced artwork uses
  `fill="norm"`.
- **A degenerate box breaks it.** A purely horizontal or vertical path has zero
  height or width, and every point collapses. `draw_icon` detects a two-point
  straight path and emits a connector instead -- which is also the more natural
  object for a rule.
- Arcs (`A`) are not implemented; potrace never emits them and hand-authored
  icons do not need them.

## Rounded rectangles and pictures

`roundRect`'s `adj` is **a fraction of the shorter side**, not an absolute
radius: `adj = radius_in / min(w, h)`, stored as `val="{adj * 100000}"`. The same
radius therefore needs a different `adj` on a tall card and a wide panel, which
is why the spec takes a radius in pixels and converts per shape.

A picture gets rounded corners by swapping its `<a:prstGeom>` for `roundRect`
(`set_prst_geom`). It stays a picture -- cropping it into a shape with a picture
fill would work too but makes it harder to replace later.

## Connectors and arrowheads

A connector drawn right-to-left is stored left-to-right with `flipH="1"`. The
flip also swaps which end of the path is last, so `tailEnd` renders at the
*start* of the visible line. `arrow_end()` counts the flips and uses `headEnd`
when there is an odd number.

The symptom is an arrow pointing backwards -- a dart that leaves the bullseye
instead of entering it. The robust alternative, when a shape must have its head
at a specific end, is to make the path three points instead of two: it then goes
through the freeform branch, where no flip is applied and `tailEnd` is
unambiguous.

## Groups

python-pptx can add a group shape, but the extents need setting by hand. A group
carries both its own offset/extent (`a:off`/`a:ext`) and its child coordinate
space (`a:chOff`/`a:chExt`). Setting the child space **equal to** the group's own
box means children keep absolute slide coordinates and nothing shifts when they
are moved into the group. `draw.group()` does this after computing the union box
of its members.

## Text frames and baselines

Text is positioned by baseline, not by box: `top = baseline - size * ascent`,
where `ascent` is the font's own hhea ascender over unitsPerEm. `build_deck.py`
reads it from the actual TTF, so switching families does not shift every line.
Frame height is `size * (ascent + descent)`.

Also needed on every frame: zero margins on all four sides, `<a:noAutofit/>`
(or PowerPoint reflows the text and the measurement stops meaning anything), and
`word_wrap = False` for single lines so a slightly-too-narrow box cannot wrap.

Runs of different sizes in one paragraph share a baseline, and the line's ascent
comes from the largest run -- which is why the frame top is computed from the
largest size.

## Bullets

A bullet is a paragraph property, not a shape, so the list reflows when edited:

```xml
<a:pPr marL="317297" indent="-317297">
  <a:buClr><a:srgbClr val="DDA92F"/></a:buClr>
  <a:buSzPct val="120000"/>
  <a:buFont typeface="Wingdings" pitchFamily="2" charset="2"/>
  <a:buChar char="ü"/>
</a:pPr>
```

`marL` is the hanging indent in EMU and `indent` is its negative, which puts the
glyph at the frame's left edge and the text at `marL`. Wingdings `ü` is a check
mark, present on every Windows machine; `buSzPct` scales it relative to the text,
and 110-125% usually matches a source whose checks look heavier than the body.

## Theme colours

`package.patch_theme()` rewrites `accent1`/`accent2` and the major/minor latin
typefaces in `ppt/theme/theme1.xml`. Shapes still carry explicit `srgbClr`
values, so the theme is not what drives them -- but setting it means the deck's
colour and font pickers show the right palette, which is what someone editing it
afterwards will reach for.

## Embedded fonts

Four things have to line up, and missing any one leaves the font silently
unembedded:

1. the font bytes as a part, `ppt/fonts/fontN.fntdata` (raw TTF);
2. an `<Override>` in `[Content_Types].xml` with
   `ContentType="application/x-fontdata"`;
3. a relationship from `ppt/_rels/presentation.xml.rels` with the `font`
   relationship type;
4. `<p:embeddedFontLst>` in `presentation.xml`, placed **after `<p:notesSz/>`**
   (element order is enforced), plus `embedTrueTypeFonts="1"` and
   `saveSubsetFonts="0"` on `<p:presentation>`.

Each `<p:embeddedFont>` names one typeface and points at up to four faces
(`regular`, `bold`, `italic`, `boldItalic`). A weight that is neither regular nor
bold is embedded as its own family -- `Barlow Semi Condensed Medium` with a
`regular` face -- matching how the static font names itself.

To test it, render on a machine where the font is *not* installed. If the render
shows the right typeface, embedding works; opening it where the font is installed
proves nothing.

Check `fsType` before embedding a licensed font: 0 means installable. OFL fonts
are 0 and safe.
