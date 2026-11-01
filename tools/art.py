"""Turn Blender renders (build/renders) into the README and website media.

    python tools/art.py

docs/media/*.webp       transparent stills for the website and README
docs/media/*.mp4        animations on a sky backdrop for the website
docs/media/gif/*.gif    the same animations for the README, on GitHub's light and dark backgrounds
"""
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
REN = ROOT / "build" / "renders"
MEDIA = ROOT / "docs" / "media"
GIF = MEDIA / "gif"
BG = {"light": (255, 255, 255), "dark": (13, 17, 23)}  # GitHub page backgrounds
SKY = ((196, 216, 233), (238, 244, 247))  # website video backdrop, top and bottom
FONT = "C:/Windows/Fonts/segoeuib.ttf"


def sky(size):
    w, h = size
    img = Image.new("RGB", size)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        c = tuple(round(SKY[0][i] + (SKY[1][i] - SKY[0][i]) * t) for i in range(3))
        d.line([(0, y), (w, y)], fill=c)
    return img


def on(img, bg):
    base = bg.copy() if isinstance(bg, Image.Image) else Image.new("RGB", img.size, bg)
    base = base.convert("RGBA")
    base.alpha_composite(img.convert("RGBA"))
    return base.convert("RGB")


def webp(src, dst, width=None, quality=88):
    im = Image.open(src).convert("RGBA")
    if width and im.width > width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(dst, "WEBP", quality=quality, method=6)


def caption(img, text, theme):
    if not text:
        return img
    d = ImageDraw.Draw(img)
    f = ImageFont.truetype(FONT, max(15, img.width // 46))
    col = (60, 72, 66) if theme != "dark" else (190, 200, 195)
    d.text((img.width * 0.035, img.height - img.width * 0.05), text, font=f, fill=col)
    return img


def sequence(frames, out_mp4=None, out_gifs=None, width_gif=760, label=None):
    """frames: list of (png path, duration in seconds). GIFs get light/dark backgrounds."""
    fps = 25
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        jobs = []
        if out_mp4:
            jobs.append(("mp4", None))
        if out_gifs:
            jobs += [("gif", t) for t in ("light", "dark")]
        for kind, theme in jobs:
            d = tmp / f"{kind}-{theme}"
            d.mkdir()
            n = 0
            cache = {}
            for path, dur in frames:
                if path not in cache:
                    im = Image.open(path)
                    bg = sky(im.size) if kind == "mp4" else BG[theme]
                    im = on(im, bg)
                    if kind == "gif":
                        im = im.resize((width_gif, round(im.height * width_gif / im.width)), Image.LANCZOS)
                        im = caption(im, label, theme)
                    cache[path] = im
                rate = fps if kind == "mp4" else 20
                for _ in range(max(1, round(dur * rate))):
                    cache[path].save(d / f"{n:05d}.png")
                    n += 1
            if kind == "mp4":
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(fps), "-i", str(d / "%05d.png"),
                                "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "23", "-preset", "slow",
                                "-movflags", "+faststart", str(out_mp4)], check=True)
            else:
                out = out_gifs[theme]
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", "20", "-i", str(d / "%05d.png"),
                                "-vf", "split[a][b];[a]palettegen=max_colors=160:stats_mode=diff[p];[b][p]paletteuse=dither=sierra2_4a:diff_mode=rectangle",
                                "-loop", "0", str(out)], check=True)


def gifs(name):
    return {t: GIF / f"{name}-{t}.gif" for t in ("light", "dark")}


def main():
    MEDIA.mkdir(parents=True, exist_ok=True)
    GIF.mkdir(exist_ok=True)
    (MEDIA / "structures").mkdir(exist_ok=True)
    # stills
    for p in sorted(REN.glob("world-*.png")) + sorted(REN.glob("biome-*.png")) + [REN / "caves.png", REN / "caves-whole.png"]:
        if p.exists():
            webp(p, MEDIA / (p.stem + ".webp"), 1400)
    webp(REN / "hero.png", MEDIA / "hero.webp", 2200, 90)
    for p in sorted(REN.glob("s-*.png")):
        webp(p, MEDIA / "structures" / (p.stem[2:] + ".webp"), 360, 86)
    print("stills done")

    # generation: parcels in the order the plugin writes them
    gen = sorted((REN / "gen").glob("*.png"))
    frames = [(gen[0], 0.5)] + [(p, 0.09) for p in gen[1:-1]] + [(gen[-1], 2.2)]
    sequence(frames, MEDIA / "generate.mp4", gifs("generate"))
    shutil.copy(gen[-1], REN / "generate-last.png")
    on(Image.open(gen[-1]), sky(Image.open(gen[-1]).size)).save(MEDIA / "generate.webp", quality=86)

    er = sorted((REN / "erase").glob("*.png"))
    frames = [(er[0], 0.7)] + [(p, 0.22) for p in er[1:-1]] + [(er[-1], 1.8)]
    sequence(frames, MEDIA / "erase.mp4", gifs("erase"))
    on(Image.open(er[8]), sky(Image.open(er[8]).size)).save(MEDIA / "erase.webp", quality=86)

    rg = sorted((REN / "region").glob("*.png"))
    frames = [(rg[0], 0.7), (rg[1], 0.7)] + [(p, 0.18) for p in rg[2:-2]] + [(rg[-2], 0.9), (rg[-1], 2.0)]
    sequence(frames, MEDIA / "region.mp4", gifs("region"))
    on(Image.open(rg[-2]), sky(Image.open(rg[-2]).size)).save(MEDIA / "region.webp", quality=86)

    st = sorted((REN / "struct").glob("*.png"))
    frames = [(st[0], 0.8)]
    for i in range(1, len(st)):
        frames.append((st[i], 0.45 if i % 2 == 1 else 0.5))
    frames[-1] = (st[-1], 2.2)
    sequence(frames, MEDIA / "structures.mp4", gifs("structures"))
    on(Image.open(st[-1]), sky(Image.open(st[-1]).size)).save(MEDIA / "structures.webp", quality=86)

    # eight worlds, cross-faded
    worlds = ["alp", "nehir", "kanyon", "volkan", "arktik", "bataklik", "sahil", "karisik"]
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        frames = []
        imgs = [Image.open(REN / f"world-{w}.png").convert("RGBA").resize((1000, 643), Image.LANCZOS) for w in worlds]
        k = 0
        for i, im in enumerate(imgs):
            nxt = imgs[(i + 1) % len(imgs)]
            p = tmp / f"{k:03d}.png"; im.save(p); frames.append((p, 1.3)); k += 1
            for s in range(1, 6):
                p = tmp / f"{k:03d}.png"; Image.blend(im, nxt, s / 6).save(p); frames.append((p, 0.06)); k += 1
        sequence(frames, MEDIA / "worlds.mp4", gifs("worlds"))
    print("animations done")


if __name__ == "__main__":
    main()
