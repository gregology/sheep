class_name Demo
extends Node
## Scripted scenarios for screenshots, balance checks and showing off.
## Run with:  godot --path . -- --demo=<scenario>
##   join        robots join (two dogs + chaos) and wait on the join screen
##   round       robot dogs herd while a robot chaos player causes trouble
##   celebrate   a round where every sheep is already home
## Add --quit-when-won to exit with the round time (balance checks).

var scenario := ""
var quit_when_won := false
var main: Node
var _chaos_device: ScriptedDevice
var _time := 0.0
var _script: Array = []


func _init(name_of_scenario: String, quit_on_win := false) -> void:
	scenario = name_of_scenario
	quit_when_won = quit_on_win
	name = "Demo"


func _ready() -> void:
	main = get_parent()
	var game: Game = main.game
	var dogs: Array[ScriptedDevice] = [ScriptedDevice.new("Robot Rover"), ScriptedDevice.new("Robot Rex")]
	_chaos_device = ScriptedDevice.new("Robot Chaos")
	for i in dogs.size():
		InputHub.add_device(dogs[i])
		Players.join(dogs[i])
		var bot := HerdingBot.new(dogs[i], -1.0 if i == 0 else 1.0)
		bot.game = game
		add_child(bot)
	InputHub.add_device(_chaos_device)
	var chaos_slot := Players.join(_chaos_device)
	Players.set_role(chaos_slot, PlayerSlot.Role.CHAOS)
	game.won.connect(_on_won)
	match scenario:
		"round":
			main.call("_start_round")
			_script = [
				[2.0, func() -> void: _chaos_device.tap(&"south")],
				[6.0, func() -> void: _chaos_device.stick = Vector2(-1, 0.3)],
				[8.0, func() -> void: _chaos_device.stick = Vector2.ZERO],
				[14.0, func() -> void: Mic.simulate(0.9)],
				[33.0, func() -> void: _chaos_device.tap(&"east")],
			]
		"celebrate":
			main.call("_start_round")
			_script = [[0.5, _pen_everyone]]


func _physics_process(delta: float) -> void:
	var before := _time
	_time += delta
	if quit_when_won and int(before / 30.0) != int(_time / 30.0):
		var game: Game = main.game
		print("DEMO_PROGRESS t=%ds penned=%d/%d" % [int(_time), game.sim.penned_count(), game.sim.sheep.size()])
		if OS.is_debug_build() and "--verbose-demo" in OS.get_cmdline_user_args():
			var loose := game.sim.loose_sheep().map(func(s: SheepState) -> String: return "(%.1f,%.1f)" % [s.pos.x, s.pos.y])
			var dogs := game.dogs.map(func(d: Dog) -> String: return "(%.1f,%.1f)" % [d.pos.x, d.pos.y])
			print("   loose=%s dogs=%s" % [", ".join(loose), ", ".join(dogs)])
	while not _script.is_empty() and _time >= _script[0][0]:
		var step: Array = _script.pop_front()
		(step[1] as Callable).call()


func _pen_everyone() -> void:
	var game: Game = main.game
	var pen := game.sim.pen.rect.grow(-0.8)
	for s in game.sim.sheep:
		s.pos = Vector2(randf_range(pen.position.x, pen.end.x), randf_range(pen.position.y, pen.end.y))


func _on_won(stats: RoundStats) -> void:
	print("DEMO_WON seconds=%.1f chaos_stars=%d" % [stats.seconds, stats.chaos_stars])
	if quit_when_won:
		get_tree().quit()
