class_name BlobShadow
extends MeshInstance3D
## A soft round shadow on the grass under a creature. It shrinks and fades as the
## creature jumps, which is how an orthographic view shows height.

const SHADER := preload("res://src/visuals/shaders/blob_shadow.gdshader")

static var _mesh: PlaneMesh
static var _material: ShaderMaterial

var size := 1.0
var opacity := 0.38


func _init(shadow_size := 1.0) -> void:
	size = shadow_size
	if _mesh == null:
		_mesh = PlaneMesh.new()
		_mesh.size = Vector2.ONE
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	mesh = _mesh
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position.y = 0.03
	set_height(0.0)


## Height of the creature above the ground, in metres.
func set_height(height: float) -> void:
	var shrink := clampf(1.0 - height * 0.18, 0.45, 1.0)
	scale = Vector3(size * shrink, 1.0, size * shrink * 0.9)
	set_instance_shader_parameter("opacity", opacity * shrink)
