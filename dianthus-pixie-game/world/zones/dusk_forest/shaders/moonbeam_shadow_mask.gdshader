shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 shadow_color : source_color = vec4(0.018, 0.026, 0.04, 1.0);
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.3;
uniform float edge_feather : hint_range(0.001, 0.5) = 0.18;
uniform float runtime_alpha_scale : hint_range(0.0, 3.0) = 1.0;

void fragment() {
	vec2 uv = UV;
	vec4 tex = texture(TEXTURE, uv);
	float left = smoothstep(0.0, edge_feather, uv.x);
	float right = 1.0 - smoothstep(1.0 - edge_feather, 1.0, uv.x);
	float top = smoothstep(0.0, edge_feather, uv.y);
	float bottom = 1.0 - smoothstep(1.0 - edge_feather, 1.0, uv.y);
	float alpha = alpha_strength * runtime_alpha_scale * tex.a * left * right * top * bottom;
	COLOR = vec4(shadow_color.rgb * tex.rgb, shadow_color.a * alpha);
}
