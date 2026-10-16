class_name PauseMenu
extends CanvasLayer
## Start pauses the round. Ordinary buttons, navigated with any D-pad.

signal resume
signal restart
signal change_players
signal open_settings

var _first: Button
var _opened_on_frame := -1


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.1, 0.15, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel(Color(0.3, 0.62, 0.95, 0.95), 40, 8))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	column.add_child(UiKit.label("Paused", 80, UiKit.SUN, 24))
	_first = _button(column, "Keep playing", resume)
	_button(column, "Start again", restart)
	_button(column, "Change players", change_players)
	_button(column, "Grown-ups' settings", open_settings)


func open() -> void:
	visible = true
	_opened_on_frame = Engine.get_physics_frames()
	_first.grab_focus()


func close() -> void:
	visible = false


func _button(parent: Container, text: String, pressed_signal: Signal) -> Button:
	var button := MenuStyle.button(text)
	button.pressed.connect(func() -> void: pressed_signal.emit())
	parent.add_child(button)
	return button


func _physics_process(_delta: float) -> void:
	# The Start press that opened the menu is still "just pressed" this tick.
	if not visible or Engine.get_physics_frames() == _opened_on_frame:
		return
	for device in InputHub.devices:
		if device.just_pressed(&"start"):
			resume.emit()
			return
