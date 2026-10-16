class_name Cooldown
extends RefCounted
## One ability's timer: READY -> (use) ACTIVE -> (done) COOLING -> READY.

signal became_ready

enum State { READY, ACTIVE, COOLING }

var state := State.READY
var time_left := 0.0
var phase_length := 0.0


func is_ready() -> bool:
	return state == State.READY


func activate(duration: float) -> void:
	_enter(State.ACTIVE, duration)


func cool(duration: float) -> void:
	if duration <= 0.0:
		_become_ready()
	else:
		_enter(State.COOLING, duration)


## Fraction of the current phase still to go: 1 = just started, 0 = done.
func remaining() -> float:
	if phase_length <= 0.0:
		return 0.0
	return clampf(time_left / phase_length, 0.0, 1.0)


func tick(delta: float) -> void:
	if state == State.READY:
		return
	time_left = maxf(0.0, time_left - delta)
	if state == State.COOLING and time_left <= 0.0:
		_become_ready()


func _enter(new_state: State, duration: float) -> void:
	state = new_state
	time_left = duration
	phase_length = duration


func _become_ready() -> void:
	state = State.READY
	time_left = 0.0
	phase_length = 0.0
	became_ready.emit()
