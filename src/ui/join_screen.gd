class_name JoinScreen
extends CanvasLayer
## "Who's playing?" Press the bottom face button to join as a dog; push right to
## become the chaos player (left to go back); right face button to leave; Start to play.

signal start_requested

const TITLE := "Sheep!"

var _title: Label
var _subtitle: Label
var _start_hint: HBoxContainer
var _time := 0.0


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.1, 0.2, 0.15, 0.25)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 22)
	root.add_child(column)

	var title_holder := Control.new()
	title_holder.custom_minimum_size = Vector2(0, 210)
	column.add_child(title_holder)
	_title = UiKit.label(TITLE, 190, UiKit.CREAM, 44)
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_holder.add_child(_title)
	_subtitle = UiKit.label("Herd the sheep into the pen!", 42, UiKit.SUN, 14)
	column.add_child(_subtitle)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 18)
	column.add_child(cards)
	for i in Players.MAX_DOGS:
		cards.add_child(JoinCard.new(i))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(36, 0)
	cards.add_child(gap)
	cards.add_child(JoinCard.new(-1))

	var hints := HBoxContainer.new()
	hints.alignment = BoxContainer.ALIGNMENT_CENTER
	hints.add_theme_constant_override("separation", 10)
	column.add_child(hints)
	_add_hint(hints, HintIcon.Kind.DIAMOND_SOUTH, "join")
	_add_hint(hints, HintIcon.Kind.LEFT_RIGHT, "dog / chaos")
	_add_hint(hints, HintIcon.Kind.DIAMOND_EAST, "leave")
	_start_hint = HBoxContainer.new()
	column.add_child(_start_hint)
	_start_hint.alignment = BoxContainer.ALIGNMENT_CENTER
	_add_hint(_start_hint, HintIcon.Kind.START, "PLAY!", 48)


func _add_hint(row: HBoxContainer, kind: HintIcon.Kind, text: String, size := 30) -> void:
	row.add_child(HintIcon.new(kind))
	row.add_child(UiKit.label(text, size))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(28, 0)
	row.add_child(spacer)


func _process(delta: float) -> void:
	_time += delta
	_title.pivot_offset = _title.size * 0.5
	_title.rotation = sin(_time * 1.6) * 0.04
	_title.scale = Vector2.ONE * (1.0 + sin(_time * 3.2) * 0.025)
	var can_start := not Players.dogs().is_empty()
	_start_hint.modulate.a = (0.75 + 0.25 * sin(_time * 5.0)) if can_start else 0.25


func _physics_process(_delta: float) -> void:
	if not visible or get_tree().paused:
		return
	for device in InputHub.devices:
		var slot := Players.slot_for(device)
		if slot == null:
			if device.just_pressed(&"south"):
				if Players.join(device):
					Sfx.play(&"pop")
					device.rumble(0.2, 0.3, 0.1)
			continue
		var push := device.just_moved()
		if push.x > 0 and slot.is_dog():
			Sfx.play(&"boing" if Players.set_role(slot, PlayerSlot.Role.CHAOS) else &"tick")
		elif push.x < 0 and slot.is_chaos():
			Sfx.play(&"pop" if Players.set_role(slot, PlayerSlot.Role.DOG) else &"tick")
		elif device.just_pressed(&"east"):
			Players.leave(device)
			Sfx.play(&"whoosh")
		elif device.just_pressed(&"start") and not Players.dogs().is_empty():
			start_requested.emit()
			return
	# Start works from any controller, even one that hasn't joined.
	for device in InputHub.devices:
		if device.just_pressed(&"start") and not Players.dogs().is_empty() and Players.slot_for(device) == null:
			start_requested.emit()
			return
