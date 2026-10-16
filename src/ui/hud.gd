class_name Hud
extends CanvasLayer
## In-round overlay. Top: a row of sheep filling in as they're penned.
## Bottom (when someone is the chaos player): the shout meter, one big button per
## creature, and their stars.

var _pen_counter: PenCounter
var _timer: Label
var _chaos_row: HBoxContainer
var _stars: StarCounter
var _game: Game


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiKit.panel(Color(0.2, 0.55, 0.3, 0.75), 30, 5))
	top.position = Vector2(28, 22)
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top.add_child(top_row)
	_pen_counter = PenCounter.new()
	top_row.add_child(_pen_counter)
	_timer = UiKit.label("0:00", 30)
	top_row.add_child(_timer)

	_chaos_row = HBoxContainer.new()
	_chaos_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_chaos_row.add_theme_constant_override("separation", 26)
	_chaos_row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE)
	_chaos_row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_chaos_row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_chaos_row.offset_bottom = -10
	root.add_child(_chaos_row)
	visible = false


func show_round(game: Game) -> void:
	_game = game
	_pen_counter.reset(game.sim.sheep.size())
	for child in _chaos_row.get_children():
		child.queue_free()
	_chaos_row.add_child(MicMeter.new())
	if game.chaos:
		for ability in game.chaos.roster.abilities:
			_chaos_row.add_child(AbilityButton.new(ability, game.chaos))
		_stars = StarCounter.new()
		_chaos_row.add_child(_stars)
	visible = true


func hide_round() -> void:
	visible = false
	_game = null


func _process(_delta: float) -> void:
	if _game and visible:
		var seconds := int(_game.stats.seconds)
		_timer.text = "%d:%02d" % [seconds / 60, seconds % 60]
