class_name UiKit
## The shared look for screens: colours, rounded panels and drawing helpers.
## Screens for the chaos player avoid words; pictures and button diamonds do the talking.

const INK := Color(0.17, 0.12, 0.16)
const CREAM := Color(1.0, 0.98, 0.93)
const SUN := Color(1.0, 0.83, 0.23)
const GRAPE := Color(0.62, 0.42, 0.95)
const MINT := Color(0.45, 0.85, 0.55)
const SHADOW := Color(0.0, 0.0, 0.0, 0.25)

## Where each face button sits in the diamond.
const DIAMOND := {
	&"north": Vector2(0, -1), &"east": Vector2(1, 0), &"south": Vector2(0, 1), &"west": Vector2(-1, 0),
}


static func panel(color: Color, radius := 28, border := 6, border_color := INK) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border)
	box.border_color = border_color
	box.shadow_color = SHADOW
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 6)
	box.anti_aliasing = true
	box.set_content_margin_all(maxf(radius * 0.6, 12.0))
	return box


static func label(text: String, size := 30, color := CREAM, outline := 12) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)
	return l


## Four little circles in a diamond, with the buttons to press filled in.
static func draw_button_diamond(canvas: CanvasItem, center: Vector2, spacing: float,
		lit: Array[StringName], color: Color) -> void:
	var r := spacing * 0.58
	for button: StringName in DIAMOND:
		var p: Vector2 = center + DIAMOND[button] * spacing
		if button in lit:
			canvas.draw_circle(p + Vector2(0, 2), r, SHADOW, true, -1.0, true)
			canvas.draw_circle(p, r, color, true, -1.0, true)
			canvas.draw_circle(p, r, INK, false, 3.0, true)
		else:
			canvas.draw_circle(p, r * 0.8, Color(1, 1, 1, 0.35), true, -1.0, true)
			canvas.draw_circle(p, r * 0.8, Color(INK, 0.5), false, 2.0, true)


static func star_points(center: Vector2, outer: float, inner: float, points := 5) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points * 2:
		var angle := -PI * 0.5 + i * PI / points
		result.append(center + Vector2(cos(angle), sin(angle)) * (outer if i % 2 == 0 else inner))
	return result


static func draw_star(canvas: CanvasItem, center: Vector2, radius: float, color: Color, filled := true) -> void:
	var points := star_points(center, radius, radius * 0.48)
	if filled:
		canvas.draw_colored_polygon(star_points(center + Vector2(0, 4), radius, radius * 0.48), SHADOW)
		canvas.draw_colored_polygon(points, color)
	else:
		canvas.draw_colored_polygon(points, Color(1, 1, 1, 0.25))
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, INK, maxf(2.0, radius * 0.09), true)


## A filled wedge, clockwise from 12 o'clock, covering `fraction` of the circle.
static func draw_pie(canvas: CanvasItem, center: Vector2, radius: float, fraction: float, color: Color) -> void:
	if fraction <= 0.0:
		return
	var points := PackedVector2Array([center])
	var steps := maxi(3, int(48 * fraction))
	for i in steps + 1:
		var angle := -PI * 0.5 + TAU * fraction * i / steps
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	canvas.draw_colored_polygon(points, color)


## A little cartoon sheep (cloud of wool and a dark face) for counters.
static func draw_sheep_icon(canvas: CanvasItem, center: Vector2, size: float, filled: bool) -> void:
	var wool := CREAM if filled else Color(1, 1, 1, 0.3)
	var face := Color(0.33, 0.27, 0.31) if filled else Color(INK, 0.25)
	var r := size * 0.26
	var puffs: Array[Vector2] = [Vector2(-0.22, -0.08), Vector2(0.05, -0.2), Vector2(0.25, -0.02), Vector2(-0.08, 0.14), Vector2(0.2, 0.18)]
	if filled:
		for p in puffs:
			canvas.draw_circle(center + p * size, r + 3.0, INK, true, -1.0, true)
	for p in puffs:
		canvas.draw_circle(center + p * size, r, wool, true, -1.0, true)
	var head := center + Vector2(-0.34, 0.1) * size
	canvas.draw_circle(head, size * 0.19 + (3.0 if filled else 0.0), INK if filled else Color(0, 0, 0, 0), true, -1.0, true)
	canvas.draw_circle(head, size * 0.19, face, true, -1.0, true)
	if filled:
		canvas.draw_circle(head + Vector2(-0.06, -0.03) * size, size * 0.05, CREAM, true, -1.0, true)


static func draw_text(canvas: CanvasItem, font: Font, pos: Vector2, text: String, size: int,
		color := CREAM, width := -1.0, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	canvas.draw_string_outline(font, pos, text, align, width, size, maxi(4, size / 5), INK)
	canvas.draw_string(font, pos, text, align, width, size, color)
