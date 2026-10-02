shader_type canvas_item;
uniform vec4 haze_color : source_color = vec4(0.69, 0.75, 0.76, 1.0);
uniform float haze_amount : hint_range(0.0, 0.5) = 0.13;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(mix(tex.rgb, haze_color.rgb, haze_amount), tex.a);
}
