class_name Effects
## Little one-shot visual flourishes: bark rings, wool puffs, pop-up words, confetti.
## Each creates its own nodes and frees them when done.

const FONT := preload("res://assets/fonts/Fredoka.ttf")


## An expanding, fading ring on the grass (barks, landings).
static func ring(parent: Node3D, at: Vector3, color: Color, radius: float, duration := 0.45) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.82
	mesh.outer_radius = 1.0
	mesh.rings = 32
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var mat := Toon.glow(color)
	instance.material_override = mat
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = at + Vector3(0, 0.12, 0)
	instance.scale = Vector3(0.3, 0.3, 0.3)
	parent.add_child(instance)
	var tween := instance.create_tween().set_parallel()
	tween.tween_property(instance, "scale", Vector3(radius, 0.6, radius), duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(instance.queue_free)


## Little balls (wool, dust, sparkles) that burst out and shrink away.
static func puff(parent: Node3D, at: Vector3, color: Color, count := 6, size := 0.16, spread := 0.9) -> void:
	for i in count:
		var ball := Shapes.sphere(parent, size, color, at + Vector3(0, 0.4, 0), Vector3.ONE, 0.02)
		ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var direction := Vector3(randf_range(-1, 1), randf_range(0.3, 1.2), randf_range(-1, 1)).normalized()
		var duration := randf_range(0.35, 0.6)
		var tween := ball.create_tween().set_parallel()
		tween.tween_property(ball, "position", ball.position + direction * spread * randf_range(0.6, 1.2), duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ball, "scale", Vector3.ONE * 0.01, duration).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(ball.queue_free)


## A word or symbol that pops up, floats and fades ("!", "WOOF!", "+1").
static func pop_text(parent: Node3D, at: Vector3, text: String, color: Color, font_size := 96, rise := 1.0) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = FONT
	label.font_size = font_size
	label.outline_size = 24
	label.modulate = color
	label.outline_modulate = Toon.OUTLINE_COLOR
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 10
	label.outline_render_priority = 9
	label.pixel_size = 0.006
	label.position = at
	label.scale = Vector3.ONE * 0.2
	parent.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position:y", at.y + rise, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(label, "outline_modulate:a", 0.0, 0.25)
	tween.tween_callback(label.queue_free)


## A burst of bright confetti for celebrations.
static func confetti(parent: Node3D, at: Vector3, amount := 120) -> void:
	var particles := CPUParticles3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.02, 0.18)
	particles.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	particles.material_override = mat
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 2.6
	particles.direction = Vector3.UP
	particles.spread = 50.0
	particles.initial_velocity_min = 7.0
	particles.initial_velocity_max = 12.0
	particles.gravity = Vector3(0, -9.0, 0)
	particles.damping_min = 1.0
	particles.damping_max = 2.5
	particles.angular_velocity_min = -400.0
	particles.angular_velocity_max = 400.0
	particles.particle_flag_rotate_y = true
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	colors.colors = PackedColorArray([
		Color(1.0, 0.42, 0.42), Color(1.0, 0.83, 0.23), Color(0.3, 0.67, 0.97),
		Color(0.69, 0.59, 0.99), Color(0.45, 0.85, 0.5)])
	particles.color_initial_ramp = colors
	particles.position = at
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)
