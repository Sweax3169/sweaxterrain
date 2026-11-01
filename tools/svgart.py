"""Animated SVG art for the README and website, drawn from the same Studio dumps as the renders.

    python tools/svgart.py

docs/art/banner-{light,dark}-{en,tr}.svg     iso block world rising parcel by parcel (real Alpine dump)
docs/art/card-<name>-{light,dark}-{en,tr}.svg feature cards
docs/art/architecture-{light,dark}-{en,tr}.svg (README and website)
"""
import base64
import io
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image

from voxels import Voxels
from render_map import shade, COLORS

ROOT = Path(__file__).resolve().parent.parent
DUMPS = ROOT / "dumps"
ART = ROOT / "docs" / "art"
FONT = "'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
MONO = "Consolas, 'SF Mono', Menlo, monospace"

THEME = {
    "light": {"bg0": "#F1F5F3", "bg1": "#E3EAE7", "ink": "#15201B", "ink2": "#4B5852", "ink3": "#7A857F",
              "line": "#CBD5D0", "grass": "#4C7D29", "water": "#2A679A", "lava": "#C9501F", "card": "#FFFFFF"},
    "dark": {"bg0": "#101815", "bg1": "#0B110F", "ink": "#E6ECE8", "ink2": "#A3AFA8", "ink3": "#75817B",
             "line": "#24312B", "grass": "#8CC157", "water": "#78B6EC", "lava": "#FF7B45", "card": "#141D19"},
}


def hexc(rgb, k=1.0):
    r, g, b = (max(0, min(255, round(c * k))) for c in rgb)
    return f"#{r:02X}{g:02X}{b:02X}"


