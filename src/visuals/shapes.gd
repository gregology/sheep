class_name Shapes
## Builders for the rounded primitive parts that stand-in models and scenery are made of.
## Meshes are cached by size, materials by colour (see Toon).

static var _meshes := {}


static func sphere(parent: Node3D, radius: float, color: Color, pos: Vector3,
		scale := Vector3.ONE, outline := Toon.DEFAULT_OUTLINE) -> MeshInstance3D:
	var key := "sphere%.3f" % radius
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = radius
		m.height = radius * 2.0
		m.radial_segments = 24
		m.rings = 12
		_meshes[key] = m
	return _add(parent, _meshes[key], color, pos, Vector3.ZERO, scale, outline)


## A capsule standing along Y (rotate it to lie it down).
static func capsule(parent: Node3D, radius: float, height: float, color: Color, pos: Vector3,
		rot := Vector3.ZERO, scale := Vector3.ONE, outline := Toon.DEFAULT_OUTLINE) -> MeshInstance3D:
	var key := "capsule%.3f/%.3f" % [radius, height]
	if not _meshes.has(key):
		var m := CapsuleMesh.new()
		m.radius = radius
		m.height = maxf(height, radius * 2.0)
		m.radial_segments = 20
		m.rings = 6
		_meshes[key] = m
	return _add(parent, _meshes[key], color, pos, rot, scale, outline)


## A cylinder (or a cone, when top is 0) standing along Y.
static func cylinder(parent: Node3D, top: float, bottom: float, height: float, color: Color, pos: Vector3,
		rot := Vector3.ZERO, scale := Vector3.ONE, outline := Toon.DEFAULT_OUTLINE) -> MeshInstance3D:
	var key := "cylinder%.3f/%.3f/%.3f" % [top, bottom, height]
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.top_radius = top
		m.bottom_radius = bottom
		m.height = height
		m.radial_segments = 16
		m.rings = 1
		_meshes[key] = m
	return _add(parent, _meshes[key], color, pos, rot, scale, outline)


static func box(parent: Node3D, size: Vector3, color: Color, pos: Vector3,
		rot := Vector3.ZERO, outline := Toon.DEFAULT_OUTLINE) -> MeshInstance3D:
	var key := "box%s" % size
	if not _meshes.has(key):
		var m := BoxMesh.new()
		m.size = size
		_meshes[key] = m
	return _add(parent, _meshes[key], color, pos, rot, Vector3.ONE, outline)


## An empty node to group and animate parts (legs swing from the hip, heads nod from the neck).
static func pivot(parent: Node3D, pivot_name: String, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = pivot_name
	node.position = pos
	parent.add_child(node)
	return node


static func _add(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot_degrees: Vector3,
		scale: Vector3, outline: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = Toon.material(color, outline)
	instance.position = pos
	instance.rotation_degrees = rot_degrees
	instance.scale = scale
	parent.add_child(instance)
	return instance
