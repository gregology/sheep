extends Node
## Owns the live Tuning and saves the grown-ups' changes to user://.

signal changed

const DEFAULTS_PATH := "res://config/tuning.tres"
const USER_PATH := "user://tuning.tres"

var tuning: Tuning


func _ready() -> void:
	tuning = _load()
	apply_audio()


func save() -> void:
	ResourceSaver.save(tuning, USER_PATH)
	apply_audio()
	changed.emit()


func reset_to_defaults() -> void:
	tuning = (load(DEFAULTS_PATH) as Tuning).duplicate()
	save()


func apply_audio() -> void:
	_set_bus_volume(&"Master", tuning.master_volume)
	_set_bus_volume(&"Music", tuning.music_volume)
	_set_bus_volume(&"Sfx", tuning.sfx_volume)


func _load() -> Tuning:
	if ResourceLoader.exists(USER_PATH):
		var saved := ResourceLoader.load(USER_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Tuning
		if saved:
			return saved
	return (load(DEFAULTS_PATH) as Tuning).duplicate()


func _set_bus_volume(bus: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
