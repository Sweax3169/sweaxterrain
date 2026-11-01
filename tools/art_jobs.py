"""Write the Blender render jobs for the README and website art (renders go to build/renders).

    python tools/art_jobs.py            -> build/jobs-*.json
    blender -b --factory-startup -P tools/render_blender.py -- build/jobs-stills.json

The dumps come from Studio (tools/studio_dump.lua): presets, biomes, caves, eraser, region,
structures. Scene positions here must match the ones used in Studio.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DUMPS = ROOT / "dumps"
BUILD = ROOT / "build"
R = "build/renders/"
SUN = {"yaw": 150, "pitch": 40}
PRESETS = ["alp", "nehir", "kanyon", "volkan", "arktik", "bataklik", "sahil", "karisik"]
BIOMES = ["ova", "tepe", "dag", "plato", "kanyon", "volkan", "col", "arktik", "bataklik"]


def iso(target, ortho, yaw=38, pitch=33):
    return {"ortho": ortho, "target": target, "yaw": yaw, "pitch": pitch, "dist": 2400}


def stills():
    jobs = []
    for i, p in enumerate(PRESETS):
        jobs.append({"out": R + f"world-{p}.png", "res": [1400, 900], "samples": 48,
                     "terrain": [{"file": f"dumps/{p}.vox"}], "camera": iso([i * 640, 22, 0], 800), "sun": SUN})
    jobs.append({"out": R + "hero.png", "res": [2200, 1240], "samples": 64,
                 "terrain": [{"file": "dumps/hero.vox"}], "camera": iso([0, 20, -2200], 1150, 36, 31), "sun": SUN})
    for i, b in enumerate(BIOMES):
        jobs.append({"out": R + f"biome-{b}.png", "res": [900, 640], "samples": 48,
                     "terrain": [{"file": f"dumps/b_{b}.vox"}],
                     "camera": {"auto": True, "margin": 1.04, "target": [1200 + i * 400, 20, -2200], "yaw": 38, "pitch": 33, "dist": 2400},
                     "sun": SUN})
    jobs.append({"out": R + "caves.png", "res": [1400, 900], "samples": 48,
                 "terrain": [{"file": "dumps/caves.vox", "cut_z": 46}],
                 "camera": iso([0, 10, -3200], 620, 30, 22), "sun": {"yaw": 160, "pitch": 34}})
    jobs.append({"out": R + "caves-whole.png", "res": [1400, 900], "samples": 48,
                 "terrain": [{"file": "dumps/caves.vox"}],
                 "camera": iso([0, 10, -3200], 620, 30, 22), "sun": {"yaw": 160, "pitch": 34}})
    return jobs


def gallery():
    jobs = []
    for f in sorted(DUMPS.glob("y_*.parts")):
        ad = f.stem[2:]
        jobs.append({"out": R + f"s-{ad}.png", "res": [520, 520], "samples": 32, "parts": [{"file": f"dumps/{f.name}"}],
                     "camera": {"auto": True, "margin": 1.1, "target": [380, 0, 1080], "yaw": 35, "pitch": 28, "dist": 2000},
                     "sun": SUN})
    for f in sorted(DUMPS.glob("a_*.vox")):
        ad = f.stem[2:]
        jobs.append({"out": R + f"s-{ad}.png", "res": [520, 520], "samples": 32, "terrain": [{"file": f"dumps/{f.name}"}],
                     "camera": {"auto": True, "margin": 1.06, "target": [380, 0, 1080], "yaw": 35, "pitch": 34, "dist": 2000},
                     "sun": SUN})
    return jobs


def frames():
    jobs = []
    # 1. generation: the plugin writes 24 x 24 column parcels, x-major (outer loop over x)
    n = 128
    order = [(px, pz) for px in range(0, n, 24) for pz in range(0, n, 24)]
    cam = iso([0, 22, 0], 800)
    for k in range(len(order) + 1):
        parcels = [[px, min(px + 24, n), pz, min(pz + 24, n)] for px, pz in order[:k]]
        if not parcels:
            parcels = [[0, 0, 0, 0]]
        jobs.append({"out": R + f"gen/{k:03d}.png", "res": [1000, 640], "samples": 24,
                     "terrain": [{"file": "dumps/alp.vox", "parcels": parcels}], "camera": cam, "sun": SUN})
    # 2. eraser brush: one dump after every stamp, the red ball where the brush was
    path = json.loads((DUMPS / "er_path.json").read_text())
    cam = iso([0, 6, -4200], 520, 32, 42)
    for k in range(len(path) + 1):
        job = {"out": R + f"erase/{k:03d}.png", "res": [1000, 640], "samples": 24,
               "terrain": [{"file": f"dumps/er_{k:02d}.vox"}], "camera": cam, "sun": SUN}
        if k < len(path):
            job["spheres"] = [{"center": path[k], "radius": 16, "alpha": 0.32}]
        jobs.append(job)
    # 3. region erase: corners, the selection box grows, then the region is gone
    box = json.loads((DUMPS / "rg_box.json").read_text())
    cam = iso([0, 30, -5000], 640, 35, 36)
    k1, k2, mn, mx = box["k1"], box["k2"], box["min"], box["max"]
    steps = []
    steps.append({"spheres": [{"center": k1, "radius": 5, "alpha": 0.9, "emit": 1.5}]})
    steps.append({"spheres": [{"center": k1, "radius": 5, "alpha": 0.9, "emit": 1.5}, {"center": k2, "radius": 5, "alpha": 0.9, "emit": 1.5}]})
    for t in (0.25, 0.5, 0.75, 1.0):
        top = mn[1] + (mx[1] - mn[1]) * t
        steps.append({"boxes": [{"min": mn, "max": [mx[0], top, mx[2]], "alpha": 0.22}],
                      "spheres": [{"center": k1, "radius": 5, "alpha": 0.9, "emit": 1.5}, {"center": k2, "radius": 5, "alpha": 0.9, "emit": 1.5}]})
    for k, s in enumerate(steps):
        jobs.append({"out": R + f"region/{k:03d}.png", "res": [1000, 640], "samples": 24,
                     "terrain": [{"file": "dumps/rg_0.vox"}], "camera": cam, "sun": SUN, **s})
    jobs.append({"out": R + f"region/{len(steps):03d}.png", "res": [1000, 640], "samples": 24,
                 "terrain": [{"file": "dumps/rg_1.vox"}], "camera": cam, "sun": SUN})
    # 4. structures placed one by one: ghost preview first, then the real thing
    plan = json.loads((DUMPS / "st_plan.json").read_text())
    cam = iso([-5, 12, -5790], 330, 28, 34)
    k = 0
    for i in range(len(plan) + 1):
        solid = [{"file": f"dumps/st_{j + 1:02d}.parts"} for j in range(i)]
        jobs.append({"out": R + f"struct/{k:03d}.png", "res": [1000, 640], "samples": 24,
                     "terrain": [{"file": "dumps/st_0.vox"}], "parts": solid, "camera": cam, "sun": SUN})
        k += 1
        if i < len(plan):
            ghost = solid + [{"file": f"dumps/st_{i + 1:02d}.parts", "ghost": True}]
            jobs.append({"out": R + f"struct/{k:03d}.png", "res": [1000, 640], "samples": 24,
                         "terrain": [{"file": "dumps/st_0.vox"}], "parts": ghost, "camera": cam, "sun": SUN})
            k += 1
    return jobs


if __name__ == "__main__":
    BUILD.mkdir(exist_ok=True)
    for name, fn in (("stills", stills), ("gallery", gallery), ("frames", frames)):
        jobs = fn()
        (BUILD / f"jobs-{name}.json").write_text(json.dumps(jobs), encoding="utf-8")
        print(name, len(jobs), "jobs")
