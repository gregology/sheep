class_name Artwork
extends Node
## Renders the Steam library artwork from the real game scene (--demo=artwork):
## cover, wide capsule, hero banner, logo and icon, saved as PNGs to --out=<dir>
## (default user://artwork). tools/make_artwork.sh copies them into dist/steam/.

const TITLE := "Sheep!"
## name, size, camera size (metres of ground shown vertically), centre, title size (0 = none)
const SHOTS := [
	["cover", Vector2i(600, 900), 11.5, Vector3(0.3, 0, -1.6), 150],
	["wide", Vector2i(920, 430), 7.4, Vector3(0.3, 0, -1.4), 110],
	["hero", Vector2i(1920, 620), 6.0, Vector3(0, 0, 0.6), 0],
]

var game: Game
var out_dir := "user://artwork"


func _init(target: Game) -> void:
	game = target
	name = "Artwork"
	out_dir = LaunchArgs.value("--out", out_dir)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	for view in game._sheep_views:
		view.visible = false
	_stage()
	await get_tree().create_timer(0.6).timeout
	for shot in SHOTS:
		await _render_scene(shot[0], shot[1], shot[2], shot[3], shot[4])
	await _render_logo()
	await _render_icon()
	print("ARTWORK_DONE ", ProjectSettings.globalize_path(out_dir))
	get_tree().quit()


## A little scene in the middle of the meadow: the flock, the dogs and the chaos crew.
func _stage() -> void:
	var stage := Node3D.new()
	stage.name = "ArtworkStage"
	game.add_child(stage)
	var scale := Settings.tuning.creature_scale
	var sheep_spots: Array[Vector3] = [
		Vector3(-0.2, 0, 0.0), Vector3(1.1, 0, -0.5), Vector3(0.6, 0, 0.9), Vector3(-1.4, 0, 0.6),
		Vector3(1.9, 0, 0.6), Vector3(-0.6, 0, -1.2), Vector3(0.9, 0, -1.8),
	]
	for i in sheep_spots.size():
		_place(stage, Models.make(&"sheep"), sheep_spots[i], PI + 0.5 - i * 0.37, scale)
	_place(stage, Models.make(&"black_sheep"), Vector3(-1.9, 0, -0.7), PI + 0.9, scale)
	_place(stage, Models.make(&"dog", {"breed": &"collie", "color": PlayerSlot.DOG_COLORS[0]}), Vector3(-2.9, 0, 1.9), PI - 0.7, scale)
	_place(stage, Models.make(&"dog", {"breed": &"corgi", "color": PlayerSlot.DOG_COLORS[1]}), Vector3(3.1, 0, 1.8), PI + 0.8, scale)
	_place(stage, Models.make(&"wolf"), Vector3(3.6, 0, -1.4), PI + 1.1, scale)


func _place(stage: Node3D, model: CreatureModel, at: Vector3, yaw: float, scale: float) -> void:
	model.size = scale
	model.position = at
	model.rotation.y = yaw
	stage.add_child(model)
	var shadow := BlobShadow.new(1.25 * scale)
	shadow.position = at + Vector3(0, 0.03, 0)
	stage.add_child(shadow)


func _render_scene(file: String, pixels: Vector2i, camera_size: float, center: Vector3, title_size: int) -> void:
	var viewport := _viewport(pixels)
	viewport.world_3d = get_viewport().find_world_3d()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = camera_size
	camera.rotation_degrees.x = -Game.PITCH_DEGREES
	var pitch := deg_to_rad(Game.PITCH_DEGREES)
	camera.position = center + Vector3(0, sin(pitch), cos(pitch)) * 40.0
	viewport.add_child(camera)
	if title_size > 0:
		var title := UiKit.label(TITLE, title_size, UiKit.CREAM, title_size / 4)
		title.position = Vector2(0, pixels.y * 0.03)
		title.size = Vector2(pixels.x, title_size * 1.4)
		viewport.add_child(title)
	camera.make_current()
	await _save(viewport, file)


func _render_logo() -> void:
	var viewport := _viewport(Vector2i(1280, 480), true)
	viewport.disable_3d = true
	var title := UiKit.label(TITLE, 300, UiKit.CREAM, 70)
	title.position = Vector2.ZERO
	title.size = Vector2(1280, 480)
	viewport.add_child(title)
	await _save(viewport, "logo")


func _render_icon() -> void:
	var portrait := Portrait.new(&"sheep", {}, 256)
	var viewport := _viewport(Vector2i(256, 256), true)
	viewport.disable_3d = true
	var badge := Panel.new()
	badge.add_theme_stylebox_override("panel", UiKit.panel(Color(0.47, 0.8, 0.36), 56, 10))
	badge.position = Vector2(8, 8)
	badge.size = Vector2(240, 240)
	viewport.add_child(badge)
	add_child(portrait)
	var face := TextureRect.new()
	face.texture = portrait.get_texture()
	face.position = Vector2(8, 8)
	face.size = Vector2(240, 240)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	viewport.add_child(face)
	await _save(viewport, "icon")


func _viewport(pixels: Vector2i, transparent := false) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = pixels
	viewport.transparent_bg = transparent
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	return viewport


func _save(viewport: SubViewport, file: String) -> void:
	for i in 4:
		await RenderingServer.frame_post_draw
	var path := "%s/%s.png" % [out_dir, file]
	viewport.get_texture().get_image().save_png(path)
	print("ARTWORK ", ProjectSettings.globalize_path(path))
	viewport.queue_free()
