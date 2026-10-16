extends TestCase
## Fences, the pen and its one-way gate.

var pen: PenArea


func before_each() -> void:
	pen = PenArea.new(Rect2(8, -8.5, 6, 6), PenArea.Side.BOTTOM, 3.4)


func test_push_out_moves_circle_off_a_fence() -> void:
	var fence: Array[Geometry.Segment] = [Geometry.Segment.new(Vector2(-5, 0), Vector2(5, 0))]
	var p := Geometry.push_out(Vector2(1, 0.2), 0.5, fence)
	check_near(p.y, 0.5, 0.001, "should end up exactly one radius from the fence")
	check_near(p.x, 1.0, 0.001, "should be pushed straight out")


func test_gate_is_in_the_middle_of_the_bottom_wall() -> void:
	check(pen.gate_center().is_equal_approx(Vector2(11, -2.5)), "gate centre was %s" % pen.gate_center())
	check(pen.inward.is_equal_approx(Vector2.UP), "the gate should open up into the pen")


func test_walls_leave_the_gate_open() -> void:
	var at_gate := Geometry.push_out(pen.gate_center(), 0.5, pen.walls())
	check(at_gate.is_equal_approx(pen.gate_center()), "a sheep in the gateway shouldn't hit a wall")


func test_gate_segment_blocks_dogs() -> void:
	var gate: Array[Geometry.Segment] = [pen.gate_segment()]
	var p := Geometry.push_out(pen.gate_center() + Vector2(0, 0.1), 0.6, gate)
	check(p.distance_to(pen.gate_center()) >= 0.599, "the closed gate should stop a dog")


func test_clamp_keeps_penned_sheep_inside() -> void:
	var p := pen.clamp_inside(Vector2(20, 20), 0.5)
	check(pen.contains(p, 0.49), "clamped position %s should be inside the pen" % p)
