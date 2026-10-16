class_name JoinCard
extends Control
## One spot on the join screen: a kennel for one of the four dogs, or the chaos spot.

const DOG_SIZE := Vector2(230, 320)
const CHAOS_SIZE := Vector2(330, 320)

## 0..3 for a dog kennel, -1 for the chaos spot.
var dog_index := -1

var _portraits: Array[Portrait] = []
var _slot: PlayerSlot
var _time := 0.0
var _bounce := 0.0
var _filled_style: StyleBoxFlat
var _empty_style: StyleBoxFlat


func _init(index: int) -> void:
	dog_index = index
	custom_minimum_size = DOG_SIZE if index >= 0 else CHAOS_SIZE
	var color := PlayerSlot.DOG_COLORS[index] if index >= 0 else PlayerSlot.CHAOS_COLOR
	_filled_style = UiKit.panel(color, 30, 6)
	_empty_style = UiKit.panel(Color(1, 1, 1, 0.3), 30, 5, Color(UiKit.INK, 0.35))


func _ready() -> void:
	if dog_index >= 0:
		_portraits.append(Portrait.new(&"dog", {
			"breed": PlayerSlot.BREEDS[dog_index], "color": PlayerSlot.DOG_COLORS[dog_index]}))
	else:
		_portraits.append(Portrait.new(&"black_sheep"))
		_portraits.append(Portrait.new(&"wolf"))
	for portrait in _portraits:
		add_child(portrait)
	visibility_changed.connect(_on_visibility_changed)
	Players.changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	_bounce = move_toward(_bounce, 0.0, delta * 2.0)
	queue_redraw()


func _draw() -> void:
	var filled := _slot != null
	var grow := 1.0 + 0.1 * sin(_bounce * PI)
	var rect := Rect2(Vector2.ZERO, size)
	rect = Rect2(rect.get_center() - rect.size * grow * 0.5, rect.size * grow).grow(-8.0)
	draw_style_box(_filled_style if filled else _empty_style, rect)

	var bob := sin(_time * 3.0 + dog_index) * 5.0 if filled else 0.0
	var tint := Color.WHITE if filled else Color(0.1, 0.08, 0.12, 0.35)
	var art := Rect2(rect.position + Vector2(10, 4 + bob), Vector2(rect.size.x - 20, rect.size.x - 20))
	if dog_index >= 0:
		draw_texture_rect(_portraits[0].get_texture(), art, false, tint)
	else:
		var each := minf(art.size.x * 0.58, 196.0)
		var top := art.position.y + 6.0
		draw_texture_rect(_portraits[0].get_texture(), Rect2(Vector2(art.position.x - 4, top), Vector2(each, each)), false, tint)
		draw_texture_rect(_portraits[1].get_texture(), Rect2(Vector2(art.end.x - each + 4, top + 4), Vector2(each, each)), false, tint)

	var font := get_theme_default_font()
	var bottom := rect.end.y - 26.0
	if filled:
		var label := "CHAOS!" if dog_index < 0 else "WOOF!"
		UiKit.draw_text(self, font, Vector2(rect.position.x, bottom - 40.0), label, 44, UiKit.CREAM, rect.size.x)
		UiKit.draw_text(self, font, Vector2(rect.position.x, bottom), _slot.device.display_name.left(22), 20,
			UiKit.CREAM, rect.size.x)
	elif dog_index >= 0:
		UiKit.draw_button_diamond(self, Vector2(rect.get_center().x, bottom - 22.0), 15.0, [&"south"], UiKit.SUN)
	else:
		var c := Vector2(rect.get_center().x, bottom - 22.0)
		var arrow := PackedVector2Array([c + Vector2(26, 0), c + Vector2(-14, -22), c + Vector2(-14, 22)])
		draw_colored_polygon(arrow, PlayerSlot.CHAOS_COLOR.lightened(0.3))
		arrow.append(arrow[0])
		draw_polyline(arrow, UiKit.INK, 3.0, true)


func _refresh() -> void:
	var before := _slot
	_slot = null
	for slot in Players.slots:
		if (dog_index < 0 and slot.is_chaos()) or (dog_index >= 0 and slot.is_dog() and slot.dog_index == dog_index):
			_slot = slot
	if _slot != null and _slot != before:
		_bounce = 1.0


func _on_visibility_changed() -> void:
	for portrait in _portraits:
		portrait.set_active(is_visible_in_tree())
