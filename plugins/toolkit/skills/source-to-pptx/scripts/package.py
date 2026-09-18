"""Post-processing on the saved .pptx package.

python-pptx cannot reach two things the rebuild needs, so the OPC package is
edited directly after saving:

  * theme colours and theme fonts, so the deck can be restyled from PowerPoint's
    colour and font pickers rather than shape by shape;
  * embedded fonts, so the deck renders correctly on machines where the source
    typeface is not installed.

Both are fiddly enough to get wrong quietly -- see references/pptx-internals.md.
"""
from __future__ import annotations

import re
import zipfile
from pathlib import Path

CT = "[Content_Types].xml"
PRES = "ppt/presentation.xml"
PRES_RELS = "ppt/_rels/presentation.xml.rels"
THEME = "ppt/theme/theme1.xml"
FONT_CT = "application/x-fontdata"
FONT_RT = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/font"

STYLE_TAGS = {"regular": "regular", "bold": "bold",
              "italic": "italic", "boldItalic": "boldItalic"}


def patch_theme(xml: str, colours: dict[str, str], major: str | None,
                minor: str | None) -> str:
    """Set theme scheme colours and the major/minor latin typefaces."""
    for name, value in colours.items():
        xml = re.sub(
            r'(<a:%s>)\s*<a:(?:srgbClr val="[0-9A-Fa-f]{6}"|sysClr[^/]*)/>\s*(</a:%s>)'
            % (name, name),
            r'\g<1><a:srgbClr val="%s"/>\g<2>' % value.upper(), xml, count=1)
    if major:
        xml = re.sub(r'(<a:majorFont>\s*<a:latin typeface=")[^"]*(")',
                     r"\g<1>%s\g<2>" % major, xml, count=1)
    if minor:
        xml = re.sub(r'(<a:minorFont>\s*<a:latin typeface=")[^"]*(")',
                     r"\g<1>%s\g<2>" % minor, xml, count=1)
    return xml


def _next_rid(rels_xml: str) -> int:
    return max((int(n) for n in re.findall(r'Id="rId(\d+)"', rels_xml)), default=0) + 1


def _set_attr(xml: str, attr: str, value: str) -> str:
    """Set an attribute on p:presentation.

    embedTrueTypeFonts and saveSubsetFonts are already present in the default
    template, so they have to be replaced rather than prepended -- a duplicate
    attribute makes the whole package unreadable.
    """
    if re.search(r'<p:presentation\b[^>]*\s%s="' % attr, xml):
        return re.sub(r'(<p:presentation\b[^>]*\s%s=")[^"]*(")' % attr,
                      r"\g<1>%s\g<2>" % value, xml, count=1)
    return xml.replace("<p:presentation ", '<p:presentation %s="%s" ' % (attr, value), 1)


def embed_fonts(items: dict[str, bytes], families: dict[str, dict[str, Path]]) -> str:
    """Add font parts and register them; returns a note for the build log."""
    rels = items[PRES_RELS].decode("utf-8")
    ct = items[CT].decode("utf-8")
    pres = items[PRES].decode("utf-8")
    rid, index = _next_rid(rels), 1
    entries, new_rels, new_ct = [], [], []

    for family, styles in families.items():
        parts = []
        for style, path in styles.items():
            tag = STYLE_TAGS.get(style)
            if tag is None or not Path(path).exists():
                continue
            part = f"ppt/fonts/font{index}.fntdata"
            items[part] = Path(path).read_bytes()
            new_ct.append(f'<Override PartName="/{part}" ContentType="{FONT_CT}"/>')
            new_rels.append(f'<Relationship Id="rId{rid}" Type="{FONT_RT}" '
                            f'Target="fonts/font{index}.fntdata"/>')
            parts.append(f'<p:{tag} r:id="rId{rid}"/>')
            rid += 1
            index += 1
        if parts:
            entries.append(f'<p:embeddedFont><p:font typeface="{family}" '
                           f'pitchFamily="34" charset="0"/>' + "".join(parts)
                           + "</p:embeddedFont>")

    if not entries:
        return "no fonts embedded"

    ct = ct.replace("</Types>", "".join(new_ct) + "</Types>")
    rels = rels.replace("</Relationships>", "".join(new_rels) + "</Relationships>")
    pres = re.sub(r"(<p:notesSz[^/]*/>)",
                  r"\g<1><p:embeddedFontLst>" + "".join(entries) + "</p:embeddedFontLst>",
                  pres, count=1)
    pres = _set_attr(pres, "embedTrueTypeFonts", "1")
    pres = _set_attr(pres, "saveSubsetFonts", "0")
    items[CT], items[PRES_RELS], items[PRES] = ct.encode(), rels.encode(), pres.encode()
    return f"embedded {index - 1} font files across {len(entries)} families"


def process(src: Path, dst: Path, *, colours: dict[str, str] | None = None,
            major: str | None = None, minor: str | None = None,
            families: dict[str, dict[str, Path]] | None = None) -> list[str]:
    notes: list[str] = []
    with zipfile.ZipFile(src) as zin:
        items = {n: zin.read(n) for n in zin.namelist()}

    if colours or major or minor:
        items[THEME] = patch_theme(items[THEME].decode("utf-8"), colours or {},
                                   major, minor).encode("utf-8")
        notes.append("theme: " + ", ".join(
            [f"{k}={v}" for k, v in (colours or {}).items()]
            + ([f"fonts={major}/{minor}"] if major or minor else [])))

    if families:
        notes.append(embed_fonts(items, families))

    dst.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as zout:
        for name, data in items.items():
            zout.writestr(name, data)
    if src != dst and src.exists():
        src.unlink()
    return notes
