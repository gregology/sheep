class_name TestCase
extends RefCounted
## Base for tests. Methods named test_* are run by tests/run_tests.gd,
## each on a fresh instance after before_each().

var failures: Array[String] = []


func before_each() -> void:
	pass


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_near(actual: float, expected: float, tolerance: float, message := "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s (expected %.3f ± %.3f, got %.3f)" % [message, expected, tolerance, actual])
