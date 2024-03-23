#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
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

float lensDistortion(vec2 uv, float u_time) {
    vec2 center = vec2(0.5, 0.5);
    vec2 offset = uv - center;
    float dist = length(offset) * 2.0;
    float distort = sin(dist * 100.0 - u_time) * 0.06;
    return 1.0 + distort;
}

void main() {
    vec2 uv = (gl_FragCoord.xy / u_resolution.xy);
    vec2 distortedUV = uv * lensDistortion(uv, u_time);

    float crystalSeed = sin(distortedUV.x + u_time * 0.5) * cos(distortedUV.y + u_time * 0.5);
    float border = 0.01;

    float red = 0.5 + 0.5 * sin(distortedUV.x * 10.0 + u_time);
    float green = 0.5 + 0.5 * sin(distortedUV.y * 10.0 + u_time);
    float blue = 0.5 + 0.5 * sin((distortedUV.x + distortedUV.y) * 10.0 + u_time);

    float noise = fractalNoise(distortedUV * 3.0 + u_time);

    red += noise * 0.1;
    green += noise * 0.05;
    blue += noise * 0.15;

    float crystalFactor = smoothstep(0.5 - border, 0.5 + border, crystalSeed);
    float crystalColor = 0.5 + 0.5 * sin(distortedUV.x * 10.0 + distortedUV.y * 10.0);

    red = mix(red, crystalColor, crystalFactor * 0.5);
    green = mix(green, crystalColor, crystalFactor * 0.5);
    blue = mix(blue, crystalColor, crystalFactor * 0.5);

    out_color = vec4(red, green, blue, 1.0);
}
