extends Node
## Plays named one-shot sound effects. For each name it looks, in order, in:
##   1. user://family_sounds/<name>/     your own recordings (never committed)
##   2. res://assets/audio/sfx/<name>/   bundled CC0 sounds
##   3. a synthesised placeholder (see Synth)
## Every .wav/.ogg/.mp3 in the winning folder joins the pool, and one is picked
## at random each time, so recording three different "baa"s gives variety.

const FAMILY_DIR := "user://family_sounds"
const BUNDLED_DIR := "res://assets/audio/sfx"
const EXTENSIONS: Array[String] = ["wav", "ogg", "mp3"]
const POOL_SIZE := 16

var _banks := {}  # StringName -> Array[AudioStream]
var _flat: Array[AudioStreamPlayer] = []
var _spatial: Array[AudioStreamPlayer3D] = []
var _next_flat := 0
var _next_spatial := 0
var _last_played := {}  # StringName -> msec
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(FAMILY_DIR)
	for i in POOL_SIZE:
		var flat := AudioStreamPlayer.new()
		flat.bus = &"Sfx"
		add_child(flat)
		_flat.append(flat)
		var spatial := AudioStreamPlayer3D.new()
		spatial.bus = &"Sfx"
		spatial.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		spatial.panning_strength = 0.6
		add_child(spatial)
		_spatial.append(spatial)


## Plays a sound everywhere. `min_gap` (seconds) skips it if the same sound played very recently.
func play(sound: StringName, volume_db := 0.0, pitch_jitter := 0.08, min_gap := 0.0) -> void:
	var stream := _pick(sound, min_gap)
	if stream == null:
		return
	var player := _flat[_next_flat]
	_next_flat = (_next_flat + 1) % _flat.size()
	_start(player, stream, volume_db, pitch_jitter)


## Plays a sound panned toward where it happened on the field.
func play_at(sound: StringName, at: Vector3, volume_db := 0.0, pitch_jitter := 0.08, min_gap := 0.0) -> void:
	var stream := _pick(sound, min_gap)
	if stream == null:
		return
	var player := _spatial[_next_spatial]
	_next_spatial = (_next_spatial + 1) % _spatial.size()
	player.global_position = at
	_start(player, stream, volume_db, pitch_jitter)


## Forget loaded sounds so newly added family recordings get picked up.
func reload() -> void:
	_banks.clear()


func family_folder() -> String:
	return ProjectSettings.globalize_path(FAMILY_DIR)


func _start(player: Node, stream: AudioStream, volume_db: float, pitch_jitter: float) -> void:
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
	player.play()


func _pick(sound: StringName, min_gap: float) -> AudioStream:
	var now := Time.get_ticks_msec()
	if min_gap > 0.0 and now - int(_last_played.get(sound, -100000)) < min_gap * 1000.0:
		return null
	_last_played[sound] = now
	if not _banks.has(sound):
		_banks[sound] = _load_bank(sound)
	var bank: Array = _banks[sound]
	return bank[_rng.randi() % bank.size()] if not bank.is_empty() else null


func _load_bank(sound: StringName) -> Array:
	var family := _load_user_files("%s/%s" % [FAMILY_DIR, sound])
	if not family.is_empty():
		return family
	var bundled := []
	var dir := "%s/%s" % [BUNDLED_DIR, sound]
	if DirAccess.dir_exists_absolute(dir):
		for file in ResourceLoader.list_directory(dir):
			if file.get_extension().to_lower() in EXTENSIONS:
				var stream := load("%s/%s" % [dir, file]) as AudioStream
				if stream:
					bundled.append(stream)
	if not bundled.is_empty():
		return bundled
	var placeholder := Synth.make(sound)
	return [placeholder] if placeholder else []


func _load_user_files(dir: String) -> Array:
	var streams := []
	if not DirAccess.dir_exists_absolute(dir):
		return streams
	for file in DirAccess.get_files_at(dir):
		var path := "%s/%s" % [dir, file]
		var stream: AudioStream = null
		match file.get_extension().to_lower():
			"wav": stream = AudioStreamWAV.load_from_file(path)
			"ogg": stream = AudioStreamOggVorbis.load_from_file(path)
			"mp3": stream = AudioStreamMP3.load_from_file(path)
		if stream:
			streams.append(stream)
	return streams
