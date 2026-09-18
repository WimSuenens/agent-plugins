# Measuring a raster page

Everything the spec needs comes from pixels: block boxes, corner radii, colours,
text baselines, type sizes. The measurements are easy to take and easy to take
wrongly, and a wrong measurement does not look wrong -- it produces a number that
is plausible, builds fine, and leaves the result subtly off.

## Contents

- [Start with the page, not the details](#start-with-the-page-not-the-details)
- [The window rule](#the-window-rule)
- [Choosing a colour predicate](#choosing-a-colour-predicate)
- [Finding blocks](#finding-blocks)
- [Text: boxes, baselines, sizes](#text-boxes-baselines-sizes)
- [Identifying the typeface](#identifying-the-typeface)
- [Things that are not what they look like](#things-that-are-not-what-they-look-like)

## Start with the page, not the details

```
probe.py palette page.png              # the palette, by coverage
probe.py blocks  page.png --min-side 60 # cards, panels, photos: box, fill, radius
probe.py cols    page.png --window 60,260,1480,620   # column positions and gaps
```

`blocks` usually recovers the whole skeleton in one call -- every card and panel
with its fill colour and corner radius. Take its numbers as the frame, then
measure text inside each block.

The first number to fix is **px_per_in**: the page raster's width divided by the
target slide width in inches. At 1536 px on a 13.333" slide that is 115.2. Every
point size in the spec follows from it (`pt = px * 72 / px_per_in`), so getting
it wrong scales all the type at once.

## The window rule

Every measurement takes a window, and the window must sit **strictly inside**
whatever is being measured. A window that overhangs a card by even a few pixels
picks up the page background, and since the page is usually light, a "white text"
probe then returns the entire window.

This is the single most common cause of nonsense measurements. The symptom is
obvious once recognised: the returned box is exactly the window, or its width is
the window width minus a pixel or two.

Once a block's position is roughly known, prefer `edges` over `box`:

```
probe.py edges page.png --expect 69,266,290,605 --color 0B2240
```

`edges` looks for each edge only within ±10 px of where it is expected, so a
neighbouring card of the same colour cannot be swallowed into the result. `box`
scans a whole window and will happily merge two cards into one.

## Choosing a colour predicate

| Option | Matches | Use for |
|---|---|---|
| `--color HEX [--tol N]` | within N per channel | text or fills of a known colour |
| `--content` (default) | anything not light-and-neutral | isolated artwork on a plain page |
| `--ink` | saturated or dark pixels | content next to a soft shadow |

Two traps:

**Shadows read as content.** A soft drop shadow is light but *neutral*, so
`--content` excludes it by design (it keys on neutrality as well as lightness).
If a box comes back a few pixels larger than the artwork on every side, the
shadow is being counted -- switch to `--ink` or name the colour.

**A pale fill on a pale page cannot be colour-matched.** `F0F2F5` on white is 15
levels apart; any sensible tolerance swallows the background. Measure such a
block by its border if it has one, or by the darker content inside it.

## Finding blocks

`blocks` reports `radius_px`, estimated from how far in the fill starts on the
block's top row. It is approximate -- antialiasing costs a pixel or two -- but
close enough, and the spec takes the radius in pixels and converts it.

Regularise what is meant to be regular. A row of cards measured individually
often comes back 222, 216, 229, 223 px wide, especially from a rendered or
AI-generated source. Pick one width and even gaps that span the same total, and
the rebuild looks deliberate rather than nearly-aligned.

## Text: boxes, baselines, sizes

```
probe.py lines page.png --window 74,380,286,580 --color FFFFFF
```

returns one entry per text line, each with a tight box. From that box:

- **left** is `box[0]`, and it is the *ink* edge. A text frame positioned there
  sits a fraction right of the original because of the glyph's left side
  bearing; nudging the spec's `left_px` a few pixels left is normal.
- **baseline** is `box[3]` for a line with no descenders. With a descender
  (`g j p q y ,`) the box bottom is below the baseline, so measure a
  descender-free line in the same style, or subtract roughly `0.21 * size`.
- **size** comes from `fittype.py size`, which fits the point size whose rendered
  width matches the measured width. Width is a far better signal than height:
  ink height is a few dozen pixels and quantises badly.

Baselines matter more than boxes. `build_deck.py` positions a `text` element by
its baseline and derives the frame top from the font's own ascent, which is why
lines land where they were measured even when the font changes.

## Identifying the typeface

```
fetch_fonts.py --shortlist --out work/fonts
fittype.py identify page.png --text "<longest line on the page>" \
    --window 75,188,1300,234 --color DDA92F --px-per-in 115.2 --fonts work/fonts
```

`identify` sizes each candidate so its rendered string is exactly as wide as the
measured ink, renders it, and scores the overlap against the source pixels.

Width and aspect ratio alone are not enough. On a line of body copy they put
Lato, Open Sans and Barlow within a percent of each other -- any of them can be
made to fit the same box. Letterform overlap separates them: in a real case the
correct family scored 0.58 against 0.54 and 0.47 for the runners-up, on a
subtitle of about ninety characters.

Read the output this way:

- `match` -- letterform overlap, higher is better. The family is the reliable
  part of the answer.
- `weight_delta` -- candidate minus source ink density. Positive means too heavy.
  Weight is the least certain part at body sizes; settle it in the render loop.
- `suggested_pt` -- the size that matches the measured width.

Run it on the longest string available. A KPI number tells you almost nothing;
a subtitle tells you the family.

A page may use more than one family. If the headline disagrees with the body
text, measure both separately: mixing a wider cut for display with a condensed
cut for body copy is a normal design choice, not an error.

## Things that are not what they look like

**Auto-fitted numbers.** A row of KPI cards may set each figure at a different
size so each fills its card -- 58, 60, 47, 46 pt in one real slide. Measure each
separately. Reproduce it, or normalise to one size deliberately, but say which
you did.

**Small caps and mixed runs.** `€400M` is often a large run plus a smaller `M`.
Two runs in one `text` element share a baseline, so this is one element.

**A "solid" fill that is a gradient.** Sample the same block near two corners.
If they differ by more than a couple of levels it is a gradient; `blocks`
reports the dominant colour only.

**Colour sampled from the wrong pixel.** Footer text is thin and antialiased, so
a single sample lands on the background. Average the ink pixels in a small window
instead of picking one.
