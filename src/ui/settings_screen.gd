class_name SettingsScreen
extends CanvasLayer
## Grown-ups' settings: microphone set-up and calibration, chaos timings, flock
## numbers and volumes. Changes apply straight away and are saved on close.

signal closed

var _rows: VBoxContainer
var _first_focus: Control
var _calibrate_status: Label
var _mic_bar: MicLevelBar


## Live view of the mic: level, what the flock is used to, and the scare line.
class MicLevelBar:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(760, 64)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var bar := Rect2(Vector2(0, 8), Vector2(size.x, 30))
		draw_rect(bar, Color(1, 1, 1, 0.35))
		var detector := Mic.detector
		var tuning := Settings.tuning
		var floor_db := tuning.mic_noise_floor_db - 5.0
		var span := 60.0
		var x_of := func(db: float) -> float: return clampf((db - floor_db) / span, 0.0, 1.0) * size.x
		var level: float = x_of.call(detector.level_db)
		draw_rect(Rect2(bar.position, Vector2(level, bar.size.y)), UiKit.MINT)
		var used: float = x_of.call(detector.baseline_db)
		draw_line(Vector2(used, 2), Vector2(used, 44), UiKit.INK, 3.0)
		var self_x: float = x_of.call(Mic.self_noise_db())
		draw_line(Vector2(self_x, 2), Vector2(self_x, 44), Color(0.3, 0.5, 1.0), 3.0)
		var scare: float = x_of.call(maxf(maxf(detector.baseline_db, tuning.mic_noise_floor_db), Mic.self_noise_db()) + tuning.mic_threshold_db)
		draw_line(Vector2(scare, 0), Vector2(scare, 46), Color(1.0, 0.35, 0.35), 5.0)
		draw_rect(Rect2(Vector2(0, 50), Vector2(size.x * detector.alertness, 10)), UiKit.SUN)
		if not Mic.available:
			UiKit.draw_text(self, get_theme_default_font(), Vector2(0, 34), "No microphone found", 26, UiKit.CREAM, size.x)


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.1, 0.15, 0.65)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel(Color(0.22, 0.45, 0.75, 0.96), 40, 8))
	margin.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 12)
	scroll.add_child(_rows)


func open() -> void:
	_build()
	visible = true
	_first_focus.grab_focus()


func close() -> void:
	if not visible:
		return
	Settings.save()
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	for child in _rows.get_children():
		child.queue_free()
	var t := Settings.tuning
	_rows.add_child(UiKit.label("Grown-ups' settings", 60, UiKit.SUN, 18))

	_section("Microphone")
	_first_focus = _toggle("Use the microphone", t.mic_enabled, func(on: bool) -> void:
		t.mic_enabled = on
		Settings.save())
	_device_picker()
	_mic_bar = MicLevelBar.new()
	_row("Live level", _mic_bar)
	_slider("Sensitivity", 0, 24, 1, 30.0 - t.mic_threshold_db, func(v: float) -> void: t.mic_threshold_db = 30.0 - v)
	_slider("Gets used to noise after (s)", 0.3, 5.0, 0.1, t.mic_habituation_time, func(v: float) -> void: t.mic_habituation_time = v)
	_slider("Tires of shouting (per scare)", 0.0, 0.8, 0.05, t.mic_alertness_cost, func(v: float) -> void: t.mic_alertness_cost = v)
	var calibrate := MenuStyle.button("Calibrate (stay quiet, then listen)", 30)
	calibrate.pressed.connect(_calibrate)
	_calibrate_status = UiKit.label("Sets how quiet the room is and how loud the game sounds at the mic.", 22)
	_row("", calibrate)
	_rows.add_child(_calibrate_status)
	var test := MenuStyle.button("Test: make a scare", 30)
	test.pressed.connect(func() -> void: Mic.simulate(0.8))
	_row("", test)

	_section("Chaos")
	_slider("Wolf / black sheep stay (s)", 3, 20, 0.5, t.chaos_duration, func(v: float) -> void: t.chaos_duration = v)
	_slider("Cool-off before next one (s)", 0, 60, 1, t.chaos_cooldown, func(v: float) -> void: t.chaos_cooldown = v)
	_slider("Wolf scariness", 5, 60, 1, t.wolf_strength, func(v: float) -> void: t.wolf_strength = v)
	_slider("Black sheep pull", 2, 25, 0.5, t.black_sheep_strength, func(v: float) -> void: t.black_sheep_strength = v)

	_section("Flock")
	_slider("Sheep (next round)", 3, 30, 1, t.sheep_count, func(v: float) -> void: t.sheep_count = int(v))
	_slider("Dog push", 1, 15, 0.5, t.dog_pressure_strength, func(v: float) -> void: t.dog_pressure_strength = v)
	_slider("Bark strength", 5, 40, 1, t.bark_strength, func(v: float) -> void: t.bark_strength = v)
	_slider("Sheep running speed", 2, 9, 0.25, t.run_speed, func(v: float) -> void: t.run_speed = v)

	_section("Volume")
	_slider("Everything", 0, 1, 0.05, t.master_volume, func(v: float) -> void:
		t.master_volume = v
		Settings.apply_audio())
	_slider("Music", 0, 1, 0.05, t.music_volume, func(v: float) -> void:
		t.music_volume = v
		Settings.apply_audio())
	_slider("Sound effects", 0, 1, 0.05, t.sfx_volume, func(v: float) -> void:
		t.sfx_volume = v
		Settings.apply_audio())

	_section("Family sounds")
	var info := UiKit.label("Put .wav/.ogg/.mp3 files in a folder named after a sound (bark, baa, howl, boing, pop, ding, star, fanfare) inside:\n%s" % Sfx.family_folder(), 22)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(1100, 0)
	_rows.add_child(info)
	var reload := MenuStyle.button("Reload family sounds", 30)
	reload.pressed.connect(func() -> void:
		Sfx.reload()
		Sfx.play(&"baa"))
	_row("", reload)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 30)
	_rows.add_child(buttons)
	var reset := MenuStyle.button("Reset to defaults")
	reset.pressed.connect(func() -> void:
		Settings.reset_to_defaults()
		open())
	buttons.add_child(reset)
	var done := MenuStyle.button("Done")
	done.pressed.connect(close)
	buttons.add_child(done)


