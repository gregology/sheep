class_name Meadow
extends Node3D
## Builds the field from a MeadowLayout: grass, fences, the pen and its swinging
## gate, and the scenery around it. Purely visual; collisions live in FlockSim.

const GROUND_SHADER := preload("res://src/visuals/shaders/ground.gdshader")
const TUFT_SHADER := preload("res://src/visuals/shaders/tuft.gdshader")

const WOOD := Color(0.8, 0.56, 0.33)
const WOOD_LIGHT := Color(0.9, 0.7, 0.45)
const GATE_WHITE := Color(0.98, 0.96, 0.92)
const GATE_RED := Color(0.95, 0.35, 0.35)
const TRUNK := Color(0.55, 0.36, 0.24)
const STRAW := Color(0.97, 0.82, 0.45)
const LEAVES: Array[Color] = [Color(0.33, 0.66, 0.31), Color(0.42, 0.75, 0.34), Color(0.28, 0.58, 0.29)]
const FLOWERS: Array[Color] = [
	Color(1, 1, 1), Color(1.0, 0.86, 0.3), Color(1.0, 0.62, 0.76), Color(0.76, 0.62, 1.0),
]
const POST_SPACING := 2.0
const GATE_SWING := 1.45  # radians when fully open

var layout: MeadowLayout
var pen: PenArea

var _doors: Array[Node3D] = []
var _door_base: Array[float] = []
var _door_sign: Array[float] = []
var _gate_open := 0.0
var _gate_target := 0.0
var _rng := RandomNumberGenerator.new()


func build(meadow_layout: MeadowLayout) -> void:
	layout = meadow_layout
	pen = layout.make_pen()
	_rng.seed = layout.scenery_seed
	_build_ground()
	_build_fences()
	_build_gate()
	_build_corner_bales()
	_build_scenery()
	_build_tufts()


## 0 = closed, 1 = wide open. The gate swings in toward the pen.
func set_gate_target(open: float) -> void:
	_gate_target = clampf(open, 0.0, 1.0)


func _process(delta: float) -> void:
	_gate_open = move_toward(_gate_open, _gate_target, delta * (5.0 if _gate_target > _gate_open else 2.0))
	var eased := ease(_gate_open, -2.0)
	for i in _doors.size():
		_doors[i].rotation.y = _door_base[i] + _door_sign[i] * eased * GATE_SWING


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(140, 100)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("noise", texture)
	var field := layout.field_rect()
	mat.set_shader_parameter("field_rect", Vector4(field.position.x, field.position.y, field.end.x, field.end.y))
	mat.set_shader_parameter("pen_rect", Vector4(pen.rect.position.x, pen.rect.position.y, pen.rect.end.x, pen.rect.end.y))
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = mat
	add_child(ground)


func _build_fences() -> void:
	var fences := Node3D.new()
	fences.name = "Fences"
	add_child(fences)
	var field := layout.field_rect()
	for segment in Geometry.rect_segments(field):
		_fence_line(fences, segment.a, segment.b)
	for segment in pen.walls():
		if not _on_field_edge(segment, field):
			_fence_line(fences, segment.a, segment.b)


func _fence_line(parent: Node3D, a: Vector2, b: Vector2) -> void:
	var length := a.distance_to(b)
	if length < 0.05:
		return
	var dir := (b - a) / length
	var posts := maxi(1, ceili(length / POST_SPACING))
	for i in posts + 1:
		_post(parent, a + dir * (length * i / posts), WOOD, 0.85)
	var yaw := rad_to_deg(atan2(-dir.y, dir.x))
	var middle := (a + b) * 0.5
	for height in [0.33, 0.62]:
		Shapes.box(parent, Vector3(length, 0.1, 0.07), WOOD_LIGHT, Vector3(middle.x, height, middle.y), Vector3(0, yaw, 0))


func _post(parent: Node3D, p: Vector2, color: Color, height: float, cap := Color(0, 0, 0, 0)) -> void:
	Shapes.cylinder(parent, 0.09, 0.1, height, color, Vector3(p.x, height * 0.5, p.y))
	Shapes.sphere(parent, 0.1 if cap.a == 0.0 else 0.15, color if cap.a == 0.0 else cap, Vector3(p.x, height, p.y))


