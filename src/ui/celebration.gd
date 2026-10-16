class_name Celebration
extends CanvasLayer
## End-of-round party. Everyone wins: the dogs get one to three stars for speed,
## and the chaos player gets a star for every bit of mischief.

signal play_again
signal change_players

## Ignore buttons for a moment so a mid-game press doesn't skip the party.
const INPUT_DELAY := 1.6

var _panel: PanelContainer
var _title: Label
var _stars: StarRow
var _time_label: Label
var _chaos_row: HBoxContainer
var _chaos_count: Label
var _chaos_star: StarRow
var _portraits: Array[Portrait] = []
var _shown_for := 0.0
var _clock := 0.0


## Draws a row of big stars that pop in one at a time.
class StarRow:
	extends Control
	var total := 3
	var earned := 0
	var playing := false
	var _age := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(420, 140)

	func start(stars: int) -> void:
		earned = stars
		_age = 0.0
		playing = true

	func _process(delta: float) -> void:
		if not playing:
			return
		var before := int(_age / 0.45)
		_age += delta
		var after := int(_age / 0.45)
		if after != before and after >= 1 and after <= earned:
			Sfx.play(&"star", 0.0, 0.0)
		queue_redraw()

	func _draw() -> void:
		for i in total:
			var shown := clampf((_age - 0.45 * (i + 1)) * 4.0, 0.0, 1.0)
			var lit := i < earned and shown > 0.0
			var pop := 1.0 + 0.35 * sin(shown * PI) if lit else 1.0
			var center := Vector2(size.x * (i + 0.5) / total, size.y * 0.5 - (12.0 if i == 1 else 0.0))
			UiKit.draw_star(self, center, 56.0 * pop, UiKit.SUN, lit)


func _ready() -> void:
	layer = 12
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.panel(Color(0.3, 0.62, 0.95, 0.92), 44, 8))
	center.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(column)

	_title = UiKit.label("Hooray!", 130, UiKit.SUN, 36)
	column.add_child(_title)
	_stars = StarRow.new()
	column.add_child(_stars)
	_time_label = UiKit.label("", 34)
	column.add_child(_time_label)

	_chaos_row = HBoxContainer.new()
	_chaos_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_chaos_row.add_theme_constant_override("separation", 12)
	column.add_child(_chaos_row)
	for kind in [&"black_sheep", &"wolf"]:
		var portrait := Portrait.new(kind)
		_portraits.append(portrait)
		_chaos_row.add_child(portrait)
		var picture := TextureRect.new()
		picture.texture = portrait.get_texture()
		picture.custom_minimum_size = Vector2(130, 130)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_chaos_row.add_child(picture)
	_chaos_star = StarRow.new()
	_chaos_star.total = 1
	_chaos_star.custom_minimum_size = Vector2(120, 130)
	_chaos_row.add_child(_chaos_star)
	_chaos_count = UiKit.label("", 72, UiKit.SUN, 20)
	_chaos_row.add_child(_chaos_count)

	var hints := HBoxContainer.new()
	hints.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(hints)
	hints.add_child(HintIcon.new(HintIcon.Kind.DIAMOND_SOUTH))
	hints.add_child(UiKit.label("play again", 32))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(40, 0)
	hints.add_child(spacer)
	hints.add_child(HintIcon.new(HintIcon.Kind.DIAMOND_EAST))
	hints.add_child(UiKit.label("change players", 32))


func show_stats(stats: RoundStats) -> void:
	var seconds := int(stats.seconds)
	_time_label.text = "All %d sheep home in %d:%02d" % [stats.sheep, seconds / 60, seconds % 60]
	_stars.start(stats.dog_stars(Settings.tuning.par_seconds_per_sheep))
	_chaos_row.visible = stats.had_chaos_player
	# Everyone wins: the chaos player always gets at least one star.
	_chaos_count.text = "x %d" % maxi(1, stats.chaos_stars)
	_chaos_star.start(1)
	for portrait in _portraits:
		portrait.set_active(true)
	_shown_for = 0.0
	visible = true
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2.ONE * 0.3
	create_tween().tween_property(_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_screen() -> void:
	visible = false
	_stars.playing = false
	_chaos_star.playing = false
	for portrait in _portraits:
		portrait.set_active(false)


func _process(delta: float) -> void:
	_clock += delta
	if visible:
		_title.pivot_offset = _title.size * 0.5
		_title.rotation = sin(_clock * 4.0) * 0.06


func _physics_process(delta: float) -> void:
	if not visible or get_tree().paused:
		return
	_shown_for += delta
	if _shown_for < INPUT_DELAY:
		return
	for device in InputHub.devices:
		if device.just_pressed(&"south") or device.just_pressed(&"start"):
			play_again.emit()
			return
		if device.just_pressed(&"east"):
			change_players.emit()
			return
