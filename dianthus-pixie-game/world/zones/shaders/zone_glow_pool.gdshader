shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float alpha_boost : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_strength : hint_range(0.0, 0.5) = 0.08;
uniform float pulse_speed : hint_range(0.0, 6.0) = 1.2;
uniform float noise_scale : hint_range(0.5, 40.0) = 10.0;
uniform float mote_strength : hint_range(0.0, 1.0) = 0.12;
uniform vec2 drift = vec2(0.01, 0.016);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.7))) * 19483.223);
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
	float pulse = 1.0 + sin(TIME * pulse_speed + SCREEN_UV.x * 8.0 + SCREEN_UV.y * 5.0) * pulse_strength;
	float n = noise(SCREEN_UV * noise_scale + TIME * drift);
	float motes = smoothstep(0.86, 1.0, n) * mote_strength;
	float alpha = clamp(base.a * alpha_boost * pulse * (0.84 + n * 0.28) + motes, 0.0, 1.0);
	vec3 glow_color = mix(base.rgb * 0.75, min(base.rgb * 1.35, vec3(1.0)), n);
	COLOR = vec4(glow_color, alpha);
}
