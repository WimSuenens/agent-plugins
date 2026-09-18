# The deck spec

`build_deck.py` contains no layout. Everything measured goes in `work/spec.json`,
which is therefore the thing to iterate on during review.

## Contents

- [Shape of the file](#shape-of-the-file)
- [Coordinates](#coordinates)
- [Element types](#element-types)
- [Runs](#runs)
- [Worked example](#worked-example)

## Shape of the file

```jsonc
{
  "deck": {
    "output": "../build/deck.pptx",       // relative to the spec file
    "slide_w_in": 13.3333,
    "slide_h_in": 7.5,
    "traced": "traced.json",              // or a list; merged, keyed by name
    "theme": {
      "accent1": "0B2240",                // also accent2, dk1, lt1, dk2, lt2
      "major_font": "Barlow",             // theme heading font
      "minor_font": "Barlow Semi Condensed"
    },
    "fonts": {
      "dir": "fonts",                     // relative to the spec file
      "embed": true,
      "families": {
        "Barlow": {"regular": "Barlow-SemiBold.ttf", "bold": "Barlow-Bold.ttf"},
        "Barlow Semi Condensed Medium": {"regular": "BarlowSemiCondensed-Medium.ttf"}
      }
    }
  },
  "defaults": {"px_per_in": 115.2, "font": "Barlow Semi Condensed",
               "color": "0B2240", "pt": 18},
  "slides": [ { /* one per page */ } ]
}
```

Each slide:

```jsonc
{
  "name": "ACME-MARKET",
  "source": "page-01.png",      // used by compare.py for the side-by-side
  "px_per_in": 115.2,
  "background": "F9FAFB",
  "bands": { "cards": {"src0": 266, "origin_in": 1.89, "scale": 0.8732} },
  "elements": [ /* drawn in order, so later elements sit on top */ ]
}
```

**Font family naming.** A weight that is neither Regular nor Bold is addressed as
its own family -- `Barlow Semi Condensed Medium`, not the base family with a
weight attribute. That is how the static fonts are named and how PowerPoint finds
them. Use `b: true` only for the actual Bold face.

Every family listed in `fonts.families` whose files exist gets embedded, so the
deck renders correctly on machines without the font installed. Set
`fonts.embed: false` (or `--no-embed`) when the deck only uses fonts that are
installed everywhere.

## Coordinates

Any geometry field can be given two ways:

- `*_px` -- source pixels, converted with the slide's `px_per_in`, and passed
  through the element's `band` on the y-axis.
- `*_in` -- inches on the slide, used as-is.

Use pixels wherever the value was measured, so it stays traceable to the source.
Use inches for things the source cannot tell you, like a footer baseline that had
to be moved after the layout was re-proportioned.

**Bands** map a range of source y-coordinates onto the slide:

```
y_in = origin_in + (y_px - src0) * scale / px_per_in
```

A length on the y-axis is scaled but not offset. x is never scaled -- which is
why point sizes measured on the source transfer unchanged. See
`layout-mapping.md` for choosing bands.

`keep_aspect: "left" | "center" | "right"` recomputes an element's width from its
height and the artwork's own proportions. Anything with fixed proportions inside
a compressed band needs it, or it comes out stretched.

## Element types

Common to all: `type`, `name` (what shows in PowerPoint's selection pane -- worth
setting), `band`.

| Type | Geometry | Key fields |
|---|---|---|
| `rect` | `box_px [x0,y0,x1,y1]` or `box_in [x,y,w,h]` | `fill`, `gradient: [from,to]`, `line`, `line_pt`, `radius_px`, `shadow` |
| `ellipse` | as `rect` | `fill`, `line`, `line_pt` |
| `line` | `from_px [x,y]`, `to_px [x,y]` | `color`, `width_pt`, `arrow` |
| `picture` | box | `file` (relative to the spec), `radius_px`, `shadow`, `keep_aspect` |
| `text` | `left_px`, `width_px`, `baseline_px` | `runs`, `align: l\|c\|r` |
| `textbox` | box | `paragraphs` (list of run-lists), `align`, `anchor: t\|m\|b`, `line_spacing_pt`, `space_after_pt` |
| `bullets` | `left_px`, `width_px`, `first_baseline_px`, `spacing_px` | `items`, `pt`, `font`, `color`, `bullet` |
| `table` | box | `rows`, `pt`, `font`, `color`, `header_fill`, `header_color`, `body_fill`, `col_widths` |
| `icon` | `center_x_px`, `top_px`, `height_px` | `icon` (library name) or `prims`, `color`, `stroke_pt` |
| `freeform` | box | `d` or `d_ref: "traced.json#name"`, `fill` or `line`+`line_pt`, `keep_aspect` |
| `group` | -- | `children` (elements), `name` |

Notes that matter in practice:

- **`text` vs `textbox`.** `text` is one line placed by its baseline: use it for
  anything positioned, which on a slide is nearly everything. `textbox` is a
  wrapped block placed by its box: use it for paragraphs of body copy, which is
  what document pages are mostly made of. Wrapped copy has no single baseline,
  so it cannot be placed by one.
- **`radius_px`** is a real radius in source pixels. The builder converts it to
  PowerPoint's `adj`, which is a fraction of the shorter side.
- **`shadow`** takes `true` or `{blur_pt, dist_pt, alpha, color}`.
- **`bullets`** reflow when the text is edited, so the bullet glyph is a bullet
  character, not a shape: `{"char": "ü", "font": "Wingdings", "color": "DDA92F",
  "size_pct": 120, "offset_px": 40}`. Wingdings `ü` is a check mark and is
  present on every Windows machine. `offset_px` is the hanging indent -- the gap
  from the bullet to the text.
- **`icon`** draws from `assets/icons/library.json` as native shapes: a group of
  freeforms, ovals and connectors. `height_px` is the artwork height; width
  follows from the artwork.
- **`group`** wraps its children so they move and scale as one object.

## Runs

A run is `{"t": text, "pt": size, "font": family, "b": bold, "i": italic, "c": hex}`.
Anything omitted falls back to `defaults`. Runs within one element share a
baseline, which is what makes `€400` + a smaller `M` a single element.

## Worked example

`assets/examples/acme-market.spec.json` is a complete dense slide: five KPI cards
with icons and three-line stacks, a photo with rounded corners, two panels (one
filled, one outlined), a traced two-colour logo, a traced map outline, two bullet
lists and a footer -- across three bands. Copy its shape rather than starting
from nothing.
