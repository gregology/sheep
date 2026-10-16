class_name MeadowLayout
extends Resource
## Where things are on a field. A new level is a new layout resource.
## Ground positions are (x, z) in metres; -z is "up" the screen.

@export var field_size := Vector2(28, 17)
## The pen's interior. It may share walls with the outer fence.
@export var pen_rect := Rect2(8, -8.5, 6, 6)
@export var gate_side: PenArea.Side = PenArea.Side.BOTTOM
@export var gate_width := 3.4
@export var sheep_spawn := Rect2(-12, -3.5, 9, 9)
@export var dog_spawn := Vector2(4, 6.6)
@export var scenery_seed := 7


func field_rect() -> Rect2:
	return Rect2(-field_size * 0.5, field_size)


func make_pen() -> PenArea:
	return PenArea.new(pen_rect, gate_side, gate_width)