func _build_gate() -> void:
	var gate := Node3D.new()
	gate.name = "Gate"
	add_child(gate)
	var center := pen.gate_center()
	for hinge in [pen.gate_a, pen.gate_b]:
		_post(gate, hinge, GATE_WHITE, 1.15, GATE_RED)
		var dir: Vector2 = (center - hinge).normalized()
		var door := Shapes.pivot(gate, "Door", Geometry.to_3d(hinge))
		var base := atan2(-dir.y, dir.x)
		door.rotation.y = base
		var width := pen.gate_width() * 0.5 - 0.12
		for height in [0.3, 0.7]:
			Shapes.box(door, Vector3(width, 0.1, 0.07), GATE_WHITE, Vector3(width * 0.5 + 0.08, height, 0))
		Shapes.box(door, Vector3(0.08, 0.6, 0.07), GATE_WHITE, Vector3(width, 0.5, 0))
		var brace := Vector2(width, 0.4)
		Shapes.box(door, Vector3(brace.length(), 0.08, 0.06), GATE_RED, Vector3(width * 0.5 + 0.06, 0.5, 0),
			Vector3(0, 0, rad_to_deg(atan2(0.4, width))))
		_doors.append(door)
		_door_base.append(base)
		# Positive yaw turns the door's far end toward (dir.y, -dir.x); open toward the inside.
		_door_sign.append(signf(Vector2(dir.y, -dir.x).dot(pen.inward)))


func _build_corner_bales() -> void:
	var bales := Node3D.new()
	bales.name = "CornerBales"
	add_child(bales)
	for cut in Geometry.corner_cuts(layout.field_rect(), pen.rect):
		var middle := (cut.a + cut.b) * 0.5
		var length := cut.a.distance_to(cut.b)
		var along := (cut.b - cut.a) / length
		var yaw := rad_to_deg(atan2(-along.y, along.x))
		# Tuck the bale into the corner so its face lines up with the invisible wall.
		var into_corner := Vector2(-along.y, along.x)
		if into_corner.dot(layout.field_rect().get_center() - middle) > 0.0:
			into_corner = -into_corner
		var at := middle + into_corner * 0.35
		Shapes.cylinder(bales, 0.55, 0.55, length * 0.95, STRAW, Vector3(at.x, 0.55, at.y), Vector3(0, yaw, 90))
		for band in [-0.3, 0.3]:
			var p: Vector2 = at + along * band * length * 0.5
			Shapes.cylinder(bales, 0.57, 0.57, 0.06, STRAW.darkened(0.25), Vector3(p.x, 0.55, p.y),
				Vector3(0, yaw, 90), Vector3.ONE, 0.0)


func _build_scenery() -> void:
	var scenery := Node3D.new()
	scenery.name = "Scenery"
	add_child(scenery)
	var field := layout.field_rect()
	var keep_out := field.grow(1.6)
	# Trees around the back and sides; only low bushes in front so nothing hides the field.
	var placed := 0
	var attempts := 0
	while placed < 46 and attempts < 2000:
		attempts += 1
		var p := Vector2(_rng.randf_range(-30, 30), _rng.randf_range(-19, 17))
		if keep_out.has_point(p):
			continue
		var in_front := p.y > field.end.y
		if in_front:
			_bush(scenery, p, _rng.randf_range(0.7, 1.1))
		elif _rng.randf() < 0.65:
			_tree(scenery, p, _rng.randf_range(0.85, 1.35))
		else:
			_bush(scenery, p, _rng.randf_range(0.8, 1.3))
		placed += 1
	for i in 10:
		var p := Vector2(_rng.randf_range(-28, 28), _rng.randf_range(-17, 16))
		if not keep_out.has_point(p):
			Shapes.sphere(scenery, _rng.randf_range(0.25, 0.5), Color(0.68, 0.68, 0.72), Geometry.to_3d(p, 0.1),
				Vector3(1.3, 0.6, 1.0))


