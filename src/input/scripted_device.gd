class_name ScriptedDevice
extends InputDevice
## A pretend controller driven by code: demo mode, bots and tests.

## Current stick direction (length 0..1).
var stick := Vector2.ZERO
var _held := {}
var _taps := {}


func _init(device_name := "Robot") -> void:
	key = "scripted:%s" % device_name
	display_name = device_name


func hold(button: StringName, down := true) -> void:
	if down:
		_held[button] = true
	else:
		_held.erase(button)


## Presses a button for exactly one tick.
func tap(button: StringName) -> void:
	_taps[button] = true


func poll() -> void:
	super.poll()
	_taps.clear()


func _read_button(button: StringName) -> bool:
	return _held.has(button) or _taps.has(button)


func _read_move() -> Vector2:
	return stick
