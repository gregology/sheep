extends TestCase
## The hay bales across the field's corners: no sheep should ever end up stuck behind one.

const TICK := 1.0 / 60.0

var tuning: Tuning
var layout: MeadowLayout
var pen: PenArea


func before_each() -> void:
	tuning = Tuning.new()
	layout = MeadowLayout.new()
	pen = layout.make_pen()


func _sim(positions: Array[Vector2]) -> FlockSim:
	var sim := FlockSim.new(tuning, layout.field_rect(), pen)
	sim.rng.seed = 99
	for i in positions.size():
		var s := SheepState.new()
		s.id = i
		s.pos = positions[i]
		s.graze_timer = 100.0
		sim.sheep.append(s)
	return sim


func _cuts() -> Array[Geometry.Segment]:
	return Geometry.corner_cuts(layout.field_rect(), pen.rect)


## Unit vector from a bale out into the field.
func _front(cut: Geometry.Segment) -> Vector2:
	var along := (cut.b - cut.a).normalized()
	var normal := Vector2(-along.y, along.x)
	var middle := (cut.a + cut.b) * 0.5
	return normal if normal.dot(layout.field_rect().get_center() - middle) > 0.0 else -normal


## How far p is out in front of a bale (negative: behind it, in the corner).
func _depth(cut: Geometry.Segment, p: Vector2) -> float:
	return (p - cut.a).dot(_front(cut))


## The middle of the little triangle of ground behind a bale.
func _behind(cut: Geometry.Segment) -> Vector2:
	return (cut.a + cut.b) * 0.5 - _front(cut) * 0.45


func _check_in_front(sim: FlockSim, label: String) -> void:
	for cut in _cuts():
		for s in sim.sheep:
			if s.penned:
				continue
			var depth := _depth(cut, s.pos)
			var level := (s.pos - cut.a).dot((cut.b - cut.a).normalized())
			if level > 0.0 and level < cut.a.distance_to(cut.b):
				check(depth > tuning.sheep_radius - 0.05,
					"%s: sheep %d is %.2f m from the bale at %s (behind it if negative)" % [label, s.id, depth, (cut.a + cut.b) * 0.5])


func test_a_dog_cant_squash_a_sheep_behind_a_bale() -> void:
	for cut in _cuts():
		var front := _front(cut)
		var middle := (cut.a + cut.b) * 0.5
		var sim := _sim([middle + front * 2.0])
		var dog := RepelInfluence.new(tuning.dog_pressure_radius, tuning.dog_pressure_strength, tuning.dog_fear)
		dog.body_radius = tuning.dog_radius
		dog.position = middle + front * 5.0
		sim.add_influence(dog)
		var deepest := INF
		for i in int(4.0 / TICK):
			# The dog runs straight into the corner and keeps pushing.
			dog.position = sim.collide_solid(dog.position.move_toward(middle - front, tuning.dog_speed * TICK), tuning.dog_radius)
			sim.step(TICK)
			deepest = minf(deepest, _depth(cut, sim.sheep[0].pos))
		check(deepest > -0.05, "the dog pushed the sheep %.2f m behind the bale at %s" % [-deepest, middle])
		_check_in_front(sim, "dog at %s" % middle)


func test_a_sheep_behind_a_bale_comes_back_out() -> void:
	for cut in _cuts():
		var sim := _sim([_behind(cut)])
		for i in int(1.0 / TICK):
			sim.step(TICK)
		_check_in_front(sim, "started behind")


func test_a_crowd_pressed_into_a_corner_stays_in_front_of_the_bale() -> void:
	for cut in _cuts():
		var front := _front(cut)
		var along := (cut.b - cut.a).normalized()
		var middle := (cut.a + cut.b) * 0.5
		var spots: Array[Vector2] = []
		for row in 3:
			for col in 4:
				spots.append(middle + front * (1.0 + row * 1.0) + along * (col - 1.5) * 1.0)
		var sim := _sim(spots)
		sim.add_influence(_wolf(middle + front * 6.0))
		for i in int(3.0 / TICK):
			sim.step(TICK)
			if i % 20 == 0:
				sim.startle(1.0)
		_check_in_front(sim, "crowd at %s" % middle)


func _wolf(at: Vector2) -> RepelInfluence:
	var wolf := RepelInfluence.new(tuning.wolf_radius, tuning.wolf_strength, tuning.wolf_fear)
	wolf.position = at
	wolf.body_radius = 0.85
	return wolf
