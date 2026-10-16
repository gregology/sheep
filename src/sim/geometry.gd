class_name Geometry
## Ground-plane helpers. Positions on the ground are Vector2(x, z).


## A straight piece of fence that creatures bump into.
class Segment:
	var a: Vector2
	var b: Vector2

	func _init(from: Vector2, to: Vector2) -> void:
		a = from
		b = to

	func closest_point(p: Vector2) -> Vector2:
		var ab := b - a
		var length_sq := ab.length_squared()
		if length_sq == 0.0:
			return a
		return a + ab * clampf((p - a).dot(ab) / length_sq, 0.0, 1.0)


static func to_3d(p: Vector2, height := 0.0) -> Vector3:
	return Vector3(p.x, height, p.y)


static func to_2d(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


## Yaw (rotation.y) that makes a model facing -Z look along `dir`.
static func yaw_for(dir: Vector2) -> float:
	return atan2(-dir.x, -dir.y)


static func rect_segments(r: Rect2) -> Array[Segment]:
	var tl := r.position
	var tr := Vector2(r.end.x, r.position.y)
	var br := r.end
	var bl := Vector2(r.position.x, r.end.y)
	return [Segment.new(tl, tr), Segment.new(tr, br), Segment.new(br, bl), Segment.new(bl, tl)]


## Short diagonal walls across the field's inside corners (including where the pen
## meets the outer fence), so sheep can't get wedged where no dog can get behind them.
static func corner_cuts(field: Rect2, pen: Rect2, size := 1.6) -> Array[Segment]:
	var cuts: Array[Segment] = []
	var corners: Array[Vector2] = [field.position, Vector2(field.end.x, field.position.y), field.end, Vector2(field.position.x, field.end.y)]
	for c in corners:
		if pen.grow(0.5).has_point(c):
			continue
		var u := Vector2(signf(field.get_center().x - c.x), 0)
		var v := Vector2(0, signf(field.get_center().y - c.y))
		cuts.append(Segment.new(c + u * size, c + v * size))
	# Where a pen wall meets the outer fence, the corner on the field side.
	var pen_corners: Array[Vector2] = [pen.position, Vector2(pen.end.x, pen.position.y), pen.end, Vector2(pen.position.x, pen.end.y)]
	for c in pen_corners:
		var on_top_or_bottom := is_equal_approx(c.y, field.position.y) or is_equal_approx(c.y, field.end.y)
		var on_left_or_right := is_equal_approx(c.x, field.position.x) or is_equal_approx(c.x, field.end.x)
		if on_top_or_bottom == on_left_or_right:
			continue  # a field corner, or not touching the fence at all
		var u: Vector2
		var v: Vector2
		if on_top_or_bottom:
			u = Vector2(signf(c.x - pen.get_center().x), 0)
			v = Vector2(0, signf(field.get_center().y - c.y))
		else:
			u = Vector2(0, signf(c.y - pen.get_center().y))
			v = Vector2(signf(field.get_center().x - c.x), 0)
		cuts.append(Segment.new(c + u * size, c + v * size))
	return cuts


## Moves a circle out of any segments it overlaps.
static func push_out(p: Vector2, radius: float, segments: Array[Segment]) -> Vector2:
	for segment in segments:
		var closest := segment.closest_point(p)
		var offset := p - closest
		var distance := offset.length()
		if distance < radius:
			if distance > 0.0001:
				p = closest + offset / distance * radius
			else:
				var along := (segment.b - segment.a).normalized()
				p = closest + Vector2(-along.y, along.x) * radius
	return p


## The point on any of the segments closest to p.
static func nearest_point(p: Vector2, segments: Array[Segment]) -> Vector2:
	var best := p
	var best_distance := INF
	for segment in segments:
		var c := segment.closest_point(p)
		var d := c.distance_squared_to(p)
		if d < best_distance:
			best_distance = d
			best = c
	return best
