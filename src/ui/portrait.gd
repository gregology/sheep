class_name Portrait
extends SubViewport
## Renders a creature model into a texture for menus and the HUD, so every icon
## matches what's in the meadow (and updates itself when the models change).

var model: CreatureModel


func _init(kind: StringName, options := {}, pixels := 256) -> void:
	size = Vector2i(pixels, pixels)
	transparent_bg = true
	own_world_3d = true
	msaa_3d = Viewport.MSAA_4X
	render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 1.0)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 5.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 160, 0)
	sun.light_energy = 1.1
	add_child(sun)

	model = Models.make(kind, options)
	add_child(model)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.1 if kind == &"wolf" else 1.65
	var target := Vector3(0, 0.95 if kind == &"wolf" else 0.6, 0)
	var eye := target + Vector3(1.4, 0.9, -2.6)
	camera.transform = Transform3D(Basis.looking_at(target - eye, Vector3.UP), eye)
	add_child(camera)


## Stops rendering while nobody can see it.
func set_active(active: bool) -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
