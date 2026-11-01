"""Render terrain and structure dumps with Blender (README and website art).

    blender -b --factory-startup -P tools/render_blender.py -- jobs.json

jobs.json: [{"out": "x.png", "res": [w, h], "samples": 32,
             "terrain": [{"file": "dumps/a.vox", "keep": {"x": [0, 64], "z": [0, 64]}, "cut_z": 40}],
             "parts": [{"file": "dumps/y.parts", "ghost": false}],
             "spheres": [{"center": [x, y, z], "radius": r, "color": [r, g, b], "alpha": 0.35}],
             "boxes": [{"min": [...], "max": [...], "color": [...], "alpha": 0.3}],
             "camera": {"ortho": 420, "target": [x, y, z], "yaw": 35, "pitch": 32, "dist": 900}
                    or {"lens": 40, "pos": [x, y, z], "target": [x, y, z]},
             "sun": {"yaw": 140, "pitch": 38}}]
Everything is in Roblox studs and Roblox axes (Y up); the script converts to Blender (Z up).
Output is a transparent PNG; tools/art.py composites it onto light and dark backgrounds.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from voxels import Voxels  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent

# on-screen colour of Roblox terrain materials (linear-ish sRGB 0..255), roughness, emission
MAT = {
    "Grass": ((92, 128, 50), 0.95, 0), "LeafyGrass": ((78, 112, 46), 0.95, 0),
    "Ground": ((118, 98, 68), 0.95, 0), "Rock": ((112, 114, 116), 0.85, 0),
    "Slate": ((86, 92, 92), 0.8, 0), "Snow": ((236, 240, 248), 0.6, 0),
    "Glacier": ((168, 210, 238), 0.35, 0), "Ice": ((176, 220, 240), 0.2, 0),
    "Sand": ((214, 192, 140), 0.95, 0), "Sandstone": ((176, 116, 82), 0.9, 0),
    "Mud": ((80, 64, 50), 0.7, 0), "Basalt": ((50, 48, 54), 0.85, 0),
    "CrackedLava": ((255, 108, 24), 0.6, 1), "Limestone": ((214, 196, 166), 0.9, 0),
    "Cobblestone": ((128, 122, 104), 0.9, 0), "Salt": ((214, 208, 200), 0.8, 0),
}
WATER = (46, 110, 168)


def rbx_to_bl(p):
    """Roblox (x, y, z) -> Blender (x, -z, y). Works on (..., 3) arrays."""
    p = np.asarray(p, dtype=np.float64)
    return np.stack([p[..., 0], -p[..., 2], p[..., 1]], axis=-1)


# ---------------------------------------------------------------- scene
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    try:
        sc.view_settings.view_transform = "AgX"
        sc.view_settings.look = "AgX - Punchy"
    except Exception:
        pass
    return sc


def world(sun_yaw, sun_pitch):
    w = bpy.data.worlds.new("w")
    bpy.context.scene.world = w
    w.use_nodes = True
    nt = w.node_tree
    bg = nt.nodes["Background"]
    sky = nt.nodes.new("ShaderNodeTexSky")
    for t in ("MULTIPLE_SCATTERING", "SINGLE_SCATTERING", "HOSEK_WILKIE"):
        try:
            sky.sky_type = t
            break
        except Exception:
            continue
    try:
        sky.sun_elevation = math.radians(sun_pitch)
        sky.sun_rotation = math.radians(sun_yaw)
        sky.sun_disc = False
    except Exception:
        pass
    nt.links.new(sky.outputs[0], bg.inputs[0])
    bg.inputs[1].default_value = 0.16
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 5.5
    sun.angle = math.radians(3.0)
    sun.color = (1.0, 0.96, 0.9)
    ob = bpy.data.objects.new("sun", sun)
    bpy.context.scene.collection.objects.link(ob)
    ob.rotation_euler = (math.radians(90 - sun_pitch), 0, math.radians(sun_yaw))


def material_vertex(name, alpha=1.0, emissive=False):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    p = nt.nodes["Principled BSDF"]
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "col"
    rough = nt.nodes.new("ShaderNodeAttribute")
    rough.attribute_name = "rough"
    em = nt.nodes.new("ShaderNodeAttribute")
    em.attribute_name = "emit"
    # small-scale noise so flat colours read as a surface
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 0.35
    noise.inputs["Detail"].default_value = 6
    tc = nt.nodes.new("ShaderNodeTexCoord")
    nt.links.new(tc.outputs["Object"], noise.inputs["Vector"])
    ramp = nt.nodes.new("ShaderNodeMapRange")
    ramp.inputs["To Min"].default_value = 0.86
    ramp.inputs["To Max"].default_value = 1.12
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Value"])
    mul = nt.nodes.new("ShaderNodeMix")
    mul.data_type = "RGBA"
    mul.blend_type = "MULTIPLY"
    mul.inputs["Factor"].default_value = 1.0
    nt.links.new(attr.outputs["Color"], mul.inputs[6])
    nt.links.new(ramp.outputs["Result"], mul.inputs[7])
    nt.links.new(mul.outputs[2], p.inputs["Base Color"])
    nt.links.new(rough.outputs["Fac"], p.inputs["Roughness"])
    if emissive:
        nt.links.new(attr.outputs["Color"], p.inputs["Emission Color"])
        mathn = nt.nodes.new("ShaderNodeMath")
        mathn.operation = "MULTIPLY"
        mathn.inputs[1].default_value = 6.0
        nt.links.new(em.outputs["Fac"], mathn.inputs[0])
        nt.links.new(mathn.outputs[0], p.inputs["Emission Strength"])
    if alpha < 1:
        p.inputs["Alpha"].default_value = alpha
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            m.blend_method = "BLEND"
    return m


def material_flat(name, color, alpha=1.0, rough=0.4, emit=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    c = tuple(srgb_to_lin(np.array(color, dtype=np.float64) / 255.0)) + (1.0,)
    p.inputs["Base Color"].default_value = c
    p.inputs["Roughness"].default_value = rough
    if emit > 0:
        p.inputs["Emission Color"].default_value = c
        p.inputs["Emission Strength"].default_value = emit
    if alpha < 1:
        p.inputs["Alpha"].default_value = alpha
        try:
            m.surface_render_method = "BLENDED"
        except Exception:
            m.blend_method = "BLEND"
    return m


def srgb_to_lin(c):
    c = np.asarray(c, dtype=np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def make_mesh(name, verts, faces, cols=None, rough=None, emit=None, mat=None, smooth=True):
    me = bpy.data.meshes.new(name)
    me.vertices.add(len(verts))
    me.vertices.foreach_set("co", np.asarray(verts, dtype=np.float32).ravel())
    faces = np.asarray(faces, dtype=np.int64)
    nf = len(faces)
    k = faces.shape[1]
    me.loops.add(nf * k)
    me.loops.foreach_set("vertex_index", faces.ravel().astype(np.int32))
    me.polygons.add(nf)
    me.polygons.foreach_set("loop_start", (np.arange(nf) * k).astype(np.int32))
    me.update(calc_edges=True)
    if cols is not None:
        a = me.color_attributes.new("col", "FLOAT_COLOR", "POINT")
        rgba = np.concatenate([srgb_to_lin(cols), np.ones((len(cols), 1))], axis=1)
        a.data.foreach_set("color", rgba.astype(np.float32).ravel())
    for nm, arr in (("rough", rough), ("emit", emit)):
        if arr is not None:
            a = me.attributes.new(nm, "FLOAT", "POINT")
            a.data.foreach_set("value", np.asarray(arr, dtype=np.float32))
    if smooth:
        me.polygons.foreach_set("use_smooth", np.ones(nf, dtype=bool))
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if mat:
        me.materials.append(mat)
    return ob


# ---------------------------------------------------------------- surface nets
EDGES = [((0, 0, 0), (1, 0, 0)), ((0, 1, 0), (1, 1, 0)), ((0, 0, 1), (1, 0, 1)), ((0, 1, 1), (1, 1, 1)),
         ((0, 0, 0), (0, 1, 0)), ((1, 0, 0), (1, 1, 0)), ((0, 0, 1), (0, 1, 1)), ((1, 0, 1), (1, 1, 1)),
         ((0, 0, 0), (0, 0, 1)), ((1, 0, 0), (1, 0, 1)), ((0, 1, 0), (0, 1, 1)), ((1, 1, 0), (1, 1, 1))]


def surface_nets(F, iso=0.5):
    """F: padded scalar field. Returns verts (in grid units), quads, cell index of each vert."""
    N = np.array(F.shape)
    inside = F > iso
    C = N - 1
    acc = np.zeros(tuple(C) + (3,), dtype=np.float64)
    cnt = np.zeros(tuple(C), dtype=np.int32)
    for a, b in EDGES:
        fa = F[a[0]:a[0] + C[0], a[1]:a[1] + C[1], a[2]:a[2] + C[2]]
        fb = F[b[0]:b[0] + C[0], b[1]:b[1] + C[1], b[2]:b[2] + C[2]]
        ia = fa > iso
        ib = fb > iso
        diff = ia != ib
        if not diff.any():
            continue
        t = np.clip((iso - fa) / np.where(np.abs(fb - fa) < 1e-6, 1e-6, fb - fa), 0, 1)
        for d in range(3):
            pos = a[d] + (b[d] - a[d]) * t
            acc[..., d] += np.where(diff, pos, 0)
        cnt += diff
    active = cnt > 0
    idx = -np.ones(tuple(C), dtype=np.int64)
    ci = np.argwhere(active)
    idx[active] = np.arange(len(ci))
    verts = ci + acc[active] / cnt[active][:, None]
    quads = []
    # x-edges: point (i,j,k)-(i+1,j,k), cells (i,j-1,k-1),(i,j,k-1),(i,j,k),(i,j-1,k)
    for axis in range(3):
        o = [0, 0, 0]
        o[axis] = 1
        p0 = inside[:N[0] - o[0], :N[1] - o[1], :N[2] - o[2]]
        p1 = inside[o[0]:, o[1]:, o[2]:]
        sl = [slice(None)] * 3
        u, v = [d for d in range(3) if d != axis]
        sl[u] = slice(1, None)
        sl[v] = slice(1, None)
        crossing = (p0 != p1)
        ijk = np.argwhere(crossing[tuple(sl)])
        if len(ijk) == 0:
            continue
        ijk[:, u] += 1
        ijk[:, v] += 1
        flip = p0[tuple(ijk.T)]

        def cell(du, dv):
            c = ijk.copy()
            c[:, u] -= du
            c[:, v] -= dv
            return idx[tuple(c.T)]

        q = np.stack([cell(1, 1), cell(0, 1), cell(0, 0), cell(1, 0)], axis=1)
        q = np.where(flip[:, None], q, q[:, ::-1])
        if axis == 1:
            q = q[:, ::-1]
        quads.append(q)
    quads = np.concatenate(quads) if quads else np.zeros((0, 4), dtype=np.int64)
    quads = quads[(quads >= 0).all(axis=1)]
    return verts, quads, ci


def terrain_objects(spec, mats):
    v = Voxels(ROOT / spec["file"])
    mat_idx = v.mat.copy()
    occ_solid = v.solid_mask()
    occ_water = v.water_mask()
    sx = slice(*spec["keep"]["x"]) if "keep" in spec and "x" in spec["keep"] else slice(None)
    sz = slice(*spec["keep"]["z"]) if "keep" in spec and "z" in spec["keep"] else slice(None)
    mask = np.zeros(v.mat.shape, dtype=bool)
    mask[sx, :, sz] = True
    if "parcels" in spec:  # list of [x0, x1, z0, z1] column ranges that exist so far
        mask[:] = False
        for x0, x1, z0, z1 in spec["parcels"]:
            mask[x0:x1, :, z0:z1] = True
    if "cut_z" in spec:  # cross-section: drop everything in front of this voxel row
        mask[:, :, :spec["cut_z"]] = False
    occ_solid = np.where(mask, occ_solid, 0)
    occ_water = np.where(mask, occ_water, 0)
    origin = np.array([v.x0, v.y0, v.z0], dtype=np.float64) + np.array(spec.get("offset", [0, 0, 0]))
    names = v.materials
    table = np.array([MAT.get(n, ((255, 0, 255), 0.9, 0))[0] for n in names], dtype=np.float64) / 255.0
    rtab = np.array([MAT.get(n, ((0, 0, 0), 0.9, 0))[1] for n in names], dtype=np.float64)
    etab = np.array([MAT.get(n, ((0, 0, 0), 0.9, 0))[2] for n in names], dtype=np.float64)
    out = []
    for kind, occ in (("solid", occ_solid), ("water", occ_water)):
        if occ.max() <= 0.5:
            continue
        F = np.pad(occ, 1)
        verts, quads, ci = surface_nets(F)
        if len(quads) == 0:
            continue
        world = origin + (verts - 1 + 0.5) * v.res
        if kind == "solid":
            # vertex material: most solid corner, preferring the top one (surface material)
            M = np.pad(mat_idx, 1)
            best = np.full(len(ci), -1.0)
            pick = np.zeros(len(ci), dtype=np.int64)
            for dx in (0, 1):
                for dy in (0, 1):
                    for dz in (0, 1):
                        c = ci + np.array([dx, dy, dz])
                        f = F[tuple(c.T)]
                        score = np.where(f > 0.01, f + 0.02 * c[:, 1], -1)
                        better = score > best
                        best = np.where(better, score, best)
                        pick = np.where(better, M[tuple(c.T)], pick)
            cols, rough, emit = table[pick], rtab[pick], etab[pick]
            ob = make_mesh("terrain", rbx_to_bl(world), quads, cols, rough, emit, mats["terrain"])
        else:
            ob = make_mesh("water", rbx_to_bl(world), quads, mat=mats["water"])
        mod = ob.modifiers.new("smooth", "CORRECTIVE_SMOOTH") if kind == "solid" else ob.modifiers.new("smooth", "SMOOTH")
        if kind == "solid":
            mod.iterations = 3
            mod.factor = 0.5
            mod.use_only_smooth = True
        else:
            mod.iterations = 4
        out.append(ob)
    return out


# ---------------------------------------------------------------- parts
PART_MAT = {"Neon": (0.3, 4.0), "Glass": (0.05, 0), "Metal": (0.35, 0), "SmoothPlastic": (0.45, 0),
            "Plastic": (0.55, 0), "Wood": (0.8, 0), "WoodPlanks": (0.85, 0), "Slate": (0.85, 0),
            "Cobblestone": (0.9, 0), "Grass": (0.95, 0), "Brick": (0.9, 0), "Concrete": (0.9, 0),
            "Fabric": (0.95, 0), "Marble": (0.3, 0), "Granite": (0.6, 0), "Rock": (0.85, 0),
            "DiamondPlate": (0.4, 0), "CorrodedMetal": (0.8, 0), "Sand": (0.95, 0), "Ice": (0.2, 0)}


def unit_shape(shape):
    """Vertices in a unit box (-0.5..0.5) and faces for each Roblox part shape."""
    if shape == "Cylinder":  # axis along local X
        n = 18
        a = np.linspace(0, 2 * math.pi, n, endpoint=False)
        ring = np.stack([np.cos(a) * 0.5, np.sin(a) * 0.5], axis=1)
        v = np.concatenate([np.c_[np.full(n, -0.5), ring], np.c_[np.full(n, 0.5), ring]])
        f = [[i, (i + 1) % n, n + (i + 1) % n, n + i] for i in range(n)]
        f.append(list(range(n))[::-1])
        f.append(list(range(n, 2 * n)))
        return v, f
    if shape == "Ball":
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.5)
        o = bpy.context.active_object
        v = np.array([x.co[:] for x in o.data.vertices])
        f = [list(p.vertices) for p in o.data.polygons]
        bpy.data.objects.remove(o)
        return v, f
    if shape == "Wedge":
        v = np.array([[-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [0.5, -0.5, 0.5], [-0.5, -0.5, 0.5],
                      [-0.5, 0.5, 0.5], [0.5, 0.5, 0.5]])
        f = [[0, 1, 2, 3], [3, 2, 5, 4], [0, 4, 5, 1], [0, 3, 4], [1, 5, 2]]
        return v, f
    v = np.array([[x, y, z] for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)])
    f = [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]
    return v, f


SHAPES = {}


def part_objects(spec, offset=(0, 0, 0)):
    parts = json.loads((ROOT / spec["file"]).read_text(encoding="utf-8"))
    ghost = spec.get("ghost", False)
    groups = {}
    for p in parts:
        key = (p["m"], round(p["t"], 2) if not ghost else 0.6)
        groups.setdefault(key, []).append(p)
    out = []
    for (mname, t), plist in groups.items():
        verts, faces, cols = [], [], []
        base = 0
        for p in plist:
            shape = p["s"] if p["s"] in ("Cylinder", "Ball", "Wedge") else "Block"
            if shape not in SHAPES:
                SHAPES[shape] = unit_shape(shape)
            uv, uf = SHAPES[shape]
            cf = p["cf"]
            pos = np.array(cf[0:3]) + np.array(offset) + np.array(spec.get("offset", [0, 0, 0]))
            R = np.array(cf[3:12]).reshape(3, 3)
            local = uv * np.array(p["size"])
            w = pos + local @ R.T
            verts.append(rbx_to_bl(w))
            for face in uf:
                faces.append([base + i for i in face])
            cols.append(np.repeat([p["c"]], len(uv), axis=0))
            base += len(uv)
        verts = np.concatenate(verts)
        cols = np.concatenate(cols)
        rough, emit = PART_MAT.get(mname, (0.6, 0))
        alpha = 1.0 - t
        if ghost:
            alpha = 0.4
        m = bpy.data.materials.new(f"part_{mname}_{t}")
        m.use_nodes = True
        nt = m.node_tree
        pr = nt.nodes["Principled BSDF"]
        attr = nt.nodes.new("ShaderNodeAttribute")
        attr.attribute_name = "col"
        nt.links.new(attr.outputs["Color"], pr.inputs["Base Color"])
        pr.inputs["Roughness"].default_value = rough
        if mname == "Metal":
            pr.inputs["Metallic"].default_value = 0.6
        if emit > 0:
            nt.links.new(attr.outputs["Color"], pr.inputs["Emission Color"])
            pr.inputs["Emission Strength"].default_value = emit
        if alpha < 0.99:
            pr.inputs["Alpha"].default_value = max(alpha, 0.15)
            try:
                m.surface_render_method = "BLENDED"
            except Exception:
                m.blend_method = "BLEND"
        # faces have mixed sizes (tris/quads/ngons): build with from_pydata
        me = bpy.data.meshes.new("parts")
        me.from_pydata(verts.tolist(), [], faces)
        me.update()
        a = me.color_attributes.new("col", "FLOAT_COLOR", "POINT")
        rgba = np.concatenate([srgb_to_lin(cols), np.ones((len(cols), 1))], axis=1)
        a.data.foreach_set("color", rgba.astype(np.float32).ravel())
        me.materials.append(m)
        ob = bpy.data.objects.new("parts", me)
        bpy.context.scene.collection.objects.link(ob)
        out.append(ob)
    return out


def sphere(spec):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=spec["radius"],
                                         location=tuple(rbx_to_bl(spec["center"])))
    o = bpy.context.active_object
    bpy.ops.object.shade_smooth()
    o.data.materials.append(material_flat("sph", spec.get("color", (235, 90, 80)), spec.get("alpha", 0.35), 0.3, spec.get("emit", 0.6)))
    return o


def box(spec):
    mn, mx = np.array(spec["min"], dtype=float), np.array(spec["max"], dtype=float)
    c = (mn + mx) / 2
    s = mx - mn
    bpy.ops.mesh.primitive_cube_add(size=1, location=tuple(rbx_to_bl(c)))
    o = bpy.context.active_object
    o.scale = (s[0], s[2], s[1])
    o.data.materials.append(material_flat("box", spec.get("color", (235, 90, 80)), spec.get("alpha", 0.25), 0.4, spec.get("emit", 0.8)))
    return o


# ---------------------------------------------------------------- camera
def camera(spec):
    cam = bpy.data.cameras.new("cam")
    ob = bpy.data.objects.new("cam", cam)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.scene.camera = ob
    cam.clip_start = 1
    cam.clip_end = 20000
    target = np.array(spec["target"], dtype=float)
    if "pos" in spec:
        pos = np.array(spec["pos"], dtype=float)
    else:
        yaw, pitch, dist = math.radians(spec["yaw"]), math.radians(spec["pitch"]), spec.get("dist", 1500)
        pos = target + dist * np.array([math.sin(yaw) * math.cos(pitch), math.sin(pitch), -math.cos(yaw) * math.cos(pitch)])
    if "ortho" in spec:
        cam.type = "ORTHO"
        cam.ortho_scale = spec["ortho"]
    else:
        cam.lens = spec.get("lens", 40)
    p, t = rbx_to_bl(pos), rbx_to_bl(target)
    ob.location = tuple(p)
    d = t - p
    import mathutils
    ob.rotation_euler = mathutils.Vector(tuple(d)).to_track_quat("-Z", "Y").to_euler()
    if "shift" in spec:
        cam.shift_x, cam.shift_y = spec["shift"]
    if spec.get("auto"):
        frame_all(ob, cam, spec.get("margin", 1.08))


def frame_all(ob, cam, margin):
    """Orthographic camera: centre on every mesh in the scene and fit it into the frame."""
    import mathutils
    bpy.context.view_layer.update()
    inv = ob.matrix_world.inverted()
    pts = []
    for o in bpy.context.scene.objects:
        if o.type != "MESH":
            continue
        for c in o.bound_box:
            pts.append(inv @ (o.matrix_world @ mathutils.Vector(c)))
    if not pts:
        return
    xs = [p.x for p in pts]
    ys = [p.y for p in pts]
    w, h = max(xs) - min(xs), max(ys) - min(ys)
    sc = bpy.context.scene
    aspect = sc.render.resolution_x / sc.render.resolution_y
    cam.type = "ORTHO"
    cam.ortho_scale = max(w, h * aspect) * margin
    cx, cy = (max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2
    ob.location = ob.matrix_world @ mathutils.Vector((cx, cy, 0))


# ---------------------------------------------------------------- main
def render(job):
    sc = reset()
    sun = job.get("sun", {"yaw": 140, "pitch": 38})
    world(sun["yaw"], sun["pitch"])
    mats = {
        "terrain": material_vertex("terrain", emissive=True),
        "water": material_flat("water", job.get("water", WATER), 0.78, 0.04),
    }
    for t in job.get("terrain", []):
        terrain_objects(t, mats)
    for p in job.get("parts", []):
        part_objects(p)
    for s in job.get("spheres", []):
        sphere(s)
    for b in job.get("boxes", []):
        box(b)
    w, h = job.get("res", [1600, 1000])
    sc.render.resolution_x, sc.render.resolution_y = w, h
    camera(job["camera"])
    sc.render.resolution_percentage = 100
    try:
        sc.eevee.taa_render_samples = job.get("samples", 32)
        sc.eevee.use_shadows = True
        sc.eevee.use_raytracing = job.get("raytracing", False)
    except Exception:
        pass
    out = ROOT / job["out"]
    out.parent.mkdir(parents=True, exist_ok=True)
    sc.render.filepath = str(out)
    bpy.ops.render.render(write_still=True)
    print("RENDERED", out)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:]
    jobs = json.loads(Path(argv[0]).read_text(encoding="utf-8"))
    for j in jobs:
        render(j)
