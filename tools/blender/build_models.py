"""Builds every creature model and exports one .glb per creature into assets/models/.

Run through tools/blender/build_models.sh (it makes sure Blender's Python has numpy,
which the glTF exporter needs):

    tools/blender/build_models.sh

Conventions the game relies on (see CreatureModel and ModelPaint in src/visuals/):
  * Models face +Y in Blender, which becomes -Z (forward) in Godot.
  * Parts are separate objects named Body, Head, Tail, EarL, EarR, LegFL, LegFR, LegBL,
    LegBR. Each object's origin is its pivot: legs swing from the hip, the head nods
    from the neck. Tail hangs off Body; ears hang off Head.
  * Material names are colour *slots* (wool, face, coat, light, bandana, eye...). Godot
    repaints every slot with its toon material, so colours and the player's bandana
    are decided in the game, not here. The colours below are only for previewing in
    Blender.

Shapes are mostly metaballs, which melt into one another for the soft, bubbly look.
"""
import math
import pathlib
import random
import sys

import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

THRESHOLD = 0.6


def surface_factor(stiffness):
    """Where a metaball's surface sits, as a fraction of its radius (cubic falloff)."""
    return math.sqrt(1 - (THRESHOLD / stiffness) ** (1 / 3))


# With the default stiffness of 2 the surface is at 0.574 x the radius.
SURFACE = surface_factor(2.0)

PREVIEW = {
    "wool": (0.99, 0.97, 0.93), "face": (0.33, 0.27, 0.31), "hoof": (0.2, 0.16, 0.19),
    "eye": (1.0, 1.0, 1.0), "pupil": (0.08, 0.06, 0.08), "shine": (1.0, 1.0, 1.0),
    "blush": (0.96, 0.6, 0.7), "ear_inner": (0.96, 0.66, 0.74), "bell": (1.0, 0.8, 0.25),
    "collar": (0.9, 0.3, 0.4), "bow": (0.96, 0.6, 0.7), "coat": (0.18, 0.17, 0.21),
    "coat_dark": (0.14, 0.13, 0.16), "light": (0.98, 0.96, 0.93), "iris": (0.25, 0.15, 0.08),
    "nose": (0.1, 0.08, 0.1), "tongue": (0.95, 0.45, 0.55), "bandana": (1.0, 0.42, 0.42),
    "brow": (0.1, 0.08, 0.1),
}

LEG_NAMES = ["LegFL", "LegFR", "LegBL", "LegBR"]


def srgb_to_linear(c):
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)


def ball(co, radius, stiffness=2.0):
    """A metaball whose visible surface has this radius. Stiffer balls blend less."""
    return {"type": "BALL", "co": co, "r": radius / surface_factor(stiffness), "stiffness": stiffness}


def ellipsoid(co, radius, size, rot=None):
    return {"type": "ELLIPSOID", "co": co, "r": radius / SURFACE, "size": size, "rot": rot}


def capsule(a, b, radius):
    """A metaball capsule from point a to point b."""
    a, b = Vector(a), Vector(b)
    axis = b - a
    rot = Vector((1, 0, 0)).rotation_difference(axis.normalized())
    return {"type": "CAPSULE", "co": tuple((a + b) / 2), "r": radius / SURFACE,
            "size": (axis.length / 2, 1, 1), "rot": rot}


class Model:
    """One creature: a fresh Blender scene, a set of parts and the slot materials."""

    def __init__(self, name, scale=1.0):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        self.name = name
        self.scale = scale
        self.materials = {}
        self.parts = {}
        self._blob_count = 0

    def material(self, slot):
        if slot not in self.materials:
            mat = bpy.data.materials.new(slot)
            color = srgb_to_linear(PREVIEW.get(slot, (0.8, 0.8, 0.8)))
            mat.diffuse_color = (*color, 1.0)
            if mat.node_tree is None:
                mat.use_nodes = True
            bsdf = mat.node_tree.nodes.get("Principled BSDF")
            if bsdf:
                bsdf.inputs["Base Color"].default_value = (*color, 1.0)
                bsdf.inputs["Roughness"].default_value = 1.0
            self.materials[slot] = mat
        return self.materials[slot]

    def part(self, name, pivot, parent=None):
        p = Part(self, name, Vector(pivot) * self.scale, parent)
        self.parts[name] = p
        return p

    def export(self, path):
        objects = {}
        for name, part in self.parts.items():  # parents are always created before children
            objects[name] = part.build(objects.get(part.parent))
        tris = sum(len(o.data.loop_triangles) for o in objects.values() if o.type == "MESH")
        path.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=str(path), export_format="GLB", export_yup=True, export_apply=True,
            export_materials="EXPORT", export_texcoords=False, export_normals=True,
            export_animations=False, export_cameras=False, export_lights=False)
        print(f"MODEL {path.name}: {len(objects)} parts, {tris} triangles")


