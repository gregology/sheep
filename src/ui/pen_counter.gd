class_name PenCounter
extends Control
## A row of little sheep that fill in as sheep reach the pen.

const ICON := 40.0

var total := 0
var penned := 0
var _pops: Array[float] = []


func _ready() -> void:
	Events.sheep_penned.connect(_on_sheep_penned)


func reset(sheep_total: int) -> void:
	total = sheep_total
	penned = 0
	_pops.clear()
	_pops.resize(total)
	_pops.fill(0.0)
	custom_minimum_size = Vector2(_spacing() * total + ICON * 0.4, ICON * 1.3)
	queue_redraw()


func _process(delta: float) -> void:
	for i in _pops.size():
		_pops[i] = maxf(0.0, _pops[i] - delta * 2.5)
	queue_redraw()


func _draw() -> void:
	var spacing := _spacing()
	for i in total:
		var pop := sin(_pops[i] * PI) * 0.45 if i < _pops.size() else 0.0
		var center := Vector2(ICON * 0.6 + i * spacing, size.y * 0.5)
		UiKit.draw_sheep_icon(self, center, ICON * (1.0 + pop), i < penned)


func _spacing() -> float:
	return minf(ICON * 1.05, 900.0 / maxf(total, 1.0))


func _on_sheep_penned(now_penned: int, sheep_total: int) -> void:
	if sheep_total != total:
		reset(sheep_total)
	penned = now_penned
	if penned - 1 < _pops.size():
		_pops[penned - 1] = 1.0
