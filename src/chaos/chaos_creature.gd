class_name ChaosCreature
extends Node3D
## Base for creatures the chaos player summons. They leap in over the fence near
## the flock, can be steered (and wander toward the fun by themselves when left
## alone), then leap back out over the nearest fence when their time is up.
##
## Subclasses override the _make_* hooks and _autopilot().

signal finished

enum Phase { ENTERING, ACTIVE, LEAVING, GONE }

const JUMP_TIME := 0.9
const JUMP_HEIGHT := 2.4
## How far either side of the fence a leap starts and lands.
const JUMP_REACH := 2.6
const RADIUS := 0.7
const ACCEL := 22.0

var sim: FlockSim
var tuning: Tuning
## Where effects (rings, words, puffs) go.
var effects: Node3D
var phase := Phase.ENTERING
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var time_left := 10.0
var influence: FlockInfluence
var model: CreatureModel
var shadow: BlobShadow

var _steer := Vector2.ZERO
var _idle := 0.0
var _height := 0.0
var _jump_from := Vector2.ZERO
var _jump_to := Vector2.ZERO
var _jump_t := -1.0
var _exit_run := Vector2.ZERO
var _exit_jump := Vector2.ZERO


func setup(flock: FlockSim, duration: float, effects_parent: Node3D) -> void:
	sim = flock
	tuning = flock.tuning
	time_left = duration
	effects = effects_parent


func _ready() -> void:
	model = _make_model()
	model.size = tuning.creature_scale
	add_child(model)
	shadow = BlobShadow.new(_shadow_size() * tuning.creature_scale)
	add_child(shadow)
	influence = _make_influence()
	var edge := _fence_point_near(sim.loose_centroid())
	var outward := _outward(edge)
	_jump(edge + outward * JUMP_REACH, edge - outward * JUMP_REACH)
	pos = _jump_from
	Sfx.play_at(&"boing", Geometry.to_3d(pos))
	_sync_transform(0.0)


## Called every tick by the chaos controller with the player's stick or D-pad.
func steer(direction: Vector2) -> void:
	_steer = direction


## Ends the visit early (e.g. the round finished).
func leave_now() -> void:
	time_left = 0.0


func _physics_process(delta: float) -> void:
	match phase:
		Phase.ENTERING:
			if _advance_jump(delta):
				phase = Phase.ACTIVE
				influence.position = pos
				sim.add_influence(influence)
				model.squash(1.0)
				Effects.puff(effects, Geometry.to_3d(pos), Color(0.85, 0.95, 0.75), 8, 0.14, 1.2)
				_on_landed()
		Phase.ACTIVE:
			time_left -= delta
			_move(delta)
			influence.position = pos
			_active_tick(delta)
			if time_left <= 0.0:
				_begin_leaving()
		Phase.LEAVING:
			if _jump_t >= 0.0:
				if _advance_jump(delta):
					_vanish()
			else:
				var to_exit := _exit_run - pos
				if to_exit.length() < 0.4:
					_jump(pos, _exit_jump)
					Sfx.play_at(&"boing", Geometry.to_3d(pos), -2.0)
				else:
					vel = vel.move_toward(to_exit.normalized() * _speed() * 1.3, ACCEL * delta)
					pos = sim.collide_solid(pos + vel * delta, RADIUS)


func _process(delta: float) -> void:
	_sync_transform(delta)


func _exit_tree() -> void:
	if sim:
		sim.remove_influence(influence)


# --- Hooks for subclasses ---------------------------------------------------

func _make_model() -> CreatureModel:
	return CreatureModel.new()


func _make_influence() -> FlockInfluence:
	return FlockInfluence.new()


func _speed() -> float:
	return 4.0


func _shadow_size() -> float:
	return 1.3


## Called once, the moment it lands in the field.
func _on_landed() -> void:
	pass


## Called every tick while it's on the field.
func _active_tick(_delta: float) -> void:
	pass


## Which way to go when nobody is steering (unit vector or zero).
func _autopilot(_delta: float) -> Vector2:
	return Vector2.ZERO


# --- Internals --------------------------------------------------------------

func _move(delta: float) -> void:
	var desired := Vector2.ZERO
	if _steer.length() > 0.15:
		_idle = 0.0
		desired = _steer * _speed()
	else:
		_idle += delta
		if _idle >= tuning.autopilot_delay:
			desired = _autopilot(delta) * _speed() * 0.85
	vel = vel.move_toward(desired, ACCEL * delta)
	pos = sim.collide_solid(pos + vel * delta, RADIUS)


func _begin_leaving() -> void:
	phase = Phase.LEAVING
	sim.remove_influence(influence)
	var edge := _fence_point_near(pos)
	var outward := _outward(edge)
	_exit_run = edge - outward * 0.9
	_exit_jump = edge + outward * JUMP_REACH
	if pos.distance_to(_exit_run) < 0.6:
		_jump(pos, _exit_jump)


func _vanish() -> void:
	phase = Phase.GONE
	Effects.puff(effects, Geometry.to_3d(pos), Color(0.9, 0.9, 1.0), 6)
	finished.emit()
	queue_free()


func _jump(from: Vector2, to: Vector2) -> void:
	_jump_from = from
	_jump_to = to
	_jump_t = 0.0
	vel = (to - from) / JUMP_TIME


## Returns true when the jump has landed.
func _advance_jump(delta: float) -> bool:
	_jump_t = minf(1.0, _jump_t + delta / JUMP_TIME)
	pos = _jump_from.lerp(_jump_to, _jump_t)
	_height = 4.0 * JUMP_HEIGHT * _jump_t * (1.0 - _jump_t)
	if _jump_t >= 1.0:
		_jump_t = -1.0
		_height = 0.0
		return true
	return false


func _sync_transform(delta: float) -> void:
	position = Geometry.to_3d(pos)
	model.position.y = _height
	shadow.set_height(_height)
	if vel.length() > 0.3:
		var target := Geometry.yaw_for(vel)
		rotation.y = target if delta == 0.0 else lerp_angle(rotation.y, target, 1.0 - exp(-delta * 12.0))
	model.gait = 0.6 if _jump_t >= 0.0 else clampf(vel.length() / _speed(), 0.0, 1.0)


## A point on the outer fence near `target`, away from the pen.
func _fence_point_near(target: Vector2) -> Vector2:
	var field := sim.field
	var avoid := sim.pen.rect.grow(2.0)
	var best := Vector2(field.position.x, field.get_center().y)
	var best_distance := INF
	for segment in Geometry.rect_segments(field):
		var length := segment.a.distance_to(segment.b)
		for i in range(1, int(length)):
			var p := segment.a.lerp(segment.b, i / length)
			if avoid.has_point(p):
				continue
			var d := p.distance_squared_to(target)
			if d < best_distance:
				best_distance = d
				best = p
	return best


func _outward(edge: Vector2) -> Vector2:
	var field := sim.field
	if absf(edge.x - field.position.x) < 0.01:
		return Vector2.LEFT
	if absf(edge.x - field.end.x) < 0.01:
		return Vector2.RIGHT
	if absf(edge.y - field.position.y) < 0.01:
		return Vector2.UP
	return Vector2.DOWN
