class_name InputDevice
extends RefCounted
## One controller (or keyboard scheme), polled once per physics tick by InputHub.
##
## Buttons are named by position (south/east/west/north) rather than letter,
## because controller brands disagree about which button is "A".

const BUTTONS: Array[StringName] = [
	&"south", &"east", &"west", &"north",
	&"left_shoulder", &"right_shoulder", &"start", &"back",
]
const FACE_BUTTONS: Array[StringName] = [&"south", &"east", &"west", &"north"]

## Stable-ish identity used to remember a device's role between sessions.
var key := ""
var display_name := ""

var _down := {}
var _prev := {}
var _move := Vector2.ZERO
var _prev_move := Vector2.ZERO


func poll() -> void:
	_prev = _down
	_down = {}
	for button in BUTTONS:
		if _read_button(button):
			_down[button] = true
	_prev_move = _move
	_move = _read_move().limit_length(1.0)


func is_down(button: StringName) -> bool:
	return _down.has(button)


func just_pressed(button: StringName) -> bool:
	return _down.has(button) and not _prev.has(button)


func any_just_pressed(buttons: Array[StringName]) -> bool:
	for button in buttons:
		if just_pressed(button):
			return true
	return false


func any_button_just_pressed() -> bool:
	return any_just_pressed(BUTTONS)


## Movement, length 0..1. Screen-relative: x right, y down.
func move() -> Vector2:
	return _move


## A fresh push in a direction this tick (for menus): (-1/0/1, -1/0/1).
func just_moved() -> Vector2i:
	var now := _direction(_move)
	var before := _direction(_prev_move)
	return Vector2i(now.x if now.x != before.x else 0, now.y if now.y != before.y else 0)


func rumble(_weak: float, _strong: float, _duration: float) -> void:
	pass


func is_keyboard() -> bool:
	return false


func _read_button(_button: StringName) -> bool:
	return false


func _read_move() -> Vector2:
	return Vector2.ZERO


static func _direction(v: Vector2) -> Vector2i:
	return Vector2i(
		1 if v.x > 0.5 else (-1 if v.x < -0.5 else 0),
		1 if v.y > 0.5 else (-1 if v.y < -0.5 else 0))
