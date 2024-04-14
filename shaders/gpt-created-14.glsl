#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

float lensDistortion(float rad, float strength) {
    return rad * (1.0 + strength * rad * rad);
}

// Function for creating a starry background pattern
float starryPattern(vec2 uv, float scale) {
    float strength = 0.0;
    uv *= scale;
    vec2 grid = fract(uv) - 0.5;
    float dist = length(grid);
    strength = smoothstep(0.03, 0.02, dist);
    return strength;
}

void main() {
    vec2 center = u_resolution * 0.5;
    vec2 uv = (gl_FragCoord.xy - center) / center.y;
    float r = length(uv);
    float distortedR = lensDistortion(r, -1.2); // Increased lens distortion effect
    uv = normalize(uv) * distortedR;

    float angle = atan(uv.y, uv.x);
    float swirl = r * cos(angle + u_time * 0.25) * 2.0;
    float distort = lensDistortion(r, -1.2); // Increased lens distortion effect

    // Black hole effect
    float holeRadius = 0.3 + 0.1 * sin(u_time);
    float holeEdge = smoothstep(holeRadius, holeRadius + 0.05, distort);

    // Modified Golden Halo: spreads outwards to left and right.
    float haloRadius = holeRadius + 0.025;
    float haloThickness = 0.0125;
    float haloYStrength = smoothstep(haloRadius, haloRadius + haloThickness, distort) * 0.5;
    // X spread factor, goes off like an asymptote.
    float haloXFactor = smoothstep(0.1, 0.3, abs(uv.x)) * (1.0 - haloYStrength);
    vec3 haloColor = vec3(0.8, 0.7, 0.3) * haloYStrength * haloXFactor;

    float background = starryPattern(uv * 10.0 + vec2(u_time * 0.1), 10.0);

    // Blend all effects and background
    float colorMix = (1.0 - holeEdge + swirl * holeEdge) * 0.2 + background * 0.8;
    vec3 finalColor = mix(vec3(colorMix), haloColor, max(haloYStrength, haloXFactor));

    out_color = vec4(finalColor, 1.0);
}
