---
name: source-to-pptx
description: Rebuild a PDF page, screenshot, scan or design mock-up as a genuinely editable PowerPoint deck - real text runs, native shapes for icons and logos, matched and embedded fonts, and a measured review loop that proves the result matches the source. Use this skill whenever someone wants a PDF, image, screenshot, poster, report page or slide picture turned into a .pptx, "made editable", "rebuilt in PowerPoint", "converted to slides", or recreated so they can change the numbers - and also when they ask to copy an existing slide's look, even if they do not say the words PowerPoint or pptx. Handles one page or many, raster or vector sources.
license: MIT
---

# Rebuilding a page as an editable deck

| The source is | Do this |
|---|---|
| A PDF **with** a text layer | `ingest.py` then `pdftext.py` -- the PDF already knows every string, font, size, colour and baseline. Seed the spec from it, then fix up grouping and fonts. |
| A PDF **without** a text layer, or an image | `ingest.py` then measure with `probe.py` + `fittype.py`. Slower, and the interesting case. |
| Many pages | One slide per page. Solve page 1 completely, then reuse its palette, fonts and band structure for the rest. |
| A deck that only needs *content* changed | Not this skill -- edit the .pptx directly. |
| A picture that should stay a picture | Not this skill -- just place it. |

The output is a `.pptx` where the text is text and the icons are shapes. If a
rebuild ends up as a picture of a slide, it has failed, however good it looks:
`verify.py` is what catches that.

> Scripts run through the toolchain wrapper, which needs no host Python:
> `scripts\run.ps1 <work-dir> <script.py> [args]` (or `scripts/run.sh`). It
> prefers Docker, builds its image on first use, and falls back to a `.venv`.
> **If it exits with code 3, the Docker daemon is not responding: ask whether to
> start Docker Desktop or continue with a local Python (`-NoDocker`), rather than
> picking for them.** Paths inside the container are `/work/...` for the work
> directory and `/skill/...` for the skill itself.

## Workflow

### 1. Ingest

```
scripts\run.ps1 . ingest.py /work/source.pdf --out /work/work --width 1536
```

Writes `work/page-NN.png` and `work/source.json`. Read the report: page count,
page size in inches, aspect ratio, and `has_text_layer`. 1536 px wide is a good
working width -- enough to measure type accurately, small enough to stay quick.

### 2. Ask the two questions that change the output

Everything else can be decided from the source, but these two cannot, and both
are visible in the result:

1. **Slide size.** Match the source page's aspect (exact reproduction, possibly
   a non-standard slide size) or standard 16:9 (drops into an existing deck, and
   the layout has to be re-proportioned)? Say which the source is.
2. **Fonts.** Identify the typeface and embed it, or restrict to fonts already
   installed everywhere (Arial, Calibri, Segoe UI)? Embedding looks right
   anywhere; system fonts mean no embedding but different metrics, so lines run
   longer or shorter than the original.

Then run to completion and report. Do not stop to confirm intermediate steps.

### 3. Read the page

**Vector PDF** -- `pdftext.py` gives text, fonts, colours, baselines and filled
rectangles as a spec fragment. What it cannot know is structure: which
rectangles are cards, which runs belong together, what a pictogram depicts.

**Raster** -- measure it:

```
run.ps1 . probe.py palette /work/work/page-01.png
run.ps1 . probe.py blocks  /work/work/page-01.png --min-side 60
run.ps1 . probe.py lines   /work/work/page-01.png --window 74,380,286,580 --color FFFFFF
run.ps1 . fittype.py identify /work/work/page-01.png --text "<the longest line>" \
    --window 75,188,1300,234 --color DDA92F --px-per-in 115.2 --fonts /work/work/fonts
```

`blocks` finds the cards and panels with their fills and corner radii; `lines`
gives each text line's box and baseline; `fittype identify` ranks candidate
faces by how well their letterforms overlap the source pixels. Fetch candidates
first with `fetch_fonts.py --shortlist`, and run `identify` on the longest
string on the page -- the signal grows with the number of glyphs.

Read `references/measuring.md` before the first measurement on a new page. It is
short, and it covers the mistakes that silently produce plausible-looking wrong
numbers.

### 4. Extract the assets

```
run.ps1 . extract.py crop  /work/work/page-01.png --box 532,265,988,607 \
    --aspect 1.571 --scale 3 --out /work/work/img/photo.png
run.ps1 . extract.py trace /work/work/page-01.png --box 1216,26,1498,122 \
    --color DDA92F --name logo_mark --out /work/work/traced.json
run.ps1 . iconlib.py find revenue employees
```

Photographs get cropped; logos, maps and flat artwork get traced into vector
paths, one colour layer at a time. For pictograms, search the bundled library
first -- 38 icons that build as native shapes. Only trace a pictogram when
nothing fits, and never settle for a cropped bitmap of one: it cannot be
recoloured, and that is the whole point of the exercise.

Check what you got: `run.ps1 . preview.py --traced /work/work/traced.json`.

