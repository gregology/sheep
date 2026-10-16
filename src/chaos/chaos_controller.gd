class_name ChaosController
extends Node
## The chaos player's powers. Summons a creature when its button is pressed and
## it's charged, steers whichever creature is out, and runs the cool-downs.
## One creature at a time, so a single D-pad always knows what it's steering.

var slot: PlayerSlot
var roster: ChaosRoster
var sim: FlockSim
var tuning: Tuning
## Where creatures and their effects are added.
var stage: Node3D
## ability id -> Cooldown
var cooldowns := {}
var active: ChaosCreature
var active_ability: ChaosAbility


func setup(player: PlayerSlot, abilities: ChaosRoster, flock: FlockSim, parent: Node3D) -> void:
	slot = player
	roster = abilities
	sim = flock
	tuning = flock.tuning
	stage = parent
	name = "ChaosController"
	for ability in roster.abilities:
		var cooldown := Cooldown.new()
		cooldown.became_ready.connect(_on_ready_again.bind(ability))
		cooldowns[ability.id] = cooldown


func cooldown_of(ability: ChaosAbility) -> Cooldown:
	return cooldowns[ability.id]


func is_busy() -> bool:
	return active != null


func _physics_process(delta: float) -> void:
	for cooldown: Cooldown in cooldowns.values():
		cooldown.tick(delta)
	if active:
		active.steer(slot.device.move())
		return
	for ability in roster.abilities:
		if slot.device.any_just_pressed(ability.buttons):
			if cooldown_of(ability).is_ready():
				summon(ability)
			else:
				Sfx.play(&"tick", -6.0)
			return


func summon(ability: ChaosAbility) -> void:
	var creature := ability.creature.instantiate() as ChaosCreature
	var duration := ability.duration_for(tuning)
	creature.setup(sim, duration, stage)
	creature.finished.connect(_on_finished.bind(ability))
	stage.add_child(creature)
	active = creature
	active_ability = ability
	cooldown_of(ability).activate(duration)
	slot.device.rumble(0.4, 0.6, 0.25)
	Events.chaos_summoned.emit(ability)


## Sends any creature home (the round is over).
func dismiss() -> void:
	if active:
		active.leave_now()


func _on_finished(ability: ChaosAbility) -> void:
	active = null
	active_ability = null
	cooldown_of(ability).cool(ability.cooldown_for(tuning))


func _on_ready_again(ability: ChaosAbility) -> void:
	Sfx.play(&"ding", -4.0, 0.0)
	slot.device.rumble(0.3, 0.0, 0.15)
	Events.chaos_ability_ready.emit(ability)
