class_name AttractInfluence
extends FlockInfluence
## Draws sheep toward a leader and calms them: the black sheep.

var radius := 12.0
## Desired follow speed (m/s) at the edge of the follow distance.
var strength := 10.0
## Followers stop about this far from the leader.
var follow_distance := 2.0
## How much followers' fear melts away.
var calm := 0.8


func _init(influence_radius := 12.0, influence_strength := 10.0, distance := 2.0) -> void:
	radius = influence_radius
	strength = influence_strength
	follow_distance = distance


func affect(sheep: SheepState, _sim: FlockSim) -> void:
	var offset := position - sheep.pos
	var distance := offset.length()
	if distance >= radius or distance < 0.001:
		return
	var t := 1.0 - distance / radius
	# Positive pulls in; inside the follow distance it gently pushes back out.
	var pull := clampf((distance - follow_distance) / follow_distance, -1.0, 1.0)
	sheep.steer += offset / distance * strength * pull * (0.35 + 0.65 * t)
	sheep.urge = maxf(sheep.urge, 0.4 + 0.6 * t)
	sheep.calming = maxf(sheep.calming, calm * t)
