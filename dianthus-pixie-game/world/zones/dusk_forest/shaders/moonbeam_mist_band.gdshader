shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 mist_color : source_color = vec4(0.58, 0.72, 0.86, 1.0);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.15;
uniform float band_thickness : hint_range(0.05, 1.0) = 0.52;
uniform float edge_feather : hint_range(0.001, 0.5) = 0.22;
uniform float noise_scale : hint_range(1.0, 32.0) = 10.0;
uniform float drift_speed : hint_range(0.0, 2.0) = 0.08;
uniform float runtime_alpha_scale : hint_range(0.0, 3.0) = 1.0;
uniform float mist_time = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(211.11, 94.13));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void fragment() {
	vec2 uv = UV;
	vec4 tex = texture(TEXTURE, uv);
	float y_dist = abs(uv.y - 0.5);
	float band = 1.0 - smoothstep(max(band_thickness * 0.5 - edge_feather, 0.0), band_thickness * 0.5, y_dist);
	float end_fade = smoothstep(0.0, 0.12, uv.x) * (1.0 - smoothstep(0.88, 1.0, uv.x));
	float noise = value_noise(vec2(uv.x * noise_scale + mist_time * drift_speed, uv.y * 3.0));
	float alpha = alpha_strength * runtime_alpha_scale * tex.a * band * end_fade * (0.72 + noise * 0.42);
	COLOR = vec4(mist_color.rgb * tex.rgb, mist_color.a * alpha);
}