func _tree(parent: Node3D, p: Vector2, s: float) -> void:
	Shapes.cylinder(parent, 0.17 * s, 0.24 * s, 1.4 * s, TRUNK, Geometry.to_3d(p, 0.7 * s))
	var canopy: Array[Vector3] = [Vector3(0, 2.0, 0), Vector3(-0.55, 1.65, 0.2), Vector3(0.55, 1.7, 0.1), Vector3(0, 2.45, -0.1)]
	for i in canopy.size():
		var offset := canopy[i] * s
		Shapes.sphere(parent, _rng.randf_range(0.75, 1.0) * s, LEAVES[(i + int(p.x)) % LEAVES.size()],
			Geometry.to_3d(p) + offset)


func _bush(parent: Node3D, p: Vector2, s: float) -> void:
	for i in 3:
		var offset := Vector3(_rng.randf_range(-0.45, 0.45), 0.35, _rng.randf_range(-0.3, 0.3)) * s
		Shapes.sphere(parent, _rng.randf_range(0.4, 0.55) * s, LEAVES[(i + 2) % LEAVES.size()], Geometry.to_3d(p) + offset)
	if _rng.randf() < 0.5:
		for i in 4:
			var berry := Vector3(_rng.randf_range(-0.5, 0.5), _rng.randf_range(0.45, 0.8), _rng.randf_range(-0.45, 0.45)) * s
			Shapes.sphere(parent, 0.07, Color(0.95, 0.3, 0.4), Geometry.to_3d(p) + berry, Vector3.ONE, 0.015)


func _build_tufts() -> void:
	var blade := CylinderMesh.new()
	blade.top_radius = 0.0
	blade.bottom_radius = 0.045
	blade.height = 0.34
	blade.radial_segments = 4
	blade.rings = 1
	var tool := SurfaceTool.new()
	for k in 4:
		var tilt := Basis(Vector3.FORWARD, _rng.randf_range(-0.45, 0.45)).rotated(Vector3.UP, k * PI * 0.5)
		tool.append_from(blade, 0, Transform3D(tilt, tilt * Vector3(0, 0.17, 0) + Vector3(_rng.randf_range(-0.05, 0.05), 0, 0)))
	var tuft_mesh := tool.commit()

	var flower := SphereMesh.new()
	flower.radius = 0.075
	flower.height = 0.15
	flower.radial_segments = 8
	flower.rings = 4

	var mat := ShaderMaterial.new()
	mat.shader = TUFT_SHADER
	var greens: Array[Color] = [Color(0.36, 0.68, 0.29), Color(0.46, 0.78, 0.33), Color(0.3, 0.6, 0.26)]
	_scatter(tuft_mesh, mat, 2600, greens, 0.0, 0.7, 1.4)
	_scatter(flower, mat, 420, FLOWERS, 0.12, 0.8, 1.2)


func _scatter(mesh: Mesh, mat: Material, count: int, colors: Array[Color], lift: float, min_scale: float, max_scale: float) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = count
	for i in count:
		var p := Vector2(_rng.randf_range(-32, 32), _rng.randf_range(-20, 20))
		while pen.rect.grow(0.2).has_point(p):
			p = Vector2(_rng.randf_range(-32, 32), _rng.randf_range(-20, 20))
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(min_scale, max_scale))
		multimesh.set_instance_transform(i, Transform3D(basis, Geometry.to_3d(p, lift)))
		multimesh.set_instance_color(i, colors[_rng.randi() % colors.size()])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = mat
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


static func _on_field_edge(segment: Geometry.Segment, field: Rect2) -> bool:
	var on_x := func(x: float) -> bool: return absf(segment.a.x - x) < 0.01 and absf(segment.b.x - x) < 0.01
	var on_y := func(y: float) -> bool: return absf(segment.a.y - y) < 0.01 and absf(segment.b.y - y) < 0.01
	return on_x.call(field.position.x) or on_x.call(field.end.x) or on_y.call(field.position.y) or on_y.call(field.end.y)
