extends ChaosCreature
## The wolf: sheep flee it far harder than any dog, and its arrival scatters the flock.
## Penned sheep can't escape, but they do a panicky dance when it prowls nearby.

const LANDING_SCARE_RADIUS := 6.0

var _target := Vector2.ZERO
var _retarget := 0.0


func _make_model() -> CreatureModel:
	return Models.make(&"wolf")


func _make_influence() -> FlockInfluence:
	var repel := RepelInfluence.new(tuning.wolf_radius, tuning.wolf_strength, tuning.wolf_fear)
	repel.body_radius = 0.85
	repel.reaches_pen = true
	return repel


func _speed() -> float:
	return tuning.wolf_speed


func _shadow_size() -> float:
	return 1.6


func _on_landed() -> void:
	Sfx.play_at(&"howl", Geometry.to_3d(pos))
	Effects.ring(effects, Geometry.to_3d(pos), Color(0.55, 0.45, 0.9), LANDING_SCARE_RADIUS)
	Effects.pop_text(effects, Geometry.to_3d(pos, 2.2), "AWOOO!", Color(0.8, 0.7, 1.0), 80)
	if sim.startle_at(pos, LANDING_SCARE_RADIUS, 1.0) >= 3:
		Events.chaos_star_earned.emit(&"wolf")


## Left alone, the wolf dashes at one sheep after another.
func _autopilot(delta: float) -> Vector2:
	_retarget -= delta
	if _retarget <= 0.0 or pos.distance_to(_target) < 1.2:
		var loose := sim.loose_sheep()
		_target = loose.pick_random().pos if not loose.is_empty() else sim.field.get_center()
		_retarget = 3.0
	return (_target - pos).normalized()
