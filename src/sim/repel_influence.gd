class_name RepelInfluence
extends FlockInfluence
## Pushes sheep away and frightens them, more strongly the closer they are.
## Dogs, barks and the wolf are all RepelInfluences with different numbers.

var radius := 5.0
## Desired flee speed (m/s) right next to the source.
var strength := 6.0
## Fear caused right next to the source (0..1).
var fear := 0.5


func _init(influence_radius := 5.0, influence_strength := 6.0, influence_fear := 0.5) -> void:
	radius = influence_radius
	strength = influence_strength
	fear = influence_fear


func affect(sheep: SheepState, sim: FlockSim) -> void:
	var offset := sheep.pos - position
	var distance := offset.length()
	if distance >= radius:
		return
	var t := 1.0 - distance / radius
	var away := offset / distance if distance > 0.001 else Vector2.RIGHT.rotated(sim.rng.randf() * TAU)
	sheep.steer += away * strength * t
	sheep.threat = maxf(sheep.threat, fear * minf(1.0, t * 1.6))
