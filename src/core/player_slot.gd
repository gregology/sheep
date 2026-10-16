class_name PlayerSlot
extends RefCounted
## One person on the couch: their controller and the role they picked.

enum Role { DOG, CHAOS }

const DOG_COLORS: Array[Color] = [
	Color(1.0, 0.42, 0.42),  # coral red
	Color(0.30, 0.67, 0.97),  # sky blue
	Color(1.0, 0.83, 0.23),  # sunshine yellow
	Color(0.69, 0.59, 0.99),  # grape
]
const BREEDS: Array[StringName] = [&"collie", &"corgi", &"golden", &"husky"]
const CHAOS_COLOR := Color(0.76, 0.42, 0.96)

var device: InputDevice
var role: Role = Role.DOG
## 0..3 among the dogs; picks colour and breed.
var dog_index := 0


func _init(input_device: InputDevice) -> void:
	device = input_device


func color() -> Color:
	return DOG_COLORS[dog_index % DOG_COLORS.size()] if role == Role.DOG else CHAOS_COLOR


func breed() -> StringName:
	return BREEDS[dog_index % BREEDS.size()]


func is_dog() -> bool:
	return role == Role.DOG


func is_chaos() -> bool:
	return role == Role.CHAOS
