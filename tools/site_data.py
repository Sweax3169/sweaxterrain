"""Export the plugin's own strings and structure list for the website (docs/data/*.json).

    python tools/site_data.py

The website's copy of the panel uses the same English/Turkish text as the plugin (src/Dil.lua)
and the same structure library (src/Yapi*.lua), so the two cannot drift apart.
"""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
OUT = ROOT / "docs" / "data"


def lua_table(text, name):
    """Key = "value" pairs inside `name = { ... }` (flat string tables only)."""
    start = text.index(name + " = {")
    depth, i = 0, text.index("{", start)
    for j in range(i, len(text)):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                body = text[i + 1:j]
                break
    pairs = re.findall(r'(?:\[\s*"([^"]+)"\s*\]|([A-Za-z_][A-Za-z0-9_]*))\s*=\s*"((?:[^"\\]|\\.)*)"', body)
    return {a or b: v for a, b, v in pairs}


def main():
    dil = (SRC / "Dil.lua").read_text(encoding="utf-8")
    strings = {"en": lua_table(dil, "T.en"), "tr": lua_table(dil, "T.tr")}
    yapi_en = lua_table(dil, "Dil.YAPI")
    kat_en = lua_table(dil, "Dil.KATEGORI")
    items = []
    for mod in ("YapiTemel", "YapiMaden", "YapiSus", "YapiAlan"):
        text = (SRC / f"{mod}.lua").read_text(encoding="utf-8")
        for ad, etiket, ikon, kat in re.findall(
                r'\{\s*ad\s*=\s*"([^"]+)",\s*etiket\s*=\s*"([^"]+)",\s*ikon\s*=\s*"([^"]+)",\s*kategori\s*=\s*"([^"]+)"', text):
            items.append({"id": ad, "tr": etiket, "en": yapi_en.get(ad, etiket), "icon": ikon,
                          "cat": kat, "catEn": kat_en.get(kat, kat), "landform": mod == "YapiAlan"})
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "strings.json").write_text(json.dumps(strings, ensure_ascii=False, indent=1), encoding="utf-8")
    (OUT / "structures.json").write_text(json.dumps(items, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(strings['en'])} strings, {len(items)} structures")
    export_parts(items)


SHAPES = {"Block": 0, "Cylinder": 1, "Ball": 2, "Wedge": 3, "CornerWedge": 0}


def export_parts(items):
    """Part lists of every structure, relative to its base (dumps/y_<id>.parts from Studio).

    In the Studio test place structure i (0-based, library order) stood at
    (-20 + (i % 9) * 100, 0, 900 + (i // 9) * 75), facing -Z, on flat ground at Y = 0.
    """
    dumps = ROOT / "dumps"
    out = OUT / "parts"
    out.mkdir(exist_ok=True)
    n = 0
    for i, s in enumerate(items):
        f = dumps / f"y_{s['id']}.parts"
        if s["landform"] or not f.exists():
            continue
        base = (-20 + (i % 9) * 100, 0, 900 + (i // 9) * 75)
        rows = []
        for p in json.loads(f.read_text(encoding="utf-8")):
            cf = p["cf"]
            pos = [cf[0] - base[0], cf[1] - base[1], cf[2] - base[2]]
            rows.append([SHAPES.get(p["s"], 0)] + [round(v, 3) for v in pos + cf[3:12] + p["size"]]
                        + [round(c * 255) for c in p["c"]] + [round(p["t"], 2), 1 if p["m"] == "Neon" else 0])
        (out / f"{s['id']}.json").write_text(json.dumps(rows, separators=(",", ":")), encoding="utf-8")
        n += 1
    print(f"{n} part lists")


if __name__ == "__main__":
    main()
