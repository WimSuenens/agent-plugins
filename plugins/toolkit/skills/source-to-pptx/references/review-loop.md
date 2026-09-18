# The review loop

Build, render, compare, fix, repeat. The loop is what turns a plausible rebuild
into a correct one, and skipping it is how a deck ships 20 px out of alignment
with nobody noticing until it is on a screen.

## Contents

- [Running it](#running-it)
- [What "close enough" means](#what-close-enough-means)
- [Reading the drift numbers](#reading-the-drift-numbers)
- [Symptom to cause](#symptom-to-cause)
- [Looking, not just measuring](#looking-not-just-measuring)
- [The editability check](#the-editability-check)

## Running it

```
run.ps1 . build_deck.py /work/work/spec.json
scripts\render.ps1 build\deck.pptx -Out work\review
run.ps1 . compare.py /work/work/spec.json --render /work/work/review --source /work/work
run.ps1 . verify.py /work/build/deck.pptx --expect-pictures 1
```

Render with PowerPoint where it exists. It is the renderer the file will be
opened in, and a successful `Open` also proves the package is valid -- a deck
that PowerPoint would offer to repair fails here rather than looking fine.
LibreOffice is the fallback; it is close on geometry and less exact on text, so
do not chase the last two pixels of a LibreOffice render.

## What "close enough" means

**Worst edge drift of about 5 px at 1536 px wide** -- roughly 0.04", or a third
of a point. Past that, something is wrong and the number will say what.

Some residual drift is measurement, not error:

- A block edge reported 1-2 px short is antialiasing on a rounded corner.
- A photograph whose sky is nearly white can read a few pixels in from its true
  edge, because the detector keys on saturation to ignore the drop shadow.
- Anything landing at exactly ±10 px -- the search window -- is not drift at all
  but a failed detection. Fix the predicate, not the layout.

## Reading the drift numbers

Each row prints expected, actual and the per-edge difference in the order
`x0, y0, x1, y1`.

| Pattern | Cause |
|---|---|
| Every block in one band off by the same amount, same direction | that band's `origin_in` |
| Top right, bottom wrong, growing down the band | that band's `scale` |
| One block off, neighbours fine | that element's `box_px` |
| Every edge exactly at ±window | detection failed (see below) |
| Blocks correct, text visibly off | a baseline, or a font-metric mismatch |

## Symptom to cause

**"-- not detected --"**, or every edge at the window bound. The colour
predicate is not finding the block. A near-white fill on a near-white page cannot
be colour-matched: `compare.py` tightens its tolerance to half the distance from
the background, and keys an outlined panel on its border rather than its fill.
Traced freeforms are excluded from detection entirely -- an outline's interior is
the block behind it, so probing across it finds nothing. Check those by eye.

**Text sits a few pixels right of the original.** Measured `left_px` is the ink
edge, but a text frame's left is where the glyph's side bearing starts. Nudge
`left_px` left by 3-8 px at display sizes.

**Text sits too high or too low, everything else fine.** The baseline was
measured off a line with a descender, so the box bottom was below the baseline.
Re-measure on a descender-free line in the same style.

**Every line in one style is off vertically by the same amount.** The font's
ascent. `build_deck.py` reads it from the TTF, so this usually means the family
in the spec has no entry in `fonts.families` and fell back to the 1.0/0.2
default.

**A line wraps that should not, or overflows its panel.** `width_px` is too
narrow. Widen it -- the width only bounds the frame, it does not affect where a
left-aligned line starts.

**A photo or logo looks subtly squashed.** A band compressed its height but not
its width. Set `keep_aspect`, and crop the source with `extract.py crop --aspect`
so the image already matches its frame.

**An arrow points the wrong way.** A flipped connector; see
`pptx-internals.md`.

**A traced shape is a solid blob.** Its sub-paths ended up in separate
`<a:path>` elements instead of one, so the even-odd holes filled in. Check with
`preview.py --traced`.

## Looking, not just measuring

The numbers confirm geometry. They say nothing about whether an icon reads
correctly, whether a weight is right, or whether a trace picked up the artwork
cleanly. Open `work/review/side-by-side.png` and look at it.

For detail, add zoom crops -- source and render side by side, with the render box
derived from the band so the two line up:

```
run.ps1 . compare.py /work/work/spec.json --render /work/work/review \
    --source /work/work --zoom 135,298,230,382:cards --zoom 1216,26,1500,122:top
```

This is where icons get fixed. A pictogram that scores perfectly on geometry can
still be the wrong pictogram.

## The editability check

```
run.ps1 . verify.py /work/build/deck.pptx --expect-pictures 1 --min-text 18
```

The point of the whole exercise is a deck someone can edit, and a rebuild can
look perfect while being a picture of a slide. `verify.py` prints every shape
with its kind, then the totals:

- **text** should roughly match the number of text lines on the page. A low
  count means text was flattened into shapes or pictures.
- **picture** should be the number of actual photographs -- pass
  `--expect-pictures` to make it fail rather than warn.
- **shape / connector / group** are the icons and traced artwork; `custGeom` in
  the listing confirms a freeform rather than a preset box.
- **embedded font parts** should match the number of faces in the spec.
- **theme accent1/2** should be the brand colours, not Office defaults.

Report these counts when handing over. They are the evidence that the deck is
editable, which a screenshot cannot show.
