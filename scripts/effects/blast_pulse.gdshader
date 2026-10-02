shader_type canvas_item;

void fragment() {
	// Keep the expanding pulse, but remove the rectangular prototype corners.
	float distance_from_center = length((UV - vec2(0.5)) * 2.0);
	COLOR.a *= 1.0 - smoothstep(0.15, 1.0, distance_from_center);
}
