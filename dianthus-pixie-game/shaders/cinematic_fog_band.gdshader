shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 fog_color : source_color = vec4(0.22, 0.18, 0.30, 0.7);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.7;
uniform float vertical_softness : hint_range(0.01, 1.0) = 0.42;
uniform float horizontal_feather : hint_range(0.01, 0.5) = 0.16;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.12;
uniform float noise_scale : hint_range(1.0, 60.0) = 11.0;
uniform float drift_speed : hint_range(-2.0, 2.0) = 0.08;
uniform float mist_time = 0.0;
uniform float runtime_alpha_scale = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.3, 289.7))) * 143758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 vertex_color = COLOR;
	vec2 uv = UV;
	float vertical = 1.0 - smoothstep(0.5 - vertical_softness, 0.5, abs(uv.y - 0.5));
	float horizontal = smoothstep(0.0, horizontal_feather, uv.x) * (1.0 - smoothstep(1.0 - horizontal_feather, 1.0, uv.x));
	float noise = value_noise(vec2(uv.x * noise_scale + mist_time * drift_speed, uv.y * 3.0));
	float alpha = vertical * horizontal * (1.0 - noise * noise_strength) * alpha_strength * runtime_alpha_scale * fog_color.a * vertex_color.a;
	COLOR = vec4(fog_color.rgb * vertex_color.rgb, alpha);
}
