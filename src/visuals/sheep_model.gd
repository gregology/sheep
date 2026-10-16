class_name SheepModel
extends CreatureModel
## Stand-in sheep made of wool puffs. The black sheep is the same body in a different style.

const WHITE := {
	"wool": Color(0.99, 0.97, 0.93),
	"face": Color(0.33, 0.27, 0.31),
	"bell": false,
}
const BLACK := {
	"wool": Color(0.25, 0.21, 0.30),
	"face": Color(0.17, 0.13, 0.18),
	"bell": true,
}
const PINK := Color(0.96, 0.6, 0.7)
const EYE_WHITE := Color(1, 1, 1)
const PUPIL := Color(0.08, 0.06, 0.08)
const GOLD := Color(1.0, 0.8, 0.25)


func _init(style: Dictionary = WHITE) -> void:
	name = "Sheep"
	var wool: Color = style["wool"]
	var face: Color = style["face"]

	for leg_name in CreatureModel.LEG_NAMES:
		var side := -1.0 if leg_name.ends_with("L") else 1.0
		var front := -1.0 if leg_name.begins_with("LegF") else 1.0
		var leg := Shapes.pivot(self, leg_name, Vector3(0.17 * side, 0.34, 0.17 * front))
		Shapes.cylinder(leg, 0.055, 0.06, 0.32, face, Vector3(0, -0.17, 0))

	var body_node := Shapes.pivot(self, "Body", Vector3.ZERO)
	Shapes.sphere(body_node, 0.36, wool, Vector3(0, 0.6, 0.02), Vector3(1.0, 0.92, 1.15))
	for puff: Array in [
		[Vector3(-0.25, 0.62, -0.14), 0.22], [Vector3(0.25, 0.62, -0.14), 0.22],
		[Vector3(-0.25, 0.62, 0.2), 0.23], [Vector3(0.25, 0.62, 0.2), 0.23],
		[Vector3(0.0, 0.84, 0.06), 0.24], [Vector3(0.0, 0.8, -0.2), 0.2],
		[Vector3(0.0, 0.76, 0.32), 0.21], [Vector3(-0.2, 0.44, 0.04), 0.2],
		[Vector3(0.2, 0.44, 0.04), 0.2],
	]:
		Shapes.sphere(body_node, puff[1], wool, puff[0])
	var tail_node := Shapes.pivot(body_node, "Tail", Vector3(0, 0.66, 0.46))
	Shapes.sphere(tail_node, 0.1, wool, Vector3(0, 0, 0.03))

	var head_node := Shapes.pivot(self, "Head", Vector3(0, 0.74, -0.34))
	Shapes.sphere(head_node, 0.2, face, Vector3(0, -0.02, -0.14), Vector3(0.92, 1.0, 1.1))
	Shapes.sphere(head_node, 0.12, wool, Vector3(0, 0.16, -0.1))
	for side in [-1.0, 1.0]:
		Shapes.sphere(head_node, 0.06, EYE_WHITE, Vector3(0.085 * side, 0.04, -0.29), Vector3.ONE, 0.012)
		Shapes.sphere(head_node, 0.033, PUPIL, Vector3(0.085 * side, 0.04, -0.34), Vector3.ONE, 0.0)
		Shapes.sphere(head_node, 0.04, PINK, Vector3(0.12 * side, -0.07, -0.27), Vector3(1.0, 0.55, 0.4), 0.0)
		var ear := Shapes.pivot(head_node, "EarL" if side < 0.0 else "EarR", Vector3(0.16 * side, 0.06, -0.1))
		ear.rotation.z = -0.35 * side
		Shapes.sphere(ear, 0.085, face, Vector3(0.08 * side, 0, 0), Vector3(1.6, 0.55, 0.9))
	if style["bell"]:
		Shapes.sphere(head_node, 0.07, GOLD, Vector3(0, -0.2, -0.1))
		Shapes.sphere(head_node, 0.06, PINK, Vector3(-0.07, 0.24, -0.08), Vector3(1.2, 0.8, 0.6))
		Shapes.sphere(head_node, 0.06, PINK, Vector3(0.07, 0.24, -0.08), Vector3(1.2, 0.8, 0.6))
