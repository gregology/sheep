extends Node
## Background music on the Music bus, looping. Uses the first track found in
## user://family_sounds/music/, then res://assets/audio/music/, otherwise a
## synthesised placeholder loop (built on a worker thread so start-up stays quick).

const FAMILY_DIR := "user://family_sounds/music"
const BUNDLED_DIR := "res://assets/audio/music"
## Mixed under the effects; the Music bus volume (settings) scales it further.
const LEVEL_DB := -9.0

var _player: AudioStreamPlayer
var _task := -1
var _generated: AudioStreamWAV


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = &"Music"
	_player.volume_db = LEVEL_DB
	add_child(_player)
	var track := _find_track()
	if track:
		_play(track)
	elif DisplayServer.get_name() != "headless":
		_task = WorkerThreadPool.add_task(_generate)


func _process(_delta: float) -> void:
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_play(_generated)


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)


func _generate() -> void:
	_generated = Synth.music_loop()


func _play(stream: AudioStream) -> void:
	_player.stream = stream
	_player.play()


func _find_track() -> AudioStream:
	if DirAccess.dir_exists_absolute(FAMILY_DIR):
		for file in DirAccess.get_files_at(FAMILY_DIR):
			var path := "%s/%s" % [FAMILY_DIR, file]
			match file.get_extension().to_lower():
				"ogg":
					var ogg := AudioStreamOggVorbis.load_from_file(path)
					if ogg:
						ogg.loop = true
						return ogg
				"mp3":
					var mp3 := AudioStreamMP3.load_from_file(path)
					if mp3:
						mp3.loop = true
						return mp3
	if DirAccess.dir_exists_absolute(BUNDLED_DIR):
		for file in ResourceLoader.list_directory(BUNDLED_DIR):
			if file.get_extension().to_lower() in ["ogg", "mp3", "wav"]:
				return load("%s/%s" % [BUNDLED_DIR, file]) as AudioStream
	return null
