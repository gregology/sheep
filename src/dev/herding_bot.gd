class_name HerdingBot
extends Node
## A simple computer sheepdog for demo mode and balance checks. It drives a
## ScriptedDevice the way a person would: get round behind the flock (or a
## straggler) on the far side from the gate without running through it, then
## walk it toward the gate, barking now and then.

var device: ScriptedDevice
var dog: Dog
var game: Game
## Which side of the flock this bot covers (-1 or 1), so two bots spread out.
var flank := 0.0

var _bark_timer := 2.0


func _init(scripted: ScriptedDevice, side := 0.0) -> void:
	device = scripted
	flank = side


func _physics_process(delta: float) -> void:
	device.stick = Vector2.ZERO
	if game == null or game.mode != Game.Mode.PLAYING:
		return
	if dog == null or not is_instance_valid(dog):
		dog = _find_dog()
		if dog == null:
			return
	var sim := game.sim
	var loose := sim.loose_sheep()
	if loose.is_empty():
		return

	var flock := sim.loose_centroid()
	var spread := 0.0
	var straggler: SheepState = null
	for s in loose:
		var d := s.pos.distance_to(flock)
		spread = maxf(spread, d)
		if d > 6.0 and (straggler == null or d > straggler.pos.distance_to(flock)):
			straggler = s
	# Bring stragglers back to the flock; otherwise drive the flock to the gate.
	var target := straggler.pos if straggler else flock
	var goal := flock if straggler else sim.pen.gate_center() - sim.pen.inward * 0.5
	var drive := (goal - target).normalized()
	var side := Vector2(-drive.y, drive.x)
	var radius := 1.0 if straggler else minf(spread, 3.5)
	var field := sim.field.grow(-1.0)
	var behind := (target - drive * (radius + 2.2) + side * flank * radius * 0.6).clamp(field.position, field.end)

	var to_spot := behind - dog.pos
	if to_spot.length() > 1.2:
		var stick := to_spot.normalized()
		# Swing wide rather than charging through the middle of the flock.
		var to_target := target - dog.pos
		if to_target.length() < radius + 2.5 and stick.dot(to_target.normalized()) > 0.3:
			var around := Vector2(-to_target.y, to_target.x).normalized()
			if around.dot(to_spot) < 0.0:
				around = -around
			stick = (around * 1.5 + stick * 0.3).normalized()
		device.stick = stick
	else:
		device.stick = drive * 0.55  # walk on, steady pressure

	_bark_timer -= delta
	if _bark_timer <= 0.0 and to_spot.length() < 1.5 and dog.pos.distance_to(target) < radius + 3.5:
		device.tap(&"south")
		_bark_timer = randf_range(3.0, 6.0)


func _find_dog() -> Dog:
	for d in game.dogs:
		if d.slot.device == device:
			return d
	return null