# Triangles per square metre of surface after decimation, and the limits per shape.
DENSITY = 1100
MIN_TRIS = 80
MAX_TRIS = 1600


def _decimate(mesh, max_tris=MAX_TRIS):
    """Metaballs come out very dense; collapse them to a sensible triangle budget."""
    tris = sum(len(p.vertices) - 2 for p in mesh.polygons)
    area = sum(p.area for p in mesh.polygons)
    target = int(min(max(area * DENSITY, MIN_TRIS), max_tris))
    if tris <= target:
        return mesh
    obj = bpy.data.objects.new("Decimate", mesh)
    bpy.context.scene.collection.objects.link(obj)
    modifier = obj.modifiers.new("Decimate", "DECIMATE")
    modifier.ratio = target / tris
    modifier.use_collapse_triangulate = True
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    result = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
    bpy.data.objects.remove(obj)
    bpy.data.meshes.remove(mesh)
    return result


class Part:
    """A rigid, separately animated piece. Shapes are given in model space."""

    def __init__(self, model, name, pivot, parent):
        self.model = model
        self.name = name
        self.pivot = pivot
        self.parent = parent
        self.bm = bmesh.new()
        self.slots = []

    def _add(self, mesh, slot):
        if slot not in self.slots:
            self.slots.append(slot)
        index = self.slots.index(slot)
        for poly in mesh.polygons:
            poly.material_index = index
            poly.use_smooth = True
        self.bm.from_mesh(mesh)
        bpy.data.meshes.remove(mesh)
        return self

    def blob(self, slot, elements, resolution=None, max_tris=None):
        """Metaball elements that melt together into one smooth shape."""
        s = self.model.scale
        model = self.model
        model._blob_count += 1
        name = f"Blob{model._blob_count}"  # unique: same-named metaballs would merge
        mb = bpy.data.metaballs.new(name)
        size = max(e["r"] * surface_factor(e.get("stiffness", 2.0)) * max(e.get("size") or (1, 1, 1)) for e in elements) * s
        res = resolution or min(max(size * 0.12, 0.009), 0.03)
        mb.resolution = res
        mb.render_resolution = res
        mb.threshold = THRESHOLD
        obj = bpy.data.objects.new(name, mb)
        bpy.context.scene.collection.objects.link(obj)
        for e in elements:
            el = mb.elements.new(type=e["type"])
            el.co = Vector(e["co"]) * s
            el.radius = e["r"] * s
            el.stiffness = e.get("stiffness", 2.0)
            if e.get("size"):
                sx, sy, sz = e["size"]
                # Capsule length is absolute; ellipsoid size is relative.
                el.size_x = sx * s if e["type"] == "CAPSULE" else sx
                el.size_y, el.size_z = sy, sz
            if e.get("rot") is not None:
                el.rotation = e["rot"]
        bpy.context.view_layer.update()
        depsgraph = bpy.context.evaluated_depsgraph_get()
        mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
        bpy.data.objects.remove(obj)
        bpy.data.metaballs.remove(mb)
        return self._add(_decimate(mesh, max_tris or MAX_TRIS), slot)

    def sphere(self, slot, center, radius, scale=(1, 1, 1), segments=20, rings=10):
        s = self.model.scale
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius * s)
        bmesh.ops.scale(bm, vec=Vector(scale), verts=bm.verts)
        bmesh.ops.translate(bm, vec=Vector(center) * s, verts=bm.verts)
        return self._add(self._to_mesh(bm), slot)

    def cone(self, slot, base, tip, radius, flatten=1.0, segments=16):
        """A rounded-ish cone from a base point to a tip, optionally flattened front-to-back."""
        s = self.model.scale
        base, tip = Vector(base) * s, Vector(tip) * s
        axis = tip - base
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=segments,
                              radius1=radius * s, radius2=radius * s * 0.12, depth=axis.length)
        bmesh.ops.scale(bm, vec=Vector((1, flatten, 1)), verts=bm.verts)
        rot = Vector((0, 0, 1)).rotation_difference(axis.normalized()).to_matrix().to_4x4()
        bmesh.ops.transform(bm, matrix=Matrix.Translation((base + tip) / 2) @ rot, verts=bm.verts)
        return self._add(self._to_mesh(bm), slot)

    def ring(self, slot, center, radius, thickness, tilt_degrees=0.0, segments=24):
        """A torus around the Z axis (collars, bandanas)."""
        s = self.model.scale
        bm = bmesh.new()
        verts = []
        minor = 8
        for i in range(segments):
            a = 2 * math.pi * i / segments
            row = []
            for j in range(minor):
                b = 2 * math.pi * j / minor
                r = radius + thickness * math.cos(b)
                row.append(bm.verts.new((r * math.cos(a), r * math.sin(a), thickness * math.sin(b))))
            verts.append(row)
        for i in range(segments):
            for j in range(minor):
                bm.faces.new((verts[i][j], verts[(i + 1) % segments][j],
                              verts[(i + 1) % segments][(j + 1) % minor], verts[i][(j + 1) % minor]))
        m = Matrix.Translation(Vector(center) * s) @ Matrix.Rotation(math.radians(tilt_degrees), 4, "X") @ Matrix.Scale(s, 4)
        bmesh.ops.transform(bm, matrix=m, verts=bm.verts)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        return self._add(self._to_mesh(bm), slot)

    @staticmethod
    def _to_mesh(bm):
        mesh = bpy.data.meshes.new("piece")
        bm.to_mesh(mesh)
        bm.free()
        return mesh

    def build(self, parent_obj):
        mesh = bpy.data.meshes.new(self.name)
        bmesh.ops.translate(self.bm, vec=-self.pivot, verts=self.bm.verts)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for slot in self.slots:
            mesh.materials.append(self.model.material(slot))
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        if parent_obj:
            obj.parent = parent_obj
            obj.location = self.pivot - self.model.parts[self.parent].pivot
        else:
            obj.location = self.pivot
        mesh.calc_loop_triangles()
        return obj


