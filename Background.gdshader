shader_type canvas_item;

// Scroll uniforms
uniform float scroll_speed_x : hint_range(-2.0, 2.0) = 0.1;
uniform float scroll_speed_y : hint_range(-2.0, 2.0) = 0.05;
uniform sampler2D tex : source_color, repeat_enable;

// Star uniforms
uniform float star_density : hint_range(0.0, 1.0) = 0.97;
uniform float star_brightness : hint_range(0.0, 1.0) = 1.0;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 1.0;
uniform float star_size : hint_range(0.5, 3.0) = 1.0;
uniform vec2 star_scroll_speed = vec2(0.01, 0.005); // stars scroll slower (parallax)

// Hash function to get pseudorandom value from a vec2
float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float star_layer(vec2 uv, float cell_size, float time) {
    // Scale UV into cells — each cell may contain one star
    vec2 scaled = uv / cell_size;
    vec2 cell   = floor(scaled);
    vec2 local  = fract(scaled);          // position within the cell (0..1)

    float result = 0.0;

    // Check the cell and its 8 neighbours to avoid edge clipping
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbour = cell + vec2(float(x), float(y));

            // Random position of the star inside this cell
            float rx = hash(neighbour);
            float ry = hash(neighbour + vec2(1.0, 0.0));
            vec2 star_pos = vec2(rx, ry);

            // Cull sparse cells — stars only appear where hash > density threshold
            float exists = step(star_density, hash(neighbour + vec2(7.3, 2.1)));

            // Distance from current pixel to star center
            vec2 to_star = local - (star_pos + vec2(float(x), float(y)));
            float dist   = length(to_star);

            // Twinkle: modulate brightness with a per-star phase offset
            float phase     = hash(neighbour + vec2(3.7, 1.5)) * 6.28;
            float twinkle   = 0.7 + 0.3 * sin(time * twinkle_speed + phase);

            // Soft circular star, size controlled by uniform
            float brightness = smoothstep(0.04 * star_size, 0.0, dist);
            result += brightness * exists * twinkle;
        }
    }

    return clamp(result, 0.0, 1.0);
}

void fragment() {
    // --- Scrolling background texture ---
    vec2 scroll_uv = UV + vec2(TIME * scroll_speed_x, TIME * scroll_speed_y);
    vec4 bg = texture(tex, scroll_uv);

    // --- Star layers (different cell sizes = different star sizes/densities) ---
    vec2 star_uv = UV + TIME * star_scroll_speed;

    float stars = 0.0;
    stars += star_layer(star_uv, 0.05, TIME) * 1.0;  // small dense stars
    stars += star_layer(star_uv, 0.12, TIME) * 0.8;  // medium stars
    stars += star_layer(star_uv, 0.25, TIME) * 0.6;  // rare large stars

    vec4 star_color = vec4(vec3(stars * star_brightness), 1.0);

    // --- Composite: stars on top of background ---
    COLOR = bg + star_color;
}