#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution;

    // Generate a cool color gradient based on time
    vec3 color = 0.5 + 0.5 * sin(vec3(u_time * 0.7, u_time * 0.5, u_time * 0.3));

    // Create a pulsating circular pattern
    float pattern = smoothstep(0.2, 0.3, abs(sin(length(st * u_resolution) + u_time)));

    out_color = vec4(color * pattern, 1.0);
}
