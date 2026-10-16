class_name ModelPaint
## Gives an imported model the game's toon look. Each material name in a model
## (wool, coat, bandana, eye...) is a colour slot; the colour comes from a palette,
## so one model can wear any breed's colours or any player's bandana.

## Tiny details look better without an outline, or with a thin one.
const NO_OUTLINE: Array[String] = ["pupil", "shine", "blush", "ear_inner", "tongue", "iris"]
const THIN_OUTLINE: Array[String] = ["eye", "nose", "brow", "bell", "bow", "collar"]
const THIN := 0.012


static func apply(root: Node, palette: Dictionary) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var mesh := mesh_instance.mesh
		for i in mesh.get_surface_count():
			var source := mesh.surface_get_material(i)
			var slot := source.resource_name.to_lower() if source else ""
			var fallback := (source as BaseMaterial3D).albedo_color if source is BaseMaterial3D else Color.WHITE
			var color: Color = palette.get(slot, fallback)
			mesh_instance.set_surface_override_material(i, Toon.material(color, outline_for(slot)))


static func outline_for(slot: String) -> float:
	if slot in NO_OUTLINE:
		return 0.0
	if slot in THIN_OUTLINE:
		return THIN
	return Toon.DEFAULT_OUTLINE
