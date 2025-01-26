shader_type canvas_item;

void vertex() {
    // Upward movement
    UV.y += TIME * 0.1;

    // Horizontal wobble
    UV.x += sin(TIME * 2.0) * 0.02;
}
