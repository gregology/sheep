extends Node
## Top level. The meadow is always running underneath; screens come and go on top.
##
## Grown-ups: hold Back/Select (or press Esc / F1) for settings.
## Developer keys: F2 small scare, F3 big scare, F12 screenshot.

const HOLD_FOR_SETTINGS := 1.2

var game: Game
var hud: Hud
var join: JoinScreen
var celebration: Celebration
var pause_menu: PauseMenu
var settings: SettingsScreen

var _back_held := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = Game.new()
	game.name = "Game"
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game)
	hud = Hud.new()
	add_child(hud)
	join = JoinScreen.new()
	add_child(join)
	celebration = Celebration.new()
	add_child(celebration)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	settings = SettingsScreen.new()
	add_child(settings)

	join.start_requested.connect(_start_round)
	game.won.connect(_on_won)
	celebration.play_again.connect(_start_round)
	celebration.change_players.connect(_show_join)
	pause_menu.resume.connect(_resume)
	pause_menu.restart.connect(func() -> void:
		_resume()
		_start_round())
	pause_menu.change_players.connect(func() -> void:
		_resume()
		_show_join())
	pause_menu.open_settings.connect(_open_settings)
	settings.closed.connect(_on_settings_closed)
	_show_join()
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--demo="):
			add_child(Demo.new(arg.get_slice("=", 1), "--quit-when-won" in args))


func _show_join() -> void:
	celebration.hide_screen()
	hud.hide_round()
	game.start_attract()
	join.visible = true
	Music.play(&"menu")


func _start_round() -> void:
	Players.remember()
	join.visible = false
	celebration.hide_screen()
	game.start_round()
	hud.show_round(game)
	Music.play(&"round")


func _on_won(stats: RoundStats) -> void:
	await get_tree().create_timer(1.8).timeout
	if game.mode == Game.Mode.CELEBRATING:
		hud.hide_round()
		celebration.show_stats(stats)


func _physics_process(delta: float) -> void:
	var holding_back := false
	for device in InputHub.devices:
		if device.is_down(&"back"):
			holding_back = true
	_back_held = _back_held + delta if holding_back else 0.0
	if _back_held >= HOLD_FOR_SETTINGS and not settings.visible:
		_open_settings()
	if settings.visible or pause_menu.visible:
		return
	if game.mode == Game.Mode.PLAYING:
		for device in InputHub.devices:
			if device.just_pressed(&"start"):
				_pause()
				break


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_ESCAPE, KEY_F1:
			if not settings.visible:
				_open_settings()
				get_viewport().set_input_as_handled()
		KEY_F2:
			Mic.simulate(0.45)
		KEY_F3:
			Mic.simulate(1.0)
		KEY_F12:
			_screenshot()


func _pause() -> void:
	get_tree().paused = true
	pause_menu.open()


func _resume() -> void:
	pause_menu.close()
	get_tree().paused = false


func _open_settings() -> void:
	_back_held = 0.0
	pause_menu.close()
	get_tree().paused = true
	settings.open()


func _on_settings_closed() -> void:
	get_tree().paused = false


func _screenshot() -> void:
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	var path := "user://screenshots/%s.png" % Time.get_datetime_string_from_system().replace(":", "-")
	get_viewport().get_texture().get_image().save_png(path)
	print("Saved ", ProjectSettings.globalize_path(path))
