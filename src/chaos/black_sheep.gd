extends ChaosCreature
## The black sheep: the flock happily follows it wherever it goes.
## Left alone, it trots to the flock and then leads them away from the pen.

const FOLLOWERS_FOR_STAR := 3

var _target := Vector2.ZERO
var _retarget := 0.0
var _star_given := false
var _check := 0.0


func _make_model() -> CreatureModel:
	return Models.make(&"black_sheep")


func _make_influence() -> FlockInfluence:
	return AttractInfluence.new(tuning.black_sheep_radius, tuning.black_sheep_strength, tuning.black_sheep_follow_distance)


func _speed() -> float:
	return tuning.black_sheep_speed


func _on_landed() -> void:
	Sfx.play_at(&"baa", Geometry.to_3d(pos), 2.0, 0.0)
	Effects.pop_text(effects, Geometry.to_3d(pos, 1.8), "BAA!", Color(0.85, 0.7, 1.0), 80)


func _active_tick(delta: float) -> void:
	_check -= delta
	if _star_given or _check > 0.0:
		return
	_check = 0.5
	var followers := 0
	for s in sim.sheep:
		if not s.penned and s.pos.distance_to(pos) < tuning.black_sheep_follow_distance * 2.5:
			followers += 1
	if followers >= FOLLOWERS_FOR_STAR:
		_star_given = true
		Events.chaos_star_earned.emit(&"black_sheep")


func _autopilot(delta: float) -> Vector2:
	var flock := sim.loose_centroid()
	if pos.distance_to(flock) > 5.0:
		return (flock - pos).normalized()
	_retarget -= delta
	if _retarget <= 0.0 or pos.distance_to(_target) < 1.0:
		# Somewhere in the field, as far from the pen as we can manage.
		var best := pos
		var best_distance := -1.0
		for i in 6:
			var area := sim.field.grow(-2.0)
			var p := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
			var d := p.distance_to(sim.pen.gate_center())
			if d > best_distance:
				best_distance = d
				best = p
		_target = best
		_retarget = 4.0
	return (_target - pos).normalized()
