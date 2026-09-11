shader_type canvas_item;
render_mode unshaded;

// Slightly matte brushed metal for the flat-colour UI panel in GameState.tscn.
//
// The node's TEXTURE supplies the base colour (and the alpha), so this is meant to sit on
// a flat fill - everything that makes it read as metal is generated here. Matte means the
// highlight is WIDE and WEAK: a narrow bright streak reads as polished chrome or glass.
//
// Deliberately static - no TIME anywhere. This panel sits behind the HUD for the whole run,
// and anything that moves or shimmers there pulls the eye off the grid.

uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Brushed grain: fine streaks running the length of the panel. Raise strength for a
// rougher, more worked surface.
uniform float brush_strength : hint_range(0.0, 0.5) = 0.07;
uniform float brush_frequency : hint_range(10.0, 1200.0) = 320.0;

// Per-pixel speckle. This is what keeps the surface matte rather than glassy.
uniform float grain_strength : hint_range(0.0, 0.3) = 0.035;

// The soft sheen sweeping across the plate. width is the whole point: keep it broad.
uniform float sheen_strength : hint_range(0.0, 1.0) = 0.16;
uniform float sheen_width : hint_range(0.05, 1.5) = 0.55;
uniform float sheen_position : hint_range(-0.5, 1.5) = 0.3;

// Darkening towards the outside, so the plate looks bevelled into the hull.
uniform float edge_shade : hint_range(0.0, 1.0) = 0.3;
uniform float edge_width : hint_range(0.0, 0.5) = 0.1;

float hash(float n) {
	return fract(sin(n * 91.3458) * 47453.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 1D value noise. Fed a single axis it is constant along the other one, which is exactly
// what makes the result read as brushing rather than as static.
float streak(float v) {
	float i = floor(v);
	float f = fract(v);
	f = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), f);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 col = tex.rgb * tint.rgb;

	// Driven by UV.x, so the streaks run vertically - along the long axis of a tall
	// panel. Swap both to UV.y to brush it horizontally instead. Two octaves: the fine
	// one is the brushing, the coarse one stops it looking mechanically even.
	float brush = (streak(UV.x * brush_frequency) - 0.5)
			+ (streak(UV.x * brush_frequency * 0.37 + 11.0) - 0.5) * 0.6;
	col *= 1.0 + brush * brush_strength;

	// Broad diagonal sheen. Added as a screen-style blend - (1.0 - col) - so it lightens
	// towards white and cannot blow past it however bright the base colour is.
	float d = (UV.x + UV.y) * 0.5;
	//Squared by multiplication, not pow(): d - sheen_position goes negative on one side
	//of the sheen and pow() with a negative base is undefined in GLSL.
	float offset = (d - sheen_position) / sheen_width;
	float sheen = exp(-offset * offset * 2.0);
	col += sheen * sheen_strength * (1.0 - col);

	// Bevel: distance to the nearest edge, so all four sides darken.
	vec2 e = min(UV, vec2(1.0) - UV);
	float edge = smoothstep(0.0, edge_width, min(e.x, e.y));
	col *= mix(1.0 - edge_shade, 1.0, edge);

	// Speckle last, over everything, so it breaks up the sheen too.
	col *= 1.0 + (hash2(UV * 1024.0) - 0.5) * grain_strength;

	COLOR = vec4(col, tex.a * tint.a);
}
