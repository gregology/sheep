// Meadow grass: two greens in big soft patches, mowed stripes inside the field,
// and straw inside the pen.
shader_type spatial;

#include "res://src/visuals/shaders/toon_light.gdshaderinc"

uniform vec4 grass_light : source_color = vec4(0.56, 0.84, 0.38, 1.0);
uniform vec4 grass_dark : source_color = vec4(0.40, 0.72, 0.30, 1.0);
uniform vec4 straw : source_color = vec4(0.95, 0.82, 0.50, 1.0);
uniform vec4 field_rect = vec4(-16.0, -11.0, 16.0, 11.0);
uniform vec4 pen_rect = vec4(9.0, -11.0, 16.0, -4.0);
uniform float stripe_width = 4.0;
uniform sampler2D noise : repeat_enable, filter_linear;

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float inside(vec2 p, vec4 r) {
	return step(r.x, p.x) * step(p.x, r.z) * step(r.y, p.y) * step(p.y, r.w);
}

void fragment() {
	vec2 p = world.xz;
	float big = texture(noise, p * 0.035).r;
	float small = texture(noise, p * 0.23 + vec2(0.37, 0.11)).r;
	vec3 c = mix(grass_dark.rgb, grass_light.rgb, smoothstep(0.3, 0.7, big));
	c *= 0.93 + 0.12 * small;
	float stripe = step(0.5, fract(p.x / stripe_width));
	c = mix(c, c * 1.06 + vec3(0.012, 0.02, 0.0), inside(p, field_rect) * stripe);
	c = mix(c, straw.rgb * (0.9 + 0.15 * small), inside(p, pen_rect) * 0.9);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