func _section(title: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	_rows.add_child(spacer)
	var label := UiKit.label(title, 40, UiKit.SUN, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_rows.add_child(label)


func _row(title: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var label := UiKit.label(title, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.custom_minimum_size = Vector2(500, 0)
	row.add_child(label)
	row.add_child(control)
	_rows.add_child(row)


func _slider(title: String, min_value: float, max_value: float, step: float, value: float, apply: Callable) -> HSlider:
	var slider := MenuStyle.slider(min_value, max_value, step, value)
	var readout := UiKit.label(_format(value, step), 28)
	readout.custom_minimum_size = Vector2(90, 0)
	slider.value_changed.connect(func(v: float) -> void:
		apply.call(v)
		readout.text = _format(v, step))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var label := UiKit.label(title, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.custom_minimum_size = Vector2(500, 0)
	row.add_child(label)
	row.add_child(slider)
	row.add_child(readout)
	_rows.add_child(row)
	return slider


func _toggle(title: String, value: bool, apply: Callable) -> CheckButton:
	var check := CheckButton.new()
	check.button_pressed = value
	check.toggled.connect(apply)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(4)
	focus.border_color = UiKit.SUN
	focus.set_corner_radius_all(10)
	check.add_theme_stylebox_override("focus", focus)
	check.scale = Vector2(1.5, 1.5)
	_row(title, check)
	return check


func _device_picker() -> void:
	var picker := OptionButton.new()
	picker.add_theme_font_size_override("font_size", 24)
	picker.custom_minimum_size = Vector2(560, 56)
	var devices := AudioServer.get_input_device_list()
	for i in devices.size():
		picker.add_item(devices[i])
		if devices[i] == Settings.tuning.mic_device:
			picker.select(i)
	picker.item_selected.connect(func(index: int) -> void:
		Settings.tuning.mic_device = devices[index]
		Settings.save())
	_row("Microphone", picker)


func _calibrate() -> void:
	if Mic.calibrating:
		return
	_calibrate_status.text = "Shh... measuring the quiet room, then playing some sounds."
	Mic.calibrate()
	var ok: bool = await Mic.calibration_finished
	var t := Settings.tuning
	_calibrate_status.text = ("Done! Quiet room: %d dB. Game sound at the mic: %+d dB." % [
		roundi(t.mic_noise_floor_db), roundi(t.mic_self_coupling_db)]) if ok else "Couldn't hear the microphone."


static func _format(value: float, step: float) -> String:
	if step >= 1.0:
		return str(int(value))
	return ("%.2f" % value) if step < 0.1 else ("%.1f" % value)
