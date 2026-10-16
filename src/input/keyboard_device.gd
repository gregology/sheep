class_name KeyboardDevice
extends InputDevice
## A slice of the keyboard acting as a controller, for development and testing.
## Enter is Start and Tab is Back on every scheme.

const SCHEMES := [
	{
		"name": "Keys: WASD",
		"move": [KEY_W, KEY_A, KEY_S, KEY_D],
		"south": KEY_SPACE, "east": KEY_E, "west": KEY_Q, "north": KEY_R,
		"left_shoulder": KEY_Z, "right_shoulder": KEY_X,
	},
	{
		"name": "Keys: IJKL",
		"move": [KEY_I, KEY_J, KEY_K, KEY_L],
		"south": KEY_U, "east": KEY_O, "west": KEY_Y, "north": KEY_P,
		"left_shoulder": KEY_N, "right_shoulder": KEY_M,
	},
	{
		"name": "Keys: arrows",
		"move": [KEY_UP, KEY_LEFT, KEY_DOWN, KEY_RIGHT],
		"south": KEY_PERIOD, "east": KEY_SLASH, "west": KEY_COMMA, "north": KEY_SEMICOLON,
		"left_shoulder": KEY_BRACKETLEFT, "right_shoulder": KEY_BRACKETRIGHT,
	},
]

var _scheme: Dictionary


func _init(scheme_index: int) -> void:
	_scheme = SCHEMES[scheme_index]
	key = "keyboard:%d" % scheme_index
	display_name = _scheme["name"]


func is_keyboard() -> bool:
	return true


func _read_button(button: StringName) -> bool:
	match button:
		&"start":
			return Input.is_physical_key_pressed(KEY_ENTER)
		&"back":
			return Input.is_physical_key_pressed(KEY_TAB)
	return Input.is_physical_key_pressed(_scheme[String(button)])


func _read_move() -> Vector2:
	var keys: Array = _scheme["move"]
	var v := Vector2(
		float(Input.is_physical_key_pressed(keys[3])) - float(Input.is_physical_key_pressed(keys[1])),
		float(Input.is_physical_key_pressed(keys[2])) - float(Input.is_physical_key_pressed(keys[0])))
	return v.normalized() if v != Vector2.ZERO else v
