"""Read terrain dumps written by tools/studio_dump.lua (via tools/bridge.py)."""
import json
from pathlib import Path

import numpy as np


class Voxels:
    """mat[x, y, z] material name index, occ[x, y, z] occupancy 0..1, origin in studs, res = 4."""

    def __init__(self, path):
        text = Path(path).read_text(encoding="utf-8")
        head, _, body = text.partition("\n")
        h = json.loads(head)
        self.x0, self.y0, self.z0 = h["x0"], h["y0"], h["z0"]
        self.nx, self.ny, self.nz = h["nx"], h["ny"], h["nz"]
        self.res = h.get("res", 4)
        self.materials = h["materials"]
        self.water_color = h.get("water")
        mat = np.zeros((self.nx, self.ny, self.nz), dtype=np.uint8)
        occ = np.zeros((self.nx, self.ny, self.nz), dtype=np.float32)
        lines = body.split("\n")
        i = 0
        for x in range(self.nx):
            for z in range(self.nz):
                y = 0
                for run in lines[i].split(","):
                    m, o, n = run.split(":")
                    n = int(n)
                    mat[x, y:y + n, z] = int(m) - 1
                    occ[x, y:y + n, z] = int(o) / 255.0
                    y += n
                i += 1
        self.mat = mat
        self.occ = occ

    def index(self, name):
        return self.materials.index(name) if name in self.materials else -1

    def solid_mask(self):
        """Occupancy of non-water, non-air voxels."""
        o = self.occ.copy()
        for name in ("Air", "Water"):
            k = self.index(name)
            if k >= 0:
                o[self.mat == k] = 0
        return o

    def water_mask(self):
        k = self.index("Water")
        o = np.zeros_like(self.occ)
        if k >= 0:
            o[self.mat == k] = self.occ[self.mat == k]
        return o

    def heightmap(self):
        """Top solid surface height (studs, world Y) and its material index per column, plus water top."""
        solid = self.solid_mask()
        filled = solid > 0.01
        ny = self.ny
        # highest filled voxel per column
        rev = filled[:, ::-1, :]
        has = rev.any(axis=1)
        top = ny - 1 - rev.argmax(axis=1)
        top = np.where(has, top, 0)
        xi, zi = np.meshgrid(np.arange(self.nx), np.arange(self.nz), indexing="ij")
        o = solid[xi, top, zi]
        h = self.y0 + top * self.res + o * self.res
        h = np.where(has, h, np.nan)
        m = self.mat[xi, top, zi]
        w = self.water_mask() > 0.01
        wrev = w[:, ::-1, :]
        whas = wrev.any(axis=1)
        wtop = ny - 1 - wrev.argmax(axis=1)
        wo = self.water_mask()[xi, wtop, zi]
        wh = np.where(whas, self.y0 + wtop * self.res + wo * self.res, np.nan)
        return h, m, wh
