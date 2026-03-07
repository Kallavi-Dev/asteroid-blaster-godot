shader_type canvas_item;
// Pulsing shield overlay effect.

uniform vec4 shield_color : source_color = vec4(0.2, 1.0, 0.5, 0.4);
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
	float alpha_boost = pulse * shield_color.a;
	COLOR = mix(col, vec4(shield_color.rgb, col.a), alpha_boost * col.a);
}
