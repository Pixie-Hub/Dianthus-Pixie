shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform float alpha_boost : hint_range(0.0, 2.0) = 1.0;
uniform float noise_scale : hint_range(0.5, 40.0) = 8.0;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.18;
uniform float shimmer_strength : hint_range(0.0, 0.4) = 0.035;
uniform float dither_strength : hint_range(0.0, 0.25) = 0.04;
uniform vec2 drift = vec2(0.018, -0.011);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	vec4 base = COLOR;
	vec2 drifted_uv = SCREEN_UV * noise_scale + TIME * drift;
	float n = noise(drifted_uv);
	float shimmer = sin((SCREEN_UV.x * 97.0 + SCREEN_UV.y * 61.0) + TIME * 1.1) * shimmer_strength;
	float dither = hash(floor(FRAGCOORD.xy));
	float dither_alpha = mix(1.0 - dither_strength, 1.0, step(0.38, dither));
	float alpha = clamp(base.a * alpha_boost * dither_alpha * (1.0 + (n - 0.5) * noise_strength + shimmer), 0.0, 1.0);
	vec3 color_variation = mix(base.rgb * 0.82, min(base.rgb * 1.18, vec3(1.0)), n);
	COLOR = vec4(color_variation, alpha);
}
