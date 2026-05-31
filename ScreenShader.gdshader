shader_type canvas_item;

uniform sampler2D tex : source_color, repeat_enable;

// --- Small Gaussian blur (Option A) ---
// Blur radius in texels. Keep small (0.5 - 2.0) for a subtle blur.
uniform float radius : hint_range(0.0, 4.0) = 1.0;

// --- Glow / bloom ---
uniform float threshold : hint_range(0.0, 1.0) = 0.6;
uniform float intensity : hint_range(0.0, 4.0) = 1.5;
uniform float spread : hint_range(0.0, 8.0) = 2.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

// True 3x3 Gaussian blur of the texture at `uv` (weights sum to 1.0).
// `tex` is the texture to sample, `px` is the per-step texel offset.
vec4 gaussian_blur(sampler2D blur_tex, vec2 uv, vec2 px) {
	vec4 c = vec4(0.0);
	c += texture(blur_tex, uv + vec2(-px.x, -px.y)) * 0.0625;
	c += texture(blur_tex, uv + vec2( 0.0,  -px.y)) * 0.125;
	c += texture(blur_tex, uv + vec2( px.x, -px.y)) * 0.0625;
	c += texture(blur_tex, uv + vec2(-px.x,  0.0))  * 0.125;
	c += texture(blur_tex, uv)                      * 0.25;
	c += texture(blur_tex, uv + vec2( px.x,  0.0))  * 0.125;
	c += texture(blur_tex, uv + vec2(-px.x,  px.y)) * 0.0625;
	c += texture(blur_tex, uv + vec2( 0.0,   px.y)) * 0.125;
	c += texture(blur_tex, uv + vec2( px.x,  px.y)) * 0.0625;
	return c;
}

// Pull only the bright part of a sample (everything below threshold -> black).
vec3 extract_bright(vec3 col) {
	float lum = dot(col, vec3(0.299, 0.587, 0.114)); // perceived brightness
	float f = smoothstep(threshold, 1.0, lum);
	return col * f;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec2 px = TEXTURE_PIXEL_SIZE * spread;

	// Base color, softened by the small Gaussian blur.
	vec4 base = gaussian_blur(TEXTURE, UV, TEXTURE_PIXEL_SIZE * radius);

	vec3 bloom = vec3(0.0);
	// center
	bloom += extract_bright(texture(TEXTURE, UV).rgb)                    * 0.25;
	// edges
	bloom += extract_bright(texture(TEXTURE, UV + vec2( px.x, 0.0)).rgb) * 0.125;
	bloom += extract_bright(texture(TEXTURE, UV + vec2(-px.x, 0.0)).rgb) * 0.125;
	bloom += extract_bright(texture(TEXTURE, UV + vec2(0.0,  px.y)).rgb) * 0.125;
	bloom += extract_bright(texture(TEXTURE, UV + vec2(0.0, -px.y)).rgb) * 0.125;
	// corners
	bloom += extract_bright(texture(TEXTURE, UV + vec2( px.x,  px.y)).rgb) * 0.0625;
	bloom += extract_bright(texture(TEXTURE, UV + vec2(-px.x,  px.y)).rgb) * 0.0625;
	bloom += extract_bright(texture(TEXTURE, UV + vec2( px.x, -px.y)).rgb) * 0.0625;
	bloom += extract_bright(texture(TEXTURE, UV + vec2(-px.x, -px.y)).rgb) * 0.0625;

	// Additively blend the blurred bright parts over the softened base.
	vec3 result = base.rgb + bloom * intensity * glow_color.rgb;
	COLOR = vec4(result, base.a);
}
