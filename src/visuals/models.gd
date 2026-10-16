class_name Models
## The one place creature models come from.
##
## If res://assets/models/<kind>.glb exists (e.g. exported by the Blender scripts),
## it is used; its parts must follow CreatureModel's part names so the procedural
## animation keeps working. Otherwise the code-built stand-in is used.


## kind: &"sheep", &"black_sheep", &"dog", &"wolf". Dogs take {"breed": StringName, "color": Color}.
static func make(kind: StringName, options := {}) -> CreatureModel:
	var variant := kind
	if kind == &"dog":
		variant = StringName("dog_%s" % options.get("breed", &"collie"))
	var path := "res://assets/models/%s.glb" % variant
	if ResourceLoader.exists(path):
		var model := CreatureModel.new()
		model.name = String(variant).capitalize()
		model.add_child((load(path) as PackedScene).instantiate())
		return model
	match kind:
		&"sheep":
			return SheepModel.new(SheepModel.WHITE)
		&"black_sheep":
			return SheepModel.new(SheepModel.BLACK)
		&"dog":
			return CanineModel.new(options.get("breed", &"collie"), options.get("color", Color.WHITE))
		&"wolf":
			return CanineModel.new(&"wolf")
	push_error("Unknown creature model '%s'" % kind)
	return CreatureModel.new()
