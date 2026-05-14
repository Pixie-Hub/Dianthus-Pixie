shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 glow_color : source_color = vec4(0.66, 0.82, 1.0, 1.0);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.18;
uniform float ellipse_width : hint_range(0.05, 2.0) = 1.0;
uniform float ellipse_height : hint_range(0.05, 2.0) = 0.42;
uniform float edge_feather : hint_range(0.001, 0.95) = 0.7;
uniform float pulse_strength : hint_range(0.0, 0.2) = 0.03;
uniform float pulse_phase = 0.0;
uniform float runtime_alpha_scale : hint_range(0.0, 3.0) = 1.0;
uniform float mist_time = 0.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	p.x /= max(ellipse_width, 0.01);
	p.y /= max(ellipse_height, 0.01);
	float d = length(p);
	float edge = 1.0 - smoothstep(max(1.0 - edge_feather, 0.0), 1.0, d);
	float center_soften = 0.72 + smoothstep(0.0, 0.55, d) * 0.28;
	float pulse = 1.0 + sin(TIME * 0.55 + pulse_phase) * pulse_strength;
	float alpha = alpha_strength * runtime_alpha_scale * edge * center_soften * pulse;
	COLOR = vec4(glow_color.rgb, glow_color.a * alpha);
}
