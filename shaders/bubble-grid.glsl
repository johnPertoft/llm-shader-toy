#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

#define PI 3.14159265359

vec2 getCenter(float time) {
    float speed = 0.6;
    float zigzag = sin(time * speed) * cos(time * speed * 2.0);
    return vec2(0.5, 0.2) + vec2(cos(time * speed), zigzag)*0.3;
}

vec2 getBubble(vec2 uv, float time) {
    vec2 center = getCenter(time);
    float dist = length(uv - center);
    float factor = sin(2.0*PI*dist - time)*0.07/dist;
    return uv + factor*(uv - center);
}

vec3 getColor(float dist) {
    float hue = mod(dist * 3.0, 1.0);
    float saturation = 1.0;
    float value = 1.0;

    // Convert HSV to RGB
    int hi = int(hue * 6.0);
    float f = hue * 6.0 - float(hi);
    float p = value * (1.0 - saturation);
    float q = value * (1.0 - f * saturation);
    float t = value * (1.0 - (1.0 - f) * saturation);

    vec3 color;

    if (hi == 0) color = vec3(value, t, p);
    else if (hi == 1) color = vec3(q, value, p);
    else if (hi == 2) color = vec3(p, value, t);
    else if (hi == 3) color = vec3(p, q, value);
    else if (hi == 4) color = vec3(t, p, value);
    else color = vec3(value, p, q);

    return color;
}

vec3 getSmiley(vec2 uv, vec2 center, float time) {
    vec3 color = vec3(1.0, 1.0, 0.0);
    float eye_r = length(uv - center - vec2(-0.05, 0.05));
    float eye_l = length(uv - center - vec2(0.05, 0.05));

    if (eye_r < 0.01 || eye_l < 0.01) {
        color = vec3(0.0, 0.0, 0.0);
    }

    vec2 mouth_pos = uv - center;
    vec2 mouth_offset = center - uv;
    float angle = atan(mouth_offset.y, mouth_offset.x);
    float dist = length(mouth_offset);

    float smile_size = sin(time) * 0.5 + 0.5; // Range 0 to 1
    float smile_lower_angle = mix(0.0, PI / 2.0, smile_size);
    float smile_upper_angle = mix(PI / 2.0, PI, 1.0 - smile_size);

    if (dist > 0.065 && dist < 0.07 && angle > smile_lower_angle && angle < smile_upper_angle) {
        color = vec3(0.0, 0.0, 0.0);
    }

    return color;
}

void main() {
    // Normalized pixel coordinates
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    vec2 bubbleUV = getBubble(uv, u_time);
    vec2 grid_pos = mod(bubbleUV * 40.0, 1.0);
    vec3 color = vec3(0.0);

    vec2 center = getCenter(u_time);
    float dist = length(uv - center);

    if (grid_pos.x < 0.03 || grid_pos.y < 0.03) {
        float fade = 1.0 - smoothstep(0.0, 0.2, dist); // Fade out towards the bubble center
        color = getColor(dist) * fade;
    }

    out_color = vec4(color, 1.0);
}
