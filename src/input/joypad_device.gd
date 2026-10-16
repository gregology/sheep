class_name JoypadDevice
extends InputDevice
## A gamepad seen through SDL (Steam Controllers arrive as Steam Input virtual pads).
## D-pad and left stick both steer, so D-pad-only controllers work everywhere.

const STICK_DEADZONE := 0.2
const TRIGGER_PRESS := 0.5
const BUTTON_MAP := {
	&"south": JOY_BUTTON_A,
	&"east": JOY_BUTTON_B,
	&"west": JOY_BUTTON_X,
	&"north": JOY_BUTTON_Y,
	&"left_shoulder": JOY_BUTTON_LEFT_SHOULDER,
	&"right_shoulder": JOY_BUTTON_RIGHT_SHOULDER,
	&"start": JOY_BUTTON_START,
	&"back": JOY_BUTTON_BACK,
}

var index := 0


func _init(joy_index: int, device_key: String) -> void:
	index = joy_index
	key = device_key
	display_name = Input.get_joy_name(joy_index)


func rumble(weak: float, strong: float, duration: float) -> void:
	Input.start_joy_vibration(index, weak, strong, duration)


func _read_button(button: StringName) -> bool:
	if Input.is_joy_button_pressed(index, BUTTON_MAP[button]):
		return true
	# Triggers count as shoulders: small hands find them easier to reach.
	if button == &"left_shoulder":
		return Input.get_joy_axis(index, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_PRESS
	if button == &"right_shoulder":
		return Input.get_joy_axis(index, JOY_AXIS_TRIGGER_RIGHT) > TRIGGER_PRESS
	return false


func _read_move() -> Vector2:
	var dpad := Vector2(
		float(Input.is_joy_button_pressed(index, JOY_BUTTON_DPAD_RIGHT))
			- float(Input.is_joy_button_pressed(index, JOY_BUTTON_DPAD_LEFT)),
		float(Input.is_joy_button_pressed(index, JOY_BUTTON_DPAD_DOWN))
			- float(Input.is_joy_button_pressed(index, JOY_BUTTON_DPAD_UP)))
	if dpad != Vector2.ZERO:
		return dpad.normalized()
	var stick := Vector2(
		Input.get_joy_axis(index, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(index, JOY_AXIS_LEFT_Y))
	var length := stick.length()
	if length < STICK_DEADZONE:
		return Vector2.ZERO
	# Rescale so movement starts from zero at the edge of the deadzone.
	return stick / length * clampf((length - STICK_DEADZONE) / (0.95 - STICK_DEADZONE), 0.0, 1.0)
