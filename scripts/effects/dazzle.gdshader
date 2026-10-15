shader_type canvas_item;

// What a flashbang leaves behind the eyes: the picture smears and repeats, as if
// the shutter had been left open on it.
// Godot 4 hands the screen in as a uniform; SCREEN_TEXTURE no longer exists.
uniform sampler2D screen : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float spread : hint_range(0.0, 0.08) = 0.022;

void fragment() {
	vec4 here = texture(screen, SCREEN_UV);
	if (strength <= 0.001) {
		COLOR = vec4(here.rgb, 0.0);
	} else {
		// Four ghosts pulled out from the middle of the screen, each fainter than the
		// last. Scaling about the centre rather than sliding sideways is what makes it
		// read as an after-image instead of a camera shake.
		vec2 middle = vec2(0.5);
		vec3 echo = vec3(0.0);
		float weight = 0.0;
		for (int i = 1; i <= 4; i++) {
			float step_out = spread * float(i) * strength;
			float fade = 1.0 / float(i);
			echo += texture(screen, middle + (SCREEN_UV - middle) * (1.0 + step_out)).rgb * fade;
			echo += texture(screen, middle + (SCREEN_UV - middle) * (1.0 - step_out)).rgb * fade;
			weight += fade * 2.0;
		}
		echo /= weight;
		// Dazzled eyes lose contrast before they lose detail, so the ghost is lifted
		// towards white rather than simply blurred.
		echo = mix(echo, echo + vec3(0.25), strength * 0.6);
		COLOR = vec4(echo, strength);
	}
}
