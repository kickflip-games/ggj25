shader_type canvas_item;

uniform vec4 transparent = vec4(0.0, 0.0, 0.0, 0.0); // Transparent black
uniform vec4 inner = vec4(1.0, 0.5, 0.0, 1.0);       // Bright orange core
uniform vec4 outer = vec4(1.0, 0.2, 0.0, 1.0);       // Reddish outer glow
uniform float inner_threshold = 0.4;
uniform float outer_threshold = 0.15;
uniform float soft_edge = 0.04;
uniform vec2 center = vec2(0.8, 0.5); // Rotated center position

// Hardcoded number of octaves, as dynamic loop bounds are not allowed in Godot
const int OCTAVES = 6;

float rand(vec2 coord) {
	return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) +
	       (c - a) * u.y * (1.0 - u.x) +
	       (d - b) * u.x * u.y;
}

float fbm(vec2 coord) {
	float value = 0.0;
	float scale = 0.5;
	for (int i = 0; i < OCTAVES; i++) {
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

float overlay(float base, float top) {
	if (base < 0.5) {
		return 2.0 * base * top;
	} else {
		return 1.0 - 2.0 * (1.0 - base) * (1.0 - top);
	}
}

float egg_shape(vec2 coord, float radius) {
	vec2 diff = abs(coord - center);
	// Rotated: now we check X coordinate and modify X scaling
	if (coord.x < center.x) {
		diff.x /= 2.0;
	} else {
		diff.x *= 2.0;
	}
	float dist = length(diff) / radius;
	float safe_val = clamp(1.0 - dist * dist, 0.0, 1.0);
	return sqrt(safe_val);
}

void fragment() {
	// Rotate UV coordinates by 90 degrees clockwise
	vec2 rotated_uv = vec2(1.0 - UV.y, UV.x);
	
	vec2 coord = rotated_uv * 8.0;
	vec2 fbmcoord = coord / 6.0;
	
	float egg_s = egg_shape(rotated_uv, 0.4);
	egg_s += egg_shape(rotated_uv, 0.2) / 2.0;
	
	// Adjust noise animation direction for horizontal flame
	float noise1 = noise(coord + vec2(TIME * 4.0, TIME * 0.25));
	float noise2 = noise(coord + vec2(TIME * 7.0, TIME * 0.5));
	float combined_noise = (noise1 + noise2) / 2.0;
	
	// Adjust FBM animation for horizontal movement
	float fbm_noise = fbm(fbmcoord + vec2(TIME * 3.0, 0.0));
	fbm_noise = overlay(fbm_noise, rotated_uv.x); // Use X coordinate for horizontal gradient
	
	float final_val = combined_noise * fbm_noise * egg_s;
	
	if (final_val < outer_threshold) {
		COLOR = transparent;
	} else if (final_val < outer_threshold + soft_edge) {
		COLOR = mix(transparent, outer, (final_val - outer_threshold) / soft_edge);
	} else if (final_val < inner_threshold) {
		COLOR = outer;
	} else if (final_val < inner_threshold + soft_edge) {
		COLOR = mix(outer, inner, (final_val - inner_threshold) / soft_edge);
	} else {
		COLOR = inner;
	}
}