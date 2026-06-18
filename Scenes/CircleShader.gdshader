shader_type canvas_item;

// --- Surface ---
uniform vec4 land_color  : source_color = vec4(0.45, 0.62, 0.40, 1.0);
uniform vec4 ocean_color : source_color = vec4(0.18, 0.30, 0.55, 1.0);
uniform float surface_scale : hint_range(1.0, 12.0) = 4.0; // noise detail
uniform float spin_speed : hint_range(0.0, 1.0) = 0.05;    // surface rotation

// --- Lighting ---
uniform vec2 light_dir = vec2(-0.6, -0.6); // direction light comes from (screen space)
uniform float ambient : hint_range(0.0, 1.0) = 0.15;

// --- Atmosphere ---
uniform vec4 atmosphere_color : source_color = vec4(0.5, 0.7, 1.0, 1.0);
uniform float atmosphere_power : hint_range(1.0, 8.0) = 3.0;

// ---- value noise + fbm ----
float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smooth interpolation
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		v += amp * noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	// Centered coords: p = (0,0) at center, edge of disc at |p| = 1.
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);

	// Soft anti-aliased disc edge.
	float aa = fwidth(r);
	float disc = smoothstep(1.0, 1.0 - aa, r);

	// Reconstruct a sphere normal from the 2D disc: z = sqrt(1 - x^2 - y^2).
	float z = sqrt(max(0.0, 1.0 - r * r));
	vec3 normal = vec3(p, z);

	// Spherical UVs so the texture wraps around the ball (and spins over time).
	vec2 sph_uv = vec2(
		atan(normal.x, normal.z) / 6.2831853 + TIME * spin_speed,
		asin(clamp(normal.y, -1.0, 1.0)) / 3.1415926 + 0.5
	);

	// Surface: noise decides land vs ocean.
	float n = fbm(sph_uv * surface_scale * vec2(2.0, 1.0));
	vec3 surface = mix(ocean_color.rgb, land_color.rgb, smoothstep(0.45, 0.55, n));

	// Diffuse lighting from a direction (pointing toward the light).
	vec3 L = normalize(vec3(-light_dir, 1.0));
	float diffuse = max(dot(normalize(normal), L), 0.0);
	surface *= ambient + (1.0 - ambient) * diffuse;

	// Atmosphere rim: brightest at the edge of the disc.
	float rim = pow(r, atmosphere_power);
	vec3 col = mix(surface, atmosphere_color.rgb, rim * disc);

	COLOR = vec4(col, disc);
}
