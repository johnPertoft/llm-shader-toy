#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

float fractalPattern(vec2 uv, float time) {
    float scale = 1.0;
    float iterations = 5.0;
    float power = 8.0;

    float s = scale;
    float iterationPower = pow(scale, power);
    float d = 0.0;

    for (float i = 0.0; i < iterations; i++) {
        uv *= iterationPower;
        vec2 uvFloor = floor(uv);
        uv = abs(uv) - 0.5;
        d += max(abs(uv.x), abs(uv.y)) / s;
    }

    return 1.0 - smoothstep(0.0, 0.1, d);
}

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    // Background color pattern with time variation in purple and green theme
    float r = 0.5 + 0.5 * sin(u_time / 2.0 + st.x * 10.0);
    float g = 0.5 + 0.5 * sin(u_time / 3.0 + st.y * 20.0);
    float b = 0.3 + 0.3 * sin(u_time / 4.0 + 2.0 * st.x * st.y * 30.0);

    // Radial gradient animations in a spiral pattern
    float aspectRatio = u_resolution.x / u_resolution.y;

    float radius[27];
    float gradient[27];

    for (int i = 0; i < 27; i++) {
        float angle = u_time * 0.5 + float(i) * 0.3; // Angle increases based on index for spiral effect
        vec2 spiralCenter = vec2(0.5 + 0.3 * cos(angle), 0.5 + 0.3 * sin(angle)); // Center follows a spiral pattern
        radius[i] = 0.1 + 0.05 * sin(u_time + float(i));

        float dist = distance(st * vec2(aspectRatio, 1.0), spiralCenter);
        gradient[i] = smoothstep(radius[i] - 0.01, radius[i] + 0.01, dist);
    }

    // Combine radial effects with the background
    vec3 color = vec3(r, g, b);
    for (int i = 0; i < 27; i++) {
        color = mix(color, vec3(gradient[i], gradient[i], st.x), 0.5);
    }

    out_color = vec4(color, 1.0);
}
