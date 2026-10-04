shader_type canvas_item;

// The facade is drawn through a mask the shelling punches holes in. What is left
// keeps its painted art exactly; what is gone shows the room behind it.
uniform sampler2D mask_tex : filter_nearest, repeat_disable;
uniform vec4 scorch : source_color = vec4(0.18, 0.15, 0.13, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float keep = texture(mask_tex, UV).r;
	// A narrow band at the edge of every hole is burnt and dusted, so the opening
	// reads as broken masonry rather than as a cut in a sheet of paper.
	float rim = smoothstep(0.35, 0.95, keep);
	vec3 tinted = mix(scorch.rgb, base.rgb, rim);
	COLOR = vec4(tinted, base.a * step(0.3, keep));
}
