extends Node
## Who is playing and as what. The join screen fills this in; rounds read it.

signal changed

const MAX_DOGS := 4
const MAX_CHAOS := 1
const REMEMBER_PATH := "user://last_players.cfg"

var slots: Array[PlayerSlot] = []
## device.key -> PlayerSlot.Role from the last session, so roles come back automatically.
var _remembered := {}


func _ready() -> void:
	_load_remembered()
	InputHub.device_disconnected.connect(leave)


func slot_for(device: InputDevice) -> PlayerSlot:
	for slot in slots:
		if slot.device == device:
			return slot
	return null


func dogs() -> Array[PlayerSlot]:
	return slots.filter(func(s: PlayerSlot) -> bool: return s.is_dog())


func chaos_slot() -> PlayerSlot:
	for slot in slots:
		if slot.is_chaos():
			return slot
	return null


## Adds the device as a player, in their remembered role when there is room.
## Returns null when the game is full.
func join(device: InputDevice) -> PlayerSlot:
	var existing := slot_for(device)
	if existing:
		return existing
	var slot := PlayerSlot.new(device)
	var wanted: int = _remembered.get(device.key, PlayerSlot.Role.DOG)
	if wanted == PlayerSlot.Role.CHAOS and chaos_slot() == null:
		slot.role = PlayerSlot.Role.CHAOS
	elif dogs().size() < MAX_DOGS:
		slot.role = PlayerSlot.Role.DOG
		slot.dog_index = _free_dog_index()
	elif chaos_slot() == null:
		slot.role = PlayerSlot.Role.CHAOS
	else:
		return null
	slots.append(slot)
	changed.emit()
	return slot


func leave(device: InputDevice) -> void:
	var slot := slot_for(device)
	if slot:
		slots.erase(slot)
		changed.emit()


## Switches a player's role. Returns false if that role is full.
func set_role(slot: PlayerSlot, role: PlayerSlot.Role) -> bool:
	if slot.role == role:
		return true
	if role == PlayerSlot.Role.CHAOS and chaos_slot() != null:
		return false
	if role == PlayerSlot.Role.DOG and dogs().size() >= MAX_DOGS:
		return false
	slot.role = role
	if role == PlayerSlot.Role.DOG:
		slot.dog_index = _free_dog_index(slot)
	changed.emit()
	return true


func remember() -> void:
	var cfg := ConfigFile.new()
	for slot in slots:
		cfg.set_value("roles", slot.device.key, slot.role)
		_remembered[slot.device.key] = slot.role
	cfg.save(REMEMBER_PATH)


func _free_dog_index(ignore: PlayerSlot = null) -> int:
	var used := {}
	for slot in slots:
		if slot != ignore and slot.is_dog():
			used[slot.dog_index] = true
	for i in MAX_DOGS:
		if not used.has(i):
			return i
	return 0


func _load_remembered() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(REMEMBER_PATH) != OK or not cfg.has_section("roles"):
		return
	for key in cfg.get_section_keys("roles"):
		_remembered[key] = cfg.get_value("roles", key)
