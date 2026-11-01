"""Top-down shaded map of a terrain dump. Quick check of a world, also used for the website.

    python tools/render_map.py dumps/alp.vox out.png [pixels-per-voxel]
"""
import sys

import numpy as np
from PIL import Image

from voxels import Voxels

# approximate on-screen colour of each Roblox terrain material (texture average, default MaterialColors)
COLORS = {
    "Grass": (96, 128, 58), "LeafyGrass": (88, 116, 56), "Ground": (112, 98, 70), "Rock": (110, 112, 114),
    "Slate": (92, 100, 98), "Snow": (232, 236, 244), "Glacier": (176, 212, 234), "Ice": (164, 206, 228),
    "Sand": (200, 180, 132), "Sandstone": (168, 112, 82), "Mud": (78, 64, 52), "Basalt": (54, 52, 58),
    "CrackedLava": (236, 112, 40), "Limestone": (206, 190, 160), "Cobblestone": (128, 122, 104),
    "Water": (40, 96, 150), "Air": (0, 0, 0),
}


def color_table(v):
    return np.array([COLORS.get(n, (255, 0, 255)) for n in v.materials], dtype=np.float32) / 255.0


def shade(v, scale=2):
    h, m, wh = v.heightmap()
    base = color_table(v)[m]
    hh = np.nan_to_num(h, nan=np.nanmin(h))
    gx, gz = np.gradient(hh, v.res)
    # sun from the north-west, 40° up
    sun = np.array([-0.55, 0.64, -0.53])
    n = np.dstack([-gx, np.ones_like(hh), -gz])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    lam = np.clip((n * sun).sum(axis=2), 0, 1)
    light = 0.38 + 0.72 * lam
    rgb = base * light[..., None]
    wet = ~np.isnan(wh) & (np.nan_to_num(wh, nan=-1e9) > hh + 0.2)
    depth = np.clip((np.nan_to_num(wh) - hh) / 14.0, 0, 1)
    water = np.array(COLORS["Water"], dtype=np.float32) / 255.0
    mix = (0.45 + 0.5 * depth)[..., None]
    rgb = np.where(wet[..., None], rgb * (1 - mix) + water * mix, rgb)
    rgb = np.where(np.isnan(h)[..., None], 0.08, rgb)
    img = (np.clip(rgb, 0, 1) * 255).astype(np.uint8)
    # array is [x, z]; show x to the right, z downward
    img = np.transpose(img, (1, 0, 2))
    return Image.fromarray(img).resize((v.nx * scale, v.nz * scale), Image.NEAREST)


if __name__ == "__main__":
    v = Voxels(sys.argv[1])
    shade(v, int(sys.argv[3]) if len(sys.argv) > 3 else 2).save(sys.argv[2])
    print("wrote", sys.argv[2])
