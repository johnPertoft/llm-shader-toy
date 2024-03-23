#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    // Background color pattern with time variation
    float r = 0.5 + 0.5 * sin(u_time / 2.0 + st.x * 10.0);
    float g = 0.5 + 0.5 * sin(u_time / 3.0 + st.y * 20.0);
    float b = 0.5 + 0.5 * sin(u_time / 4.0 + st.x * st.y * 30.0);

    // Radial gradient animation
    float aspectRatio = u_resolution.x / u_resolution.y;
    vec2 center = vec2(0.5, 0.5);
    float radius = 0.3 + 0.2 * sin(u_time);

    // Lighting effect
    vec2 lightDir = normalize(vec2(1.0, 1.0));
    float lightIntensity = dot(lightDir, center - st) * 0.5 + 0.5;

    float dist = distance(st * vec2(aspectRatio, 1.0), center);
    float gradient = smoothstep(radius - 0.01, radius + 0.01, dist);

    // Apply lighting to the background and gradient
    vec3 color = vec3(r, g, b) * (1.0 - gradient) + vec3(gradient, st.x, st.y) * lightIntensity;

    out_color = vec4(color, 1.0);
}
