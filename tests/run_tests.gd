extends SceneTree
## Runs every tests/test_*.gd file. Exit code 1 if anything failed.
##   godot --headless --path . -s res://tests/run_tests.gd

const TEST_DIR := "res://tests"


func _initialize() -> void:
	var passed := 0
	var failed := 0
	var files := Array(DirAccess.get_files_at(TEST_DIR))
	files.sort()
	for file: String in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: GDScript = load("%s/%s" % [TEST_DIR, file])
		for method in script.get_script_method_list():
			var test_name: String = method["name"]
			if not test_name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.before_each()
			test.call(test_name)
			if test.failures.is_empty():
				passed += 1
				print("  ok    %s :: %s" % [file.get_basename(), test_name])
			else:
				failed += 1
				for failure in test.failures:
					print("  FAIL  %s :: %s — %s" % [file.get_basename(), test_name, failure])
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
