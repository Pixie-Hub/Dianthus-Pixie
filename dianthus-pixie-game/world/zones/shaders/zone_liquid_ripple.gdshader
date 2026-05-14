shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float alpha_boost : hint_range(0.0, 2.0) = 1.0;
uniform float ripple_strength : hint_range(0.0, 0.6) = 0.16;
uniform float ripple_frequency : hint_range(1.0, 60.0) = 22.0;
uniform float ripple_speed : hint_range(0.0, 8.0) = 1.4;
uniform float noise_scale : hint_range(0.5, 40.0) = 9.0;
uniform vec2 flow = vec2(0.012, 0.018);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(73.7, 19.9))) * 37291.44);
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
	vec2 p = SCREEN_UV + flow * TIME;
	float ripple = sin((p.x * 1.7 + p.y) * ripple_frequency + TIME * ripple_speed) * ripple_strength;
	float n = noise(p * noise_scale);
	float alpha = clamp(base.a * alpha_boost * (0.9 + ripple + (n - 0.5) * 0.18), 0.0, 1.0);
	vec3 color_variation = mix(base.rgb * 0.68, min(base.rgb * 1.22, vec3(1.0)), n + ripple * 0.45);
	COLOR = vec4(color_variation, alpha);
}