# --- Sheep -------------------------------------------------------------------

def wool_bumps(center, radii, count, bump, seed, min_z=-0.35, spread=0.93):
    """Little balls spread over an ellipsoid's surface: the cloud-like fleece."""
    rng = random.Random(seed)
    elements = []
    golden = math.pi * (3 - math.sqrt(5))
    for i in range(count):
        z = 1 - (i + 0.5) / count * 2
        if z < min_z:
            continue
        r = math.sqrt(1 - z * z)
        a = golden * i
        p = Vector((math.cos(a) * r * radii[0], math.sin(a) * r * radii[1], z * radii[2]))
        elements.append(ball(tuple(Vector(center) + p * spread), bump * rng.uniform(0.85, 1.15), stiffness=10.0))
    return elements


def build_sheep(name, black=False):
    m = Model(name)
    body = m.part("Body", (0, 0, 0))
    centre = (0, -0.02, 0.6)
    body.blob("wool", [ellipsoid(centre, 0.27, (1.0, 1.15, 0.9))]
              + wool_bumps(centre, (0.31, 0.36, 0.28), 34, 0.14, seed=3, spread=1.0),
              max_tris=3000)
    if black:
        body.ring("collar", (0, 0.32, 0.6), 0.13, 0.022, tilt_degrees=-35)
        body.sphere("bell", (0, 0.43, 0.5), 0.06)
    tail = m.part("Tail", (0, -0.44, 0.66), parent="Body")
    tail.blob("wool", [ball((0, -0.5, 0.66), 0.1), ball((0.04, -0.47, 0.71), 0.07), ball((-0.04, -0.47, 0.71), 0.07)])

    head = m.part("Head", (0, 0.34, 0.74))
    head.blob("face", [ball((0, 0.47, 0.74), 0.18),
                       ellipsoid((0, 0.6, 0.67), 0.11, (0.85, 1.1, 0.8))])
    head.blob("wool", [ball((0, 0.44, 0.9), 0.1), ball((0.07, 0.42, 0.88), 0.075), ball((-0.07, 0.42, 0.88), 0.075),
                       ball((0, 0.5, 0.88), 0.07)])
    for side in (-1, 1):
        head.sphere("eye", (0.085 * side, 0.6, 0.78), 0.058, segments=16, rings=8)
        head.sphere("pupil", (0.088 * side, 0.645, 0.78), 0.033, segments=12, rings=6)
        head.sphere("shine", (0.078 * side, 0.672, 0.795), 0.011, segments=8, rings=4)
        head.sphere("blush", (0.115 * side, 0.6, 0.68), 0.04, scale=(1.0, 0.5, 0.6), segments=12, rings=6)
        head.sphere("pupil", (0.025 * side, 0.705, 0.68), 0.012, segments=8, rings=4)  # nostrils
        ear = m.part("EarL" if side < 0 else "EarR", (0.15 * side, 0.45, 0.8), parent="Head")
        ear.blob("face", [ellipsoid((0.24 * side, 0.45, 0.76), 0.085, (1.6, 0.85, 0.55))])
        ear.blob("ear_inner", [ellipsoid((0.25 * side, 0.475, 0.762), 0.05, (1.5, 0.5, 0.45))])
    if black:
        for side in (-1, 1):
            head.blob("bow", [ellipsoid((0.065 * side, 0.43, 0.99), 0.06, (1.3, 0.6, 0.9))])
        head.sphere("bow", (0, 0.43, 0.99), 0.03)

    for leg_name in LEG_NAMES:
        x = -0.17 if leg_name.endswith("L") else 0.17
        y = 0.17 if leg_name.startswith("LegF") else -0.17
        leg = m.part(leg_name, (x, y, 0.36))
        leg.blob("face", [capsule((x, y, 0.36), (x, y, 0.1), 0.055)])
        leg.blob("hoof", [ellipsoid((x, y + 0.01, 0.05), 0.065, (1.0, 1.15, 0.75))])
    return m


