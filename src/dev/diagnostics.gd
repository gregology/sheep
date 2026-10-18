class_name Diagnostics
extends Node
## A plain-text health report about the machine the game is running on: GPU and
## screen, frame rate, controllers (and every button pressed), and what the
## microphone hears. Started with --diagnose; writes user://diagnostics.txt every
## few seconds and on exit. --shots=5,20 saves screenshots at those seconds and
## --quit-at=40 quits, so a whole test can run unattended.

const REPORT := "user://diagnostics.txt"
const MAX_EVENTS := 400

var _shots: Array[float] = []
var _quit_at := -1.0
var _elapsed := 0.0
var _next_write := 5.0
var _frame_times := PackedFloat32Array()
var _mic_levels := PackedFloat32Array()
var _mic_sample := 0.0
var _events: Array[String] = []
var _startles: Array[String] = []


func _init() -> void:
	name = "Diagnostics"
	for part in LaunchArgs.value("--shots").split(",", false):
		_shots.append(float(part))
	_quit_at = float(LaunchArgs.value("--quit-at", "-1"))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Mic.startled.connect(_on_startled)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_log("diagnostics started")


func _process(delta: float) -> void:
	_elapsed += delta
	_frame_times.append(delta)
	_mic_sample -= delta
	if _mic_sample <= 0.0:
		_mic_sample = 0.25
		if Mic.available:
			_mic_levels.append(Mic.detector.level_db)
	if not _shots.is_empty() and _elapsed >= _shots[0]:
		_shots.pop_front()
		Diagnostics.screenshot(get_viewport(), "diagnose-%02ds" % int(_elapsed))
	if _elapsed >= _next_write:
		_next_write += 5.0
		write_report()
	if _quit_at > 0.0 and _elapsed >= _quit_at:
		_quit_at = -1.0
		write_report()
		get_tree().quit()


func _input(event: InputEvent) -> void:
	if _events.size() >= MAX_EVENTS:
		return
	var button := event as InputEventJoypadButton
	if button and button.pressed:
		_log("pad %d (%s) button %d" % [button.device, Input.get_joy_name(button.device), button.button_index])
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		_log("key %s" % OS.get_keycode_string(key.physical_keycode))


func _exit_tree() -> void:
	write_report()


func write_report() -> String:
	var text := "\n".join([
		"Sheep! diagnostics, %s, %.0f s after start" % [Time.get_datetime_string_from_system(), _elapsed],
		"",
		system_summary(),
		"",
		"Frame rate: " + _frame_summary(),
		"Microphone levels (dB, every 0.25 s): " + _level_summary(),
		"Microphone scares: %d" % _startles.size(),
		"  " + "\n  ".join(_startles),
		"",
		"Events (%d):" % _events.size(),
		"  " + "\n  ".join(_events),
	])
	var file := FileAccess.open(REPORT, FileAccess.WRITE)
	if file:
		file.store_string(text + "\n")
	return text


## A snapshot of this machine: what the grown-ups' settings screen shows, too.
static func system_summary() -> String:
	var lines: Array[String] = []
	lines.append("Game: %s" % ProjectSettings.get_setting("application/config/version", "?"))
	lines.append("System: %s %s, %s (%d threads)" % [
		OS.get_distribution_name(), OS.get_version(), OS.get_processor_name(), OS.get_processor_count()])
	lines.append("GPU: %s (%s)" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version()])
	lines.append("Screen: %s at %.0f Hz, window %s" % [
		DisplayServer.screen_get_size(), DisplayServer.screen_get_refresh_rate(), DisplayServer.window_get_size()])
	var steam := OS.get_environment("SteamGameId")
	lines.append("Launched by Steam: %s" % ("yes (Steam Input active)" if steam != "" else "no"))
	var pads := Input.get_connected_joypads()
	lines.append("Controllers: %d" % pads.size())
	for index in pads:
		var info := Input.get_joy_info(index)
		lines.append("  #%d %s  guid %s  %s" % [index, Input.get_joy_name(index), Input.get_joy_guid(index),
			"vendor %s product %s" % [info.get("vendor_id", "?"), info.get("product_id", "?")]])
	lines.append("Sound out: %s, %d Hz, latency %.0f ms" % [
		AudioServer.output_device, AudioServer.get_mix_rate(), AudioServer.get_output_latency() * 1000.0])
	var mic_state := "NOT available"
	if Mic.available:
		mic_state = "open, but no sound from it yet (switched off or muted?)" if Mic.is_silent() else "working"
	lines.append("Microphone: %s, device '%s' of %s" % [mic_state, AudioServer.input_device, AudioServer.get_input_device_list()])
	var t := Settings.tuning
	lines.append("Microphone calibration: quiet room %.0f dB, game sound at mic %+.0f dB, scare threshold %.0f dB" % [
		t.mic_noise_floor_db, t.mic_self_coupling_db, t.mic_threshold_db])
	return "\n".join(lines)


static func screenshot(viewport: Viewport, label := "") -> String:
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "user://screenshots/%s%s.png" % [stamp, ("-" + label) if label != "" else ""]
	viewport.get_texture().get_image().save_png(path)
	print("Saved ", ProjectSettings.globalize_path(path))
	return path


func _frame_summary() -> String:
	if _frame_times.size() < 10:
		return "not enough frames yet"
	var sorted := _frame_times.duplicate()
	sorted.sort()
	var total := 0.0
	for t in sorted:
		total += t
	var p99 := sorted[int(sorted.size() * 0.99)]
	return "average %.1f fps, 1%% low %.1f fps, worst frame %.1f ms (%d frames)" % [
		sorted.size() / total, 1.0 / p99, sorted[-1] * 1000.0, sorted.size()]


func _level_summary() -> String:
	if _mic_levels.is_empty():
		return "none (no microphone)"
	var sorted := _mic_levels.duplicate()
	sorted.sort()
	return "quietest %.0f, median %.0f, loudest %.0f" % [sorted[0], sorted[sorted.size() / 2], sorted[-1]]


func _log(what: String) -> void:
	_events.append("%6.1fs  %s" % [_elapsed, what])


func _on_startled(strength: float) -> void:
	_startles.append("%6.1fs  strength %.2f" % [_elapsed, strength])


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	_log("pad %d %s: %s" % [device, "connected" if connected else "disconnected", Input.get_joy_name(device)])
