shader_type canvas_item;

// Idle drift for a ship the camera is locked onto. Since the camera never moves
// relative to the ship, the sense of motion has to come from the ship itself:
// a slow bob/sway/roll (course corrections) plus a fast low-amplitude buzz
// (engines). All offsets are in the sprite's LOCAL pixels, so a node scaled 4x
// shows 4x this much movement on screen.

uniform float bob_amount : hint_range(0.0, 20.0) = 1.5;
uniform float bob_speed : hint_range(0.0, 5.0) = 0.7;
uniform float sway_amount : hint_range(0.0, 20.0) = 1.0;
uniform float sway_speed : hint_range(0.0, 5.0) = 0.43;
uniform float roll_degrees : hint_range(0.0, 15.0) = 1.5;
uniform float roll_speed : hint_range(0.0, 5.0) = 0.31;
uniform float buzz_amount : hint_range(0.0, 4.0) = 0.15;
uniform float buzz_speed : hint_range(0.0, 60.0) = 27.0;

void vertex() {
	float t = TIME;

	// Roll around the sprite's own centre (Sprite2D is centred by default).
	float a = radians(roll_degrees) * sin(t * roll_speed * TAU);
	float s = sin(a);
	float c = cos(a);
	VERTEX = mat2(vec2(c, s), vec2(-s, c)) * VERTEX;

	// Two out-of-tune sines per axis so the loop never reads as a loop.
	vec2 drift = vec2(
		sin(t * sway_speed) + sin(t * sway_speed * 2.3 + 1.7) * 0.35,
		sin(t * bob_speed + 0.6) + sin(t * bob_speed * 1.9 + 2.4) * 0.3
	) * vec2(sway_amount, bob_amount);

	vec2 buzz = vec2(sin(t * buzz_speed), sin(t * buzz_speed * 1.37 + 2.1)) * buzz_amount;

	VERTEX += drift + buzz;
}
