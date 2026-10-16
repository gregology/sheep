// Soft two-tone cartoon lighting, shared by every lit surface so the game keeps one look.
uniform float rim_amount : hint_range(0.0, 1.0) = 0.22;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.02, 0.14, ndl);
	float shadow = smoothstep(0.25, 0.65, ATTENUATION);
	float amount = lit * shadow;
	DIFFUSE_LIGHT += amount * LIGHT_COLOR / PI;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	SPECULAR_LIGHT += rim * rim_amount * amount * LIGHT_COLOR / PI;
}
