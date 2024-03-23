#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

float fractalNoise(vec2 p) {
    float val = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;

    for (int i = 0; i < 5; i++) {
        val += amplitude * rand(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return val;
}

void main() {
    vec2 position = (gl_FragCoord.xy / u_resolution.xy) + u_time * 0.05; // Slower movement factor
    float v = 0.0;
    v += sin(position.x * 50.0) + cos(position.y * 50.0); // Adjusted frequencies for a slower effect
    v += sin(position.y * 25.0) + cos(position.x * 25.0);
    v += sin(position.x * 5.0) + cos(position.y * 5.0);

    float red = 0.5 + 0.5 * sin(v + u_time);
    float green = 0.5 + 0.5 * sin(v + u_time + 2.0);
    float blue = 0.5 + 0.5 * sin(v + u_time + 4.0);

    // Add fractal noise effect
    float noise = fractalNoise(position * 3.0 + u_time);

    // Apply noise to colors
    red += noise * 0.2;
    green += noise * 0.1;
    blue += noise * 0.3;

    out_color = vec4(red, green, blue, 1.0);
}
