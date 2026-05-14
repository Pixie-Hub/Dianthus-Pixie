shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 glow_color : source_color = vec4(0.55, 0.16, 0.9, 0.65);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.65;
uniform float ellipse_width : hint_range(0.1, 3.0) = 1.0;
uniform float ellipse_height : hint_range(0.1, 3.0) = 1.0;
uniform float edge_power : hint_range(0.5, 8.0) = 2.2;
uniform float pulse_strength : hint_range(0.0, 0.5) = 0.08;
uniform float mist_time = 0.0;
uniform float runtime_alpha_scale = 1.0;

void fragment() {
	vec4 vertex_color = COLOR;
	vec2 centered = (UV - vec2(0.5)) * vec2(ellipse_width, ellipse_height);
	float dist = length(centered);
	float radial = pow(max(0.0, 1.0 - dist), edge_power);
	float pulse = 1.0 + sin(mist_time * 1.1) * pulse_strength;
	float alpha = radial * alpha_strength * runtime_alpha_scale * pulse * glow_color.a * vertex_color.a;
	COLOR = vec4(glow_color.rgb * vertex_color.rgb, alpha);
}
