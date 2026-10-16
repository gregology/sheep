class_name Tuning
extends Resource
## Every number that shapes how the game feels, in one place.
##
## Defaults live in res://config/tuning.tres. The grown-ups' settings screen
## saves a copy to user://tuning.tres, which wins over the defaults.

@export_group("Round")
@export_range(1, 40) var sheep_count: int = 12
## Seconds into a round before the gate starts gently helping stragglers in.
@export var assist_after: float = 150.0
## Seconds per sheep for a three-star round.
@export var par_seconds_per_sheep: float = 10.0

@export_group("Sheep")
## How big creatures are drawn. Collision radii below should grow with it.
@export var creature_scale: float = 1.25
@export var sheep_radius: float = 0.56
@export var graze_speed: float = 0.9
@export var run_speed: float = 5.5
@export var sheep_accel: float = 9.0
@export var separation_radius: float = 1.55
@export var separation_weight: float = 4.0
@export var cohesion_radius: float = 6.0
@export var cohesion_weight: float = 0.5
## How keen a sheep with nobody nearby is to walk back to the flock (0 = not at all).
@export var lonely_pull: float = 0.9
## Extra cohesion when frightened, so scared sheep bunch up.
@export var cohesion_fear_bonus: float = 1.5
@export var alignment_weight: float = 0.6
## Fear lost per second.
@export var fear_decay: float = 0.45
## Fraction of a neighbour's fear that spreads to a sheep.
@export var contagion: float = 0.7
@export var contagion_radius: float = 2.8
@export var wall_avoid_distance: float = 1.2
@export var wall_avoid_weight: float = 3.0
@export var gate_funnel_radius: float = 4.0
@export var gate_funnel_strength: float = 1.5

@export_group("Dogs")
@export var dog_speed: float = 6.5
@export var dog_accel: float = 28.0
@export var dog_radius: float = 0.6
@export var dog_pressure_radius: float = 5.0
@export var dog_pressure_strength: float = 5.0
@export var dog_fear: float = 0.55
@export var bark_radius: float = 7.0
@export var bark_strength: float = 22.0
@export var bark_fear: float = 1.0
@export var bark_duration: float = 0.3
@export var bark_cooldown: float = 0.9

@export_group("Chaos")
@export var chaos_duration: float = 10.0
## Cool-off after a creature leaves, before it can be summoned again.
@export var chaos_cooldown: float = 20.0
## Seconds without steering before a creature wanders toward the flock by itself.
@export var autopilot_delay: float = 2.0
@export var wolf_speed: float = 6.0
@export var wolf_radius: float = 9.0
@export var wolf_strength: float = 30.0
@export var wolf_fear: float = 1.0
@export var black_sheep_speed: float = 3.6
@export var black_sheep_radius: float = 12.0
@export var black_sheep_strength: float = 10.0
@export var black_sheep_follow_distance: float = 2.0

@export_group("Microphone")
@export var mic_enabled: bool = true
@export var mic_device: String = "Default"
## How far (dB) a sound must jump above what the flock has got used to.
@export var mic_threshold_db: float = 12.0
## Jump (dB) above the threshold that counts as a full-strength scare.
@export var mic_full_scale_db: float = 18.0
## Seconds for the flock to get used to a continuing noise.
@export var mic_habituation_time: float = 1.5
## Seconds for the flock to forget a noise after it stops.
@export var mic_recovery_time: float = 4.0
@export var mic_refractory: float = 0.5
## How much each scare tires the flock out (repeated shouts work less).
@export var mic_alertness_cost: float = 0.35
## Alertness regained per second.
@export var mic_alertness_recovery: float = 0.12
@export var mic_highpass_hz: float = 150.0
@export var mic_startle_strength: float = 7.0
## Quietest the room gets, as the mic hears it. Set by calibration.
@export var mic_noise_floor_db: float = -55.0
## How loud the game's own sound is at the mic relative to what it plays. Set by calibration.
@export var mic_self_coupling_db: float = -12.0
## Seconds to keep ignoring the game's own sound after it plays (room echo and latency).
@export var mic_self_hold: float = 0.35

@export_group("Audio")
@export_range(0.0, 1.0) var master_volume: float = 0.8
@export_range(0.0, 1.0) var music_volume: float = 0.5
@export_range(0.0, 1.0) var sfx_volume: float = 0.9
