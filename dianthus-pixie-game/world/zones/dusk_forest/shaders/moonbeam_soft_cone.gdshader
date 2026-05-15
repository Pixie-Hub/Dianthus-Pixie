shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 beam_color : source_color = vec4(0.62, 0.72, 1.0, 1.0);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.18;
uniform float source_width : hint_range(0.0, 1.0) = 0.14;
uniform float bottom_width : hint_range(0.0, 1.0) = 0.72;
uniform float edge_feather : hint_range(0.001, 0.5) = 0.18;
uniform float mist_strength : hint_range(0.0, 1.0) = 0.22;
uniform float noise_scale : hint_range(0.5, 24.0) = 5.0;
uniform float time_scale : hint_range(0.0, 2.0) = 0.15;
uniform float flicker_strength : hint_range(0.0, 0.25) = 0.04;
uniform float flicker_phase = 0.0;
uniform float runtime_alpha_scale : hint_range(0.0, 3.0) = 1.0;
uniform float mist_time = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
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
	float half_width = mix(source_width, bottom_width, uv.y) * 0.5;
	float edge_start = max(half_width - edge_feather, 0.0);
	float cone = 1.0 - smoothstep(edge_start, half_width, abs(uv.x - 0.5));
	float top_fade = smoothstep(0.0, 0.18, uv.y);
	float bottom_fade = 1.0 - smoothstep(0.82, 1.0, uv.y);
	float vertical_fade = top_fade * bottom_fade;
	float mist = value_noise(uv * noise_scale + vec2(mist_time * time_scale, -mist_time * time_scale * 0.25));
	float mist_mix = mix(1.0, 0.72 + mist * 0.56, mist_strength);
	float flicker = 1.0 + sin(TIME * time_scale + flicker_phase) * flicker_strength;
	float alpha = alpha_strength * runtime_alpha_scale * tex.a * cone * vertical_fade * mist_mix * flicker;
	COLOR = vec4(beam_color.rgb * tex.rgb, beam_color.a * alpha);
}
