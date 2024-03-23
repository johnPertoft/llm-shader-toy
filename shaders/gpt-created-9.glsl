#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233))) *
        43758.5453123);
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

void main() {
    float waveAmplitude = 0.2;
    float waveFrequency = 4.0;

    float x = gl_FragCoord.x / u_resolution.x;
    float y = gl_FragCoord.y / u_resolution.y - 0.2; // Move the wave down by 0.2 units

    float noiseValue = noise(vec2(x * waveFrequency, u_time)) * 0.5;

    float sineWave = 0.2 + waveAmplitude * sin((x + u_time) * waveFrequency) + noiseValue;

    if (abs(y - sineWave) < 0.025) {
        out_color = vec4(1.0);
    } else {
        discard;
    }
}
