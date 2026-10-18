extends Node
## Listens to the microphone and turns sudden noises into flock startles
## (Events.flock_startled). The detection logic lives in StartleDetector.
##
## To stop the game scaring its own sheep through the TV speakers, it tracks
## how loud the game itself is (the Master bus peak) and ignores anything at
## the mic that could just be that sound coming back.

signal startled(strength: float)
signal calibration_finished(ok: bool)

## Smallest startle worth sending to the flock.
const MIN_STARTLE := 0.05
const BLOCK_SECONDS := 0.01
const CALIBRATION_QUIET := 3.0
const CALIBRATION_LOUD := 3.0
## Seconds of pure digital silence before a mic that has never sent any sound
## counts as switched off.
const SILENCE_AFTER := 2.0

var available := false
var detector: StartleDetector
var calibrating := false

var _mix_rate := 44100.0
var _block_frames := 441
var _sum_squares := 0.0
var _frames_in_block := 0
var _highpass_alpha := 1.0
var _hp_last_in := 0.0
var _hp_last_out := 0.0
var _self_env_db := -90.0
var _self_hold := 0.0
var _calibration_samples: Array[Vector2] = []  # (mic_db, self_db)
var _silent_for := 0.0
## The input device that has sent real sound (anything but exact zeros) at least once.
var _heard_from := ""
var _calibration_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	detector = StartleDetector.new(Settings.tuning)
	Settings.changed.connect(_on_settings_changed)
	_open_device()


func _process(delta: float) -> void:
	_track_own_sound(delta)
	if available:
		_read_frames()
	if calibrating:
		_calibration_time += delta


## True when the microphone is open but has sent nothing but exact zeros: a real
## microphone always hisses a little, so it's switched off or muted. Some wireless
## mics send exact zeros whenever the room is quiet, so one that has sent any sound
## at all counts as working.
func is_silent() -> bool:
	return available and _heard_from != AudioServer.input_device and _silent_for > SILENCE_AFTER


## The game's own sound as it probably arrives at the mic (dB).
func self_noise_db() -> float:
	return _self_env_db + Settings.tuning.mic_self_coupling_db


## Startle the flock as if the mic heard a sudden noise (keyboard shortcut, testing).
func simulate(strength: float) -> void:
	_emit(detector.force(strength))


## Measures the quiet room, then plays a few game sounds to learn how much of
## them leaks back into the mic. Results are saved to Settings.
func calibrate() -> void:
	if calibrating:
		return
	calibrating = true
	_calibration_samples.clear()
	_calibration_time = 0.0
	await get_tree().create_timer(CALIBRATION_QUIET, true, false, true).timeout
	var quiet := _calibration_samples.map(func(s: Vector2) -> float: return s.x)
	_calibration_samples.clear()
	for i in 6:
		Sfx.play([&"bark", &"baa", &"boing"][i % 3])
		await get_tree().create_timer(CALIBRATION_LOUD / 6.0, true, false, true).timeout
	var loud := _calibration_samples.duplicate()
	calibrating = false

	if quiet.is_empty():
		calibration_finished.emit(false)
		return
	quiet.sort()
	Settings.tuning.mic_noise_floor_db = clampf(quiet[int(quiet.size() * 0.9)] + 3.0, -80.0, -20.0)
	var leaks: Array[float] = []
	for s: Vector2 in loud:
		if s.y > -40.0:
			leaks.append(s.x - s.y)
	if leaks.size() >= 5:
		leaks.sort()
		Settings.tuning.mic_self_coupling_db = clampf(leaks[int(leaks.size() * 0.8)] + 3.0, -40.0, 10.0)
	Settings.save()
	calibration_finished.emit(true)


func _open_device() -> void:
	var tuning := Settings.tuning
	available = false
	if not tuning.mic_enabled or not ProjectSettings.get_setting("audio/driver/enable_input", false):
		AudioServer.set_input_device_active(false)
		return
	if tuning.mic_device in AudioServer.get_input_device_list():
		AudioServer.input_device = tuning.mic_device
	available = AudioServer.set_input_device_active(true) == OK
	_mix_rate = AudioServer.get_input_mix_rate()
	_block_frames = maxi(64, int(_mix_rate * BLOCK_SECONDS))
	var rc := 1.0 / (TAU * tuning.mic_highpass_hz)
	_highpass_alpha = rc / (rc + 1.0 / _mix_rate)
	if not available:
		push_warning("Microphone unavailable; the noise mechanic is off.")


func _read_frames() -> void:
	var count := AudioServer.get_input_frames_available()
	if count <= 0:
		return
	var frames := AudioServer.get_input_frames(count)
	for frame in frames:
		var x := (frame.x + frame.y) * 0.5
		# One-pole high-pass: footsteps and TV rumble shouldn't count.
		var y := _highpass_alpha * (_hp_last_out + x - _hp_last_in)
		_hp_last_in = x
		_hp_last_out = y
		_sum_squares += y * y
		_frames_in_block += 1
		if _frames_in_block >= _block_frames:
			var rms := sqrt(_sum_squares / _frames_in_block)
			_sum_squares = 0.0
			_frames_in_block = 0
			_feed(linear_to_db(rms + 1e-9), _block_frames / _mix_rate)


func _feed(block_db: float, dt: float) -> void:
	if block_db < -170.0:
		_silent_for += dt
	else:
		_silent_for = 0.0
		_heard_from = AudioServer.input_device
	var self_db := self_noise_db()
	if calibrating:
		_calibration_samples.append(Vector2(block_db, _self_env_db))
		detector.process(block_db, dt, 100.0)  # keep the meters moving, never startle
		return
	_emit(detector.process(block_db, dt, self_db))


func _emit(strength: float) -> void:
	if strength < MIN_STARTLE:
		return
	startled.emit(strength)
	Events.flock_startled.emit(strength, &"mic")


func _track_own_sound(delta: float) -> void:
	var peak := maxf(AudioServer.get_bus_peak_volume_left_db(0, 0), AudioServer.get_bus_peak_volume_right_db(0, 0))
	if peak >= _self_env_db:
		_self_env_db = peak
		_self_hold = Settings.tuning.mic_self_hold
	elif _self_hold > 0.0:
		_self_hold -= delta
	else:
		_self_env_db = lerpf(_self_env_db, maxf(peak, -90.0), 1.0 - exp(-delta / 0.15))


func _on_settings_changed() -> void:
	detector.tuning = Settings.tuning
	_open_device()
