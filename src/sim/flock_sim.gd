class_name FlockSim
extends RefCounted
## The sheep brain: a pure simulation on the ground plane, with no nodes or
## rendering, so it can be unit-tested and tuned on its own.
##
## Each tick, every loose sheep adds up:
##   - pushes and pulls from registered FlockInfluences (dogs, barks, wolf, black sheep...)
##   - flocking: separation, cohesion (stronger when scared) and alignment
##   - calm grazing with short wanders
##   - fence avoidance, and a gentle funnel toward the pen gate
## Fear spreads between neighbours and fades over time; it sets how fast a sheep runs.

signal sheep_penned(sheep: SheepState)

var tuning: Tuning
var field: Rect2
var pen: PenArea
## Outer fence and pen walls. The gate gap is open for sheep.
var fences: Array[Geometry.Segment] = []
## Fences plus the closed gate: what dogs and other creatures bump into.
var solid_fences: Array[Geometry.Segment] = []
var sheep: Array[SheepState] = []
var influences: Array[FlockInfluence] = []
## 0..1: the round raises this when it has gone on a while, widening the gate funnel.
var assist := 0.0
var rng := RandomNumberGenerator.new()

var _flock_center := Vector2.ZERO


func _init(sim_tuning: Tuning, field_rect: Rect2, pen_area: PenArea) -> void:
	tuning = sim_tuning
	field = field_rect
	pen = pen_area
	fences = Geometry.rect_segments(field_rect)
	fences.append_array(pen.walls())
	fences.append_array(Geometry.corner_cuts(field_rect, pen.rect))
	solid_fences = fences.duplicate()
	solid_fences.append(pen.gate_segment())


func spawn(count: int, area: Rect2) -> void:
	sheep.clear()
	for i in count:
		var s := SheepState.new()
		s.id = i
		s.pos = _free_spot(area)
		s.heading = rng.randf() * TAU
		s.graze_timer = rng.randf_range(0.5, 4.0)
		sheep.append(s)


func add_influence(influence: FlockInfluence) -> void:
	if not influences.has(influence):
		influences.append(influence)


func remove_influence(influence: FlockInfluence) -> void:
	influences.erase(influence)


func penned_count() -> int:
	var n := 0
	for s in sheep:
		if s.penned:
			n += 1
	return n


func all_penned() -> bool:
	return not sheep.is_empty() and penned_count() == sheep.size()


func loose_sheep() -> Array[SheepState]:
	return sheep.filter(func(s: SheepState) -> bool: return not s.penned)


## Middle of the sheep still loose in the field (field centre if none are).
func loose_centroid() -> Vector2:
	var total := Vector2.ZERO
	var n := 0
	for s in sheep:
		if not s.penned:
			total += s.pos
			n += 1
	return total / n if n > 0 else field.get_center()


## Keeps a non-sheep creature out of the fences and the pen.
func collide_solid(p: Vector2, radius: float) -> Vector2:
	p = Geometry.push_out(p, radius, solid_fences)
	var inner := field.grow(-radius)
	return Vector2(clampf(p.x, inner.position.x, inner.end.x), clampf(p.y, inner.position.y, inner.end.y))


## A sudden noise: every loose sheep hops and bolts away from its neighbours, each
## its own way, forgetting to flock until the bolt fades; penned sheep just hop
## about. Returns how many loose sheep scattered.
func startle(intensity: float) -> int:
	var scattered := 0
	for s in sheep:
		s.start_hop(0.3 + 0.25 * intensity)
		if s.penned:
			s.fear = maxf(s.fear, intensity * 0.5)
			continue
		var away := s.pos - _neighbour_center(s, tuning.cohesion_radius)
		if away.length() < 0.1:
			away = Vector2.RIGHT.rotated(rng.randf() * TAU)
		away = away.normalized().rotated(rng.randf_range(-0.9, 0.9))
		var oomph := 0.5 + 0.5 * intensity
		s.bolt = away * tuning.mic_startle_strength * oomph * rng.randf_range(0.75, 1.25)
		s.bolt_left = maxf(s.bolt_left, tuning.mic_scatter_time * oomph)
		s.vel += s.bolt
		s.fear = maxf(s.fear, intensity)
		scattered += 1
	return scattered


## Something scary appeared at `at`: nearby loose sheep flee from it.
func startle_at(at: Vector2, radius: float, intensity: float) -> int:
	var scattered := 0
	for s in sheep:
		var offset := s.pos - at
		var distance := offset.length()
		if distance > radius:
			continue
		var t := 1.0 - distance / radius
		s.start_hop(0.35)
		if s.penned:
			s.fear = maxf(s.fear, intensity * t * 0.5)
			continue
		var away := offset / distance if distance > 0.01 else Vector2.RIGHT.rotated(rng.randf() * TAU)
		s.vel += away * tuning.mic_startle_strength * intensity * (0.5 + 0.5 * t)
		s.fear = maxf(s.fear, intensity * (0.5 + 0.5 * t))
		scattered += 1
	return scattered


