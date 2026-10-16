class_name StartleDetector
extends RefCounted
## Turns a stream of loudness readings (dB, one per ~10 ms block) into startles.
##
## A startle is a sudden jump above what the flock is used to:
##   - `baseline_db` follows the room's loudness slowly, so a continuing noise
##     stops being scary (habituation) and the flock calms back down after it stops;
##   - `alertness` drops after each startle and recovers over time, so repeated
##     shouts have less and less effect;
##   - `self_db` is the game's own sound as heard at the mic, which never counts.

var tuning: Tuning
## Fast-moving loudness.
var level_db := -90.0
## What the flock has got used to.
var baseline_db := -90.0
## 1 = jumpy, 0 = tired of being shouted at.
var alertness := 1.0
## Re-armed once the noise drops back down, so one long shout is one startle.
var armed := true

var _refractory := 0.0


func _init(detector_tuning: Tuning) -> void:
	tuning = detector_tuning
	baseline_db = tuning.mic_noise_floor_db
	level_db = tuning.mic_noise_floor_db


## Feeds one block. Returns the startle strength 0..1, or 0 when nothing happened.
func process(block_db: float, dt: float, self_db := -90.0) -> float:
	var time_constant := 0.005 if block_db > level_db else 0.08
	level_db = lerpf(level_db, block_db, 1.0 - exp(-dt / time_constant))

	var reference := maxf(maxf(baseline_db, tuning.mic_noise_floor_db), self_db)
	var excess := level_db - reference - tuning.mic_threshold_db
	var result := 0.0
	_refractory = maxf(0.0, _refractory - dt)
	if armed and _refractory <= 0.0 and excess > 0.0:
		result = _fire(clampf(0.35 + excess / tuning.mic_full_scale_db, 0.0, 1.0))
	elif not armed and excess < -tuning.mic_threshold_db * 0.5:
		armed = true

	var follow := tuning.mic_habituation_time if level_db > baseline_db else tuning.mic_recovery_time
	baseline_db = lerpf(baseline_db, level_db, 1.0 - exp(-dt / follow))
	baseline_db = maxf(baseline_db, tuning.mic_noise_floor_db)
	alertness = minf(1.0, alertness + tuning.mic_alertness_recovery * dt)
	return result


## A startle that didn't come from the microphone (keyboard shortcut, tests).
func force(strength: float) -> float:
	return _fire(clampf(strength, 0.0, 1.0))


## How loud the room is right now, 0..1, for meters.
func level01() -> float:
	return clampf((level_db - tuning.mic_noise_floor_db) / 45.0, 0.0, 1.0)


func _fire(strength: float) -> float:
	var result := strength * alertness
	alertness = maxf(0.0, alertness - tuning.mic_alertness_cost * strength)
	armed = false
	_refractory = tuning.mic_refractory
	return result
