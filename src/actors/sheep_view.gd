class_name SheepView
extends Node3D
## Draws one sheep from its SheepState; the simulation does all the thinking.

const HOP_HEIGHT := 0.9

var state: SheepState
var tuning: Tuning
var model: CreatureModel
var shadow: BlobShadow
var _was_airborne := false


func _init(sheep_state: SheepState, sheep_tuning: Tuning) -> void:
	state = sheep_state
	tuning = sheep_tuning
	name = "Sheep%d" % state.id


func _ready() -> void:
	model = Models.make(&"sheep")
	model.size = tuning.creature_scale
	add_child(model)
	shadow = BlobShadow.new(1.2 * tuning.creature_scale)
	add_child(shadow)
	position = Geometry.to_3d(state.pos)
	rotation.y = state.heading


func _process(delta: float) -> void:
	position = Geometry.to_3d(state.pos)
	rotation.y = lerp_angle(rotation.y, state.heading, 1.0 - exp(-delta * 10.0))
	var height := state.hop_height() * HOP_HEIGHT * clampf(state.hop_length / 0.5, 0.4, 1.2)
	model.position.y = height
	shadow.set_height(height)
	if _was_airborne and height <= 0.0:
		model.squash(0.6)
	_was_airborne = height > 0.0
	var speed := state.vel.length()
	model.gait = clampf(speed / tuning.run_speed * 1.4, 0.0, 1.0)
	model.fear = state.fear
	model.grazing = speed < 0.1 and state.fear < 0.1 and not state.wandering
