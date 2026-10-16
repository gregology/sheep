class_name Game
extends Node3D
## One meadow and everything on it.
##
##   ATTRACT      sheep graze behind the join screen (the mic still works: have a go!)
##   PLAYING      dogs and the chaos player are out; ends when every sheep is penned
##   CELEBRATING  confetti, waiting for the next round

signal won(stats: RoundStats)

enum Mode { ATTRACT, PLAYING, CELEBRATING }

const LAYOUT := preload("res://config/meadow_layout.tres")
const ROSTER := preload("res://config/chaos_roster.tres")
const PITCH_DEGREES := 55.0
## Space around the field on screen (metres of ground): room for HUD at the bottom.
const MARGIN_TOP := 3.2
const MARGIN_BOTTOM := 4.8
const MARGIN_SIDE := 2.0
const STARTLE_EMOTES := 5

var mode := Mode.ATTRACT
var tuning: Tuning
var layout: MeadowLayout
var meadow: Meadow
var sim: FlockSim
var camera: Camera3D
var chaos: ChaosController
var dogs: Array[Dog] = []
var stats := RoundStats.new()

var _actors: Node3D
var _sheep_views: Array[SheepView] = []
var _baa_timer := 3.0


func _ready() -> void:
	layout = LAYOUT
	_build_stage()
	meadow = Meadow.new()
	meadow.name = "Meadow"
	add_child(meadow)
	meadow.build(layout)
	_actors = Node3D.new()
	_actors.name = "Actors"
	add_child(_actors)
	Events.flock_startled.connect(_on_flock_startled)
	Events.chaos_star_earned.connect(_on_chaos_star)
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()
	start_attract()


func start_attract() -> void:
	_reset()
	mode = Mode.ATTRACT


func start_round() -> void:
	_reset()
	mode = Mode.PLAYING
	stats = RoundStats.new()
	stats.sheep = sim.sheep.size()
	var dog_slots := Players.dogs()
	for i in dog_slots.size():
		var dog := Dog.new()
		var offset := (i - (dog_slots.size() - 1) * 0.5) * 2.2
		dog.setup(dog_slots[i], sim, layout.dog_spawn + Vector2(offset, 0), _actors)
		_actors.add_child(dog)
		dogs.append(dog)
	for dog in dogs:
		dog.pack = dogs
	var chaos_slot := Players.chaos_slot()
	if chaos_slot:
		stats.had_chaos_player = true
		chaos = ChaosController.new()
		chaos.setup(chaos_slot, ROSTER, sim, _actors)
		add_child(chaos)
	Events.round_started.emit()


func _reset() -> void:
	tuning = Settings.tuning
	for dog in dogs:
		dog.queue_free()
	dogs.clear()
	if chaos:
		chaos.queue_free()
		chaos = null
	for child in _actors.get_children():
		child.queue_free()
	for view in _sheep_views:
		view.queue_free()
	_sheep_views.clear()
	sim = FlockSim.new(tuning, layout.field_rect(), meadow.pen)
	sim.rng.randomize()
	sim.spawn(tuning.sheep_count, layout.sheep_spawn)
	sim.sheep_penned.connect(_on_sheep_penned)
	for s in sim.sheep:
		var view := SheepView.new(s, tuning)
		_actors.add_child(view)
		_sheep_views.append(view)
	meadow.set_gate_target(0.0)


func _physics_process(delta: float) -> void:
	if mode == Mode.PLAYING:
		stats.seconds += delta
		sim.assist = clampf((stats.seconds - tuning.assist_after) / 60.0, 0.0, 1.0)
	sim.step(delta)
	_update_gate()
	_idle_baas(delta)
	if mode == Mode.PLAYING and sim.all_penned():
		_win()


func _win() -> void:
	mode = Mode.CELEBRATING
	if chaos:
		chaos.dismiss()
	Sfx.play(&"fanfare")
	Music.duck(2.5)
	_confetti_burst()
	for i in 3:
		get_tree().create_timer(0.4 + i * 0.5).timeout.connect(_confetti_burst)
	sim.startle(0.3)
	won.emit(stats)
	Events.round_won.emit(stats)


