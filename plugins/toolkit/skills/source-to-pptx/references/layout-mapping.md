# Fitting a page to a slide

A source page and the target slide rarely share proportions. A 3:2 mock-up, an A4
report page and a 16:9 deck all have to become slides, and how that is handled is
the difference between a rebuild that looks designed and one that looks squeezed.

## Contents

- [Decide the slide size first](#decide-the-slide-size-first)
- [When the aspect matches](#when-the-aspect-matches)
- [When it does not: bands](#when-it-does-not-bands)
- [What must never be scaled](#what-must-never-be-scaled)
- [Portrait pages](#portrait-pages)

## Decide the slide size first

Two defensible answers, and the user picks:

**Match the source aspect.** Set `slide_w_in`/`slide_h_in` to the page's own
proportions and every coordinate maps by a single division. A 1536x1024 source
becomes a 13.333 x 8.889" slide. Nothing moves, nothing compresses, and the
result is a pixel-faithful reproduction -- at a slide size that will not match
the rest of anyone's deck.

**Standard 16:9** (13.333 x 7.5"). Drops straight into an existing deck, and the
layout has to be re-proportioned vertically. This is usually what people want,
and it is what bands are for.

Either way, keep the **horizontal** mapping exact: `px_per_in = raster_width /
slide_width_in`. Because x is never scaled, every measured point size transfers
unchanged, which removes a whole class of error.

## When the aspect matches

Nothing to do. One `px_per_in`, no bands, `y_in = y_px / px_per_in`. A vector PDF
of a 16:9 deck lands here, and the rebuild can be within a pixel.

## When it does not: bands

Vertical space has to come from somewhere. Taking it out of the blocks squashes
the design; taking it out of the whitespace does not, because whitespace is the
most forgiving part of a layout.

A band maps a range of source y onto the slide:

```jsonc
"bands": {
  "top":    {"src0": 30,  "origin_in": 0.26, "scale": 0.88},
  "cards":  {"src0": 266, "origin_in": 1.89, "scale": 0.8732},
  "panels": {"src0": 647, "origin_in": 4.67, "scale": 0.8881}
}
```

`src0` is where the band starts in source pixels, `origin_in` is where it starts
on the slide, `scale` compresses everything inside it.

### Choosing them

1. Split the page into blocks -- title area, card row, panel row, footer -- with
   the gaps between them.
2. Add up the block heights and the gap heights in source pixels. Convert to
   inches with `px_per_in`; the total will overflow the slide.
3. Give the blocks a scale of about **0.85-0.92** and let the gaps take the rest.
   Below 0.85, cards start to look short for their width.
4. Set each band's `origin_in` to where its block should start, working down the
   slide. Check the last block plus the footer still clears the bottom margin.

One real case: a 3:2 page into 16:9 needed 15% of the height removed. Block
heights went to 0.87-0.89 and the gaps between blocks were roughly halved. The
cards went from 0.65 to 0.72 width-to-height, which reads as a deliberate
proportion rather than a compressed one.

### Sanity checks

- A block that lands uniformly off by the same amount on all four edges is an
  `origin_in` error.
- A block whose top is right and bottom is wrong is a `scale` error.
- Text drifting while its block holds means a baseline is outside the band it
  belongs to.

## What must never be scaled

A band compresses y and not x, so anything with fixed proportions distorts unless
it is protected:

- **Pictures** -- set `keep_aspect`, and crop the source with
  `extract.py crop --aspect` so the image already matches its frame. Cropping is
  almost always better than stretching; a squeezed photograph is obvious on
  anything with a horizon, a face or a circular logo in it.
- **Traced artwork** -- a logo or a map: `keep_aspect`.
- **Icons** -- the builder scales an icon by its height and derives the width
  from the artwork, so they are safe by construction.
- **Type** -- point sizes come from the horizontal scale and are never touched
  by a band. Text does not compress; only its baseline moves.

Because type does not compress, a block at scale 0.87 holds the same type in 13%
less height. Check the tight ones: a card with an icon, a big number and two
labels can run out of room. Either accept slightly tighter internal spacing, or
drop the type a point.

## Portrait pages

An A4 page on a 16:9 slide is a bad fit -- 0.71 against 1.78 -- and no amount of
banding fixes it. Three options, in order of preference:

1. **Match the page aspect** and make a portrait slide. Right for a document
   being made editable rather than presented.
2. **Split the page across slides** at a natural break. Right when the content is
   sectioned already.
3. **Re-lay the content** into two columns on a landscape slide. A redesign, not
   a rebuild -- say so explicitly, because the result will not compare against
   the source and `compare.py` numbers stop being meaningful.

For a document-like page, reach for `textbox` rather than `text`: body copy is
wrapped paragraphs, and placing each line by its own baseline both defeats
editing and breaks the moment anyone types a word.
