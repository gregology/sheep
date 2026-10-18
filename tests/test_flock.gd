extends TestCase
## How sheep react to dogs, the wolf, the black sheep, noises, fences and the pen.

const TICK := 1.0 / 60.0

var tuning: Tuning
var layout: MeadowLayout


func before_each() -> void:
	tuning = Tuning.new()
	layout = MeadowLayout.new()


func _sim(positions: Array[Vector2]) -> FlockSim:
	var sim := FlockSim.new(tuning, layout.field_rect(), layout.make_pen())
	sim.rng.seed = 1234
	for i in positions.size():
		var s := SheepState.new()
		s.id = i
		s.pos = positions[i]
		s.graze_timer = 100.0  # no wandering off during tests
		sim.sheep.append(s)
	return sim


func _run(sim: FlockSim, seconds: float) -> void:
	for i in int(seconds / TICK):
		sim.step(TICK)


func _dog(at: Vector2) -> RepelInfluence:
	var dog := RepelInfluence.new(tuning.dog_pressure_radius, tuning.dog_pressure_strength, tuning.dog_fear)
	dog.position = at
	dog.body_radius = tuning.dog_radius
	return dog


func _wolf(at: Vector2) -> RepelInfluence:
	var wolf := RepelInfluence.new(tuning.wolf_radius, tuning.wolf_strength, tuning.wolf_fear)
	wolf.position = at
	wolf.reaches_pen = true
	return wolf


func test_calm_flock_stays_calm() -> void:
	var sim := _sim([Vector2(-5, 0), Vector2(-3.5, 0.5), Vector2(-4, 2)])
	_run(sim, 10.0)
	for s in sim.sheep:
		check(s.fear < 0.05, "sheep %d got scared of nothing (fear %.2f)" % [s.id, s.fear])
		check(s.vel.length() < tuning.graze_speed * 1.2, "sheep %d is rushing about" % s.id)


func test_sheep_move_away_from_a_dog() -> void:
	var sim := _sim([Vector2(-4, 0)])
	sim.add_influence(_dog(Vector2(-6, 0)))
	_run(sim, 1.0)
	check(sim.sheep[0].pos.x > -2.5, "the sheep should have moved away (x = %.2f)" % sim.sheep[0].pos.x)


func test_wolf_is_much_scarier_than_a_dog() -> void:
	var with_dog := _sim([Vector2(-4, 0)])
	with_dog.add_influence(_dog(Vector2(-7, 0)))
	var with_wolf := _sim([Vector2(-4, 0)])
	with_wolf.add_influence(_wolf(Vector2(-7, 0)))
	_run(with_dog, 1.0)
	_run(with_wolf, 1.0)
	var dog_push := with_dog.sheep[0].pos.x + 4.0
	var wolf_push := with_wolf.sheep[0].pos.x + 4.0
	check(wolf_push > dog_push * 1.5, "wolf moved the sheep %.2f m, dog %.2f m" % [wolf_push, dog_push])
	check(with_wolf.sheep[0].fear > with_dog.sheep[0].fear, "the wolf should frighten more")


func test_flock_follows_the_black_sheep() -> void:
	var sim := _sim([Vector2(-8, 0), Vector2(-8, 1.5), Vector2(-9.5, -1)])
	var leader := AttractInfluence.new(tuning.black_sheep_radius, tuning.black_sheep_strength, tuning.black_sheep_follow_distance)
	leader.position = Vector2(-2, 0)
	sim.add_influence(leader)
	_run(sim, 4.0)
	for s in sim.sheep:
		check(s.pos.distance_to(leader.position) < 4.0, "sheep %d didn't follow (%.1f m away)" % [s.id, s.pos.distance_to(leader.position)])


func test_fences_keep_sheep_in() -> void:
	var sim := _sim([Vector2(-13, 0)])
	sim.add_influence(_wolf(Vector2(-9, 0)))
	_run(sim, 3.0)
	var inside := layout.field_rect().grow(-tuning.sheep_radius + 0.01)
	check(inside.has_point(sim.sheep[0].pos), "the sheep escaped the field to %s" % sim.sheep[0].pos)


func test_sheep_pushed_through_the_gate_get_penned() -> void:
	var pen := layout.make_pen()
	var sim := _sim([pen.gate_center() - pen.inward * 2.0])
	var dog := _dog(pen.gate_center() - pen.inward * 4.5)
	sim.add_influence(dog)
	var penned := []
	sim.sheep_penned.connect(func(s: SheepState) -> void: penned.append(s.id))
	for i in int(8.0 / TICK):
		# The dog keeps walking up behind the sheep.
		var behind := sim.sheep[0].pos - pen.inward * 2.0
		dog.position = Geometry.push_out(dog.position.move_toward(behind, 3.0 * TICK), 0.6, sim.solid_fences)
		sim.step(TICK)
	check(sim.sheep[0].penned, "the sheep should be in the pen (it's at %s)" % sim.sheep[0].pos)
	check(penned == [0], "sheep_penned should fire once")


func test_penned_sheep_never_leave_even_for_the_wolf() -> void:
	var pen := layout.make_pen()
	var sim := _sim([pen.rect.get_center()])
	_run(sim, 0.1)
	check(sim.sheep[0].penned, "a sheep in the middle of the pen counts as penned")
	sim.add_influence(_wolf(pen.gate_center() - pen.inward * 1.0))
	sim.startle(1.0)
	_run(sim, 5.0)
	check(sim.sheep[0].penned and pen.contains(sim.sheep[0].pos), "the penned sheep got out to %s" % sim.sheep[0].pos)


func test_a_startle_scatters_the_flock() -> void:
	var sim := _sim([Vector2(-4, 0), Vector2(-3, 0.6), Vector2(-5, 0.6), Vector2(-4, -1), Vector2(-4, 1.2)])
	var before := _spread(sim)
	var scattered := sim.startle(1.0)
	_run(sim, 0.6)
	check(scattered == 5, "all five loose sheep should scatter (got %d)" % scattered)
	check(_spread(sim) > before * 1.5, "the flock should spread out (%.2f -> %.2f)" % [before, _spread(sim)])


func test_a_dog_cant_push_a_sheep_through_the_fence() -> void:
	var sim := _sim([Vector2(0, -6.5)])
	var dog := _dog(Vector2(0, -2))
	sim.add_influence(dog)
	for i in int(3.0 / TICK):
		dog.position = sim.collide_solid(dog.position + Vector2(0, -tuning.dog_speed * TICK), tuning.dog_radius)
		sim.step(TICK)
	var inside := layout.field_rect().grow(-tuning.sheep_radius + 0.01)
	check(inside.has_point(sim.sheep[0].pos), "the dog shoved the sheep out of the field to %s" % sim.sheep[0].pos)
	check(sim.sheep[0].pos.distance_to(dog.position) > tuning.dog_radius + tuning.sheep_radius - 0.2,
		"the sheep should squeeze out sideways, not stay squashed under the dog")


func test_fear_spreads_to_neighbours() -> void:
	var sim := _sim([Vector2(-4, 0), Vector2(-2.6, 0), Vector2(8, 5)])
	sim.add_influence(_dog(Vector2(-5.5, 0)))
	_run(sim, 0.2)
	check(sim.sheep[1].fear > 0.1, "a neighbour of a frightened sheep should get nervous")
	check(sim.sheep[2].fear < 0.01, "a faraway sheep shouldn't care")


func _spread(sim: FlockSim) -> float:
	var center := sim.loose_centroid()
	var total := 0.0
	for s in sim.sheep:
		total += s.pos.distance_to(center)
	return total / sim.sheep.size()