func step(dt: float) -> void:
	_tick_influences(dt)
	for s in sheep:
		s.steer = Vector2.ZERO
		s.threat = 0.0
		s.urge = 0.0
		s.calming = 0.0
	for influence in influences:
		if not influence.enabled:
			continue
		for s in sheep:
			if not s.penned or influence.reaches_pen:
				influence.affect(s, self)
	_update_fear(dt)
	_flock_center = loose_centroid()
	for s in sheep:
		if s.penned:
			_step_penned(s, dt)
		else:
			_step_loose(s, dt)
		if s.hop > 0.0:
			s.hop = maxf(0.0, s.hop - dt)
	_resolve_overlaps()
	for s in sheep:
		if not s.penned and pen.contains(s.pos, tuning.sheep_radius + 0.15):
			s.penned = true
			s.fear = minf(s.fear, 0.3)
			sheep_penned.emit(s)


func _tick_influences(dt: float) -> void:
	for i in range(influences.size() - 1, -1, -1):
		influences[i].tick(dt)
		if influences[i].is_finished():
			influences.remove_at(i)


func _update_fear(dt: float) -> void:
	var before: Array[float] = []
	for s in sheep:
		before.append(s.fear)
	for i in sheep.size():
		var s := sheep[i]
		var spread := 0.0
		for j in sheep.size():
			var o := sheep[j]
			if i != j and o.penned == s.penned and s.pos.distance_to(o.pos) < tuning.contagion_radius:
				spread = maxf(spread, before[j] * tuning.contagion)
		var decayed := s.fear - tuning.fear_decay * (1.0 + s.calming * 3.0) * dt
		s.fear = clampf(maxf(decayed, maxf(s.threat, spread * (1.0 - s.calming))), 0.0, 1.0)


func _step_loose(s: SheepState, dt: float) -> void:
	var desired := s.steer
	# 1 just after a fright, fading to 0: running off alone instead of flocking.
	var scatter := 0.0
	if s.bolt_left > 0.0:
		s.bolt_left = maxf(0.0, s.bolt_left - dt)
		scatter = minf(1.0, s.bolt_left / tuning.mic_scatter_time)
		desired += s.bolt * scatter
	var separation := Vector2.ZERO
	var center := Vector2.ZERO
	var heading := Vector2.ZERO
	var neighbours := 0
	for o in sheep:
		if o == s or o.penned:
			continue
		var offset := s.pos - o.pos
		var distance := offset.length()
		if distance < tuning.separation_radius and distance > 0.0001:
			separation += offset / distance * (1.0 - distance / tuning.separation_radius)
		if distance < tuning.cohesion_radius:
			center += o.pos
			heading += o.vel
			neighbours += 1
	desired += separation * tuning.separation_weight
	if neighbours > 0:
		center /= neighbours
		var bunching := tuning.cohesion_weight * (1.0 + s.fear * tuning.cohesion_fear_bonus) * (1.0 - scatter)
		desired += (center - s.pos).limit_length(1.0) * bunching
		desired += heading / neighbours * tuning.alignment_weight * maxf(s.fear, s.urge) * (1.0 - scatter)
	elif s.pos.distance_to(_flock_center) > tuning.cohesion_radius:
		# All alone: amble back toward the others, as sheep do.
		desired += (_flock_center - s.pos).normalized() * tuning.graze_speed * tuning.lonely_pull * (1.0 - scatter)

	if s.fear < 0.15 and s.steer.length() < 0.2:
		_graze(s, dt)
		if s.wandering:
			desired += (s.wander_target - s.pos).limit_length(1.0) * tuning.graze_speed
		elif desired.length() < 0.35 and neighbours > 0:
			desired = Vector2.ZERO  # standing still, munching
	else:
		s.wandering = false

	desired += _wall_avoidance(s.pos)
	desired += _gate_funnel(s.pos)

	var top_speed := lerpf(tuning.graze_speed, tuning.run_speed, maxf(s.fear, s.urge * 0.7))
	desired = desired.limit_length(top_speed)
	s.vel = s.vel.move_toward(desired, tuning.sheep_accel * (1.0 + s.fear) * dt)
	s.pos = _fence_in(s.pos + s.vel * dt)
	if s.vel.length() > 0.15:
		s.heading = Geometry.yaw_for(s.vel)


