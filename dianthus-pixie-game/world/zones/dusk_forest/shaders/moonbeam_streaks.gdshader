shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 streak_color : source_color = vec4(0.78, 0.86, 1.0, 1.0);
uniform float streak_density : hint_range(2.0, 80.0) = 26.0;
uniform float streak_softness : hint_range(0.01, 0.5) = 0.16;
uniform float streak_angle = -0.25;
uniform float streak_alpha : hint_range(0.0, 1.0) = 0.10;
uniform float drift_speed : hint_range(0.0, 2.0) = 0.08;
uniform float source_width : hint_range(0.0, 1.0) = 0.14;
uniform float bottom_width : hint_range(0.0, 1.0) = 0.78;
uniform float edge_feather : hint_range(0.001, 0.5) = 0.18;
uniform float flicker_phase = 0.0;
uniform float runtime_alpha_scale : hint_range(0.0, 3.0) = 1.0;
uniform float mist_time = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(71.17, 313.91));
	p += dot(p, p + 27.13);
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
	float cone = 1.0 - smoothstep(max(half_width - edge_feather, 0.0), half_width, abs(uv.x - 0.5));
	float vertical_fade = smoothstep(0.04, 0.22, uv.y) * (1.0 - smoothstep(0.78, 1.0, uv.y));
	mat2 rotation = mat2(vec2(cos(streak_angle), -sin(streak_angle)), vec2(sin(streak_angle), cos(streak_angle)));
	vec2 streak_uv = rotation * (uv - 0.5);
	float noise = value_noise(vec2(streak_uv.x * 8.0, uv.y * 2.0 + mist_time * drift_speed));
	float stripe = sin((streak_uv.x + noise * 0.06) * streak_density + mist_time * drift_speed);
	float streak = smoothstep(1.0 - streak_softness, 1.0, stripe * 0.5 + 0.5);
	float flicker = 0.94 + sin(TIME * 0.55 + flicker_phase) * 0.06;
	float alpha = streak_alpha * runtime_alpha_scale * tex.a * cone * vertical_fade * streak * flicker;
	COLOR = vec4(streak_color.rgb * tex.rgb, streak_color.a * alpha);
}