def png_uri(img):
    buf = io.BytesIO()
    img.convert("RGB").quantize(48, method=Image.Quantize.MEDIANCUT).save(buf, "PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


# ------------------------------------------------------------------ iso blocks from a dump
def iso_world(vox, n=18, block=27, step=4.5, row0=0, col0=0):
    """Downsample a terrain dump to n x n columns; return SVG groups ordered back to front."""
    v = Voxels(DUMPS / vox)
    h, m, wh = v.heightmap()
    s = (v.nx - row0) // n
    cols = []
    for i in range(n):
        for j in range(n):
            a, b = row0 + i * s, col0 + j * s
            hh = h[a:a + s, b:b + s]
            mm = m[a:a + s, b:b + s]
            ww = wh[a:a + s, b:b + s]
            top = float(np.nanmean(hh))
            vals, counts = np.unique(mm, return_counts=True)
            mat = v.materials[int(vals[counts.argmax()])]
            wet = np.count_nonzero(~np.isnan(ww)) > hh.size * 0.4
            if wet:
                top = float(np.nanmean(ww))
                mat = "Water"
            cols.append((i, j, top, mat))
    lo = min(c[2] for c in cols)
    W = block
    out = []
    for i, j, top, mat in sorted(cols, key=lambda c: (c[0] + c[1], c[0])):
        hb = max(1, round((top - lo) / step)) + 1
        x = (i - j) * W / 2
        y = (i + j) * W / 4
        H = hb * W / 4
        c = COLORS.get(mat, (200, 0, 200))
        side = COLORS["Rock"] if mat in ("Snow", "Rock", "Slate") else COLORS["Ground"]
        if mat == "Water":
            side = (40, 88, 140)
        topf = f"M{x:.1f},{y - H:.1f} l{W / 2:.1f},{W / 4:.1f} l{-W / 2:.1f},{W / 4:.1f} l{-W / 2:.1f},{-W / 4:.1f}z"
        left = f"M{x - W / 2:.1f},{y - H + W / 4:.1f} l{W / 2:.1f},{W / 4:.1f} v{H:.1f} l{-W / 2:.1f},{-W / 4:.1f}z"
        right = f"M{x + W / 2:.1f},{y - H + W / 4:.1f} l{-W / 2:.1f},{W / 4:.1f} v{H:.1f} l{W / 2:.1f},{-W / 4:.1f}z"
        parcel = (i // 6) * 3 + (j // 6)  # 3 x 3 parcels written x-major, like the plugin
        delay = parcel * 0.32 + ((i % 6) + (j % 6)) * 0.018
        out.append((delay, f'<g class="b" style="animation-delay:{delay:.2f}s"><path d="{left}" fill="{hexc(side, 0.78)}"/>'
                           f'<path d="{right}" fill="{hexc(side, 0.6)}"/><path d="{topf}" fill="{hexc(c, 1.04)}"/></g>'))
    return [g for _, g in out]


def banner(theme, lang):
    T = THEME[theme]
    blocks = iso_world("karisik.vox")
    title = "Sweax Terrain"
    sub = {"en": "Generate, erase and build worlds in Roblox Studio",
           "tr": "Roblox Studio'da dünya üret, sil, üstüne kur"}[lang]
    facts = {"en": "9 biomes  ·  8 worlds  ·  54 structures  ·  Ctrl+Z on every step",
             "tr": "9 biyom  ·  8 dünya  ·  54 yapı  ·  her adımda Ctrl+Z"}[lang]
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="420" viewBox="0 0 1280 420" role="img" aria-label="{esc(title)}: {esc(sub)}">
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{T['bg0']}"/><stop offset="1" stop-color="{T['bg1']}"/></linearGradient>
<radialGradient id="sh"><stop offset="0" stop-color="#000" stop-opacity="{.28 if theme == 'dark' else .16}"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>
</defs>
<style>
.b{{animation:rise 10s cubic-bezier(.34,1.56,.64,1) infinite both;transform-box:fill-box}}
@keyframes rise{{0%{{opacity:0;transform:translateY(-46px)}}5%{{opacity:1;transform:translateY(0)}}72%{{opacity:1;transform:translateY(0)}}80%{{opacity:0;transform:translateY(14px)}}100%{{opacity:0;transform:translateY(14px)}}}}
.t{{font-family:{FONT}}}
@media (prefers-reduced-motion:reduce){{.b{{animation:none}}}}
</style>
<rect width="1280" height="420" rx="22" fill="url(#bg)"/>
<g transform="translate(70,0)">
<g transform="translate(0,118)"><path d="M16 3 29 10.5 16 18 3 10.5z" fill="#6F9D3C" transform="scale(2.2)"/><path d="M3 10.5 16 18v11L3 21.5z" fill="#8A6A45" transform="scale(2.2)"/><path d="M29 10.5 16 18v11l13-7.5z" fill="#6B7075" transform="scale(2.2)"/><path d="M12.4 9.3 16 5.6l3.6 3.7-1.9-.5-1.7 1.3-1.6-1.2z" fill="#F4F6FA" transform="scale(2.2)"/></g>
<text class="t" x="0" y="232" font-size="72" font-weight="800" fill="{T['ink']}" letter-spacing="-1.5">{esc(title)}</text>
<text class="t" x="2" y="278" font-size="25" font-weight="500" fill="{T['ink2']}">{esc(sub)}</text>
<text class="t" x="2" y="322" font-size="17" font-weight="600" fill="{T['grass']}">{esc(facts)}</text>
</g>
<ellipse cx="925" cy="378" rx="260" ry="26" fill="url(#sh)"/>
<g transform="translate(925,150)">
{chr(10).join(blocks)}
</g>
</svg>
'''


# ------------------------------------------------------------------ feature cards
def card_frame(theme, title, text, body, w=600, h=300):
    T = THEME[theme]
    lines = wrap(text, 52)
    tl = "".join(f'<text x="28" y="{238 + k * 22}" class="t" font-size="16" fill="{T["ink2"]}">{esc(s)}</text>' for k, s in enumerate(lines))
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" role="img" aria-label="{esc(title)}">
<style>.t{{font-family:{FONT}}}.m{{font-family:{MONO}}}@media (prefers-reduced-motion:reduce){{*{{animation:none!important}}}}</style>
<rect x=".5" y=".5" width="{w - 1}" height="{h - 1}" rx="16" fill="{T['card']}" stroke="{T['line']}"/>
{body}
<text x="28" y="214" class="t" font-size="21" font-weight="800" fill="{T['ink']}">{esc(title)}</text>
{tl}
</svg>
'''


def wrap(s, n):
    out, cur = [], ""
    for w in s.split():
        if len(cur) + len(w) + 1 > n and cur:
            out.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    if cur:
        out.append(cur)
    return out[:3]


def profile(vox, row=None, n=72, w=540, h=120, base=None):
    v = Voxels(DUMPS / vox)
    hh, m, wh = v.heightmap()
    r = row if row is not None else v.nx // 2
    line = hh[r, :]
    idx = np.linspace(0, len(line) - 1, n)
    ys = np.interp(idx, np.arange(len(line)), np.nan_to_num(line, nan=np.nanmin(line)))
    mats = [v.materials[int(m[r, int(round(i))])] for i in idx]
    return ys, mats


def card_biomes(theme, lang):
    T = THEME[theme]
    names = ["ova", "tepe", "dag", "kanyon", "volkan", "col"]
    profs = [profile(f"b_{b}.vox")[0] for b in names]
    w, x0, yb = 544, 28, 168
    def path(ys):
        sc = 1.15
        pts = [f"{x0 + k * w / (len(ys) - 1):.1f},{yb - 18 - (y - 0) * sc:.1f}" for k, y in enumerate(ys)]
        return f"M{x0},{yb} L" + " L".join(pts) + f" L{x0 + w},{yb} Z"
    ds = [path(p) for p in profs] + [path(profs[0])]
    vals = ";".join(ds)
    kt = ";".join(f"{k / (len(ds) - 1):.3f}" for k in range(len(ds)))
    labels = {"en": ["Plains", "Hills", "Mountains", "Canyons", "Volcanic", "Desert dunes"],
              "tr": ["Ovalar", "Tepeler", "Dağlar", "Kanyonlar", "Volkanik", "Çöl kumulları"]}[lang]
    lab = "".join(f'<text x="{x0}" y="40" class="t" font-size="14" font-weight="700" fill="{T["ink3"]}" opacity="0"><animate attributeName="opacity" dur="12s" repeatCount="indefinite" values="{";".join("1" if q == k else "0" for q in range(len(names)))};0" keyTimes="{";".join(f"{q / len(names):.3f}" for q in range(len(names)))};1" calcMode="discrete"/>{esc(t)}</text>' for k, t in enumerate(labels))
    body = f'''<path fill="{T['grass']}" opacity=".9"><animate attributeName="d" dur="12s" repeatCount="indefinite" values="{vals}" keyTimes="{kt}" calcMode="spline" keySplines="{';'.join(['.5 0 .2 1'] * (len(ds) - 1))}"/></path>
<path d="M{x0},{yb} H{x0 + w}" stroke="{T['line']}" stroke-width="2"/>{lab}'''
    title = {"en": "Nine biomes", "tr": "Dokuz biyom"}[lang]
    text = {"en": "Each is its own height function. Turn on several and they blend; weights set how much land each one gets.",
            "tr": "Her biri kendi yükseklik fonksiyonu. Birkaçını aç, birbirine karışsınlar; ağırlık kaplayacağı yeri belirler."}[lang]
    return card_frame(theme, title, text, body)


def raster_frames(theme, frames, x, y, size, dur, extra=""):
    """Cross-cut sequence of small map rasters, one visible at a time."""
    n = len(frames)
    parts = []
    for k, img in enumerate(frames):
        vals = ";".join("1" if q == k else "0" for q in range(n)) + ";" + ("1" if k == 0 else "0")
        kt = ";".join(f"{q / n:.4f}" for q in range(n)) + ";1"
        parts.append(f'<image href="{png_uri(img)}" x="{x}" y="{y}" width="{size[0]}" height="{size[1]}" opacity="{1 if k == 0 else 0}" style="image-rendering:pixelated"><animate attributeName="opacity" dur="{dur}s" repeatCount="indefinite" values="{vals}" keyTimes="{kt}" calcMode="discrete"/></image>')
    return "".join(parts) + extra


def card_erase(theme, lang):
    T = THEME[theme]
    frames = []
    for k in range(0, 17, 2):
        v = Voxels(DUMPS / f"er_{k:02d}.vox")
        frames.append(shade(v, 2).resize((150, 150), Image.LANCZOS))
    path = json.loads((DUMPS / "er_path.json").read_text())
    # frames show er_00, er_02 .. er_16; the ball sits on the last stamp made (path[2k - 1])
    xy = lambda p: (28 + (p[0] + 160) / 320 * 150, 24 + (p[2] + 4360) / 320 * 150)
    pos = [xy(path[0]), xy(path[0])] + [xy(path[2 * k - 1]) for k in range(1, 9)] + [xy(path[15])]
    n = len(pos)
    vals_x = ";".join(f"{p[0]:.1f}" for p in pos + [pos[-1]])
    vals_y = ";".join(f"{p[1]:.1f}" for p in pos + [pos[-1]])
    kt = ";".join(f"{q / n:.4f}" for q in range(n + 1))
    circle = (f'<circle r="7.5" fill="{T["lava"]}" fill-opacity=".35" stroke="{T["lava"]}" stroke-width="2">'
              f'<animate attributeName="cx" dur="6s" repeatCount="indefinite" values="{vals_x}" keyTimes="{kt}" calcMode="discrete"/>'
              f'<animate attributeName="cy" dur="6s" repeatCount="indefinite" values="{vals_y}" keyTimes="{kt}" calcMode="discrete"/></circle>')
    body = raster_frames(theme, [frames[0]] + frames + [frames[-1]], 28, 24, (150, 150), 6, circle)
    rg0 = shade(Voxels(DUMPS / "rg_0.vox"), 2).resize((150, 150), Image.LANCZOS)
    rg1 = shade(Voxels(DUMPS / "rg_1.vox"), 2).resize((150, 150), Image.LANCZOS)
    box = json.loads((DUMPS / "rg_box.json").read_text())
    bx0 = 300 + (box["min"][0] + 192) / 384 * 150
    bz0 = 24 + (box["min"][2] + 5192) / 384 * 150
    bw = (box["max"][0] - box["min"][0]) / 384 * 150
    bh = (box["max"][2] - box["min"][2]) / 384 * 150
    sel = f'<rect x="{bx0:.1f}" y="{bz0:.1f}" width="{bw:.1f}" height="{bh:.1f}" fill="{T["lava"]}" fill-opacity=".25" stroke="{T["lava"]}" stroke-width="2" stroke-dasharray="5 4"><animate attributeName="opacity" dur="6s" repeatCount="indefinite" values="0;1;1;0;0" keyTimes="0;.2;.55;.6;1"/></rect>'
    body += raster_frames(theme, [rg0, rg0, rg0, rg1, rg1], 300, 24, (150, 150), 6, sel)
    title = {"en": "Brush and region eraser", "tr": "Fırça ve bölge silgisi"}[lang]
    text = {"en": "Drag the brush, or click two corners and erase the box between them. Any terrain, any time.",
            "tr": "Fırçayı sürükle ya da iki köşeye tıkla, aradaki kutuyu sil. Her arazide, her zaman."}[lang]
    return card_frame(theme, title, text, body)


def card_caves(theme, lang):
    T = THEME[theme]
    v = Voxels(DUMPS / "caves.vox")
    z = v.nz // 2
    occ = v.solid_mask()[:, :, z]
    mat = v.mat[:, :, z]
    ny = v.ny
    px = 544 / v.nx
    cells = []
    ytop = None
    for x in range(v.nx):
        for y in range(ny):
            if occ[x, y] > 0.5:
                c = COLORS.get(v.materials[mat[x, y]], (120, 120, 120))
                yy = 175 - (y + 1) * px * 1.0
                cells.append(f'<rect x="{28 + x * px:.1f}" y="{yy:.1f}" width="{px + .3:.1f}" height="{px + .3:.1f}" fill="{hexc(c, .9)}"/>')
    body = f'<g opacity=".95">{"".join(cells)}</g>'
    # tunnels: air under the surface, highlighted with a slow pulse
    holes = []
    for x in range(v.nx):
        col = occ[x]
        filled = np.where(col > 0.5)[0]
        if not len(filled):
            continue
        topy = filled.max()
        for y in range(1, topy - 1):
            if col[y] <= 0.5:
                yy = 175 - (y + 1) * px
                holes.append(f'<rect x="{28 + x * px:.1f}" y="{yy:.1f}" width="{px + .3:.1f}" height="{px + .3:.1f}"/>')
    body += f'<g fill="{T["lava"]}">{"".join(holes)}<animate attributeName="opacity" dur="3s" repeatCount="indefinite" values=".25;.85;.25"/></g>'
    title = {"en": "Caves and outcrops", "tr": "Mağaralar ve kaya çıkıntıları"}[lang]
    text = {"en": "A real slice through generated hills: tunnels start 6 studs under the surface.",
            "tr": "Üretilmiş tepelerden gerçek bir kesit: tüneller yüzeyin 6 stud altından başlar."}[lang]
    return card_frame(theme, title, text, body)


def card_worlds(theme, lang):
    T = THEME[theme]
    names = ["alp", "nehir", "kanyon", "volkan", "arktik", "bataklik", "sahil", "karisik"]
    maps = [shade(Voxels(DUMPS / f"{n}.vox"), 1).resize((150, 150), Image.LANCZOS) for n in names]
    body = raster_frames(theme, maps[:4], 28, 24, (150, 150), 8) + raster_frames(theme, maps[4:], 196, 24, (150, 150), 8)
    seeds = ["8927", "314159", "77001", "40404"]
    st = "".join(f'<text x="372" y="{70 + k * 30}" class="m" font-size="15" fill="{T["ink3"]}">{s}</text>' for k, s in enumerate(seeds))
    body += f'<text x="372" y="44" class="t" font-size="13" font-weight="700" fill="{T["ink2"]}">{"Seed" if lang == "en" else "Tohum"}</text>{st}'
    title = {"en": "Eight worlds, endless seeds", "tr": "Sekiz dünya, sonsuz tohum"}[lang]
    text = {"en": "Pick a world and generate. A new seed every run; type a seed to get the same world again.",
            "tr": "Bir dünya seç, üret. Her üretimde yeni tohum; aynı dünyayı geri almak için tohumu yaz."}[lang]
    return card_frame(theme, title, text, body)


def card_structures(theme, lang):
    T = THEME[theme]
    parts = json.loads((ROOT / "docs" / "data" / "parts" / "gozetlemeKulesi.json").read_text())
    polys = iso_parts(parts, scale=4.2, ox=150, oy=150)
    ghost = "".join(polys)
    body = f'''<g transform="translate(0,0)"><g><animateTransform attributeName="transform" type="translate" dur="5s" repeatCount="indefinite" values="0,-40;0,-40;0,0;0,0;0,0" keyTimes="0;.15;.35;.9;1" calcMode="spline" keySplines="0 0 1 1;.34 1.56 .64 1;0 0 1 1;0 0 1 1"/>{ghost}<animate attributeName="opacity" dur="5s" repeatCount="indefinite" values=".35;.35;.45;1;1" keyTimes="0;.15;.35;.42;1"/></g></g>
<ellipse cx="150" cy="156" rx="70" ry="14" fill="{T['ink']}" opacity=".1"/>'''
    names = {"en": ["Watchtower", "Mine Entrance", "Stone Bridge", "Ore Cart", "Campfire", "Tent"],
             "tr": ["Gözetleme Kulesi", "Maden Girişi", "Taş Köprü", "Cevher Vagonu", "Kamp Ateşi", "Çadır"]}[lang]
    body += "".join(f'<text x="330" y="{48 + k * 24}" class="t" font-size="15" fill="{T["ink2"] if k else T["ink"]}" font-weight="{700 if k == 0 else 500}">{esc(s)}</text>' for k, s in enumerate(names))
    body += f'<text x="330" y="{48 + 6 * 24}" class="t" font-size="15" fill="{T["ink3"]}">+ 48</text>'
    title = {"en": "44 structures, 10 landforms", "tr": "44 yapı, 10 arazi alanı"}[lang]
    text = {"en": "A ghost follows the mouse and sits on the ground. Moss, ruin, scale and rotation are sliders.",
            "tr": "Yarı saydam önizleme fareyi izler ve zemine oturur. Yosun, yıkıklık, ölçek ve dönüş kaydırıcıda."}[lang]
    return card_frame(theme, title, text, body)


def iso_parts(rows, scale, ox, oy):
    """Isometric polygons of a part list (blocks only, others as their box), painter-sorted."""
    faces = []
    a = math.radians(30)
    def proj(p):
        x, y, z = p
        return (ox + (x - z) * math.cos(a) * scale, oy + ((x + z) * math.sin(a) - y) * scale)
    for r in rows:
        R = r[4:13]
        size = r[13:16]
        col = r[16:19]
        if r[19] > 0.8:
            continue
        corners = []
        for sx in (-0.5, 0.5):
            for sy in (-0.5, 0.5):
                for sz in (-0.5, 0.5):
                    l = (sx * size[0], sy * size[1], sz * size[2])
                    w = (R[0] * l[0] + R[1] * l[1] + R[2] * l[2] + r[1], R[3] * l[0] + R[4] * l[1] + R[5] * l[2] + r[2],
                         R[6] * l[0] + R[7] * l[1] + R[8] * l[2] + r[3])
                    corners.append(w)
        quads = [((0, 1, 3, 2), 0.62), ((4, 6, 7, 5), 0.62), ((0, 4, 5, 1), 0.5), ((2, 3, 7, 6), 1.05), ((0, 2, 6, 4), 0.8), ((1, 5, 7, 3), 0.8)]
        for q, k in quads:
            pts = [corners[i] for i in q]
            cx = sum(p[0] for p in pts) / 4
            cy = sum(p[1] for p in pts) / 4
            cz = sum(p[2] for p in pts) / 4
            depth = cx + cz + cy * 0.2
            faces.append((depth, " ".join(f"{proj(p)[0]:.1f},{proj(p)[1]:.1f}" for p in pts), hexc(col, k)))
    faces.sort(key=lambda f: f[0])
    return [f'<polygon points="{p}" fill="{c}"/>' for _, p, c in faces]


def card_undo(theme, lang):
    T = THEME[theme]
    rg0 = shade(Voxels(DUMPS / "rg_0.vox"), 2).resize((150, 150), Image.LANCZOS)
    rg1 = shade(Voxels(DUMPS / "rg_1.vox"), 2).resize((150, 150), Image.LANCZOS)
    body = raster_frames(theme, [rg1, rg1, rg0, rg0], 28, 24, (150, 150), 4)
    key = lambda x, label: f'<g transform="translate({x},70)"><rect width="74" height="58" rx="9" fill="{T["card"]}" stroke="{T["line"]}" stroke-width="2"/><text x="37" y="37" text-anchor="middle" class="t" font-size="18" font-weight="700" fill="{T["ink"]}">{label}</text><animateTransform attributeName="transform" type="translate" dur="4s" repeatCount="indefinite" values="{x},70;{x},70;{x},76;{x},70;{x},70" keyTimes="0;.42;.5;.58;1"/></g>'
    body += key(220, "Ctrl") + f'<text x="306" y="106" class="t" font-size="22" font-weight="700" fill="{T["ink3"]}">+</text>' + key(326, "Z")
    title = {"en": "Ctrl+Z, like everything else", "tr": "Ctrl+Z, her şeyde olduğu gibi"}[lang]
    text = {"en": "Every generate, brush stroke, erase and placement is one undo step in Studio.",
            "tr": "Her üretim, fırça darbesi, silme ve yerleştirme Studio'da tek bir geri alma adımı."}[lang]
    return card_frame(theme, title, text, body)


# ------------------------------------------------------------------ architecture
def architecture(theme, lang):
    T = THEME[theme]
    L = {
        "en": {"panel": "Panel", "panelS": "tabs, sliders, presets, EN · TR", "core": "Generator", "p1": "Pass 1 · height map",
               "p1s": "warp → biomes → lakes, rivers, coast", "p2": "Pass 2 · voxels", "p2s": "materials, outcrops, caves",
               "lib": "Structure library", "libS": "44 part structures · 10 landforms", "tools": "Tools", "toolsS": "brush · region · last area · all",
               "terrain": "workspace.Terrain", "terrainS": "WriteVoxels in 24×24 parcels", "folder": "workspace.SweaxYapilar", "folderS": "models with SweaxStructure, SweaxSeed",
               "undo": "ChangeHistory waypoint after every step"},
        "tr": {"panel": "Panel", "panelS": "sekmeler, kaydırıcılar, hazır dünyalar, EN · TR", "core": "Üretici", "p1": "1. geçiş · yükseklik",
               "p1s": "warp → biyomlar → göl, nehir, kıyı", "p2": "2. geçiş · vokseller", "p2s": "malzeme, çıkıntı, mağara",
               "lib": "Yapı kütüphanesi", "libS": "44 parça yapı · 10 arazi alanı", "tools": "Araçlar", "toolsS": "fırça · bölge · son alan · hepsi",
               "terrain": "workspace.Terrain", "terrainS": "24×24 parçada WriteVoxels", "folder": "workspace.SweaxYapilar", "folderS": "SweaxStructure, SweaxSeed nitelikli modeller",
               "undo": "Her adımdan sonra ChangeHistory noktası"},
    }[lang]
    def box(x, y, w, h, title, file, sub, accent):
        return (f'<g><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="{T["card"]}" stroke="{T["line"]}" stroke-width="1.5"/>'
                f'<rect x="{x}" y="{y + 14}" width="4" height="{h - 28}" rx="2" fill="{accent}"/>'
                f'<text x="{x + 20}" y="{y + 30}" class="t" font-size="17" font-weight="800" fill="{T["ink"]}">{esc(title)}</text>'
                f'<text x="{x + 20}" y="{y + 50}" class="m" font-size="12.5" fill="{T["ink3"]}">{esc(file)}</text>'
                f'<text x="{x + 20}" y="{y + 72}" class="t" font-size="13.5" fill="{T["ink2"]}">{esc(sub)}</text></g>')
    def arrow(d):
        return f'<path d="{d}" class="fl" fill="none" stroke="{T["grass"]}" stroke-width="2" marker-end="url(#ah)"/>'
    g = T["grass"]
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="980" height="560" viewBox="0 0 980 560" role="img" aria-label="Sweax Terrain architecture">
<defs><marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0 0 10 5 0 10z" fill="{g}"/></marker></defs>
<style>.t{{font-family:{FONT}}}.m{{font-family:{MONO}}}.fl{{stroke-dasharray:6 6;animation:fl 1.2s linear infinite}}@keyframes fl{{to{{stroke-dashoffset:-12}}}}@media (prefers-reduced-motion:reduce){{.fl{{animation:none}}}}</style>
<rect width="980" height="560" rx="18" fill="{T['bg0']}"/>
{box(30, 40, 290, 92, L['panel'], 'Ana.server.lua · Arayuz.lua · Dil.lua', L['panelS'], T['water'])}
{box(345, 40, 290, 92, L['core'], 'Uretici.lua', L['p1'] + ' · ' + L['p2'], g)}
{box(660, 40, 290, 92, L['lib'], 'Yapilar.lua → Yapi*.lua', L['libS'], T['lava'])}
{box(345, 186, 290, 92, L['p1'], 'BIYOM.* · fbm · ridged', L['p1s'], g)}
{box(345, 312, 290, 92, L['p2'], 'TAKIM.* · math.noise 3D', L['p2s'], g)}
{box(30, 186, 290, 92, L['tools'], 'FillBall · FillRegion · Clear', L['toolsS'], T['lava'])}
{box(170, 446, 300, 92, L['terrain'], 'Terrain', L['terrainS'], T['water'])}
{box(530, 446, 300, 92, L['folder'], 'Folder', L['folderS'], T['water'])}
{arrow('M320 86 H343')}
{arrow('M635 86 H658')}
{arrow('M175 132 V184')}
{arrow('M490 132 V184')}
{arrow('M490 278 V310')}
{arrow('M490 404 Q490 425 380 444')}
{arrow('M175 278 Q175 380 250 444')}
{arrow('M805 132 V300 Q805 400 720 444')}
<text x="490" y="430" text-anchor="middle" class="t" font-size="12.5" fill="{T['ink3']}" transform="translate(0,-2)"> </text>
<text x="950" y="28" text-anchor="end" class="t" font-size="13" fill="{T['ink3']}">{esc(L['undo'])}</text>
</svg>
'''


def main():
    ART.mkdir(parents=True, exist_ok=True)
    cards = {"biomes": card_biomes, "worlds": card_worlds, "caves": card_caves, "erase": card_erase,
             "structures": card_structures, "undo": card_undo}
    for theme in ("light", "dark"):
        for lang in ("en", "tr"):
            (ART / f"banner-{theme}-{lang}.svg").write_text(banner(theme, lang), encoding="utf-8")
            (ART / f"architecture-{theme}-{lang}.svg").write_text(architecture(theme, lang), encoding="utf-8")
            for name, fn in cards.items():
                (ART / f"card-{name}-{theme}-{lang}.svg").write_text(fn(theme, lang), encoding="utf-8")
    sizes = sorted((f.stat().st_size // 1024, f.name) for f in ART.glob("*.svg"))
    print(len(sizes), "svg files, largest", sizes[-3:])


if __name__ == "__main__":
    main()
