shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 silhouette_color : source_color = vec4(0.025, 0.018, 0.026, 1.0);
uniform float alpha_strength : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness : hint_range(0.001, 0.4) = 0.06;
uniform float bottom_fade : hint_range(0.0, 1.0) = 0.0;
uniform float chip_strength : hint_range(0.0, 0.35) = 0.08;
uniform float chip_scale : hint_range(1.0, 80.0) = 18.0;
uniform float slope : hint_range(-1.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
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
	float sloped_top = 0.08 + slope * (uv.x - 0.5);
	float top_mask = smoothstep(sloped_top - edge_softness, sloped_top + edge_softness, uv.y);
	float bottom_mask = 1.0 - smoothstep(1.0 - edge_softness, 1.0, uv.y) * bottom_fade;
	float side_mask = smoothstep(0.0, edge_softness, uv.x) * (1.0 - smoothstep(1.0 - edge_softness, 1.0, uv.x));
	float chip = 1.0 - value_noise(uv * chip_scale) * chip_strength;
	float alpha = top_mask * bottom_mask * side_mask * chip * alpha_strength * silhouette_color.a * vertex_color.a;
	COLOR = vec4(silhouette_color.rgb * vertex_color.rgb, alpha);
}
