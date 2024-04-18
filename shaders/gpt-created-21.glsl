#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

// Produces a simple soft circle SDF
float circleSDF(vec2 p, vec2 c, float r) {
    return length(p - c) - r;
}

// Repeat pattern utilising the fract function
vec2 repeat(vec2 p, vec2 c) {
    return mod(p, c) - 0.5 * c;
}

// Color palette function for interesting color variability
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d));
}

// Modified pattern function with varying circle displacements
float dynamicCircleSDF(vec2 p, vec2 offset, float baseRadius, float time, float frequency) {
    float dynamicRadius = baseRadius + 0.05 * sin(time * frequency);
    return circleSDF(p, offset, dynamicRadius);
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    vec2 p = uv * 2.0;

    // Apply time-based translation for dynamic movement
    float t = u_time * 0.1;
    p.x += sin(t);
    p.y += cos(t);

    // Recursive pattern effect
    p = repeat(p, vec2(1.0, 1.0));

    // Different time variations for different circles in the pattern
    float d1 = dynamicCircleSDF(p, vec2(-0.5, -0.5), 0.3, u_time, 2.0);
    float d2 = dynamicCircleSDF(p, vec2(0.5, 0.5), 0.3, u_time, 3.0);
    float d3 = dynamicCircleSDF(p, vec2(-0.5, 0.5), 0.3, u_time, 4.0);
    float d4 = dynamicCircleSDF(p, vec2(0.5, -0.5), 0.3, u_time, 5.0);

    float d = min(min(d1, d2), min(d3, d4));  // Combine SDF values for overlay effect

    // Create a smooth blend between colors based on the distance field
    vec3 color = palette(fract(d - u_time * 0.1));

    // Use smoothstep for soft edges
    float alpha = smoothstep(0.02, 0.0, d);

    out_color = vec4(color, alpha);
}
