extends TestCase
## The microphone scare rules: loud and sudden spooks the flock, a continuing
## noise stops working, repeated shouts get weaker, and the game's own sound
## never counts.

const BLOCK := 0.01
const QUIET := -60.0

var tuning: Tuning
var detector: StartleDetector


func before_each() -> void:
	tuning = Tuning.new()
	tuning.mic_noise_floor_db = QUIET
	detector = StartleDetector.new(tuning)


## Feeds a steady level for `seconds`; returns the strengths of any startles.
func _feed(db: float, seconds: float, self_db := -90.0) -> Array[float]:
	var startles: Array[float] = []
	for i in int(round(seconds / BLOCK)):
		var strength := detector.process(db, BLOCK, self_db)
		if strength > 0.0:
			startles.append(strength)
	return startles


func test_quiet_room_never_startles() -> void:
	check(_feed(QUIET, 5.0).is_empty(), "a quiet room caused a startle")


func test_small_noises_do_not_startle() -> void:
	_feed(QUIET, 2.0)
	check(_feed(QUIET + 8.0, 1.0).is_empty(), "a noise 8 dB over the quiet room caused a startle")


func test_sudden_shout_startles_once() -> void:
	_feed(QUIET, 2.0)
	var startles := _feed(-20.0, 0.4)
	check(startles.size() == 1, "expected one startle for one shout, got %d" % startles.size())
	check(not startles.is_empty() and startles[0] > 0.8, "a big shout should be a strong scare")


func test_continuing_noise_stops_scaring() -> void:
	_feed(QUIET, 2.0)
	var first := _feed(-25.0, 6.0)
	check(first.size() == 1, "the noise starting should scare once (got %d)" % first.size())
	check(_feed(-25.0, 4.0).is_empty(), "a continuing noise kept scaring the flock")


func test_after_getting_used_to_noise_only_a_bigger_jump_scares() -> void:
	_feed(QUIET, 2.0)
	_feed(-25.0, 6.0)
	check(_feed(-20.0, 0.5).is_empty(), "a 5 dB rise over a steady noise shouldn't scare")
	check(_feed(-5.0, 0.3).size() == 1, "a big jump over a steady noise should scare")


func test_repeated_shouts_get_weaker() -> void:
	_feed(QUIET, 2.0)
	var strengths: Array[float] = []
	for i in 4:
		strengths.append_array(_feed(-20.0, 0.3))
		_feed(QUIET, 1.2)
	check(strengths.size() == 4, "expected four startles, got %d" % strengths.size())
	for i in range(1, strengths.size()):
		check(strengths[i] < strengths[i - 1], "shout %d (%.2f) wasn't weaker than shout %d (%.2f)" % [
			i + 1, strengths[i], i, strengths[i - 1]])


func test_flock_recovers_after_a_rest() -> void:
	_feed(QUIET, 2.0)
	for i in 4:
		_feed(-20.0, 0.3)
		_feed(QUIET, 0.8)
	check(detector.alertness < 0.6, "shouting a lot should tire the flock")
	_feed(QUIET, 10.0)
	check_near(detector.alertness, 1.0, 0.01, "the flock should be fully jumpy again after a rest")


func test_game_sound_does_not_startle() -> void:
	_feed(QUIET, 2.0)
	check(_feed(-25.0, 0.5, -22.0).is_empty(), "the game's own sound scared the flock")


func test_shouting_over_game_sound_still_works() -> void:
	_feed(QUIET, 2.0)
	check(_feed(-5.0, 0.3, -30.0).size() == 1, "a shout well over the game's sound should scare")


func test_forced_startle_uses_alertness() -> void:
	var first := detector.force(1.0)
	var second := detector.force(1.0)
	check_near(first, 1.0, 0.001, "first forced startle")
	check(second < first, "a second forced startle straight after should be weaker")
