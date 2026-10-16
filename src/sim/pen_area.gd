class_name PenArea
extends RefCounted
## The small pen sheep are herded into, with a one-way gate in one wall.

enum Side { TOP, RIGHT, BOTTOM, LEFT }

var rect: Rect2
var side: Side
var gate_a: Vector2
var gate_b: Vector2
## Unit vector pointing from the gate into the pen.
var inward: Vector2


func _init(pen_rect: Rect2, gate_side: int, gate_width: float) -> void:
	rect = pen_rect
	side = gate_side as Side
	var corners := _side_corners(side)
	var middle := (corners[0] + corners[1]) * 0.5
	var along := (corners[1] - corners[0]).normalized()
	gate_a = middle - along * gate_width * 0.5
	gate_b = middle + along * gate_width * 0.5
	match side:
		Side.TOP: inward = Vector2.DOWN
		Side.BOTTOM: inward = Vector2.UP
		Side.LEFT: inward = Vector2.RIGHT
		Side.RIGHT: inward = Vector2.LEFT


func gate_center() -> Vector2:
	return (gate_a + gate_b) * 0.5


func gate_width() -> float:
	return gate_a.distance_to(gate_b)


## True when p is inside the pen, at least `margin` from the walls.
func contains(p: Vector2, margin := 0.0) -> bool:
	return rect.grow(-margin).has_point(p)


## Pen walls, leaving the gate open. Sheep can walk through the gap; dogs can't (see gate_segment).
func walls() -> Array[Geometry.Segment]:
	var result: Array[Geometry.Segment] = []
	for s in [Side.TOP, Side.RIGHT, Side.BOTTOM, Side.LEFT]:
		var c := _side_corners(s)
		if s == side:
			var gate_first := c[0].distance_squared_to(gate_a) < c[0].distance_squared_to(gate_b)
			var near := gate_a if gate_first else gate_b
			var far := gate_b if gate_first else gate_a
			result.append(Geometry.Segment.new(c[0], near))
			result.append(Geometry.Segment.new(far, c[1]))
		else:
			result.append(Geometry.Segment.new(c[0], c[1]))
	return result


## The gate itself, as a wall for anything that isn't a sheep.
func gate_segment() -> Geometry.Segment:
	return Geometry.Segment.new(gate_a, gate_b)


## Keeps a penned sheep inside.
func clamp_inside(p: Vector2, radius: float) -> Vector2:
	var inner := rect.grow(-radius)
	return Vector2(clampf(p.x, inner.position.x, inner.end.x), clampf(p.y, inner.position.y, inner.end.y))


func _side_corners(s: Side) -> Array[Vector2]:
	var tl := rect.position
	var tr := Vector2(rect.end.x, rect.position.y)
	var br := rect.end
	var bl := Vector2(rect.position.x, rect.end.y)
	match s:
		Side.TOP: return [tl, tr]
		Side.RIGHT: return [tr, br]
		Side.BOTTOM: return [bl, br]
		_: return [tl, bl]