func _confetti_burst() -> void:
	var pen_center := Geometry.to_3d(meadow.pen.rect.get_center())
	Effects.confetti(_actors, pen_center + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2, 2)), 90)


func _on_flock_startled(intensity: float, source: StringName) -> void:
	var scattered := sim.startle(intensity)
	var shown := 0
	for view in _sheep_views:
		if shown >= STARTLE_EMOTES or view.state.penned:
			continue
		if randf() < 0.5:
			continue
		Effects.pop_text(_actors, view.position + Vector3(0, 1.4, 0), "!", Color(1.0, 0.85, 0.3), 110, 0.5)
		Effects.puff(_actors, view.position, Color(0.99, 0.97, 0.93), 3, 0.12)
		shown += 1
	Sfx.play(&"baa", -2.0, 0.15, 0.2)
	if intensity > 0.5:
		get_tree().create_timer(0.15).timeout.connect(func() -> void: Sfx.play(&"baa", -4.0, 0.2))
	if mode == Mode.PLAYING and source == &"mic" and stats.had_chaos_player and scattered >= 3 and intensity >= 0.3:
		Events.chaos_star_earned.emit(&"shout")


func _on_chaos_star(_reason: StringName) -> void:
	if mode == Mode.PLAYING:
		stats.chaos_stars += 1
		Sfx.play(&"star", -3.0, 0.0)


func _on_sheep_penned(s: SheepState) -> void:
	var at := Geometry.to_3d(s.pos)
	Sfx.play_at(&"pop", at, 0.0, 0.1)
	Effects.puff(_actors, at, Color(1.0, 0.86, 0.35), 6, 0.1, 1.2)
	Effects.pop_text(_actors, at + Vector3(0, 1.5, 0), "+1", Color(1.0, 0.86, 0.35), 90, 0.8)
	Events.sheep_penned.emit(sim.penned_count(), sim.sheep.size())


func _update_gate() -> void:
	var gate := meadow.pen.gate_center()
	var near := false
	for s in sim.sheep:
		if s.pos.distance_to(gate) < 2.4:
			near = true
			break
	meadow.set_gate_target(1.0 if near else 0.0)


func _idle_baas(delta: float) -> void:
	_baa_timer -= delta
	if _baa_timer > 0.0 or sim.sheep.is_empty():
		return
	_baa_timer = randf_range(3.0, 8.0)
	Sfx.play_at(&"baa", Geometry.to_3d(sim.sheep.pick_random().pos), -10.0, 0.2)


func _build_stage() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.56, 0.82, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.8, 1.0)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 5.0
	env.ssao_enabled = true
	env.ssao_radius = 0.8
	env.ssao_intensity = 1.4
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.glow_bloom = 0.03
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.05
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52, -32, 0)
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 140.0
	sun.shadow_blur = 1.5
	sun.shadow_opacity = 0.7
	add_child(sun)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.rotation_degrees = Vector3(-PITCH_DEGREES, 0, 0)
	camera.near = 1.0
	camera.far = 200.0
	add_child(camera)


## Frames the whole field (plus HUD margins) on any screen shape.
func _fit_camera() -> void:
	var aspect := get_viewport().get_visible_rect().size.aspect()
	var pitch := deg_to_rad(PITCH_DEGREES)
	var field := layout.field_size
	var need_v := (field.y + MARGIN_TOP + MARGIN_BOTTOM) * sin(pitch)
	var need_h := (field.x + MARGIN_SIDE * 2.0) / aspect
	camera.size = maxf(need_v, need_h)
	var look_at := Vector3(0, 0, (MARGIN_BOTTOM - MARGIN_TOP) * 0.5)
	var back := Vector3(0, sin(pitch), cos(pitch))
	camera.position = look_at + back * 60.0
