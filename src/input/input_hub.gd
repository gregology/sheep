extends Node
## Keeps the list of input devices and polls them all at the start of each physics tick,
## so every reader sees the same "just pressed" state.

signal device_connected(device: InputDevice)
signal device_disconnected(device: InputDevice)

var devices: Array[InputDevice] = []
var _joypads := {}  # SDL joypad index -> JoypadDevice


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -100
	for i in KeyboardDevice.SCHEMES.size():
		devices.append(KeyboardDevice.new(i))
	for index in Input.get_connected_joypads():
		_add_joypad(index)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _physics_process(_delta: float) -> void:
	for device in devices:
		device.poll()


## Adds a non-hardware device (demo bots, tests).
func add_device(device: InputDevice) -> void:
	devices.append(device)
	device_connected.emit(device)


func joypads() -> Array[InputDevice]:
	return devices.filter(func(d: InputDevice) -> bool: return not d.is_keyboard())


func _on_joy_connection_changed(index: int, connected: bool) -> void:
	if connected:
		_add_joypad(index)
	elif _joypads.has(index):
		var device: JoypadDevice = _joypads[index]
		_joypads.erase(index)
		devices.erase(device)
		device_disconnected.emit(device)


func _add_joypad(index: int) -> void:
	if _joypads.has(index):
		return
	# Identical controllers share a name, so number them in connection order.
	var name := Input.get_joy_name(index)
	var same_name := 0
	for other: JoypadDevice in _joypads.values():
		if other.display_name == name:
			same_name += 1
	var device := JoypadDevice.new(index, "%s#%d" % [name, same_name])
	_joypads[index] = device
	devices.append(device)
	device_connected.emit(device)
