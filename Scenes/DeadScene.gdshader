shader_type canvas_item;

// Old-90s-TV flicker for the dead screen.
// Tweak these in the inspector to taste.
uniform float flicker_strength : hint_range(0.0, 0.5) = 0.06;   // brightness flicker amount
uniform float flicker_speed    : hint_range(0.0, 60.0) = 18.0;  // how fast it flickers
uniform float jitter_strength  : hint_range(0.0, 0.02) = 0.002; // horizontal stutter
uniform float roll_strength    : hint_range(0.0, 0.05) = 0.004; // slow vertical drift
uniform float roll_speed       : hint_range(0.0, 2.0) = 0.15;   // how fast it rolls
uniform float scanline_strength: hint_range(0.0, 1.0) = 0.12;   // dark scanlines
uniform float scanline_count   : hint_range(50.0, 1080.0) = 480.0;
uniform float chroma_offset    : hint_range(0.0, 0.01) = 0.0015; // RGB split

// cheap pseudo-random
float rand(float n) {
	return fract(sin(n) * 43758.5453123);
}

void fragment() {
	vec2 uv = UV;

	// --- a little moving: slow vertical roll ---
	uv.y += sin(TIME * roll_speed) * roll_strength;

	// --- a little stuttering: occasional horizontal jitter per scanline ---
	float line = floor(uv.y * scanline_count);
	float jitter = (rand(line + floor(TIME * 12.0)) - 0.5) * 2.0;
	// only jitter some of the time so it stutters rather than constantly shakes
	float stutter = step(0.92, rand(floor(TIME * 8.0)));
	uv.x += jitter * jitter_strength * stutter;

	// --- sample texture with a tiny chromatic split for that CRT look ---
	vec4 col;
	col.r = texture(TEXTURE, uv + vec2(chroma_offset, 0.0)).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, uv - vec2(chroma_offset, 0.0)).b;
	col.a = texture(TEXTURE, uv).a;

	// --- a little flicker: global brightness wobble ---
	float flicker = 1.0
		+ sin(TIME * flicker_speed) * flicker_strength * 0.5
		+ (rand(floor(TIME * flicker_speed)) - 0.5) * flicker_strength;
	col.rgb *= flicker;

	// --- scanlines ---
	float scan = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
	col.rgb *= 1.0 - scan * scanline_strength;

	COLOR = col;
}
