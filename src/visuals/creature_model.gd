class_name CreatureModel
extends Node3D
## A creature's body plus its procedural animation (walk cycle, grazing, fright, squash).
##
## Models are built from named parts, so the same animation drives the code-built
## stand-ins and Blender-made models alike. Part names (all optional):
##   Body, Head, Tail, EarL, EarR, LegFL, LegFR, LegBL, LegBR
## Legs pivot at the hip, the head at the neck. Models face -Z.

const LEG_NAMES: Array[String] = ["LegFL", "LegFR", "LegBL", "LegBR"]

## 0 = standing still, 1 = running flat out.
var gait := 0.0
## 0..1: scared creatures hold their heads and ears up.
var fear := 0.0
var grazing := false
## How far legs swing at full gait (radians).
var stride := 0.9
## Overall size (see Tuning.creature_scale).
var size := 1.0

var body: Node3D
var head: Node3D
var tail: Node3D
var legs: Array[Node3D] = []
var ears: Array[Node3D] = []

var _phase := 0.0
var _time := 0.0
var _squash := 0.0
var _graze := 0.0
var _body_rest_y := 0.0
var _ear_rest: Array[Vector3] = []


func _ready() -> void:
	_time = randf() * 10.0
	_find_parts()
	_disable_shadows(self)


## A quick squash, e.g. on landing or barking.
func squash(amount := 1.0) -> void:
	_squash = maxf(_squash, amount)


func _process(delta: float) -> void:
	_time += delta
	if gait > 0.03:
		_phase += delta * lerpf(6.0, 16.0, gait)
	var swing := sin(_phase) * stride * minf(gait * 1.6, 1.0)
	for i in legs.size():
		var diagonal := i == 1 or i == 2  # front-right moves with back-left
		legs[i].rotation.x = -swing if diagonal else swing
	if body:
		body.position.y = _body_rest_y + absf(sin(_phase)) * 0.07 * gait + sin(_time * 2.4) * 0.01
		body.rotation.z = sin(_phase) * 0.06 * gait
	if head:
		_graze = move_toward(_graze, 1.0 if grazing else 0.0, delta * 2.0)
		var nibble := sin(_time * 9.0) * 0.07 * _graze
		head.rotation.x = -0.75 * _graze + nibble + fear * 0.25 + sin(_time * 1.7) * 0.03
	for i in ears.size():
		var flop := sin(_time * 3.0 + i) * 0.08 + gait * 0.25
		ears[i].rotation = _ear_rest[i] + Vector3(0.0, 0.0, (flop - fear * 0.35) * (1.0 if i == 0 else -1.0))
	if tail:
		tail.rotation.y = sin(_time * lerpf(5.0, 16.0, gait)) * 0.45
	_squash = move_toward(_squash, 0.0, delta * 5.0)
	var s := sin(_squash * PI * 0.5)
	scale = Vector3(1.0 + 0.2 * s, 1.0 - 0.25 * s, 1.0 + 0.2 * s) * size


func _find_parts() -> void:
	body = find_child("Body", true, false) as Node3D
	head = find_child("Head", true, false) as Node3D
	tail = find_child("Tail", true, false) as Node3D
	legs.clear()
	for leg_name in LEG_NAMES:
		var leg := find_child(leg_name, true, false) as Node3D
		if leg:
			legs.append(leg)
	ears.clear()
	_ear_rest.clear()
	for ear_name in ["EarL", "EarR"]:
		var ear := find_child(ear_name, true, false) as Node3D
		if ear:
			ears.append(ear)
			_ear_rest.append(ear.rotation)
	if body:
		_body_rest_y = body.position.y


static func _disable_shadows(node: Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D:
			(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_disable_shadows(child)
