shader_type canvas_item;
// Adds a soft glow outline around a sprite.
// Attach to a ShaderMaterial on any Sprite2D.

uniform vec4 glow_color : source_color = vec4(0.3, 0.7, 1.0, 0.8);
uniform float glow_size : hint_range(0.0, 10.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.5;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a > 0.1) {
		COLOR = col;
		return;
	}

	float outline = 0.0;
	vec2 size = TEXTURE_PIXEL_SIZE * glow_size;

	for (float x = -1.0; x <= 1.0; x += 0.5) {
		for (float y = -1.0; y <= 1.0; y += 0.5) {
			outline += texture(TEXTURE, UV + vec2(x, y) * size).a;
		}
	}

	outline = min(outline * 0.04 * glow_intensity, 1.0);
	COLOR = vec4(glow_color.rgb, outline * glow_color.a);
}
