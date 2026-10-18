class_name LaunchArgs
## Options for development and remote testing: --demo=<scenario>, --diagnose,
## --shots=<s,s,...>, --quit-at=<s>, --code-models, --quit-when-won.
##
## They come from the command line (after "--"). Steam doesn't easily pass arguments
## to a non-Steam shortcut, so a one-shot file, user://next_launch_args.txt, is also
## read at start-up and then deleted, so it only ever affects one launch.

const ONE_SHOT := "user://next_launch_args.txt"

static var _args: PackedStringArray
static var _loaded := false


static func all() -> PackedStringArray:
	if not _loaded:
		_loaded = true
		_args = OS.get_cmdline_user_args()
		if FileAccess.file_exists(ONE_SHOT):
			var text := FileAccess.get_file_as_string(ONE_SHOT)
			# Delete before using it, so a crash can't make it stick.
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ONE_SHOT))
			for word in text.replace("\n", " ").split(" ", false):
				_args.append(word)
	return _args


static func has(flag: String) -> bool:
	return flag in all()


## The value of "--name=value", or `fallback` when absent.
static func value(name: String, fallback := "") -> String:
	for arg in all():
		if arg.begins_with(name + "="):
			return arg.get_slice("=", 1)
	return fallback