func _step_penned(s: SheepState, dt: float) -> void:
	var desired := Vector2.ZERO
	for o in sheep:
		if o == s or not o.penned:
			continue
		var offset := s.pos - o.pos
		var distance := offset.length()
		if distance < tuning.separation_radius and distance > 0.0001:
			desired += offset / distance * (1.0 - distance / tuning.separation_radius) * tuning.separation_weight
	if s.threat > 0.3 or s.fear > 0.5:
		# Something scary nearby: a panicky little dance on the spot.
		if s.hop <= 0.0 and rng.randf() < dt * 3.0:
			s.start_hop(rng.randf_range(0.25, 0.4))
			s.heading += rng.randf_range(-1.5, 1.5)
	else:
		_graze(s, dt)
		if s.wandering:
			desired += (s.wander_target - s.pos).limit_length(1.0) * tuning.graze_speed * 0.6
	s.vel = s.vel.move_toward(desired.limit_length(tuning.graze_speed * 2.0), tuning.sheep_accel * dt)
	s.pos = pen.clamp_inside(s.pos + s.vel * dt, tuning.sheep_radius)
	if s.vel.length() > 0.15:
		s.heading = Geometry.yaw_for(s.vel)


func _graze(s: SheepState, dt: float) -> void:
	s.graze_timer -= dt
	if s.graze_timer > 0.0:
		if s.wandering and s.pos.distance_to(s.wander_target) < 0.3:
			s.wandering = false
		return
	if s.wandering or rng.randf() < 0.4:
		s.wandering = false
		s.graze_timer = rng.randf_range(2.0, 6.0)
	else:
		s.wandering = true
		var area := pen.rect.grow(-0.8) if s.penned else field.grow(-1.0)
		var target := s.pos + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(1.0, 3.0)
		s.wander_target = target.clamp(area.position, area.end)
		s.graze_timer = rng.randf_range(1.5, 3.5)


func _wall_avoidance(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for segment in fences:
		var offset := p - segment.closest_point(p)
		var distance := offset.length()
		if distance < tuning.wall_avoid_distance and distance > 0.0001:
			push += offset / distance * (1.0 - distance / tuning.wall_avoid_distance)
	return push * tuning.wall_avoid_weight


## Near the gate, sheep drift toward it, so herding them in is forgiving.
func _gate_funnel(p: Vector2) -> Vector2:
	var gate := pen.gate_center()
	if (p - gate).dot(pen.inward) > 0.0:
		return Vector2.ZERO  # already through
	var radius := tuning.gate_funnel_radius * (1.0 + assist)
	var distance := p.distance_to(gate)
	if distance > radius:
		return Vector2.ZERO
	var target := gate + pen.inward * 1.0
	return (target - p).normalized() * tuning.gate_funnel_strength * (1.0 - distance / radius) * (0.5 + assist)


func _resolve_overlaps() -> void:
	var min_distance := tuning.sheep_radius * 2.0
	for i in sheep.size():
		var a := sheep[i]
		for j in range(i + 1, sheep.size()):
			var b := sheep[j]
			if a.penned != b.penned:
				continue
			var offset := a.pos - b.pos
			var distance := offset.length()
			if distance < min_distance:
				var push := (offset / distance if distance > 0.0001 else Vector2.RIGHT) * (min_distance - distance) * 0.5
				a.pos += push
				b.pos -= push
	for influence in influences:
		if influence.body_radius <= 0.0 or not influence.enabled:
			continue
		var reach := influence.body_radius + tuning.sheep_radius
		for s in sheep:
			if s.penned:
				continue
			var offset := s.pos - influence.position
			var distance := offset.length()
			if distance >= reach:
				continue
			var pushed := influence.position + (offset / distance if distance > 0.0001 else Vector2.RIGHT) * reach
			s.pos = _fence_in(pushed)
			# Pinned against a fence or a bale: squeeze out sideways along it, rather
			# than staying squashed underneath whoever is pushing.
			var blocked := s.pos - pushed
			if blocked.length() > 0.001:
				var along := Vector2(-blocked.y, blocked.x).normalized()
				var side := along.dot(offset)
				if absf(side) < 0.001:
					side = 1.0 if s.id % 2 == 0 else -1.0
				s.pos = _fence_in(s.pos + along * signf(side) * blocked.length())
	for s in sheep:
		if s.penned:
			s.pos = pen.clamp_inside(s.pos, tuning.sheep_radius)
		else:
			s.pos = _fence_in(s.pos)


## Keeps a loose sheep inside the field and clear of the fences, pen walls and bales.
func _fence_in(p: Vector2) -> Vector2:
	var inner := field.grow(-tuning.sheep_radius)
	return Geometry.push_out(p.clamp(inner.position, inner.end), tuning.sheep_radius, fences)


func _neighbour_center(s: SheepState, radius: float) -> Vector2:
	var total := Vector2.ZERO
	var n := 0
	for o in sheep:
		if o != s and not o.penned and s.pos.distance_to(o.pos) < radius:
			total += o.pos
			n += 1
	return total / n if n > 0 else s.pos


func _free_spot(area: Rect2) -> Vector2:
	var best := area.get_center()
	for attempt in 30:
		var p := Vector2(
			rng.randf_range(area.position.x, area.end.x),
			rng.randf_range(area.position.y, area.end.y))
		var clear := true
		for s in sheep:
			if s.pos.distance_to(p) < tuning.separation_radius:
				clear = false
				break
		if clear:
			return p
		best = p
	return best
