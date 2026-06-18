shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}
float rand(float n) {
	return fract(sin(n) * 43758.5453123);
}
uniform float star_density : hint_range(10.0, 200.0) = 70.0;  // grid cells across the screen
uniform float star_amount : hint_range(0.0, 1.0) = 0.06;      // fraction of cells that hold a star
uniform float star_size : hint_range(0.0, 1.0) = 0.06;
uniform float twinkle_speed : hint_range(0.0, 10.0) = 2.5;
uniform vec4 star_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);


float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}
void fragment() {
	vec2 uv = UV;
	vec2 grid = uv * star_density;
	vec2 cell = floor(grid);
	vec2 cell_uv = fract(grid);
	vec3 col = vec3(0.0,0.0,0.0);
	float rnd = hash21(cell);
	
	
	if (rnd < star_amount) {
		// Random position inside the cell so stars aren't grid-aligned.
		vec2 star_pos = vec2(hash21(cell + 1.7), hash21(cell + 4.3));
		float d = distance(cell_uv, star_pos);

		// Soft round star.
		float glow = smoothstep(star_size, 0.0, d);

		// Glimmer: each star twinkles at its own phase (independent hash spans full 0-1).
		float phase = hash21(cell + 9.1) * 6.2831853;
		float twinkle = 0.5 + 0.5 * sin(TIME * twinkle_speed + phase);

		col += star_color.rgb * glow * twinkle;
	}
	COLOR = vec4(col, 1.0);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
