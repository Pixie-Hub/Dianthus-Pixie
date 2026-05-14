shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float alpha_boost : hint_range(0.0, 2.0) = 1.0;
uniform float vein_strength : hint_range(0.0, 1.0) = 0.22;
uniform float pulse_strength : hint_range(0.0, 0.6) = 0.1;
uniform float noise_scale : hint_range(0.5, 60.0) = 18.0;
uniform vec3 vein_color = vec3(0.34, 0.22, 0.56);
uniform vec2 drift = vec2(-0.016, 0.01);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(157.3, 113.1))) * 28931.141);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	vec4 base = COLOR;
	vec2 p = SCREEN_UV * noise_scale + TIME * drift;
	float n = noise(p);
	float vein = smoothstep(0.62, 0.96, n) * vein_strength;
	float pulse = 1.0 + sin(TIME * 1.35 + n * 6.28318) * pulse_strength;
	float alpha = clamp(base.a * alpha_boost * pulse * (0.92 + vein), 0.0, 1.0);
	vec3 cracked_color = mix(base.rgb * 0.72, vein_color, vein);
	COLOR = vec4(cracked_color, alpha);
}
