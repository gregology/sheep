// Soft round shadow under creatures: in an orthographic view it's what tells you how high a jump is.
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, shadows_disabled;

instance uniform float opacity = 0.35;

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	ALBEDO = vec3(0.10, 0.15, 0.24);
	ALPHA = opacity * (1.0 - smoothstep(0.3, 1.0, d));
}
