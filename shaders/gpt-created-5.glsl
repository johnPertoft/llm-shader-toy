#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

float sdOrganicShape(vec2 p, float time) {
    float noiseFactor = 0.4 * sin(time * 1.0); // Increased noise factor
    float displacement = sin(p.x * p.y + time) + sin(p.x + p.y + time) * noiseFactor * 3.0; // Further increased displacement effect
    return length(p) - 0.5 - 0.2 * displacement; // Increased overall displacement
}

vec3 lighting(vec2 p, vec2 lightPos, vec3 lightColor, float ambient) {
    vec2 lightDir = normalize(lightPos - p);
    float diff = max(dot(lightDir, normalize(p)), 0.0);

    vec3 finalColor = vec3(0.0);
    finalColor += lightColor * diff + ambient;

    return finalColor;
}

void main() {
    float time = u_time;

    vec2 p = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);

    vec2 lightPos1 = vec2(0.2 + 0.1 * sin(time), 0.7 - 0.1 * cos(time)); // Moving first light source
    vec2 lightPos2 = vec2(0.8 - 0.1 * sin(time), 0.3 + 0.1 * cos(time)); // Moving second light source

    vec3 lightColor1 = vec3(1.0, 0.5, 0.8); // Pinkish hue
    vec3 lightColor2 = vec3(0.5, 1.0, 0.2); // More greenish light source color

    float d = sdOrganicShape(p, time); // signed distance to organic shape

    float ambient = 0.1;
    vec3 color = vec3(1.0 - smoothstep(-0.01, 0.01, d)) * 0.5;

    vec3 finalColor = lighting(p, lightPos1, lightColor1, ambient) + lighting(p, lightPos2, lightColor2, ambient) + color;

    out_color = vec4(finalColor, 1.0);
}