### 5. Write the spec

`work/spec.json` is the deliverable of all the measuring, and the thing to
iterate on. Coordinates go in **source pixels**, so every number stays traceable
to something measured on the page. Read `references/spec-schema.md` for the
element types; `assets/examples/medi-market.spec.json` is a complete worked
example of a dense slide.

When the target aspect differs from the source, use **bands** rather than
rescaling by hand: each band maps a range of source y-coordinates onto the slide
with its own origin and scale, so block heights compress while the gaps between
blocks absorb the difference. `references/layout-mapping.md` explains how to
choose them. x is never scaled, which is why point sizes transfer unchanged.

### 6. Build, render, compare, verify

```
run.ps1 . build_deck.py /work/work/spec.json
scripts\render.ps1 work\deck.pptx -Out work\review
run.ps1 . compare.py /work/work/spec.json --render /work/work/review --source /work/work
run.ps1 . verify.py /work/work/deck.pptx --expect-pictures 1
```

The deck lands where the spec's `deck.output` points, relative to the spec file.

Iterate on the spec until the worst edge drift is about 5 px at 1536 px wide and
`verify.py` says OK. Then *look* at `work/review/side-by-side.png` yourself --
the numbers confirm geometry, not whether an icon reads correctly or a weight is
right. `--zoom x0,y0,x1,y1:band` adds matching detail crops for exactly that.

`references/review-loop.md` maps symptoms to causes; consult it when a number
will not come down.

### 7. Report

Give the deck path, the structure counts from `verify.py`, the drift number, and
anything deliberately different from the source. Flag deviations rather than
hiding them -- an auto-fitted number set at four different sizes, a font
substitution, a photo that had to be cropped.

## Scripts

Paths are relative to this skill's directory; all of them print JSON or a table.

| Script | What it does |
|---|---|
| `scripts/run.ps1`, `run.sh` | Toolchain wrapper: Docker, else `.venv`. Exit 3 = Docker installed but stopped. |
| `scripts/ingest.py` | PDF or image to page rasters plus a report, including whether a PDF has a text layer. `--pages 2-5` selects. |
| `scripts/pdftext.py` | Vector PDF to a spec fragment: text with fonts, sizes, colours, exact baselines, plus filled rects and images. |
| `scripts/probe.py` | Measure a raster: `palette`, `blocks`, `box`, `lines`, `cols`, `sample`, `edges`. |
| `scripts/fittype.py` | `identify` ranks candidate faces by letterform overlap; `size` fits point sizes for a list of measured items. |
| `scripts/fetch_fonts.py` | Any Google Fonts family by name; instances static weights out of variable fonts. `--shortlist` fetches the candidates. |
| `scripts/extract.py` | `crop` a photograph (with `--aspect` to avoid stretching); `trace` flat artwork into vector paths. |
| `scripts/iconlib.py` | `list` / `find` over the bundled icon library. |
| `scripts/preview.py` | Contact sheet of icons and traced paths, to check artwork before it reaches the deck. |
| `scripts/build_deck.py` | The spec to a .pptx: shapes, text, icons, freeforms, theme, embedded fonts. |
| `scripts/render.ps1` | Deck to PNGs via PowerPoint COM (falls back to LibreOffice). A successful open also proves the package is valid. |
| `scripts/compare.py` | Numeric drift report plus side-by-side, overlay and zoom images. |
| `scripts/verify.py` | Structural check: text frames, shapes, pictures, embedded fonts, theme colours. |

## References

Read these when the step calls for them rather than up front:

- `references/measuring.md` -- measuring a raster page: windows, colour
  predicates, baselines, type sizing, and the traps. **Read before step 3.**
- `references/spec-schema.md` -- every spec field and element type. **Read
  before step 5.**
- `references/layout-mapping.md` -- fitting a source page's proportions to the
  target slide: bands, cropping, when to compress and when not to.
- `references/pptx-internals.md` -- the OOXML mechanics behind the builder.
  Read when extending `build_deck.py` or `draw.py`, or when PowerPoint refuses
  a file.
- `references/review-loop.md` -- symptom to cause, and what "close enough" is.

## Assets

- `assets/icons/library.json` -- 38 line icons on a 64-unit grid, drawn as
  native PowerPoint shapes. Add to it in the same style when a page needs
  something new and generic.
- `assets/fonts/catalog.json` -- identification candidates, free equivalents for
  common licensed faces, and the list of Windows-safe fonts that need no
  embedding.
- `assets/examples/medi-market.spec.json` -- a dense worked example: five KPI
  cards, two panels, a photo, a traced logo, bullets, bands.
- `assets/docker/` -- the toolchain image.

## Dependencies

`python-pptx`, `Pillow`, `numpy`, `lxml`, `fontTools`, `pypdfium2`, `pdfplumber`
(pip) · `potrace` (apt) -- all provided by `assets/docker/Dockerfile`, built
automatically on first run · PowerPoint via COM for rendering on Windows, with
LibreOffice (`soffice`) as the fallback.
