#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main() {
    float x = gl_FragCoord.x / u_resolution.x;
    float y = gl_FragCoord.y / u_resolution.y;

    float waveHeight = 0.2 * sin(u_time + x * 10.0);
    float threshold = 0.05;

    float noise = random(vec2(floor(x * 100.0), floor(u_time * 100.0))) * 0.2 - 0.1;

    if (abs(y - 0.5 + waveHeight + noise) < threshold) {
        float r = 0.5 + 0.5 * sin(u_time + x);
        float g = 0.5 + 0.5 * sin(u_time / 3.0 + x);
        float b = 0.5 + 0.5 * sin(u_time / 5.0 + x);
        out_color = vec4(r, g, b, 1.0);
    } else {
        out_color = vec4(0.0, 0.0, 0.0, 1.0);
    }
}
