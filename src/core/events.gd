extends Node
## Game-wide signals. Features talk through these so new ones can plug in
## without the existing code needing to know about them.

## Something spooked the whole flock. `source` is e.g. &"mic".
signal flock_startled(intensity: float, source: StringName)
## The chaos player caused something worth a star.
signal chaos_star_earned(reason: StringName)
signal chaos_summoned(ability: ChaosAbility)
signal chaos_ability_ready(ability: ChaosAbility)
signal dog_barked(slot: PlayerSlot, at: Vector3)
signal sheep_penned(penned: int, total: int)
signal round_started
signal round_won(stats: RoundStats)
