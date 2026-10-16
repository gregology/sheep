class_name CanineModel
extends CreatureModel
## Stand-in dogs (one look per breed, with a bandana in the player's colour) and the wolf.

const STYLES := {
	&"collie": {
		"coat": Color(0.18, 0.17, 0.21), "light": Color(0.98, 0.96, 0.93),
		"ears": "tipped", "tail": "brush", "eyes": Color(0.25, 0.15, 0.08), "legs": 0.3,
	},
	&"corgi": {
		"coat": Color(0.93, 0.56, 0.24), "light": Color(0.99, 0.95, 0.88),
		"ears": "tall", "tail": "stub", "eyes": Color(0.2, 0.12, 0.06), "legs": 0.2,
	},
	&"golden": {
		"coat": Color(0.93, 0.71, 0.38), "light": Color(0.98, 0.86, 0.6),
		"ears": "floppy", "tail": "brush", "eyes": Color(0.25, 0.15, 0.08), "legs": 0.3,
	},
	&"husky": {
		"coat": Color(0.55, 0.59, 0.67), "light": Color(0.97, 0.97, 0.99),
		"ears": "tall", "tail": "curl", "eyes": Color(0.3, 0.6, 0.95), "legs": 0.3,
	},
	&"wolf": {
		"coat": Color(0.45, 0.5, 0.6), "light": Color(0.85, 0.88, 0.93),
		"ears": "tall", "tail": "bushy", "eyes": Color(1.0, 0.8, 0.15), "legs": 0.36,
		"brows": true, "scale": 1.3,
	},
}
const NOSE := Color(0.1, 0.08, 0.1)
const EYE_WHITE := Color(1, 1, 1)
const PUPIL := Color(0.06, 0.05, 0.07)
const TONGUE := Color(0.95, 0.45, 0.55)


func _init(breed: StringName, bandana := Color(0, 0, 0, 0)) -> void:
	name = String(breed).capitalize()
	var style: Dictionary = STYLES.get(breed, STYLES[&"collie"])
	var coat: Color = style["coat"]
	var light: Color = style["light"]
	var leg_height: float = style["legs"]
	var hip := leg_height + 0.02
	stride = 1.0

	for leg_name in CreatureModel.LEG_NAMES:
		var side := -1.0 if leg_name.ends_with("L") else 1.0
		var front := -1.0 if leg_name.begins_with("LegF") else 1.0
		var leg := Shapes.pivot(self, leg_name, Vector3(0.13 * side, hip, 0.24 * front))
		Shapes.cylinder(leg, 0.06, 0.065, leg_height, coat, Vector3(0, -leg_height * 0.5, 0))
		Shapes.sphere(leg, 0.07, light, Vector3(0, -leg_height + 0.02, -0.03), Vector3(1.0, 0.7, 1.2))

	var body_node := Shapes.pivot(self, "Body", Vector3.ZERO)
	var body_y := hip + 0.13
	Shapes.capsule(body_node, 0.21, 0.78, coat, Vector3(0, body_y, 0.02), Vector3(90, 0, 0))
	Shapes.sphere(body_node, 0.17, light, Vector3(0, body_y - 0.03, -0.25), Vector3(0.95, 1.0, 0.8))

	var tail_node := Shapes.pivot(body_node, "Tail", Vector3(0, body_y + 0.08, 0.38))
	match style["tail"]:
		"stub":
			Shapes.sphere(tail_node, 0.08, coat, Vector3(0, 0.02, 0.04))
		"curl":
			Shapes.capsule(tail_node, 0.06, 0.3, coat, Vector3(0, 0.14, 0.06), Vector3(-25, 0, 0))
			Shapes.sphere(tail_node, 0.075, light, Vector3(0, 0.27, 0.0))
		"bushy":
			Shapes.capsule(tail_node, 0.1, 0.48, coat, Vector3(0, 0.1, 0.2), Vector3(60, 0, 0))
			Shapes.sphere(tail_node, 0.1, light, Vector3(0, 0.2, 0.4))
		_:
			Shapes.capsule(tail_node, 0.065, 0.38, coat, Vector3(0, 0.08, 0.14), Vector3(55, 0, 0))
			Shapes.sphere(tail_node, 0.07, light, Vector3(0, 0.16, 0.29))

	if bandana.a > 0.0:
		Shapes.cylinder(body_node, 0.13, 0.17, 0.09, bandana, Vector3(0, body_y + 0.14, -0.32), Vector3(-25, 0, 0))
		Shapes.cylinder(body_node, 0.0, 0.11, 0.16, bandana, Vector3(0, body_y + 0.0, -0.42),
			Vector3(180, 0, 0), Vector3(1.0, 1.0, 0.4))

	var head_node := Shapes.pivot(self, "Head", Vector3(0, body_y + 0.25, -0.38))
	Shapes.sphere(head_node, 0.2, coat, Vector3(0, 0.02, -0.06))
	var snout := 1.25 if style.has("brows") else 1.0
	Shapes.sphere(head_node, 0.1, light, Vector3(0, -0.04, -0.21), Vector3(1.0, 0.8, 1.25 * snout))
	Shapes.sphere(head_node, 0.045, NOSE, Vector3(0, -0.0, -0.21 - 0.12 * snout), Vector3.ONE, 0.015)
	Shapes.sphere(head_node, 0.04, TONGUE, Vector3(0, -0.11, -0.25), Vector3(1.0, 0.5, 1.2), 0.0)
	var eye_color: Color = style["eyes"]
	for side in [-1.0, 1.0]:
		Shapes.sphere(head_node, 0.052, EYE_WHITE, Vector3(0.08 * side, 0.07, -0.19), Vector3.ONE, 0.012)
		Shapes.sphere(head_node, 0.032, eye_color, Vector3(0.08 * side, 0.07, -0.232), Vector3.ONE, 0.0)
		Shapes.sphere(head_node, 0.016, PUPIL, Vector3(0.08 * side, 0.07, -0.258), Vector3.ONE, 0.0)
		if style.has("brows"):
			Shapes.capsule(head_node, 0.018, 0.11, NOSE, Vector3(0.08 * side, 0.135, -0.2),
				Vector3(0, 0, 90 + 25 * side), Vector3.ONE, 0.0)
		var ear := Shapes.pivot(head_node, "EarL" if side < 0.0 else "EarR", Vector3(0.12 * side, 0.15, -0.02))
		match style["ears"]:
			"tall":
				ear.rotation.z = -0.25 * side
				Shapes.cylinder(ear, 0.0, 0.075, 0.2, coat, Vector3(0, 0.09, 0), Vector3.ZERO, Vector3(1.0, 1.0, 0.55))
			"tipped":
				ear.rotation.z = -0.3 * side
				Shapes.cylinder(ear, 0.02, 0.07, 0.15, coat, Vector3(0, 0.06, 0), Vector3(-30, 0, 0), Vector3(1.0, 1.0, 0.55))
				Shapes.sphere(ear, 0.035, light, Vector3(0, 0.13, -0.05))
			_:
				ear.rotation.z = 0.2 * side
				Shapes.sphere(ear, 0.085, coat.darkened(0.12), Vector3(0.05 * side, -0.08, 0), Vector3(0.55, 1.35, 0.9))

	var body_scale: float = style.get("scale", 1.0)
	for child in get_children():
		(child as Node3D).position *= body_scale
		(child as Node3D).scale *= body_scale
