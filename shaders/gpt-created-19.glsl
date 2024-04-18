#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 centered_uv = (uv - 0.5) * 2.0;
    float angle = atan(centered_uv.y, centered_uv.x);
    float radius = length(centered_uv);

    float wave = sin(radius * 10.0 - u_time * 4.0);
    float wave2 = sin(angle * 8.0 - u_time * 2.0);

    float r = 0.5 + 0.5 * sin(wave + u_time * 1.5 + wave2);
    float g = 0.5 + 0.5 * sin(wave - u_time * 0.5 + wave2);
    float b = 0.5 + 0.5 * cos(wave - u_time * 2.0 + wave2);

    out_color = vec4(r, g, b, 1.0);
}
