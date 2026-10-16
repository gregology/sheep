class_name ChaosAbility
extends Resource
## Something the chaos player can summon onto the field.
##
## To add one: make a scene whose root extends ChaosCreature, then add a
## ChaosAbility pointing at it to res://config/chaos_roster.tres.

@export var id: StringName
@export var creature: PackedScene
## Controller buttons that summon it, by position (see InputDevice.BUTTONS).
@export var buttons: Array[StringName] = []
@export var color := Color.WHITE
## Model kind shown on its HUD button (see Models.make).
@export var portrait: StringName
## Seconds on the field and seconds to recharge after; negative uses Tuning's chaos defaults.
@export var duration := -1.0
@export var cooldown := -1.0


func duration_for(tuning: Tuning) -> float:
	return duration if duration > 0.0 else tuning.chaos_duration


func cooldown_for(tuning: Tuning) -> float:
	return cooldown if cooldown >= 0.0 else tuning.chaos_cooldown
