class_name Toon
## Shared cartoon materials. Every coloured surface goes through here so the
## whole game keeps one look: soft two-tone shading plus a dark outline.

const TOON_SHADER := preload("res://src/visuals/shaders/toon.gdshader")
const OUTLINE_SHADER := preload("res://src/visuals/shaders/outline.gdshader")
const OUTLINE_COLOR := Color(0.17, 0.12, 0.16)
const DEFAULT_OUTLINE := 0.035

static var _cache := {}


## A cached toon material. `outline` is the outline width in metres (0 = none).
static func material(color: Color, outline := DEFAULT_OUTLINE) -> ShaderMaterial:
	var key := "%s|%.3f" % [color.to_html(), outline]
	if _cache.has(key):
		return _cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = TOON_SHADER
	mat.set_shader_parameter("albedo", color)
	if outline > 0.0:
		var outline_mat := ShaderMaterial.new()
		outline_mat.shader = OUTLINE_SHADER
		outline_mat.set_shader_parameter("width", outline)
		outline_mat.set_shader_parameter("outline_color", OUTLINE_COLOR)
		mat.next_pass = outline_mat
	_cache[key] = mat
	return mat


## A see-through unshaded material for effects that fade out.
static func glow(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
