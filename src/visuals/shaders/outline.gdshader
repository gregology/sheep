// Inverted-hull outline: drawn as a second pass, pushed out along the normals,
// showing only back faces. With an orthographic camera the width is constant on screen.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.17, 0.12, 0.16, 1.0);
uniform float width = 0.035;

void vertex() {
	VERTEX += normalize(NORMAL) * width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
