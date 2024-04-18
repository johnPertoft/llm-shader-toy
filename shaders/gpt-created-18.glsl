#version 300 es
precision highp float;

uniform vec2 u_resolution;
uniform float u_time;

out vec4 out_color;

vec3 coolEffect(float x, float y, float time) {
    // Modify position for psychedelic movement
    float offset = cos(time) / 2.0;
    float cx = x - 0.5 + offset * sin(y * 10.0 + time * 2.0);
    float cy = y - 0.5 + offset * cos(x * 10.0 + time * 2.0);

    // Color cycling influenced by position and time
    float i = sin(cx * 10.0 + time) + cos(cy * 10.0 + time);
    float r = 0.5 + 0.5 * sin(i * 2.0 + time);
    float g = 0.5 + 0.5 * cos(i * 2.8 + time);
    float b = 0.5 + 0.5 * sin(i * 3.6 + time);

    // Blur edges for a more dreamlike feeling
    float edgeBlur = 0.02 / length(u_resolution - 2.0 * gl_FragCoord.xy);
    r += edgeBlur;
    g += edgeBlur;
    b += edgeBlur;

    return vec3(r, g, b);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec3 color = coolEffect(uv.x, uv.y, u_time);
    out_color = vec4(color, 1.0);
}
