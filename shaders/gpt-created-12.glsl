#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

vec3 fractal(vec3 p, int iter) {
    for (int i = 0; i < iter; i++) {
        p = abs(p) / dot(p, p) - 0.5;
    }
    return p;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv = uv * 4.0 - 2.0;

    float time = u_time * 0.5;

    vec3 color = fractal(vec3(uv, time), 20); // Increased recursiveness here

    out_color = vec4(color, 1.0);
}
