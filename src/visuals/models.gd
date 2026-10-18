class_name Models
## The one place creature models come from.
##
## Uses res://assets/models/<kind>.glb (made by tools/blender/build_models.sh) when it
## exists, painted by ModelPaint; otherwise builds the code stand-in. Models must
## follow CreatureModel's part names so the procedural animation works on both.
## Pass --code-models on the command line to force the stand-ins.


## kind: &"sheep", &"black_sheep", &"dog", &"wolf". Dogs take {"breed": StringName, "color": Color}.
static func make(kind: StringName, options := {}) -> CreatureModel:
	var breed: StringName = options.get("breed", &"collie")
	var color: Color = options.get("color", Color.WHITE)
	var variant := StringName("dog_%s" % breed) if kind == &"dog" else kind
	var path := "res://assets/models/%s.glb" % variant
	if ResourceLoader.exists(path) and not LaunchArgs.has("--code-models"):
		var model := CreatureModel.new()
		model.name = String(variant).to_pascal_case()
		if kind == &"dog" or kind == &"wolf":
			model.stride = 1.0
		var body := (load(path) as PackedScene).instantiate()
		model.add_child(body)
		ModelPaint.apply(body, palette(kind, breed, color))
		return model
	match kind:
		&"sheep":
			return SheepModel.new(SheepModel.WHITE)
		&"black_sheep":
			return SheepModel.new(SheepModel.BLACK)
		&"dog":
			return CanineModel.new(breed, color)
		&"wolf":
			return CanineModel.new(&"wolf")
	push_error("Unknown creature model '%s'" % kind)
	return CreatureModel.new()


## Colour for every material slot a creature's model uses.
static func palette(kind: StringName, breed := &"collie", bandana := Color.WHITE) -> Dictionary:
	match kind:
		&"sheep":
			return SheepModel.palette(SheepModel.WHITE)
		&"black_sheep":
			return SheepModel.palette(SheepModel.BLACK)
		&"dog":
			return CanineModel.palette(breed, bandana)
		&"wolf":
			return CanineModel.palette(&"wolf")
	return {}
