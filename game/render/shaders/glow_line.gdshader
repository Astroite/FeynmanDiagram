shader_type canvas_item;
render_mode blend_add;

uniform vec4 line_color : source_color = vec4(0.39, 0.96, 1.0, 0.92);
uniform vec4 glow_color : source_color = vec4(0.70, 0.92, 1.0, 0.36);
uniform float glow_strength = 1.0;
uniform float core_alpha = 0.9;


void fragment() {
	vec4 source = COLOR;
	vec3 mixed_color = mix(line_color.rgb, glow_color.rgb, clamp(glow_strength * 0.35, 0.0, 1.0));
	float alpha = source.a * line_color.a * core_alpha;
	COLOR = vec4(mixed_color * (1.0 + glow_strength), alpha);
}