# --- Dogs and the wolf ---------------------------------------------------------

DOG_STYLES = {
    "collie": {"legs": 0.3, "ears": "tipped", "tail": "brush", "blaze": True},
    "corgi": {"legs": 0.2, "ears": "tall", "tail": "stub", "blaze": True, "long": True},
    "golden": {"legs": 0.3, "ears": "floppy", "tail": "brush"},
    "husky": {"legs": 0.3, "ears": "tall", "tail": "curl", "blaze": True, "mask": True},
    "wolf": {"legs": 0.34, "ears": "tall", "tail": "bushy", "brows": True, "snout": 1.25, "scale": 1.3},
}


def build_canine(name, style_name):
    st = DOG_STYLES[style_name]
    m = Model(name, scale=st.get("scale", 1.0))
    leg_h = st["legs"]
    hip = leg_h + 0.02
    bz = hip + 0.13  # body height
    half = 0.36 if st.get("long") else 0.3
    snout = st.get("snout", 1.0)

    for leg_name in LEG_NAMES:
        x = -0.13 if leg_name.endswith("L") else 0.13
        y = 0.24 if leg_name.startswith("LegF") else -0.24
        if st.get("long"):
            y *= 1.15
        leg = m.part(leg_name, (x, y, hip))
        leg.blob("coat", [capsule((x, y, hip + 0.04), (x, y, 0.08), 0.06)])
        leg.blob("light", [ellipsoid((x, y + 0.03, 0.045), 0.07, (1.0, 1.3, 0.7))])

    body = m.part("Body", (0, 0, 0))
    body.blob("coat", [capsule((0, -half + 0.08, bz), (0, half - 0.06, bz + 0.02), 0.19),
                       ball((0, -half + 0.06, bz + 0.01), 0.19),
                       ball((0, half - 0.06, bz + 0.04), 0.2),
                       ball((0, half + 0.02, bz + 0.17), 0.13)])  # neck
    body.blob("light", [ellipsoid((0, half + 0.06, bz - 0.01), 0.15, (0.95, 0.7, 1.05))])
    if style_name != "wolf":
        body.ring("bandana", (0, half + 0.04, bz + 0.16), 0.16, 0.06, tilt_degrees=-30)
        body.cone("bandana", (0, half + 0.17, bz + 0.09), (0, half + 0.21, bz - 0.1), 0.13, flatten=0.35)

    tail = m.part("Tail", (0, -half - 0.05, bz + 0.08), parent="Body")
    tail_style = st["tail"]
    if tail_style == "stub":
        tail.blob("coat", [ball((0, -half - 0.1, bz + 0.07), 0.08)])
    else:
        if tail_style == "curl":
            points = [(0, -half - 0.08 - 0.12 * math.sin(a), bz + 0.1 + 0.2 * (1 - math.cos(a))) for a in
                      [i * 0.45 for i in range(7)]]
            radii = [0.065, 0.065, 0.062, 0.06, 0.058, 0.056, 0.055]
        elif tail_style == "bushy":
            points = [(0, -half - 0.08 - 0.09 * i, bz + 0.04 - 0.04 * i + 0.012 * i * i) for i in range(7)]
            radii = [0.08, 0.095, 0.1, 0.1, 0.095, 0.085, 0.07]
        else:  # brush: up and back
            points = [(0, -half - 0.08 - 0.07 * i, bz + 0.09 + 0.06 * i) for i in range(5)]
            radii = [0.065, 0.07, 0.07, 0.066, 0.06]
        tail.blob("coat", [ball(p, r) for p, r in zip(points[:-1], radii[:-1])])
        tail.blob("light", [ball(points[-1], radii[-1]), ball(points[-2], radii[-2] * 0.7)])

    hz = bz + 0.25  # neck pivot height
    head = m.part("Head", (0, half + 0.08, hz))
    hy = half + 0.14  # skull centre, front-back
    head.blob("coat", [ball((0, hy, hz + 0.03), 0.19),
                       ball((0.08, hy + 0.07, hz - 0.03), 0.1),
                       ball((-0.08, hy + 0.07, hz - 0.03), 0.1)])
    muzzle_y = hy + 0.15 * snout
    head.blob("light", [ellipsoid((0, muzzle_y, hz - 0.04), 0.105, (1.0, 1.3 * snout, 0.8)),
                        ball((0, muzzle_y - 0.03, hz - 0.09), 0.07)])
    head.sphere("nose", (0, muzzle_y + 0.115 * snout, hz - 0.01), 0.045, scale=(1.25, 0.95, 0.8), segments=14, rings=7)
    head.blob("tongue", [ellipsoid((0, muzzle_y + 0.03, hz - 0.13), 0.045, (0.9, 1.2, 0.35))])
    if st.get("blaze"):
        head.blob("light", [ellipsoid((0, hy + 0.13, hz + 0.1), 0.06, (0.65, 0.9, 1.6))])
    for side in (-1, 1):
        ex = 0.085 * side
        ey = hy + 0.15
        head.sphere("eye", (ex, ey, hz + 0.08), 0.052, segments=16, rings=8)
        head.sphere("iris", (ex * 1.03, ey + 0.035, hz + 0.08), 0.033, segments=12, rings=6)
        head.sphere("pupil", (ex * 1.05, ey + 0.058, hz + 0.08), 0.017 if style_name == "wolf" else 0.02, segments=10, rings=5)
        head.sphere("shine", (ex * 0.95, ey + 0.068, hz + 0.093), 0.009, segments=8, rings=4)
        if st.get("mask"):
            head.blob("light", [ellipsoid((ex * 1.1, ey - 0.02, hz + 0.09), 0.07, (1.0, 0.6, 0.8))])
        if st.get("brows"):
            head.blob("brow", [capsule((ex * 0.6, ey + 0.03, hz + 0.145), (ex * 1.4, ey + 0.015, hz + 0.155), 0.015)])

        ear = m.part("EarL" if side < 0 else "EarR", (0.11 * side, hy - 0.02, hz + 0.15), parent="Head")
        ears = st["ears"]
        if ears == "floppy":
            ear.blob("coat_dark", [ellipsoid((0.185 * side, hy + 0.03, hz + 0.0), 0.095, (0.6, 1.0, 1.5))])
        else:
            tall = 0.23 if ears == "tall" else 0.17
            tip = (0.16 * side, hy - 0.02, hz + 0.15 + tall)
            if ears == "tipped":
                tip = (0.15 * side, hy + 0.04, hz + 0.15 + tall)
            ear.cone("coat", (0.115 * side, hy - 0.02, hz + 0.12), tip, 0.085, flatten=0.55)
            ear.cone("ear_inner", (0.115 * side, hy + 0.005, hz + 0.13),
                     (tip[0] * 0.97, tip[1] + 0.025, tip[2] - 0.05), 0.05, flatten=0.3)
            if ears == "tipped":
                ear.blob("light", [ball((tip[0], tip[1] + 0.02, tip[2] - 0.01), 0.035)])
    return m


def main():
    out = pathlib.Path(sys.argv[sys.argv.index("--") + 1])
    build_sheep("sheep").export(out / "sheep.glb")
    build_sheep("black_sheep", black=True).export(out / "black_sheep.glb")
    for breed in ("collie", "corgi", "golden", "husky"):
        build_canine(f"dog_{breed}", breed).export(out / f"dog_{breed}.glb")
    build_canine("wolf", "wolf").export(out / "wolf.glb")


main()
