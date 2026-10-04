shader_type canvas_item;

// The facade is drawn through a mask the shelling punches holes in. What is left
// keeps its painted art exactly; what is gone shows the room behind it.
//
// The room is sampled here rather than drawn by a node underneath, so it can only
// ever appear inside the building's own silhouette. A node behind the facade spills
// its rectangle out past the roofline and the house reads as a brown box.
uniform sampler2D mask_tex : filter_nearest, repeat_disable;
uniform sampler2D room_tex : filter_nearest, repeat_disable;
uniform vec4 scorch : source_color = vec4(0.16, 0.13, 0.11, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec4 room = texture(room_tex, UV);
	float keep = texture(mask_tex, UV).r;
	// Standing masonry shows its paint; a breach shows the room; the narrow band
	// between them is scorched and dusted, so the opening reads as broken stone
	// rather than as a cut in a sheet of paper.
	vec3 wall = mix(scorch.rgb, base.rgb, smoothstep(0.45, 0.95, keep));
	vec3 colour = mix(room.rgb, wall, smoothstep(0.12, 0.5, keep));
	// Alpha comes from the artwork alone, so nothing is ever drawn outside the
	// house's own outline, hole or no hole.
	COLOR = vec4(colour, base.a);
}
