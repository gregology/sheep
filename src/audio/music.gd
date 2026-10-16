extends Node
## Background music on the Music bus: one looping track per screen, cross-faded.
##
## A track named N comes from user://family_sounds/music/N.(ogg|mp3) (or any single
## file in that folder, for every track), then res://assets/audio/music/N.ogg,
## otherwise a synthesised placeholder loop built on a worker thread.

## Mixed under the effects; the Music bus volume (settings) scales it further.
const LEVEL_DB := -8.0
const SILENT_DB := -60.0
const FADE := 1.2
const FAMILY_DIR := "user://family_sounds/music"
const BUNDLED_DIR := "res://assets/audio/music"

var track := &""

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _duck_tween: Tween
var _placeholder: AudioStreamWAV
var _task := -1
var _waiting := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)


## Cross-fades to the named track ("menu", "round"...). Does nothing if it's already playing.
func play(track_name: StringName) -> void:
	if track_name == track:
		return
	track = track_name
	var stream := _find(track_name)
	if stream == null:
		if _placeholder:
			stream = _placeholder
		else:
			_start_placeholder()
			return
	_crossfade_to(stream)


## Dips the music for a moment, e.g. under the victory fanfare.
func duck(seconds: float, by_db := 14.0) -> void:
	var player := _players[_active]
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(player, "volume_db", LEVEL_DB - by_db, 0.25)
	_duck_tween.tween_interval(seconds)
	_duck_tween.tween_property(player, "volume_db", LEVEL_DB, 1.0)


func _process(_delta: float) -> void:
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		if _waiting:
			_waiting = false
			_crossfade_to(_placeholder)


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)


func _crossfade_to(stream: AudioStream) -> void:
	var old := _players[_active]
	_active = 1 - _active
	var new := _players[_active]
	new.stream = stream
	new.volume_db = SILENT_DB
	new.play()
	if _duck_tween:
		_duck_tween.kill()
	var tween := create_tween().set_parallel()
	tween.tween_property(new, "volume_db", LEVEL_DB, FADE).set_ease(Tween.EASE_OUT)
	tween.tween_property(old, "volume_db", SILENT_DB, FADE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(old.stop)


func _start_placeholder() -> void:
	_waiting = true
	if _task < 0 and DisplayServer.get_name() != "headless":
		_task = WorkerThreadPool.add_task(func() -> void: _placeholder = Synth.music_loop())


func _find(track_name: StringName) -> AudioStream:
	var family := _family_track(track_name)
	if family:
		return family
	var path := "%s/%s.ogg" % [BUNDLED_DIR, track_name]
	if ResourceLoader.exists(path):
		var stream := load(path) as AudioStream
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		return stream
	return null


func _family_track(track_name: StringName) -> AudioStream:
	if not DirAccess.dir_exists_absolute(FAMILY_DIR):
		return null
	var files := Array(DirAccess.get_files_at(FAMILY_DIR)).filter(
		func(f: String) -> bool: return f.get_extension().to_lower() in ["ogg", "mp3"])
	if files.is_empty():
		return null
	var chosen: String = files[0]
	for file: String in files:
		if file.get_basename() == String(track_name):
			chosen = file
	var path := "%s/%s" % [FAMILY_DIR, chosen]
	if chosen.get_extension().to_lower() == "ogg":
		var ogg := AudioStreamOggVorbis.load_from_file(path)
		if ogg:
			ogg.loop = true
		return ogg
	var mp3 := AudioStreamMP3.load_from_file(path)
	if mp3:
		mp3.loop = true
	return mp3
