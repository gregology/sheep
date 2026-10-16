class_name FlockInfluence
extends RefCounted
## Anything that pushes or pulls on sheep: a dog, a bark, the wolf, the black sheep...
##
## To add a new kind of influence, extend this class, override affect(),
## and register an instance with FlockSim.add_influence(). Keep `position` updated.

## Where it is on the ground (x, z).
var position := Vector2.ZERO
var enabled := true
## Sheep can't overlap a body this big (0 = no body, e.g. a bark).
var body_radius := 0.0
## Whether penned sheep react too (they can't escape, but they can panic).
var reaches_pen := false
## Seconds left to live; negative means "until removed".
var time_left := -1.0


## Add this influence's effect on one sheep to its per-tick accumulators
## (steer, threat, urge, calming).
func affect(_sheep: SheepState, _sim: FlockSim) -> void:
	pass


func tick(delta: float) -> void:
	if time_left > 0.0:
		time_left = maxf(0.0, time_left - delta)


func is_finished() -> bool:
	return time_left == 0.0
