// Grass tufts and flowers (MultiMesh): instance colour, swaying in the breeze.
// SWAY is a constant rather than a uniform: a uniform here crashes Mesa's software
// Vulkan driver (lavapipe), which the headless screenshot tests run on.
shader_type spatial;
render_mode cull_disabled;

#include "res://src/visuals/shaders/toon_light.gdshaderinc"

const float SWAY = 0.12;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float bend = max(VERTEX.y, 0.0);
	VERTEX.x += sin(TIME * 1.6 + origin.x * 0.35 + origin.z * 0.21) * SWAY * bend;
	VERTEX.z += cos(TIME * 1.3 + origin.x * 0.17) * SWAY * 0.5 * bend;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}
