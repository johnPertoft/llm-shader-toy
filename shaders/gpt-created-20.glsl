#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    vec2 centered_uv = (uv - 0.5) * 2.0;
    float angle = atan(centered_uv.y, centered_uv.x) / (2.0 * 3.1415926535897932384626433832795);
    float radius = length(centered_uv);

    float t = u_time * 0.1;
    vec2 p = fract(vec2(t - radius, t + angle));
    vec2 recurse_p = fract(vec2(sin(10.0 * t - p.x * 40.0), cos(10.0 * t - p.y * 40.0)));

    float wave = sin(recurse_p.x * 40.0 - t);
    float wave2 = sin(recurse_p.y * 32.0 - t);

    float r = 0.5 + 0.5 * sin(wave + t * 1.5 + wave2);
    float g = 0.5 + 0.5 * sin(wave - t * 0.5 + wave2);
    float b = 0.5 + 0.5 * cos(wave - t * 2.0 + wave2);

    out_color = vec4(r, g, b, 1.0);
}
