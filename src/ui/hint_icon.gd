class_name HintIcon
extends Control
## A tiny picture of which controller input to use, for hint bars.

enum Kind { DIAMOND_SOUTH, DIAMOND_EAST, LEFT_RIGHT, START, BACK }

var kind: Kind
var color: Color


func _init(icon_kind: Kind, icon_color := UiKit.SUN) -> void:
	kind = icon_kind
	color = icon_color
	custom_minimum_size = Vector2(64, 56)


func _draw() -> void:
	var c := size * 0.5
	match kind:
		Kind.DIAMOND_SOUTH:
			UiKit.draw_button_diamond(self, c, 15.0, [&"south"], color)
		Kind.DIAMOND_EAST:
			UiKit.draw_button_diamond(self, c, 15.0, [&"east"], color)
		Kind.LEFT_RIGHT:
			for direction in [-1.0, 1.0]:
				var tip := c + Vector2(26.0 * direction, 0)
				var back := c + Vector2(6.0 * direction, 0)
				var arrow := PackedVector2Array([tip, back + Vector2(0, -15), back + Vector2(0, 15)])
				draw_colored_polygon(arrow, color)
				arrow.append(tip)
				draw_polyline(arrow, UiKit.INK, 3.0, true)
		Kind.START, Kind.BACK:
			var pill := Rect2(c - Vector2(30, 15), Vector2(60, 30))
			draw_style_box(UiKit.panel(color, 15, 3), pill)
			for i in 3:
				var y := c.y - 7.0 + i * 7.0
				if kind == Kind.START:
					draw_line(Vector2(c.x - 11, y), Vector2(c.x + 11, y), UiKit.INK, 3.0, true)
				else:
					draw_rect(Rect2(c.x - 11 + i * 2.0, c.y - 9 + i * 2.0, 14, 12), UiKit.INK, false, 2.5)
