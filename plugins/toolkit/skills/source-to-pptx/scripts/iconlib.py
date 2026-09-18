"""The bundled icon library: look icons up, and turn them into shape primitives.

    iconlib.py list                  # every icon with its tags
    iconlib.py find revenue people   # icons matching those words

Icons live in assets/icons/library.json on a 64-unit grid. build_deck.py draws
them as native PowerPoint shapes, so they stay editable and recolourable.

When nothing in the library matches what is on the page, there are two good
options and one bad one. Trace the artwork out of the source with extract.py
(exact, and the right call for a logo, a map or anything brand-specific), or add
a new entry here in the same style (better when the source icon is a generic
pictogram that happens to be low-resolution). Pasting a cropped bitmap is the bad
one: it cannot be recoloured and it defeats the point of the rebuild.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import ASSETS  # noqa: E402

LIBRARY = ASSETS / "icons" / "library.json"


def load() -> dict:
    return json.loads(LIBRARY.read_text())


def icon(name: str) -> list:
    """Primitives for one icon, as [[kind, spec], ...]."""
    data = load()
    entry = data["icons"].get(name)
    if entry is None:
        raise KeyError(f"no icon {name!r}; try: iconlib.py find {name}")
    return entry["prims"]


def viewbox() -> float:
    return float(load().get("viewbox", 64))


def find(words: list[str]) -> list[dict]:
    data = load()
    words = [w.lower() for w in words]
    hits = []
    for name, entry in data["icons"].items():
        haystack = name.lower() + " " + " ".join(entry.get("tags", []))
        matched = [w for w in words if w in haystack]
        if matched:
            hits.append({"name": name, "matched": matched,
                         "tags": entry.get("tags", [])})
    return sorted(hits, key=lambda h: -len(h["matched"]))


def main() -> int:
    args = sys.argv[1:]
    if not args or args[0] == "list":
        data = load()
        for name, entry in sorted(data["icons"].items()):
            print(f"{name:12s} {', '.join(entry.get('tags', []))}")
        print(f"\n{len(data['icons'])} icons on a {data.get('viewbox', 64)}-unit grid")
        return 0
    if args[0] == "find":
        hits = find(args[1:])
        if not hits:
            print("no match -- trace the artwork with extract.py, "
                  "or add an entry to assets/icons/library.json")
            return 1
        for h in hits:
            print(f"{h['name']:12s} matched {h['matched']}  ({', '.join(h['tags'])})")
        return 0
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
