class_name MenuStyle
## Chunky, friendly buttons and sliders for the grown-up menus (pause, settings).


static func button(text: String, font_size := 36) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(440, 76)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", UiKit.INK)
	b.add_theme_color_override("font_focus_color", UiKit.INK)
	b.add_theme_color_override("font_hover_color", UiKit.INK)
	b.add_theme_color_override("font_pressed_color", UiKit.INK)
	b.add_theme_stylebox_override("normal", UiKit.panel(UiKit.CREAM, 24, 4))
	b.add_theme_stylebox_override("hover", UiKit.panel(UiKit.CREAM, 24, 4))
	b.add_theme_stylebox_override("pressed", UiKit.panel(UiKit.SUN.darkened(0.1), 24, 4))
	b.add_theme_stylebox_override("focus", UiKit.panel(Color(0, 0, 0, 0), 24, 7, UiKit.SUN))
	return b


static func slider(min_value: float, max_value: float, step: float, value: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_value
	s.max_value = max_value
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(420, 40)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.5)
	track.set_corner_radius_all(8)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = UiKit.SUN
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(4)
	focus.border_color = UiKit.SUN
	focus.set_corner_radius_all(10)
	focus.set_expand_margin_all(6)
	s.add_theme_stylebox_override("focus", focus)
	return s
