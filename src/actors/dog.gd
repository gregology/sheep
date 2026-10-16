class_name Dog
extends Node3D
## A sheepdog driven by one player. Sheep keep away from it (a RepelInfluence that
## travels with it), and any face button barks: a short, strong burst that scatters them.

const BARK_BUTTONS: Array[StringName] = [&"south", &"east", &"west", &"north", &"right_shoulder"]

var slot: PlayerSlot
var sim: FlockSim
var tuning: Tuning
## Where barks draw their rings and words.
var effects: Node3D
## The other dogs, so they don't stand inside each other.
var pack: Array[Dog] = []

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var presence: RepelInfluence
var model: CreatureModel
var shadow: BlobShadow

var _bark_cooldown := 0.0


func setup(player: PlayerSlot, flock: FlockSim, start: Vector2, effects_parent: Node3D) -> void:
	slot = player
	sim = flock
	tuning = flock.tuning
	pos = start
	effects = effects_parent
	name = "Dog%d" % slot.dog_index


func _ready() -> void:
	model = Models.make(&"dog", {"breed": slot.breed(), "color": slot.color()})
	model.size = tuning.creature_scale
	add_child(model)
	shadow = BlobShadow.new(1.25 * tuning.creature_scale)
	add_child(shadow)
	add_child(_player_ring())
	presence = RepelInfluence.new(tuning.dog_pressure_radius, tuning.dog_pressure_strength, tuning.dog_fear)
	presence.body_radius = tuning.dog_radius
	presence.position = pos
	sim.add_influence(presence)
	position = Geometry.to_3d(pos)
	rotation.y = PI  # face up the field


func _exit_tree() -> void:
	sim.remove_influence(presence)


func _physics_process(delta: float) -> void:
	vel = vel.move_toward(slot.device.move() * tuning.dog_speed, tuning.dog_accel * delta)
	pos = sim.collide_solid(pos + vel * delta, tuning.dog_radius)
	for other in pack:
		if other != self:
			var offset := pos - other.pos
			var distance := offset.length()
			var reach := tuning.dog_radius * 2.0
			if distance < reach and distance > 0.0001:
				pos += offset / distance * (reach - distance) * 0.5
	presence.position = pos
	_bark_cooldown -= delta
	if _bark_cooldown <= 0.0 and slot.device.any_just_pressed(BARK_BUTTONS):
		bark()


func _process(delta: float) -> void:
	position = Geometry.to_3d(pos)
	if vel.length() > 0.3:
		rotation.y = lerp_angle(rotation.y, Geometry.yaw_for(vel), 1.0 - exp(-delta * 14.0))
	model.gait = clampf(vel.length() / tuning.dog_speed, 0.0, 1.0)


func bark() -> void:
	_bark_cooldown = tuning.bark_cooldown
	var burst := RepelInfluence.new(tuning.bark_radius, tuning.bark_strength, tuning.bark_fear)
	burst.position = pos
	burst.time_left = tuning.bark_duration
	sim.add_influence(burst)
	model.squash(0.8)
	Effects.ring(effects, position, slot.color(), tuning.bark_radius * 0.8)
	Effects.pop_text(effects, position + Vector3(0, 1.5, 0), "WOOF!", slot.color(), 72, 0.7)
	Sfx.play_at(&"bark", position, 0.0, 0.12)
	slot.device.rumble(0.2, 0.5, 0.12)
	Events.dog_barked.emit(slot, position)


func _player_ring() -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.55
	mesh.outer_radius = 0.68
	mesh.rings = 32
	ring.mesh = mesh
	var mat := Toon.glow(Color(slot.color(), 0.85))
	ring.material_override = mat
	ring.scale = Vector3(1.0, 0.15, 1.0) * tuning.creature_scale
	ring.position.y = 0.04
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ring
