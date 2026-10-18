class_name SheepState
extends RefCounted
## One sheep's simulation state. Views read it; only FlockSim writes it.

var id := 0
var pos := Vector2.ZERO
var vel := Vector2.ZERO
## Facing, as a yaw for a model that looks down -Z.
var heading := 0.0
## 0 = calm, 1 = panicking. Sets running speed; spreads to neighbours.
var fear := 0.0
var penned := false
## Seconds left in a startled hop, and how long that hop is.
var hop := 0.0
var hop_length := 0.4
## A startled dash (direction × speed) and seconds left in it. It fades as the
## time runs out, and the sheep doesn't flock until it's over.
var bolt := Vector2.ZERO
var bolt_left := 0.0
var wandering := false
var wander_target := Vector2.ZERO
var graze_timer := 0.0

# Per-tick accumulators, filled in by FlockInfluences.
## Desired-velocity contribution from influences.
var steer := Vector2.ZERO
## Strongest fear an influence is causing this tick.
var threat := 0.0
## Eagerness to move without being scared (following a leader).
var urge := 0.0
## Extra fear decay (a calm leader nearby).
var calming := 0.0


func start_hop(length: float) -> void:
	if hop <= 0.0:
		hop_length = length
		hop = length


## Height of the current hop, 0..1.
func hop_height() -> float:
	if hop <= 0.0 or hop_length <= 0.0:
		return 0.0
	return sin(PI * (1.0 - hop / hop_length))
