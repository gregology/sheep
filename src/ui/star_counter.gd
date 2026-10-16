class_name StarCounter
extends Control
## The chaos player's stars this round. Each new one pops in with a sparkle.

var count := 0
var _pop := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(150, 150)


func _ready() -> void:
	Events.chaos_star_earned.connect(_on_star)


func reset() -> void:
	count = 0
	queue_redraw()


func _process(delta: float) -> void:
	_pop = move_toward(_pop, 0.0, delta * 2.0)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.42)
	var r := 46.0 * (1.0 + 0.4 * sin(_pop * PI))
	UiKit.draw_star(self, center, r, UiKit.SUN, count > 0)
	UiKit.draw_text(self, get_theme_default_font(), Vector2(0, size.y - 10.0), str(count), 52, UiKit.CREAM, size.x)


func _on_star(_reason: StringName) -> void:
	count += 1
	_pop = 1.0
