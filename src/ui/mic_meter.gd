class_name MicMeter
extends Control
## The "shout" button: a sheep with sound waves that light up with the room's
## noise. The ring around it is how jumpy the flock is; it drains with each
## scare and refills over time. It jumps when a scare lands.

const RADIUS := 64.0
const RING_COLOR := Color(0.45, 0.85, 0.55)

var _portrait: Portrait
var _time := 0.0
var _bounce := 0.0
var _level := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(RADIUS * 2.0 + 70.0, RADIUS * 2.0 + 74.0)


func _ready() -> void:
	_portrait = Portrait.new(&"sheep")
	add_child(_portrait)
	Mic.startled.connect(_on_startled)


func _on_startled(_strength: float) -> void:
	_bounce = 1.0


func _process(delta: float) -> void:
	_time += delta
	_bounce = move_toward(_bounce, 0.0, delta * 2.0)
	_level = lerpf(_level, Mic.detector.level01(), 1.0 - exp(-delta * 18.0))
	queue_redraw()


func _draw() -> void:
	var center := Vector2(RADIUS + 12.0, RADIUS + 8.0)
	var r := RADIUS * (1.0 + 0.2 * sin(_bounce * PI))
	var on := Mic.available and not Mic.is_silent()
	draw_circle(center + Vector2(0, 7), r, UiKit.SHADOW, true, -1.0, true)
	draw_circle(center, r, Color(0.98, 0.72, 0.8) if on else Color(0.6, 0.6, 0.65), true, -1.0, true)
	draw_circle(center, r - 10.0, UiKit.CREAM, true, -1.0, true)
	var face := r * 0.95
	draw_texture_rect(_portrait.get_texture(), Rect2(center - Vector2(face, face), Vector2(face, face) * 2.0), false)
	if on:
		var alert := Mic.detector.alertness
		draw_arc(center, r - 5.0, -PI * 0.5, -PI * 0.5 + TAU * alert, 64, RING_COLOR.lerp(UiKit.SUN, 1.0 - alert), 9.0, true)
	draw_arc(center, r, 0.0, TAU, 64, UiKit.INK, 6.0, true)
	if not on:
		draw_line(center + Vector2(-r, -r) * 0.6, center + Vector2(r, r) * 0.6, UiKit.INK, 10.0, true)
		return
	# Sound waves, lighting up with the noise in the room.
	for i in 3:
		var lit := _level > (i + 0.5) / 3.5
		var wave_r := r + 14.0 + i * 16.0
		draw_arc(center + Vector2(6, 0), wave_r, -0.55, 0.55, 16,
			UiKit.SUN if lit else Color(1, 1, 1, 0.35), 8.0, true)
