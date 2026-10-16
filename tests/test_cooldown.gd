extends TestCase
## Chaos abilities: ready -> out on the field -> cooling off -> ready.

var cooldown: Cooldown
var ready_signals := 0


func before_each() -> void:
	cooldown = Cooldown.new()
	cooldown.became_ready.connect(func() -> void: ready_signals += 1)


func test_starts_ready() -> void:
	check(cooldown.is_ready(), "a new ability should be ready")


func test_active_phase_waits_for_the_creature() -> void:
	cooldown.activate(10.0)
	cooldown.tick(15.0)
	check(cooldown.state == Cooldown.State.ACTIVE, "ACTIVE should last until the creature leaves")
	check_near(cooldown.remaining(), 0.0, 0.001, "the timer ring should have run down")


func test_cooling_counts_down_to_ready() -> void:
	cooldown.activate(10.0)
	cooldown.cool(20.0)
	check_near(cooldown.remaining(), 1.0, 0.001, "cooling starts full")
	cooldown.tick(10.0)
	check_near(cooldown.remaining(), 0.5, 0.001, "half way through cooling")
	check(not cooldown.is_ready(), "not ready half way through")
	cooldown.tick(10.0)
	check(cooldown.is_ready(), "ready after the full cool-off")
	check(ready_signals == 1, "became_ready should fire exactly once (fired %d)" % ready_signals)


func test_zero_cooldown_is_instantly_ready() -> void:
	cooldown.activate(5.0)
	cooldown.cool(0.0)
	check(cooldown.is_ready(), "a zero cool-off should be ready straight away")
